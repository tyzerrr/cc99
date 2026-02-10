local M = {}

local cc99_state = {
	open = false,
	buf = nil,
	win = nil,
	marked = {
		start_line = nil,
		end_line = nil,
	},
}

local function get_project_root()
	local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return vim.fn.getcwd()
	end
	return root
end

local function get_cc99_md_path()
	return get_project_root() .. "/.cc99/CC99.md"
end

local function read_cc99_md()
	local path = get_cc99_md_path()
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

local function ensure_cc99_md(callback)
	local path = get_cc99_md_path()
	print("[cc99] CC99.md path:", path)
	if vim.fn.filereadable(path) == 1 then
		print("[cc99] CC99.md exists, skipping generation")
		callback()
		return
	end
	-- Create .cc99 directory
	local dir = get_project_root() .. "/.cc99"
	print("[cc99] Creating directory:", dir)
	vim.fn.mkdir(dir, "p")
	print("[cc99] Starting Claude for project analysis...")
	-- Ask Claude to analyze the project and write CC99.md
	vim.system({
		"claude",
		"--dangerously-skip-permissions",
		"--allowedTools",
		"Read,Grep,Glob,LS",
		"--print",
		"Analyze this project. Understand the languages used, project structure, and purpose. "
			.. "Output a concise markdown summary (in Japanese) covering: "
			.. "1. Project overview 2. Languages/frameworks 3. Directory structure 4. Key files. "
			.. "Output ONLY the markdown content, no code fences.",
	}, { text = true }, function(obj)
		vim.schedule(function()
			print("[cc99] Claude analysis done. code:", obj.code)
			print("[cc99] stderr:", obj.stderr or "(none)")
			print("[cc99] stdout length:", #(obj.stdout or ""))
			local stdout = obj.stdout or ""
			if #stdout > 0 then
				local f = io.open(path, "w")
				if f then
					f:write(stdout)
					f:close()
					print("[cc99] CC99.md written to:", path)
				else
					print("[cc99] ERROR: could not open file for writing:", path)
				end
			else
				print("[cc99] WARNING: Claude returned empty stdout")
			end
			callback()
		end)
	end)
end

local create_floating_window = function()
	local win_height = math.floor(vim.o.lines * 0.6)
	local win_width = math.floor(vim.o.columns * 0.6)
	local row = math.floor((vim.o.lines - win_height) / 2)
	local col = math.floor((vim.o.columns - win_width) / 2)

	if cc99_state.buf == nil then
		cc99_state.buf = vim.api.nvim_create_buf(false, true)
	end
	cc99_state.win = vim.api.nvim_open_win(cc99_state.buf, true, {
		relative = "editor",
		row = row,
		col = col,
		width = win_width,
		height = win_height,
		border = "rounded",
		style = "minimal",
		title = "cc99",
		title_pos = "center",
	})
	cc99_state.open = true
end

local cc99_open = function()
	if cc99_state.open then
		return
	end

	vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes("<Esc>", true, false, true), "nx", false)
	local start_line = vim.fn.line("'<")
	local end_line = vim.fn.line("'>")
	if start_line > end_line then
		start_line, end_line = end_line, start_line
	end
	cc99_state.marked.start_line = start_line - 1
	cc99_state.marked.end_line = end_line
	create_floating_window()
end

local cc99_close = function()
	if not cc99_state.open then
		return
	end
	vim.api.nvim_win_close(cc99_state.win, true)
	cc99_state.open = false
end

local cc99_exec = function()
	local elems = vim.api.nvim_buf_get_lines(cc99_state.buf, 0, -1, false)
	if not cc99_state.open then
		return
	end
	vim.api.nvim_win_close(cc99_state.win, true)
	cc99_state.open = false

	local user_prompt = "<USER PROMPT>\n"
	local prompt_content = table.concat(elems, " ")
	user_prompt = user_prompt .. prompt_content .. "\n</USER PROMPT>\n"

	local selected_code = "<REPLACED>\n"
	local code_lines = vim.api.nvim_buf_get_lines(0, cc99_state.marked.start_line, cc99_state.marked.end_line, false)
	selected_code = selected_code .. table.concat(code_lines, "\n") .. "\n</REPLACED>\n"
	user_prompt = user_prompt .. selected_code

	print("[cc99] ccx triggered, prompt:", user_prompt)
	ensure_cc99_md(function()
		print("[cc99] ensure_cc99_md callback fired")
		local system_prompt = [[You are a code-only assistant embedded in a text editor.
		 Your output will directly replace the user's selected code.
         THIS RULE MUST BE FOLLOWED STRICTLY.

		 RULES:
             1. Output ONLY the replacement code.
             2. NEVER include explanations, descriptions, or commentary.
             3. NEVER wrap output in markdown code fences (``` or ```lua etc).
             4. Output nothing before or after the code.

         INPUT FORMAT:
            <USER PROMPT>
                {USER PROMPT }
            </USER PROMPT>
            <REPLACED>
                {USER SELECTED CODE}
            </REPLACED>

        
         OUTPUT FORMAT:
         <CODE>
            {YOUR OUTPUT REPLACEMENT CODE}
         </CODE>
         ]]

		local context = read_cc99_md()
		if context then
			print("[cc99] CC99.md loaded, length:", #context)
			system_prompt = system_prompt .. "\n\n<PROJECT_CONTEXT>\n" .. context .. "\n</PROJECT_CONTEXT>"
		else
			print("[cc99] CC99.md not found or empty")
		end

		vim.system({
			"claude",
			"--dangerously-skip-permissions",
			"--allowedTools",
			"Read,Grep,Glob,LS",
			"--system-prompt",
			system_prompt,
			"--print",
			user_prompt,
		}, { text = true }, function(obj)
			vim.schedule(function()
				print("[cc99] Main Claude done. code:", obj.code)
				print("[cc99] stderr:", obj.stderr or "(none)")
				local stdout = obj.stdout or ""
				print("[cc99] stdout length:", #stdout)
				local code = stdout:match("<CODE>\n?(.-)\n?</CODE>")
				if code then
					code = code:gsub("^%s*\n", ""):gsub("\n%s*$", "")
				else
					code = stdout
				end
				local lines = vim.split(code, "\n")
				vim.api.nvim_buf_set_lines(0, cc99_state.marked.start_line, cc99_state.marked.end_line, false, lines)
			end)
		end)
	end)
end

--- user commands
vim.api.nvim_create_user_command("CC99Open", cc99_open, {})
vim.api.nvim_create_user_command("CC99Close", cc99_close, {})
vim.api.nvim_create_user_command("CC99Exec", cc99_exec, {})

--- remap
vim.keymap.set("v", "<leader>cco", "<cmd>CC99Open<CR>", {})
vim.keymap.set("n", "<leader>ccq", "<cmd>CC99Close<CR>")
vim.keymap.set("n", "<leader>ccx", "<cmd>CC99Exec<CR>", {})
return M

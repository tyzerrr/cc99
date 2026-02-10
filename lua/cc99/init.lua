local cc99_fs = require("cc99.fs")
local cc99_prompt = require("cc99.prompt")

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

---@param cb function: this is the main part for cc99
local function init(cb)
	local path = cc99_fs.get_cc99_md_path()
	print("[cc99] CC99.md path:", path)
	if vim.fn.filereadable(path) == 1 then
		print("[cc99] CC99.md exists, skipping generation")
		cb()
		return
	end
	-- Create .cc99 directory
	local dir = cc99_fs.get_cc99_dir()
	print("[cc99] Creating directory:", dir)
	vim.fn.mkdir(dir, "p")
	print("[cc99] Starting Claude for project analysis...")
	-- Ask Claude to analyze the project and write CC99.md
	local init_md_path = cc99_fs.get_prompts_dir() .. "/init.md"
	local init_md_content = cc99_fs.read_md(init_md_path)
	if not init_md_content then
		print("[cc99] ERROR: could not read init.md from:", init_md_path)
		vim.notify("CC99 Error: could not read init.md. Check the logs for details.", vim.log.levels.ERROR)
		return
	end
	vim.system({
		"claude",
		"--dangerously-skip-permissions",
		"--allowedTools",
		"Read,Grep,Glob,LS",
		"--print",
		init_md_content,
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
			cb()
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

---@param system_prompt string
---@param user_prompt string
---@return nil
local exec = function(system_prompt, user_prompt)
	print("[cc99] init callback fired")

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
end

local cc99_exec = function()
	vim.api.nvim_win_close(cc99_state.win, true)
	cc99_state.open = false

	--- user prompt
	local user_prompt = cc99_prompt.build_user_prompt(
		cc99_state.buf,
		cc99_state.marked.start_line,
		cc99_state.marked.end_line,
		cc99_state.open
	)
	if not user_prompt then
		print("[cc99] ERROR: user prompt is empty, aborting execution")
		vim.notify("CC99 Error: user prompt is empty. Check the logs for details.", vim.log.levels.ERROR)
		return
	end

	--- system prompt
	local system_prompt = cc99_prompt.build_system_prompt()
	if not system_prompt then
		print("[cc99] ERROR: system prompt is empty, aborting execution")
		vim.notify("CC99 Error: system prompt is empty. Check the logs for details.", vim.log.levels.ERROR)
		return
	end

	init(function()
		exec(system_prompt, user_prompt)
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

local cc99_ui = require("cc99.v2.ui")
local cc99_fs = require("cc99.v2.fs")
local cc99_service = require("cc99.v2.service")
local cc99_domain = require("cc99.v2.domain")

local M = {}

---@return V2Float
local create_float = function()
  local start_pos = vim.fn.getpos("v")
  local end_pos = vim.fn.getpos(".")
  local start_row, start_col = start_pos[2], start_pos[3]
  local end_row, end_col = end_pos[2], end_pos[3]
  if start_row > end_row then
    start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
  end

  local ns_id = vim.api.nvim_create_namespace("cc99.v2")
  local range = cc99_ui.V2Range.new(
    cc99_ui.V2Point.from_1_indexed(start_row, start_col),
    cc99_ui.V2Point.from_1_indexed(end_row, end_col)
  )
  local extmark_id =
    vim.api.nvim_buf_set_extmark(vim.api.nvim_get_current_buf(), ns_id, range.start.row, range.start.col, {})
  local mark = cc99_ui.V2Mark.new(range, extmark_id, ns_id)

  return cc99_ui.V2Float.new(vim.api.nvim_create_buf(false, true), -1, false, mark)
end

---@type V2Float | nil
local float = nil

M.open_float = function()
  if float == nil then
    vim.notify("Creating float window...", vim.log.levels.INFO)
    float = create_float()
  end
  float:open()
end

M.close_float = function()
  if float == nil then
    vim.notify("float window is not created, something went wrong", vim.log.levels.ERROR)
    return
  end
  float:close()
end

---@return string | nil
local prepare_for_analyze = function()
  local dir = cc99_fs.V2FS.get_cc99_dir()
  print("[cc99] Creating directory:", dir)
  vim.fn.mkdir(dir, "p")
  print("[cc99] Starting Claude for project analysis...")
  -- Ask Claude to analyze the project and write CC99.md
  local analyze_md = cc99_fs.V2FS.get_prompts_dir() .. "/analyze.md"
  local analyze_md_content = cc99_fs.V2FS.read_md(analyze_md)
  if not analyze_md_content then
    print("[cc99] ERROR: could not read init.md from:", analyze_md)
    return nil
  end
  return analyze_md_content
end

M.analyze = function()
  --- Analyze entire project, then write the {PROJECT_ROOT}/.cc99/CC99.md
  local path = cc99_fs.V2FS.get_cc99_md_path()
  print("[cc99] CC99.md path:", path)
  if vim.fn.filereadable(path) == 1 then
    print("[cc99] CC99.md exists, skipping analyze")
    return
  end

  --- Create .cc99 directory, then read the anaylyze_md_content
  local analyze_md_content = prepare_for_analyze()
  if not analyze_md_content then
    vim.notify("CC99 Error: could not read init.md. Check the logs for details.", vim.log.levels.ERROR)
    return
  end

  ---@type Observer
  local analyze_observer = {
    on_exit = function(obj)
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
    end,
  }

  local analysis_cmd = {
    "claude",
    "--dangerously-skip-permissions",
    "--allowedTools",
    "Read,Grep,Glob,LS",
    "--print",
    analyze_md_content,
  }
  cc99_service.ClaudeCodeService:request(analysis_cmd, analyze_observer)
end

---@param text string
---@return string[]
local split_lines = function(text)
  local content = string.match(text, "<CODE>\n?(.-)\n?</CODE>")
  if not content then
    return {}
  end
  return vim.split(content, "\n")
end

---@param context Context
---@param mark V2Mark
M.replace = function(context, mark)
  local buf = vim.api.nvim_get_current_buf()
  local response_buffer = ""
  print("[cc99] init callback fired")

  ---@type Observer
  local observer = {
    on_stdout = function(err, data)
      if err then
        vim.schedule(function()
          print("[cc99] Claude stdout error:", err)
          vim.notify("[CC99 Error stdout]: Claude has errors. " .. err, vim.log.levels.ERROR)
        end)
        return
      end
      if not data then
        vim.schedule(function()
          vim.notify("[CC99 Warning stdout]: Claude returned no data.", vim.log.levels.WARN)
        end)
        return
      end
      response_buffer = response_buffer .. data
    end,

    on_stderr = function(err, data)
      if err then
        vim.schedule(function()
          print("[cc99] Claude stderr error:", err)
          vim.notify("[CC99 Error stderr]: Claude has stderr errors. " .. err, vim.log.levels.ERROR)
        end)
        return
      end
      if not data then
        vim.schedule(function()
          vim.notify("[CC99 Warning stderr]: Claude stderr returned no data.", vim.log.levels.WARN)
        end)
        return
      end
    end,

    on_exit = function(obj)
      local lines = split_lines(response_buffer)
      vim.schedule(function()
        print("[cc99] Main Claude done. code:", obj.code)
        if #lines > 0 then
          local pos = vim.api.nvim_buf_get_extmark_by_id(buf, mark.ns_id, mark.extmark_id, {})
          print("[on exit]: position by vim.api.nvim_buf_get_extmark_by_id:", vim.inspect(pos))
          local start_row = pos[1]
          print("[on exit]: start_row:", start_row)
          local end_row = start_row + mark.range.end_.row - mark.range.start.row + 1
          print("[on exit]: end_row:", end_row)
          vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), start_row, end_row, false, lines)
        end
        response_buffer = ""
      end)
    end,
  }

  local query = {
    "claude",
    "--dangerously-skip-permissions",
    "--allowedTools",
    "Read,Grep,Glob,LS",
    "--system-prompt",
    context.prompt.system_prompt,
    "--print",
    context.prompt.user_prompt,
  }

  cc99_service.ClaudeCodeService:request(query, observer)
end

M.cc_exec = function()
  if float == nil then
    vim.notify("float window is not created, something went wrong", vim.log.levels.ERROR)
    return
  end

  --- Analyze project
  M.analyze()
  local analysis = cc99_fs.V2FS.read_md(cc99_fs.V2FS.get_cc99_md_path())
  if not analysis then
    vim.notify("Failed to read analysis from CC99.md", vim.log.levels.ERROR)
    return
  end

  -- Get user prompt from float buffer
  local user_prompt_lines = vim.api.nvim_buf_get_lines(float.buf, 0, -1, false)
  local user_prompt = table.concat(user_prompt_lines, "\n")

  --- move focus to editor buffer
  float:close()
  local code_to_replace_lines = vim.api.nvim_buf_get_lines(
    vim.api.nvim_get_current_buf(),
    float.mark.range.start.row,
    float.mark.range.end_.row + 1,
    false
  )

  --- Get code to replace
  local code_to_replace = table.concat(code_to_replace_lines, "\n")
  local system_prompt_path = cc99_fs.V2FS.get_prompts_dir() .. "/system.md"
  local system_prompt = cc99_fs.V2FS.read_md(system_prompt_path)
  if not system_prompt then
    vim.notify("Failed to read system prompt from " .. system_prompt_path, vim.log.levels.ERROR)
    return
  end

  -- build context
  local prompt = cc99_domain.Prompt.new(system_prompt, user_prompt)
  local context = cc99_domain.Context.new(prompt, code_to_replace, analysis)

  --- replace code
  M.replace(context, float.mark)
end

return M

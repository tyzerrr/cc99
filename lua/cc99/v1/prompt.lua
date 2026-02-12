local PROMPT = {}

local cc99_fs = require("cc99.fs")

---@return string | nil
PROMPT.build_system_prompt = function()
    local system_prompt_path = cc99_fs.FS:get_prompts_dir() .. "/system.md"
    local system_prompt = cc99_fs.FS:read_md(system_prompt_path)
    if not system_prompt then
        print("[cc99] ERROR: could not read system.md from:", system_prompt_path)
        return
    end

    local context = cc99_fs.FS:read_cc99_md()
    if not context then
        print("[cc99] CC99.md not found or empty")
        return
    end
    system_prompt = system_prompt .. "\n\n<PROJECT_CONTEXT>\n" .. context .. "\n</PROJECT_CONTEXT>"
    return system_prompt
end

---@param bufnr number
---@param mark_start_row number
---@param mark_end_row number
---@param buf_open boolean
---@return string | nil
PROMPT.build_user_prompt = function(bufnr, mark_start_row, mark_end_row, buf_open)
    local elems = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
    if buf_open then
        print("[cc99] ERROR: build_user_prompt called but cc99 is not open")
        return
    end

    local user_prompt = "<USER PROMPT>\n"
    local prompt_content = table.concat(elems, " ")
    user_prompt = user_prompt .. prompt_content .. "\n</USER PROMPT>\n"

    local selected_code = "<REPLACED>\n"
    local code_lines = vim.api.nvim_buf_get_lines(0, mark_start_row, mark_end_row, false)
    selected_code = selected_code .. table.concat(code_lines, "\n") .. "\n</REPLACED>\n"
    user_prompt = user_prompt .. selected_code
    print("[cc99] ccx triggered, prompt:", user_prompt)
    return user_prompt
end

return PROMPT

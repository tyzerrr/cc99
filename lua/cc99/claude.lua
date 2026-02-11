---@class Claude
---@field fs FS
---@field tsb TextStreamBuffer | nil
---@field request_status RequestStatus | nil
local Claude = {}
Claude.__index = Claude

---@param fs FS
---@param tsb TextStreamBuffer | nil
---@return Claude
function Claude.new(fs, tsb, request_status)
    local self = setmetatable({}, Claude)
    self.fs = fs
    self.tsb = tsb
    self.request_status = request_status
    return self
end

function Claude:analyze()
    local path = self.fs:get_cc99_md_path()
    print("[cc99] CC99.md path:", path)
    if vim.fn.filereadable(path) == 1 then
        print("[cc99] CC99.md exists, skipping analyze")
        return
    end
    -- Create .cc99 directory
    local dir = self.fs:get_cc99_dir()
    print("[cc99] Creating directory:", dir)
    vim.fn.mkdir(dir, "p")
    print("[cc99] Starting Claude for project analysis...")
    -- Ask Claude to analyze the project and write CC99.md
    local analyze_md = self.fs:get_prompts_dir() .. "/analyze.md"
    local analyze_md_content = self.fs:read_md(analyze_md)
    if not analyze_md_content then
        print("[cc99] ERROR: could not read init.md from:", analyze_md)
        vim.notify("CC99 Error: could not read init.md. Check the logs for details.", vim.log.levels.ERROR)
        return
    end
    vim.system({
        "claude",
        "--dangerously-skip-permissions",
        "--allowedTools",
        "Read,Grep,Glob,LS",
        "--print",
        analyze_md_content,
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
        end)
    end)
end

---@param system_prompt string
---@param user_prompt string
---@param marked MarkedState
function Claude:exec(system_prompt, user_prompt, marked)
    print("[cc99] init callback fired")
    self.request_status:start()
    vim.system({
        "claude",
        "--dangerously-skip-permissions",
        "--allowedTools",
        "Read,Grep,Glob,LS",
        "--system-prompt",
        system_prompt,
        "--print",
        user_prompt,
    }, {
        text = true,
        stdout = function(err, data)
            if err then
                print("[cc99] Claude stdout error:", err)
                vim.notify("[CC99 Error]: Claude has errors. " .. err, vim.log.levels.ERROR)
                return
            end
            if not data then
                vim.notify("[CC99 Warning]: Claude returned no data.", vim.log.levels.WARN)
                return
            end
            self.tsb:insert(data)
            self.tsb:drain()
        end,
        stderr = function(err, data)
            if err then
                print("[cc99] Claude stderr error:", err)
                vim.notify("[CC99 Error]: Claude has stderr errors. " .. err, vim.log.levels.ERROR)
                return
            end
            if not data then
                vim.notify("[CC99 Warning]: Claude stderr returned no data.", vim.log.levels.WARN)
                return
            end
        end,
    }, function(obj)
        self.tsb:flush()
        vim.schedule(function()
            print("[cc99] Main Claude done. code:", obj.code)
            self.request_status:stop()
            if #self.tsb.code_lines > 0 then
                vim.api.nvim_buf_set_lines(
                    vim.api.nvim_get_current_buf(),
                    marked.start_row,
                    marked.end_row,
                    false,
                    self.tsb.code_lines
                )
            end
        end)
    end)
end

return {
    Claude = Claude,
}

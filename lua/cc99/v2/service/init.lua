---@class Observer
---@field on_exit fun(obj: vim.SystemCompleted)
---@field on_stdout fun(err: string?, data: string?, )?
---@field on_stderr fun(err: string?, data: string?)?
local Observer = {}

---@class ProviderService
local ProviderService = {}

---@param query string[]
---@param observer Observer
---@return nil
function ProviderService:request(query, observer)
  vim.system(query, {
    text = true,
    stdout = function(err, data)
      print("[stdout], data:", data)
      print("[stdout], err:", err)
      if err then
        vim.notify("Error in stdout: " .. err, vim.log.levels.ERROR)
        return
      end
      observer.on_stdout(err, data)
    end,
    stderr = function(err, data)
      print("[stderr], data:", data)
      print("[stderr], err:", err)
      if err then
        vim.notify("Error in stderr: " .. err, vim.log.levels.ERROR)
        return
      end
      observer.on_stderr(err, data)
    end,
  }, vim.schedule_wrap(observer.on_exit))
end

local ClaudeCodeService = setmetatable({}, { __index = ProviderService })

return {
  ClaudeCodeService = ClaudeCodeService,
}

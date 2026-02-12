---@class Observer
---@field on_exit fun(obj: vim.SystemCompleted)
---@field on_stdout fun(data: string?)?
---@field on_stderr fun(data: string?)?
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
      if err then
        vim.notify("Error in stdout: " .. err, vim.log.levels.ERROR)
        return
      end
      observer.on_stdout(data)
    end,
    stderr = function(err, data)
      if err then
        vim.notify("Error in stderr: " .. err, vim.log.levels.ERROR)
        return
      end
      observer.on_stderr(data)
    end,
  }, vim.schedule_wrap(observer.on_exit))
end

local ClaudeCodeService = setmetatable({}, { __index = ProviderService })

return {
  ClaudeCodeService = ClaudeCodeService,
}

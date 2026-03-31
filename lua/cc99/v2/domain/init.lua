---@class Prompt
---@field system_prompt string
---@field user_prompt string
local Prompt = {}
Prompt.__index = Prompt

---@param system_prompt string
---@param user_prompt string
---@return Prompt
function Prompt.new(system_prompt, user_prompt)
  return setmetatable({
    system_prompt = system_prompt,
    user_prompt = user_prompt,
  }, Prompt)
end

---@class Context
---@field prompt Prompt
---@field replace_code string
---@field code_analysis string
local Context = {}
Context.__index = Context

---@return Context
function Context.new(prompt, replace_code, code_analysis)
  return setmetatable({
    prompt = prompt,
    replace_code = replace_code,
    code_analysis = code_analysis,
  }, Context)
end

function Context:get_full_prompt()
  return function() end
end

return {
  Prompt = Prompt,
  Context = Context,
}

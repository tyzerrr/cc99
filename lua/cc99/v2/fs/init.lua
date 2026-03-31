---V2FS is a utility class.
---@class V2FS
local V2FS = {}

---@param path string
---@return string | nil
function V2FS.read_md(path)
  local f = io.open(path, "r")
  if not f then
    vim.notify("Failed to open file: " .. path, vim.log.levels.ERROR)
    return nil
  end
  local content = f:read("*a")
  f:close()
  return content
end

---@return string
function V2FS.get_project_root()
  local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
  if vim.v.shell_error ~= 0 then
    return vim.fn.getcwd()
  end
  return root
end

---@return string
function V2FS.get_cc99_md_path()
  return V2FS.get_project_root() .. "/.cc99/CC99.md"
end

---@return string
function V2FS.get_cc99_dir()
  return V2FS.get_project_root() .. "/.cc99"
end

---@return string
function V2FS.get_prompts_dir()
  return V2FS.get_project_root() .. "/.cc99/prompts"
end

return {
  V2FS = V2FS,
}

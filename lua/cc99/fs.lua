---@class FS
local FS = {}
FS.__index = FS

---@return FS
function FS.new()
    return setmetatable({}, FS)
end

---@return string
function FS:get_project_root()
    local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
    if vim.v.shell_error ~= 0 then
        return vim.fn.getcwd()
    end
    return root
end

---@return string
function FS:get_cc99_md_path()
    return self:get_project_root() .. "/.cc99/CC99.md"
end

---@return string
function FS:get_cc99_dir()
    return self:get_project_root() .. "/.cc99"
end

---@return string
function FS:get_prompts_dir()
    return self:get_project_root() .. "/.cc99/prompts"
end

---@param path string
---@return string|nil
function FS:read_md(path)
    local f = io.open(path, "r")
    if not f then
        return nil
    end
    local content = f:read("*a")
    f:close()
    return content
end

---@return string|nil
function FS:read_cc99_md()
    return self:read_md(self:get_cc99_md_path())
end

return {
    FS = FS,
}

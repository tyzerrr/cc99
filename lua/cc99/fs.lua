local FS = {}

---@return string
FS.get_project_root = function()
	local root = vim.fn.systemlist("git rev-parse --show-toplevel")[1]
	if vim.v.shell_error ~= 0 then
		return vim.fn.getcwd()
	end
	return root
end

---@return string
FS.get_cc99_md_path = function()
	return FS.get_project_root() .. "/.cc99/CC99.md"
end

---@return string
FS.get_cc99_dir = function()
	return FS.get_project_root() .. "/.cc99"
end

---@return string
FS.get_prompts_dir = function()
	return FS.get_project_root() .. "/.cc99/prompts"
end

---@param path string
---@return string|nil
FS.read_md = function(path)
	local f = io.open(path, "r")
	if not f then
		return nil
	end
	local content = f:read("*a")
	f:close()
	return content
end

---@return string|nil
FS.read_cc99_md = function()
	return FS.read_md(FS.get_cc99_md_path())
end

return FS

---@class Mark
---@field buf number
---@field ns_id number
---@field extmark_id number
local Mark = {}
Mark.__index = Mark

---@param buf number
---@param start_row number
function Mark.new(buf, start_row)
    local self = setmetatable({}, Mark)
    self.ns_id = vim.api.nvim_create_namespace("cc99.mark")
    print(buf)
    self.buf = buf
    ---NOTE: Maybe, column should be handled more carefully.
    self.extmark_id = vim.api.nvim_buf_set_extmark(self.buf, self.ns_id, start_row, 0, {})
    return self
end

---@param lines string[]
function Mark:set_virtual_lines(lines)
    local pos = vim.api.nvim_buf_get_extmark_by_id(self.buf, self.ns_id, self.extmark_id, {})
    if #pos == 0 then
        print("extmark is broken.  it does not exist")
        vim.notify("Error: extmark is broken, it does not exist.", vim.log.levels.ERROR)
        return
    end
    local row, col = pos[1], pos[2]
    local formatted_lines = {}
    for _, line in ipairs(lines) do
        table.insert(formatted_lines, {
            --- "Comment" is the highlight group
            { line, "Comment" },
        })
    end
    vim.api.nvim_buf_set_extmark(self.buf, self.ns_id, row, col, {
        id = self.extmark_id,
        virt_lines = formatted_lines,
    })
end

function Mark:clear_virtual_lines()
    vim.api.nvim_buf_del_extmark(self.buf, self.ns_id, self.extmark_id)
end
return {
    Mark = Mark,
}

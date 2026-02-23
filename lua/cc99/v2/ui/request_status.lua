local spinner_status = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }

---@class V2StatusLine
---@field index number
---@field header_line string
---@field message string[]
---@field max_lines number
---@field update_time number
local V2StatusLine = {}
V2StatusLine.__index = V2StatusLine

---@param header_line string
---@param update_time number
function V2StatusLine.new(header_line, update_time)
  return setmetatable({
    index = 1,
    header_line = header_line,
    message = {},
    max_lines = 1,
    update_time = update_time,
  })
end

function V2StatusLine:update()
  self.index = (self.index % #spinner_status) + 1
end

---@return string
function V2StatusLine:to_string()
  return spinner_status[self.index] .. " " .. self.header_line .. table.concat(self.message, "\n")
end

---@class V2RequestStatus
---@field status_line V2StatusLine
---@field is_running boolean
---@field mark V2Mark
local V2RequestStatus = {}
V2RequestStatus.__index = V2RequestStatus

---@param status_line V2StatusLine
---@param mark V2Mark
function V2RequestStatus.new(status_line, mark)
  return setmetatable({
    status_line = status_line,
    mark = mark,
    is_running = false,
  }, V2RequestStatus)
end

---@param message_line string
function V2RequestStatus:push(message_line)
  table.insert(self.status_line.message, message_line)
  if #self.status_line.message > self.status_line.max_lines then
    table.remove(self.status_line.message, 1)
  end
end

function V2RequestStatus:run()
  self.is_running = true
  local function update_spinner()
    if not self.is_running then
      return
    end

    self.status_line:update()
    local pos =
      vim.api.nvim_buf_get_extmark_by_id(vim.api.nvim_get_current_buf(), self.mark.ns_id, self.mark.extmark_id, {})
    local row, col = pos[1], pos[2]
    local formatted_lines = {}
    table.insert(formatted_lines, {
      --- "Comment" is the highlight group
      { self.status_line:to_string(), "Comment" },
    })

    vim.api.nvim_buf_set_extmark(vim.api.nvim_get_current_buf(), self.mark.ns_id, row, col, {
      id = self.mark.extmark_id,
      virt_lines = formatted_lines,
    })

    vim.defer_fn(update_spinner, self.status_line.update_time)
  end

  vim.defer_fn(update_spinner, self.status_line.update_time)
end

function V2RequestStatus:stop()
  self.is_running = false
end

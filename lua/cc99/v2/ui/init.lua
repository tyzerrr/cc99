---@class V2Point
---@field row number
---@field col number
local V2Point = {}
V2Point.__index = V2Point

---@param row number
---@param col number
---@return V2Point
function V2Point.from_0_indexed(row, col)
  return setmetatable({ row = row, col = col }, V2Point)
end

function V2Point.from_1_indexed(row, col)
  return setmetatable({ row = row - 1, col = col - 1 }, V2Point)
end

---@class V2Range
---@field start V2Point
---@field end_ V2Point
local V2Range = {}
V2Range.__index = V2Range

---@param start V2Point
---@param end_ V2Point
---@return V2Range
function V2Range.new(start, end_)
  return setmetatable({ start = start, end_ = end_ }, V2Range)
end

---@class V2Mark
---@field range V2Range
---@field extmark_id number
---@field ns_id number
local V2Mark = {}
V2Mark.__index = V2Mark

---@param range V2Range
---@param extmark_id number
---@param ns_id number
---@return V2Mark
function V2Mark.new(range, extmark_id, ns_id)
  return setmetatable({ range = range, extmark_id = extmark_id, ns_id = ns_id }, V2Mark)
end

---@class V2Float
---@field buf number
---@field win number
---@field is_open boolean
---@field mark V2Mark
local V2Float = {}
V2Float.__index = V2Float

---@param buf number
---@param win number
---@param is_open boolean
---@param mark V2Mark
---@return V2Float
function V2Float.new(buf, win, is_open, mark)
  return setmetatable({ buf = buf, win = win, is_open = is_open, mark = mark }, V2Float)
end

function V2Float:open()
  if self.is_open then
    return
  end
  local win_height = math.floor(vim.o.lines * 0.6)
  local win_width = math.floor(vim.o.columns * 0.6)
  local row = math.floor((vim.o.lines - win_height) / 2)
  local col = math.floor((vim.o.columns - win_width) / 2)

  local window_config = {
    relative = "editor",
    row = row,
    col = col,
    width = win_width,
    height = win_height,
    border = "rounded",
    style = "minimal",
    title = "cc99",
    title_pos = "center",
  }

  self.win = vim.api.nvim_open_win(self.buf, true, window_config)
  self.is_open = true
end

function V2Float:close()
  if not self.is_open then
    return
  end
  vim.api.nvim_win_hide(self.win)
  self.is_open = false
end

return {
  V2Float = V2Float,
  V2Mark = V2Mark,
  V2Range = V2Range,
  V2Point = V2Point,
}

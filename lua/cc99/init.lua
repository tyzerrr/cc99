local cc99_prompt = require("cc99.prompt")
local cc99_fs = require("cc99.fs")
local cc99_claude = require("cc99.claude")
local cc99_tsb = require("cc99.text_stream_buffer")
local cc99_request = require("cc99.request")
local cc99_mark = require("cc99.mark")

local CC99 = {}

---@type Float
local CC99_Float = {
    is_open = false,
    buf = nil,
    win = nil,
    marked = nil,
    claude = nil,
    win_config = nil,
}

---@class MarkedState
---@field start_row number
---@field start_col number
---@field end_row number
---@field end_col number
---@field extmark_id number
local MarkedState = {}
MarkedState.__index = MarkedState

---@return MarkedState
function MarkedState.new()
    local self = setmetatable({}, MarkedState)
    self.start_row = -1
    self.start_col = -1
    self.end_row = -1
    self.end_col = -1
    self.extmark_id = -1
    return self
end

---@class Float
---@field is_open boolean
---@field buf number | nil
---@field win number | nil
---@field marked MarkedState | nil
---@field claude Claude | nil
---@field win_config FloatWinConfig | nil
local Float = {}
Float.__index = Float

---@class FloatWinConfig
---@field relative string
---@field row number,
---@field col number,
---@field width number,
---@field height number,
---@field border string,
---@field style string,
---@field title string,
---@field title_pos string

---@param buf number
---@param win number
---@param win_config FloatWinConfig
---@param marked MarkedState | nil
---@return Float
function Float.new(buf, win, win_config, marked, claude)
    local self = setmetatable({}, Float)
    self.is_open = false
    self.buf = buf
    self.win = win
    self.win_config = win_config
    self.marked = marked
    self.claude = claude
    return self
end

---TODO: opts should be typed
---
---@param opts any
---@return {win: number, buf: number, win_config: FloatWinConfig}
local create_buf_win = function(opts)
    local win_height = opts.height or math.floor(vim.o.lines * 0.6)
    local win_width = opts.width or math.floor(vim.o.columns * 0.6)
    local row = math.floor((vim.o.lines - win_height) / 2)
    local col = math.floor((vim.o.columns - win_width) / 2)

    local buf = vim.api.nvim_create_buf(false, true)

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

    if opts.window then
        window_config.relative = opts.window.relative
        window_config.row = opts.window.row
        window_config.col = opts.window.col
        window_config.width = opts.window.width
        window_config.height = opts.window.height
        window_config.border = opts.window.border
        window_config.style = opts.window.style
        window_config.title = opts.window.title
        window_config.title_pos = opts.window.title_pos
    end

    return { buf = buf, win = nil, win_config = window_config }
end

---TODO: opts should be typed
---
---@param opts any
local init_cc99_float = function(opts)
    local float = create_buf_win(opts)
    local marked = MarkedState.new()
    local claude = cc99_claude.Claude.new(cc99_fs.FS.new(), nil, nil)
    CC99_Float = Float.new(float.buf, float.win, float.win_config, marked, claude)
end

function Float:exec()
    self:close()
    --- user prompt
    local user_prompt = cc99_prompt.build_user_prompt(
        CC99_Float.buf,
        CC99_Float.marked.start_row,
        CC99_Float.marked.end_row,
        CC99_Float.is_open
    )
    if not user_prompt then
        print("[cc99] ERROR: user prompt is empty, aborting execution")
        vim.notify("CC99 Error: user prompt is empty. Check the logs for details.", vim.log.levels.ERROR)
        return
    end

    --- system prompt
    local system_prompt = cc99_prompt.build_system_prompt()
    if not system_prompt then
        print("[cc99] ERROR: system prompt is empty, aborting execution")
        vim.notify("CC99 Error: system prompt is empty. Check the logs for details.", vim.log.levels.ERROR)
        return
    end

    self.claude:analyze()
    self.claude:exec(system_prompt, user_prompt, self.marked)
end

function Float:open()
    self.win = vim.api.nvim_open_win(self.buf, true, {
        relative = self.win_config.relative,
        row = self.win_config.row,
        col = self.win_config.col,
        width = self.win_config.width,
        height = self.win_config.height,
        border = self.win_config.border,
        style = self.win_config.style,
        title = self.win_config.title,
        title_pos = self.win_config.title_pos,
    })
    self.is_open = true
end

function Float:close()
    vim.api.nvim_win_hide(CC99_Float.win)
    self.is_open = false
end

function Float:mark()
    if self.is_open then
        return
    end
    local start_pos = vim.fn.getpos("v")
    local end_pos = vim.fn.getpos(".")
    local start_row, start_col = start_pos[2], start_pos[3]
    local end_row, end_col = end_pos[2], end_pos[3]
    if start_row > end_row then
        start_row, start_col, end_row, end_col = end_row, end_col, start_row, start_col
    end
    self.marked.start_row = start_row - 1
    self.marked.start_col = start_col
    self.marked.end_row = end_row
    self.marked.end_col = end_col
    self.claude.request_status = cc99_request.RequestStatus.new(
        cc99_request.StatusLine.new("Implementing..."),
        {},
        250,
        3,
        cc99_mark.Mark.new(vim.api.nvim_get_current_buf(), self.marked.start_row - 1)
    )
    self.claude.tsb = cc99_tsb.TextStreamBuffer.new(self.claude.request_status)
    self:open()
end

CC99.mark = function()
    CC99_Float:mark()
end

CC99.quit = function()
    -- CC99_Float:quit()
    print("quit cc99")
end

CC99.close = function()
    CC99_Float:close()
end

CC99.exec = function()
    CC99_Float:exec()
end

---@param opts SetupOptions | nil
CC99.setup = function(opts)
    opts = opts or {}
    init_cc99_float(opts)

    --- user commands
    vim.api.nvim_create_user_command("CC99Mark", CC99.mark, {})
    vim.api.nvim_create_user_command("CC99Quit", CC99.quit, {})
    vim.api.nvim_create_user_command("CC99Close", CC99.close, {})
    vim.api.nvim_create_user_command("CC99Exec", CC99.exec, {})

    --- remap
    vim.keymap.set("v", "<leader>ccm", "<cmd>CC99Mark<CR>", {})
    vim.keymap.set("n", "<leader>ccq", "<cmd>CC99Quit<CR>", {})
    vim.keymap.set("n", "<leader>ccc", "<cmd>CC99Close<CR>", {})
    vim.keymap.set("n", "<leader>ccx", "<cmd>CC99Exec<CR>", {})
end

CC99.setup()

return CC99

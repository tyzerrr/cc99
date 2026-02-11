---@class TextStreamBuffer
---@field request_status_channel RequestStatus
---@field in_code boolean
---@field code_lines string[]
---@field stdout_buffer string
local TextStreamBuffer = {}
TextStreamBuffer.__index = TextStreamBuffer

---@param request_status_channel RequestStatus
---@return TextStreamBuffer
function TextStreamBuffer.new(request_status_channel)
    local self = setmetatable({}, TextStreamBuffer)
    self.request_status_channel = request_status_channel
    self.in_code = false
    self.code_lines = {}
    self.stdout_buffer = ""
    return self
end

---@param line string
function TextStreamBuffer:insert(line)
    self.stdout_buffer = self.stdout_buffer .. line
end

---@param line string
function TextStreamBuffer:process_line(line)
    if line:match("^</CODE>") then
        self.in_code = false
    elseif self.in_code then
        table.insert(self.code_lines, line)
    elseif line:match("^<CODE>") then
        self.in_code = true
    else
        local status_line = line:gsub("^%s+", ""):gsub("%s+$", "")
        if #status_line > 0 then
            vim.schedule(function()
                self.request_status_channel:push(status_line)
            end)
        end
    end
end

function TextStreamBuffer:drain()
    while true do
        local newline_pos = self.stdout_buffer:find("\n")
        if not newline_pos then
            break
        end
        local line = self.stdout_buffer:sub(1, newline_pos - 1)
        self.stdout_buffer = self.stdout_buffer:sub(newline_pos + 1)
        self:process_line(line)
    end
end

function TextStreamBuffer:flush()
    self:drain()
    if #self.stdout_buffer > 0 then
        self:process_line(self.stdout_buffer)
        self.stdout_buffer = ""
    end
end

return {
    TextStreamBuffer = TextStreamBuffer,
}

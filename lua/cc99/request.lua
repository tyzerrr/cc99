---@class StatusLine
---@field index number
---@field title string
---@field spinner string[]
local StatusLine = {}
StatusLine.__index = StatusLine

---@param title string
function StatusLine.new(title)
	local self = setmetatable({}, StatusLine)
	self.index = 1
	self.title = title
	self.spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
	return self
end

function StatusLine:update()
	print(self.index)
	self.index = (self.index + 1) % #self.spinner + 1
end

function StatusLine:to_string()
	print(self.spinner[self.index])
	print(self.title)

	return self.spinner[self.index] .. " " .. self.title
end

---@class RequestStatus
---@field status_line StatusLine
---@field message_lines string[]
---@field update_time number
---@field max_lines number
---@field mark Mark
---@field running boolean
local RequestStatus = {}
RequestStatus.__index = RequestStatus

---@param status_line StatusLine
---@param message_lines string[]
---@param update_time number
---@param max_lines number
---@param mark Mark
---@return RequestStatus
function RequestStatus.new(status_line, message_lines, update_time, max_lines, mark)
	local self = setmetatable({}, RequestStatus)
	self.status_line = status_line
	self.message_lines = message_lines
	self.update_time = update_time
	self.max_lines = max_lines
	self.mark = mark
	self.running = false
	return self
end

---@param message_line string
function RequestStatus:push(message_line)
	print("Pushing message line: ", vim.inspect(message_line))
	table.insert(self.message_lines, message_line)
	if #self.message_lines > self.max_lines then
		table.remove(self.message_lines, 1)
	end
	print("Current message lines:", vim.inspect(self.message_lines))
end

---@return string[]
function RequestStatus:get()
	local result = { self.status_line:to_string() }
	print("Getting message lines:", vim.inspect(self.message_lines))
	for _, line in ipairs(self.message_lines) do
		table.insert(result, line)
	end
	print("Resulting lines:", vim.inspect(result))
	return result
end

function RequestStatus:start()
	self.running = true
	local function update_spinner()
		if not self.running then
			return
		end
		self.status_line:update()
		self.mark:set_virtual_lines(self:get())
		vim.defer_fn(update_spinner, self.update_time)
	end
	vim.defer_fn(update_spinner, self.update_time)
end

function RequestStatus:stop()
	self.running = false
	self.mark:clear_virtual_lines()
end

return {
	StatusLine = StatusLine,
	RequestStatus = RequestStatus,
}

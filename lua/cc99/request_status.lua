---@class RequestStatus
---@field extmark_id number
---@field running boolean
---@field spinner string[]
---@field message string
---@field spinner_index number
local RequestStatus = {}
RequestStatus.__index = RequestStatus

---@param bufnr number buffer
---@param ns_id number namespace id
---@param mark_start_line number cc99 visual selected marked start line
function RequestStatus.new(bufnr, ns_id, mark_start_line)
	local self = setmetatable({}, RequestStatus)
	self.extmark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, mark_start_line, 1, {})
	self.running = false
	self.spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
	self.message = ""
	self.spinner_index = 1
	return self
end

function RequestStatus:update()
	self.index = (self.index + 1) % #self.spinner + 1
end

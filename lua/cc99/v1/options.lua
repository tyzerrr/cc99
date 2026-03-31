---@class SetupOptions
local SetupOptions = {}
SetupOptions.__index = SetupOptions

function SetupOptions.new()
	local self = setmetatable({}, SetupOptions)
	return self
end

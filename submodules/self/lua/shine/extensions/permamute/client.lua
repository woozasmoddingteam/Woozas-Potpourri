--[[
    Shine plugin
]]

local Shine = Shine
local Plugin = Plugin


function Plugin:Initialise()
	self.Enabled = true

	return true
end

function Plugin:ReceivePermamuteNotifcation(msg)
	if not self.Enabled then return end
	Shine.AddChatText(218, 68, 83, "Warning: ", 200, 200, 200, msg.str);
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )

	self.Enabled = false
end

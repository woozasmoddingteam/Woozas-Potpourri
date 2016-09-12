--[[
	Shine NS2News plugin.
]]
local Plugin = {}
Plugin.Version = "1.0"

function Plugin:SetupDataTable()
	self:AddDTVar( "boolean", "ShowMenuEntry", true )
end

function Plugin:NetworkUpdate( _, OldValue, NewValue )
	if Client and OldValue ~= NewValue then
		self:UpdateMenuEntry(NewValue)
	end
end

Shine:RegisterExtension( "ns2news", Plugin )

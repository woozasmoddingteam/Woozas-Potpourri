--[[
	DisableVanillaVotes - Shared
	Inspired by the TF plugin from ShamelessCookie which can be found here:
	https://github.com/ShamelessCookie/tactical-freedom/blob/master/output/lua/shine/extensions/tf_disablestockvoting.lua
 ]]

local Plugin = {}
local Shine = Shine

Plugin.NS2Only = true

function Plugin:SetupDataTable()
	self:AddDTVar( "integer (0 to 255)", "R", 81 )
	self:AddDTVar( "integer (0 to 255)", "G", 194 )
	self:AddDTVar( "integer (0 to 255)", "B", 243 )

	local Message = {
		Message = "string(255)",
	}
	self:AddNetworkMessage( "Message", Message, "Client" )
end

Shine:RegisterExtension("disablevanillavotes", Plugin )


--[[
	[Shine] ModSelector by Keats & Yeats.
	A Shine plugin to enable and disable server mods in-game.
	Please see https://github.com/keatsandyeats/Shine-ModSelector for more information.
--]]


local Shine = Shine
local Plugin = {}

function Plugin:SetupDataTable()
	self:AddNetworkMessage("RequestModData", {}, "Server")
	self:AddNetworkMessage("ModData", {
		HexID = "string (32)", 
		DisplayName = "string(32)", 
		Enabled = "boolean",
		}, "Client")
	
end

Shine:RegisterExtension("modselector", Plugin)
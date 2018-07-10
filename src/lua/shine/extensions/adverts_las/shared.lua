local Shine = Shine
local Plugin = {}
Plugin.Version = "2.1"
Plugin.PrintName = "AdvertsLas"
Plugin.HasConfig = true
Plugin.ConfigName = "AdvertsLas.json"
Plugin.DefaultState = false
Plugin.NS2Only = false
Plugin.CheckConfig = false
Plugin.CheckConfigTypes = false
Plugin.Conflicts = {
	DisableThem = {
		"adverts"
	}
}

local uint8 = "integer (0 to 255)"

function Plugin:SetupDataTable()
	self:AddDTVar("string (128)", "ServerID", "")
	self:AddNetworkMessage("AdvertShort", {
		str = "string (128)",
		group = "string (32)"
	}, "Client")
	self:AddNetworkMessage("AdvertMedium", {
		str = "string (256)",
		group = "string (32)"
	}, "Client")
	self:AddNetworkMessage("AdvertLong", {
		str = "string (384)",
		group = "string (32)"
	}, "Client")
	self:AddNetworkMessage("RequestForGroups", {}, "Server")
	self:AddNetworkMessage("Group", {
		name = "string (32)",
		prefix = "string (32)",
		pr = uint8,
		pg = uint8,
		pb = uint8,
		r = uint8,
		g = uint8,
		b = uint8,
		hidable = "boolean"
	}, "Client")
end

Shine:RegisterExtension("adverts_las", Plugin)

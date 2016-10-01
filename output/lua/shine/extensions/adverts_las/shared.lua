local Shine = Shine;
local Plugin = {}
Plugin.Version = "1.0";
Plugin.PrintName = "AdvertsLas";
Plugin.HasConfig = true;
Plugin.ConfigName = "AdvertsLas.json";
Plugin.DefaultState = false;
Plugin.NS2Only = false;
Plugin.CheckConfig = false;
Plugin.CheckConfigTypes = false;
Plugin.Conflicts = {
	DisableThem = {
		"adverts";
	};
};

local StringMessage = string.format("string (%i)", kMaxChatLength * 2);
local IntMessage = "integer (0 to " .. tostring(2^32-1) .. ")";

function Plugin:SetupDataTable()
	self:AddDTVar(StringMessage, "ServerID", "");
	self:AddNetworkMessage("Advert", {
		prefix = "string (32)";
		group = "string (96)";
		message = "string (256)";
		pr = "integer (0 to 255)";
		pg = "integer (0 to 255)";
		pb = "integer (0 to 255)";
		r = "integer (0 to 255)";
		g = "integer (0 to 255)";
		b = "integer (0 to 255)";
	}, "Client");
	self:AddNetworkMessage("RequestForGroups", {}, "Server");
	self:AddNetworkMessage("GroupsPart", {
		msg = StringMessage;
	}, "Client");
	self:AddNetworkMessage("GroupsEnd", {}, "Client");
end

Shine:RegisterExtension("adverts_las", Plugin);

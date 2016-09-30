local Shine = Shine;
local Plugin = {}
Plugin.Version = "1.0";
Plugin.PrintName = "AdvertsLas";
Plugin.HasConfig = true;
Plugin.DefaultState = false; --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = false; --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.
Plugin.CheckConfig = false; --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = false; --Should we check the types of values in the config to make sure they match our default's types?
Plugin.Conflicts = {
	DisableThem = {
		"adverts";
	};
};

local StringMessage = string.format("string (%i)", kMaxChatLength * 4 + 1);
local IntMessage = "integer (0 to " .. tostring(2^32-1) .. ")";

function Plugin:SetupDataTable()
	self:AddDTVar(StringMessage, "ServerID", "");
	self:AddNetworkMessage("Advert", {
		pr = "integer (0 to 255)";
		pg = "integer (0 to 255)";
		pb = "integer (0 to 255)";
		r = "integer (0 to 255)";
		g = "integer (0 to 255)";
		b = "integer (0 to 255)";
		prefix = StringMessage;
		message = StringMessage;
		group = StringMessage;
	}, "Client");
	self:AddNetworkMessage("RequestForGroups", {}, "Server");
	self:AddNetworkMessage("GroupsPart", {
		msg = StringMessage;
	}, "Client");
	self:AddNetworkMessage("GroupsEnd", {}, "Client");
end

--[[
Shared.RegisterNetworkMessage("ADVERTS_LAS_ADVERT", {
	pr = "integer (0 to 255)";
	pg = "integer (0 to 255)";
	pb = "integer (0 to 255)";
	r = "integer (0 to 255)";
	g = "integer (0 to 255)";
	b = "integer (0 to 255)";
	prefix = StringMessage;
	message = StringMessage;
	group = StringMessage;
});
--]]

Shine:RegisterExtension("adverts_las", Plugin);

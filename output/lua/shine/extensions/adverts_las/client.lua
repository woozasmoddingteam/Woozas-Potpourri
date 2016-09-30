local Plugin = Plugin;

Plugin.ConfigName = "AdvertsLasClient.json";
Plugin.DefaultConfig = {}

local unwanted;
local serverID;

function Plugin:Initialise()
	Shared.Message("shine adverts client init");
	serverID = self.dt.ServerID;
	unwanted = self.Config[serverID] or {};
	self.Config[serverID] = unwanted;

	self:SendNetworkMessage("RequestForGroups", {}, true);

	self.Enabled = true;
	return true;
end

function Plugin:ReceiveAdvert(msg)
	local group = string.Explode(msg.group, "|");
	for _, v in ipairs(group) do
		if table.contains(unwanted, v) then Shared.Message("AdvertsLasClient: Skipped an advert."); return nil; end;
	end
	Shine.AddChatText(msg.pr, msg.pg, msg.pb, msg.prefix, msg.r/255, msg.g/255, msg.b/255, msg.message);
end

local GroupsGotten = false;
local Groups = {};

function Plugin:ReceiveGroupsEnd()
	GroupsGotten = true;
end
function Plugin:ReceiveGroupsPart(msg)
	table.insert(Groups, msg.msg);
end

Event.Hook("Console_sh_disable_advert_group", function(group)
	Shared.Message("Disabled advert group '" .. group .. "'.");
	table.insert(unwanted, group);
	Plugin.SaveConfig(Plugin);
end)

Event.Hook("Console_sh_enable_advert_group", function(group)
	local success = table.removevalue(unwanted, group);
	if success then
		Shared.Message("Enabled advert group '" .. group .. "'.");
		Plugin.SaveConfig(Plugin);
	else
		Shared.Message("Can not enable an already enable advert group!");
	end
end)

Event.Hook("Console_sh_print_advert_groups", function()
	if not GroupsGotten then
		Shared.Message("Still waiting for some groups!");
	end
	local delimiter = "-------------------";
	Shared.Message(delimiter);
	for _, v in ipairs(Groups) do
		Shared.Message(v);
	end
	Shared.Message(delimiter);
end)
--Plugin.BindCommand("sh_disable_advert", "DisableAdvert", Plugin.DisableAdvert, true, true);

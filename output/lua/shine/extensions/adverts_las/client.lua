local Plugin = Plugin;

Plugin.ConfigName = "AdvertsLasClient.json";
Plugin.DefaultConfig = {
	-- true: always skip
	-- false: always show
	-- nil: take on parent value
	-- Child values take precedence.
	["Generic Server ID"] = { -- Server id
		[""] = true; -- Global parent
		["Warnings"] = false; -- Advert group
		["Hints"] = true;
		["Events"] = false;
		["Events×NSL"] = true;
	}
}

local serverID;
local config;
local all_groups_gotten = false;
local groups = {}; -- A table of all the groups with all values set to true

function Plugin:Initialise()
	Shared.Message("shine adverts client init");
	serverID = self.dt.ServerID;
	self.Config[serverID] = self.Config[serverID] or {};
	config = self.Config[serverID];
	assert(config);
	-- self:SaveConfig(); -- Commented out so that we don't bloat the config with unconfigured servers.

	self:SendNetworkMessage("RequestForGroups", {}, true);

	Shine.VoteMenu:AddPage("Configure advert groups", function(self)
		self:AddTopButton("[Return]", function()
			self:SetPage("Main");
		end);
	end)

	self.Enabled = true;
	return true;
end

function Plugin:ReceiveAdvert(msg)
	local substr = msg.group;
	while true do
		local v = config[substr];
		if v == true then
			Shared.Message("AdvertsLasClient: Skipped an advert.");
			return;
		elseif v == false then -- Nil doesn't count!
			break;
		end
		if substr:len() == 0 then
			break;
		end
		substr = substr:sub(1,
			(substr:find("×", 1, true) or 1)-1
		);
	end
	Shine.AddChatText(msg.pr, msg.pg, msg.pb, msg.prefix, msg.r/255, msg.g/255, msg.b/255, msg.message);
end

function Plugin:ReceiveGroupsEnd()
	all_groups_gotten = true;
end

function Plugin:ReceiveGroupsPart(msg)
	groups[msg.msg] = true;
end

local function noGroup()
	if all_groups_gotten then
		Shared.Message("Can not configure a non-existent group!");
	else
		Shared.Message("Either not all groups haven't been received or the group isn't valid.");
	end
end

Event.Hook("Console_sh_disable_advert_group", function(group)
	if not groups[group] then
		noGroup();
		return nil;
	end
	config[group] = true;
	Shared.Message("Disabled advert group '" .. group .. "'.");
	Plugin.SaveConfig(Plugin);
end)

Event.Hook("Console_sh_enable_advert_group", function(group)
	if not groups[group] then
		noGroup();
		return nil;
	end
	config[group] = false;
	Plugin.SaveConfig(Plugin);
end)

Event.Hook("Console_sh_unset_advert_group", function(group)
	if not groups[group] then
		noGroup();
		return nil;
	end
	config[group] = nil;
	Plugin.SaveConfig(Plugin);
end)

Event.Hook("Console_sh_print_advert_groups", function()
	if not all_groups_gotten then
		Shared.Message("Still waiting for some groups!");
	end
	local delimiter = "-------------------";
	Shared.Message(delimiter);
	for group, _ in pairs(groups) do
		Shared.Message(group .. ": " .. tostring(config[group]));
	end
	Shared.Message(delimiter);
end)

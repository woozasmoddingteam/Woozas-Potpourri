local Plugin = Plugin;

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
local groups = {}; -- A table of all the groups with all values set to their suffixes

local function disableGroup(group)
	config[group] = true;
	Shared.Message("Disabled advert group '" .. group .. "'.");
	Plugin:SaveConfig();
end

local function enableGroup(group)
	config[group] = false;
	Shared.Message("Enabled advert group '" .. group .. "'.");
	Plugin:SaveConfig();
end

local function unsetGroup(group)
	config[group] = nil;
	Shared.Message("Unset advert group '" .. group .. "'.");
	Plugin:SaveConfig();
end

local function unsetGroupRecursively(group)
	for k, _ in pairs(config) do
		if k:StartsWith(group) then
			config[k] = nil;
		end
	end
	Shared.Message("Unset advert group '" .. group .. "' & children.");
	Plugin:SaveConfig();
end

local function populateAdvertPage(self, str)
	self:AddTopButton("[Cancel]", function()
		self:SetPage("Advert Config");
	end);
	self:AddSideButton("Enable", function()
		enableGroup(str);
		self:SetPage("Advert Config");
	end);
	self:AddSideButton("Disable", function()
		disableGroup(str);
		self:SetPage("Advert Config");
	end);
	self:AddSideButton("Unset", function()
		unsetGroup(str);
		self:SetPage("Advert Config");
	end);
	self:AddSideButton("Unset + Children", function()
		unsetGroupRecursively(str);
		self:SetPage("Advert Config");
	end);
	local current = config[str];
	local str;
	if current == false then
		str = "Status: Enabled";
	elseif current == true then
		str = "Status: Disabled";
	else
		str = "Status: Unset";
	end
	self:AddBottomButton(str, function() end);
end

function Plugin:Initialise()
	serverID = self.dt.ServerID;
	self.Config[serverID] = self.Config[serverID] or {};
	config = self.Config[serverID];
	-- self:SaveConfig(); -- Commented out so that we don't bloat the config with unconfigured servers.

	self:SendNetworkMessage("RequestForGroups", {}, true);

	Shine.VoteMenu:AddPage("Advert Config All", function(self)
		populateAdvertPage(self, "");
	end);

	Shine.VoteMenu:AddPage("Advert Config", function(self)
		self:AddTopButton("[Return]", function()
			self:SetPage("Main");
		end);
		self:AddBottomButton("All", function()
			self:SetPage("Advert Config All");
		end);
	end);

	Shine.VoteMenu:EditPage("Main", function(self)
		self:AddSideButton("Advert Config", function()
			self:SetPage("Advert Config");
		end);
	end);

	self.Enabled = true;
	return true;
end

function Plugin:ReceiveAdvert(msg)
	if not self.Enabled then return end
	local substr = msg.group;
	while true do
		local v = config[substr];
		if v == true then
			Shared.Message("AdvertsLasClient: Skipped an advert.");
			return;
		elseif v == false then -- Nil doesn't count!
			break;
		end
		substr = substr:match("(.*)(|.*)");
		if not substr then
			if config[""] == true then
				Shared.Message("AdvertsLasClient: Skipped an advert.");
				return;
			end
			break;
		end
	end
	Shine.AddChatText(msg.pr, msg.pg, msg.pb, msg.prefix, msg.r/255, msg.g/255, msg.b/255, msg.message);
end

function Plugin:ReceiveGroupsEnd()
	all_groups_gotten = true;
	Shine.VoteMenu:EditPage("Advert Config", function(self)
		for full, suffix in pairs(groups) do
			self:AddSideButton(suffix, function()
				self:SetPage("Advert: " .. full);
			end);
		end
	end);
end

function Plugin:ReceiveGroupsPart(msg)
	local str = msg.msg;
	local suffix = str:match("(.*|)(.*|.*)") or str;
	groups[str] = suffix;
	Shine.VoteMenu:AddPage("Advert: " .. str, function(self)
		populateAdvertPage(self, str);
	end);
end

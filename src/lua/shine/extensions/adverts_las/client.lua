local Plugin = Plugin;

Plugin.DefaultConfig = {}

local serverID;
local groups = {};
local hidable_group_count = 0;
local config;

function Plugin:Initialise()
	serverID = self.dt.ServerID;
	self.Config[serverID] = type(self.Config[serverID]) ~= "table" and {} or self.Config[serverID];
	config = self.Config[serverID];

	Shine.VoteMenu:EditPage("Main", function(self)
		self:AddSideButton("Advert Config", function()
			self:SetPage("Advert Config");
		end);
	end);

	Shine.VoteMenu:AddPage("Advert Config", function(self)
		self:AddTopButton("[Cancel]", function()
			self:SetPage("Main");
		end);
	end);

	self:SendNetworkMessage("RequestForGroups", {}, true);

	self.Enabled = true;
	return true;
end

function Plugin:ReceiveAdvertShort(msg)
	if not self.Enabled then return end
	local group = groups[msg.group];
	if not group then
		Shared.Message("AdvertsLasClient: Insufficient information to show advert! Hiding it.");
		return;
	end
	if config[msg.group] and group.hidable then
		Shared.Message("AdvertsLasClient: Skipped an advert from the group '" .. msg.group .. "'.");
		return;
	end
	local tmp = StartSoundEffect
	StartSoundEffect = nil
	Shine.AddChatText(group.pr, group.pg, group.pb, group.prefix, group.r/255, group.g/255, group.b/255, msg.str);
	StartSoundEffect = tmp
end

Plugin.ReceiveAdvertMedium = Plugin.ReceiveAdvertShort
Plugin.ReceiveAdvertLong   = Plugin.ReceiveAdvertShort

function Plugin:ReceiveGroup(msg)
	local name = msg.name;
	groups[name] = msg;
	config[name] = config[name] or false;
	if msg.hidable then
		Shine.VoteMenu:EditPage("Advert Config", function(self)
			local str = (config[name] and "Show " or "Hide ") .. name;
			self:AddSideButton(str, function()
				config[name] = not config[name];
				Plugin:SaveConfig();
				self:SetIsVisible(false);
				self:SetPage("Main");
			end);
		end);
	end
end

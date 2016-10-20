local Plugin = Plugin;

Plugin.DefaultConfig = {}

local serverID;
local should_hide;
local groups = {};
local hidable_group_count = 0;
local config;

local VoteMenuFunction = function() end;

function Plugin:Initialise()
	serverID = self.dt.ServerID;
	--should_hide = self.Config[serverID] or false; -- Being nil also counts!
	self.Config[serverID] = type(self.Config[serverID]) ~= "table" and {} or self.Config[serverID];
	config = self.Config[serverID];

	self:SendNetworkMessage("RequestForGroups", {}, true);

	Shine.VoteMenu:EditPage("Main", function(self)
		VoteMenuFunction(self);
	end);

	self.Enabled = true;
	return true;
end

function Plugin:ReceiveAdvert(msg)
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
	Shine.AddChatText(group.pr, group.pg, group.pb, group.prefix, group.r/255, group.g/255, group.b/255, msg.str);
end

function Plugin:ReceiveGroup(msg)
	local name = msg.name;
	groups[name] = msg;
	config[name] = config[name] or false;
	if msg.hidable then
		hidable_group_count = hidable_group_count + 1;
		if hidable_group_count > 2 then
			Shine.VoteMenu:EditPage("Advert Config", function(self)
				local str = (config[name] and "Show " or "Hide ") .. name;
				self:AddSideButton(str, function()
					config[name] = not config[name];
					Plugin:SaveConfig();
					self:SetIsVisible(false);
				end);
			end);
		elseif hidable_group_count == 2 then
			Shine.VoteMenu:AddPage("Advert Config", function(self)
				self:AddTopButton("[Cancel]", function()
					self:SetPage("Main");
				end);
				local str = (config[name] and "Show " or "Hide ") .. name;
				self:AddSideButton(str, function()
					config[name] = not config[name];
					Plugin:SaveConfig();
					self:SetIsVisible(false);
				end);
			end);
			VoteMenuFunction = function(self)
				self:AddSideButton("Advert Config", function()
					self:SetPage("Advert Config");
				end);
			end
		elseif hidable_group_count == 1 then
			VoteMenuFunction = function(self)
				local str = (config[name] and "Show " or "Hide ") .. name;

				self:AddSideButton(str, function()
					config[name] = not config[name];
					Plugin:SaveConfig();
					self:SetIsVisible(false);
				end);
			end
		end
	end
end

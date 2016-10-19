local Plugin = Plugin;

Plugin.DefaultConfig = {}

local serverID;
local should_hide;
local groups = {};

local VoteMenuFunction = function(self)
	local str;
	if should_hide then
		str = "Show Hints";
	else
		str = "Hide Hints";
	end

	self:AddSideButton(str, function()
		should_hide = not should_hide;
		Plugin.Config[serverID] = should_hide;
		Plugin:SaveConfig();
		self:SetIsVisible(false);
	end);
end

function Plugin:Initialise()
	serverID = self.dt.ServerID;
	should_hide = self.Config[serverID] or false; -- Being nil also counts!

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
	if should_hide and group.hidable then
		Shared.Message("AdvertsLasClient: Skipped an advert from the group '" .. msg.group .. "'.");
		return;
	end
	Shine.AddChatText(group.pr, group.pg, group.pb, group.prefix, group.r/255, group.g/255, group.b/255, msg.str);
end

function Plugin:ReceiveGroup(msg)
	local name = msg.name;
	msg.name = nil;
	groups[name] = msg;
end

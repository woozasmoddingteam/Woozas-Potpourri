local Shine = Shine

local TableQuickCopy = table.QuickCopy
local pairs = pairs;
local Plugin = Plugin;

Plugin.DefaultConfig = {
	RandomiseOrder = true;
	ServerID = "Your (semi-) unique server ID.";
	Adverts = {
		Warnings = {
			Randomise = false;
			Prefix = "Warning!";
			PrefixColor = {
				255, 0, 0
			};
			Color = {
				176, 127, 0
			};
			Hidable = true;
			Interval = 60;
			DestroyAt = {"Countdown", "Started"};
			Messages = {
				"message1",
				"message2"
			};
		};
		PowerHints = {
			Randomise = true;
			Prefix = "POWER!";
			PrefixColor = {
				255, 255, 255
			};
			Color = {
				0, 0, 0
			};
			Hidable = false;
			Interval = 20;
			CreateAt = "Started";
			Messages = {
				"Message of power 1!",
				"Message of power 2!",
				"Message of power 3!",
			};
		}
	}
}

local groups = {};
local bor = bit.bor;
local band = bit.band;
local lshift = bit.lshift;

local function initGroup(group)
	if not group.messages then
		return;
	end

	local messages = group.messages;
	local shuffle;
	if group.randomise then
		shuffle = table.QuickShuffle;
	else
		shuffle = function() end
	end
	local len = #messages;
	local msg_n = 1;
	local func = function()
		local msg = messages[msg_n];
		Plugin:SendNetworkMessage(nil, "Advert", {
			str = msg;
			group = group.name;
		}, true);
		msg_n = msg_n + 1;
		if msg_n > len then
			msg_n = 1;
			shuffle(messages);
		end
	end
	Plugin:CreateTimer(group.name, group.interval, -1, func);
end

local parseTime = function(time)
	if type(time) == "nil" then
		return 0;
	end

	if type(time) == "string" then
		local index = kGameState[time];
		return lshift(1, index-1);
	end

	local state = kGameState;
	local v = 0;
	for i = 1, #time do
		local index = state[time[i]];
		v = bor(v, lshift(1, index-1));
	end

	return v;
end

function Plugin:Initialise()
	local serverID = self.Config.ServerID;
	if (serverID:len() == 0) or serverID == "Your (semi-) unique server ID." then
		return false, "No valid ServerID given!";
	end
	self.dt.ServerID = serverID;

	for k, v in pairs(self.Config.Adverts) do

		local group = {
			name = k;
			prefix = v.Prefix or "";
			pr = v.PrefixColor and v.PrefixColor[1] or 255;
			pg = v.PrefixColor and v.PrefixColor[2] or 255;
			pb = v.PrefixColor and v.PrefixColor[3] or 255;
			r = v.Color and v.Color[1] or 255;
			g = v.Color and v.Color[2] or 255;
			b = v.Color and v.Color[3] or 255;
			hidable = v.Hidable;
			createAt = parseTime(v.CreateAt);
			destroyAt = parseTime(v.DestroyAt);
			randomise = v.Randomise or true;
			interval = assert(v.Interval, "Interval for " .. k .. " is missing!");
			messages = v.Messages;
		};
		table.insert(groups, group);
		if group.createAt == 0 then
			initGroup(groups[#groups]);
		end
	end

	self.Enabled = true;

	return true;
end

function Plugin:SetGameState(gamerules, new, old)
	for i = 1, #groups do
		local group = groups[i];
	 	local v = lshift(1, new-1);
		if band(group.createAt, v) ~= 0 and not self:TimerExists(group.name) then
			initGroup(group)
		elseif band(group.destroyAt, v) ~= 0 then
			self:DestroyTimer(group.name);
		end
	end
end

function Plugin:ReceiveRequestForGroups(Client)
	for i = 1, #groups do
		self:SendNetworkMessage(Client, "Group", groups[i], true)
	end
end

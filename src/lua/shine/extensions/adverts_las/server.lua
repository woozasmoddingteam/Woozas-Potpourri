local Shine = Shine

local TableQuickCopy = table.QuickCopy
local pairs = pairs;
local Plugin = Plugin;

Plugin.DefaultConfig = {
	RandomiseOrder = true;
	ServerID = "Your (semi-) unique server ID.";
	TimeToWait = 1;
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
			Maps = "ns2_descent";
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
			Maps = {"ns2_gorge", "ns2_gorgon"};
		}
	}
}

local groups = {};
local bor = bit.bor;
local band = bit.band;
local lshift = bit.lshift;
local lastPrint = 0;
local timeToWait;

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
	local func;
	local maps = group.maps;
	func = function()
		if maps then
			local map = Shared.GetMapName();
			if map:len() == 0 then
				return
			end
			for i = 1, #maps do
				if maps[i] == map then
					maps = nil;
					goto continue;
				end
			end
			Plugin:DestroyTimer(group.name);
			return;
		end
		::continue::
		local now = Shared.GetTime();
		if lastPrint > now - timeToWait then
			Plugin:SimpleTimer(timeToWait, func);
			return;
		end
		lastPrint = now;
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
	timeToWait = self.Config.TimeToWait or 1;

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
			hidable = v.Hidable or false;
			createAt = parseTime(v.CreateAt);
			destroyAt = parseTime(v.DestroyAt);
			randomise = v.Randomise or true;
			interval = assert(v.Interval, "Interval for " .. k .. " is missing!");
			messages = v.Messages;
			maps = type(v.Maps) == "string" and {v.Maps} or v.Maps; -- Even if v.Maps is nil it will work as expected.
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
		Log("Sent %s!", groups[i])
		self:SendNetworkMessage(Client, "Group", groups[i], true)
	end
end

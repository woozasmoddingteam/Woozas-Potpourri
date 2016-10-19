local Shine = Shine

local TableQuickCopy = table.QuickCopy
local TableQuickShuffle = table.QuickShuffle
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
			Messages = {
				"Message of power 1!",
				"Message of power 2!",
				"Message of power 3!",
			};
		}
	}
}

local groups = {};

function Plugin:Initialise()
	local serverID = self.Config.ServerID;
	if (serverID:len() == 0) or serverID == "Your (semi-) unique server ID." then
		return false, "No valid ServerID given!";
	end
	self.dt.ServerID = serverID;

	for k, v in pairs(self.Config.Adverts) do
		assert(v.Interval, "Interval for " .. k .. " is missing!");
		table.insert(groups, {
			name = k;
			prefix = v.Prefix or "";
			pr = v.PrefixColor and v.PrefixColor[1] or 255;
			pg = v.PrefixColor and v.PrefixColor[2] or 255;
			pb = v.PrefixColor and v.PrefixColor[3] or 255;
			r = v.Color and v.Color[1] or 255;
			g = v.Color and v.Color[2] or 255;
			b = v.Color and v.Color[3] or 255;
			hidable = v.Hidable;
		});
		local msg_n = 1;
		local randomise = v.Randomise or true;
		local messages = {};
		for i = 1, #v.Messages do
			messages[i] = v.Messages[i];
		end
		local len = #messages;
		local func = function()
			Shared.Message("Timer! " .. k);
			Shared.Message("Length: " .. len);
			Shared.Message("index: " .. msg_n);
			local msg = messages[msg_n];
			Shared.Message("__________________");
			self:SendNetworkMessage(nil, "Advert", {
				str = msg;
				group = k;
			}, true);
			msg_n = msg_n + 1;
			if msg_n > len then
				msg_n = 1;
				TableQuickShuffle(messages);
			end
		end
		Shared.Message(k);
		self:CreateTimer("Adverts timer " .. k, v.Interval, -1, func);
	end

	self.Enabled = true;

	return true;
end

function Plugin:ReceiveRequestForGroups(Client)
	for i = 1, #groups do
		self:SendNetworkMessage(Client, "Group", groups[i], true)
	end
end

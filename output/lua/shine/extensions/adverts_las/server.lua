local Shine = Shine

local TableQuickCopy = table.QuickCopy
local TableQuickShuffle = table.QuickShuffle
local pairs = pairs;
local Plugin = Plugin;

Plugin.DefaultConfig = {
	Interval = 60;
	RandomiseOrder = true;
	ServerID = "Your (semi-) unique server ID.";
	Adverts = {
		Warnings = {
			Prefix = "Warning!";
			PrefixR = 255;
			PrefixG = 0;
			PrefixB = 0;
			R = 176;
			G = 127;
			B = 0;
			Messages = {
				"message1",
				"message2"
			};
			Hidable = true;
		}
	}
}

-- Recursive function that does a deep traversal of the adverts.
local function parseAdverts(adverts)
	local messages = {};
	local groups = {};

	for group, value in pairs(adverts) do
		table.insert(groups, {
			name = group;
			prefix = value.Prefix or "";
			pr = value.PrefixR or 0;
			pg = value.PrefixG or 0;
			pb = value.PrefixB or 0;
			r = value.R or 0;
			g = value.G or 0;
			b = value.G or 0;
			hidable = value.Hidable or false;
		});
		for i = 1, #value.Messages do
			table.insert(messages, {
				str = value.Messages[i];
				group = group;
			});
		end
	end

	return messages, groups;
end

function Plugin:Initialise()
	local serverID = self.Config.ServerID;
	if (serverID:len() == 0) or serverID == "Your (semi-) unique server ID." then
		return false, "No valid ServerID given!";
	end
	self.dt.ServerID = serverID;

	local configAdverts = self.Config.Adverts;
	--if not configAdverts then return false, "No adverts to show!" end
	assert(configAdverts);

	local adverts, groups = parseAdverts(configAdverts);
	local len = #adverts;
	assert(len ~= 0);

	local interval = self.Config.Interval or 60;

	local msg_id_func;
	local msg_id = 0;

	if self.Config.RandomiseOrder then
		msg_id_func = function()
			if msg_id == len then
				TableQuickShuffle(adverts);
				msg_id = 0;
			end
		end
	else
		msg_id_func = function()
			msg_id = msg_id % len;
		end
	end

	local function printNextAdvert()
		msg_id_func();
		msg_id = msg_id + 1;

		local msg = adverts[msg_id];
		self:SendNetworkMessage(nil, "Advert", msg, true);
	end

	self:CreateTimer("Adverts timer", interval, -1, printNextAdvert);

	--self:BindCommand("sh_print_next_advert", "PrintNextAdvert", printNextAdvert, true, true);

	function self:ReceiveRequestForGroups(Client)
		for i = 1, #groups do
			self:SendNetworkMessage(Client, "Group", groups[i], true)
		end
	end

	self.Enabled = true;

	return true;
end

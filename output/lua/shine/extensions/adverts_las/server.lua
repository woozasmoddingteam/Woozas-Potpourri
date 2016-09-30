local Shine = Shine

local TableQuickCopy = table.QuickCopy
local TableQuickShuffle = table.QuickShuffle
local pairs = pairs;
local ipairs = ipairs;
local Plugin = Plugin;

Plugin.ConfigName = "AdvertsLas.json"; --What's the name of the file?
Plugin.DefaultConfig = {
	Interval = 60;
	RandomiseOrder = true;
	GlobalName = "all";
	ServerID = "Your (semi-) unique server ID.";
	Adverts = {
		R = 255;
		G = 0;
		B = 0;
		PrefixR = 0;
		PrefixG = 255;
		PrefixB = 255;
		Prefix = "[Prefix] ";
		Messages = {
			"A standard message.";
		};
		Nested = {
			["Warnings"] = {
				B = 255;
				Prefix = "[PrefixWarning] ";
				Messages = {
					"A standard warning.";
				}
			}
		}
	}
}

Plugin.PrintNextAdvert = nil; -- This will be set to a function in Initialise.

local Groups = {};

-- Recursive function that does a deep traversal of the adverts.
local function parseAdverts(group, adverts, default)
	local messages = {};

	local template = {
		pr = adverts.PrefixR or default.pr;
		pg = adverts.PrefixG or default.pg;
		pb = adverts.PrefixB or default.pg;
		r = adverts.R or default.r;
		g = adverts.G or default.g;
		b = adverts.B or default.b;
		prefix = adverts.Prefix or default.prefix;
	};
	if group then
		template.group = default.group .. "|" .. group;
	else
		template.group = default.group;
	end

	assert(string.len(template.group) <= (kMaxChatLength * 4 + 1), "Too deep a group nesting and/or too long group names!");

	Groups[template.group] = true; -- The groups table is server-side a hash-table to make every group a unique member.

	adverts.Messages = adverts.Messages or {};
	for _, v in ipairs(adverts.Messages) do
		local message = {
			prefix = template.prefix;
			group = template.group;
			pr = template.pr;
			pg = template.pg;
			pb = template.pb;
			r = template.r;
			g = template.g;
			b = template.b;
			message = v;
		}
		table.insert(messages, message);
	end

	adverts.Nested = adverts.Nested or {};
	for k, v in pairs(adverts.Nested) do
		local nested = parseAdverts(k, v, template);
		for _, v in ipairs(nested) do
			table.insert(messages, v);
		end
	end

	return messages;
end

function Plugin:Initialise()
	Shared.Message("shine adverts server init");
	local serverID = self.Config.ServerID;
	if (string.len(serverID) == 0) or serverID == "Your (semi-) unique server ID." then
		return false, "No valid ServerID given!";
	end
	self.dt.ServerID = serverID;
	local globalName = self.Config.GlobalName or "All";

	local configAdverts = self.Config.Adverts;
	if not configAdverts then return false, "No adverts!" end

	local adverts = parseAdverts(nil, configAdverts, {
		prefix = "";
		pr = 255;
		pg = 255;
		pb = 255;
		r = 255;
		g = 255;
		b = 255;
		group = globalName;
	});

	local newGroups = {};
	for k, _ in pairs(Groups) do
		table.insert(newGroups, k);
	end
	Groups = newGroups;

	local len = #adverts;

	local interval = self.Config.Interval or 10;

	local msg_id_func;
	local msg_id = 0;

	if self.Config.RandomiseOrder then
		msg_id_func = function()
			if msg_id == 0 then
				TableQuickShuffle(adverts);
				msg_id = 0;
			end
		end
	else
		msg_id_func = function()
			msg_id = msg_id % len;
		end
	end

	self.PrintNextAdvert = function()
		msg_id_func();
		msg_id = msg_id + 1;

		local msg = adverts[msg_id];
		--Server.SendNetworkMessage("ADVERTS_LAS_ADVERT", msg, true);
		self:SendNetworkMessage(nil, "Advert", msg, true);
	end

	self:SimpleTimer(interval, self.PrintNextAdvert);

	self:BindCommand("sh_print_next_advert", "PrintNextAdvert", Plugin.PrintNextAdvert, true, true);

	self.Enabled = true;

	return true;
end

function Plugin:ReceiveRequestForGroups(Client)
	for _, v in ipairs(Groups) do
		self:SendNetworkMessage(Client, "GroupsPart", {msg = v}, true)
	end
	self:SendNetworkMessage(Client, "GroupsEnd", {}, true);
end

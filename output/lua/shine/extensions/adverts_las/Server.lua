local Shine = Shine

local TableQuickCopy = table.QuickCopy
local TableQuickShuffle = table.QuickShuffle
local pairs = pairs;
local ipairs = ipairs;
local Plugin = Plugin;

Plugin.Version = "1.0"
Plugin.HasConfig = true --Does this plugin have a config file?
Plugin.ConfigName = "AdvertsLas.json" --What's the name of the file?
Plugin.DefaultState = true --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = false --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.
Plugin.DefaultConfig = {
    Interval = 30,
    GlobalName = "Something",
	RandomiseOrder = true,
}
Plugin.CheckConfig = false --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = false --Should we check the types of values in the config to make sure they match our default's types?

Plugin.PrintNextAdvert = nil; -- This will be set to a function in Initialise.


-- Recursive function that does a deep traversal of the adverts.
local function parseAdverts(group, adverts, default)
	local messages = {};
	if adverts == nil then adverts = {} end

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
	Shared.Message("shine adverts server init")
	local globalName = self.Config.GlobalName or "All";

	local adverts = parseAdverts(nil, self.Config.Adverts, {
		prefix = "";
		pr = 255;
		pg = 255;
		pb = 255;
		r = 255;
		g = 255;
		b = 255;
		group = globalName;
	});

	local len = #adverts;

	local interval = self.Config.Interval or 10;

	local msg_id_func;
	local msg_id = 0;

	msg_id_func = function()
		if self.Config.RandomiseOrder or false then
			if msg_id == 0 then
				TableQuickShuffle(adverts);
			end
		end
		msg_id = msg_id % len;
	end

	self.PrintNextAdvert = function()
		msg_id_func();
		msg_id = msg_id + 1;

		local msg = adverts[msg_id];
		if msg then
			Server.SendNetworkMessage("ADVERTS_LAS_ADVERT", msg, true);
		end
	end

	Shared.Message(tostring(interval));

	self:SimpleTimer(interval, self.PrintNextAdvert);

	self:BindCommand("sh_print_next_advert", "PrintNextAdvert", Plugin.PrintNextAdvert, true, true);

	self.Enabled = true;

	return true;
end

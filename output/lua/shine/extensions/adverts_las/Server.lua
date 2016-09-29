local Shine = Shine

local TableQuickCopy = table.QuickCopy
local TableQuickShuffle = table.QuickShuffle
local TableRemove = table.remove
local type = type;
local pairs = pairs;
local ipairs = ipairs;
local Plugin = Plugin;

Plugin.HasConfig = true;
Plugin.ConfigName = "AdvertsLas.json";

-- Recursive function that does a deep traversal of the adverts.
local function parseAdverts(group, adverts, default)
	local messages = {};

	local template = {
		type = adverts.Type or default.type;
		prefix = adverts.Prefix or default.prefix;
		pr = adverts.PrefixR or default.pr;
		pg = adverts.PrefixG or default.pg;
		pb = adverts.PrefixB or default.pg;
		r = adverts.R or default.r;
		g = adverts.G or default.g;
		b = adverts.B or default.b;
		--position = (adverts.Position or default.position):lower();
		position = "top";
	};
	if group then
		template.group = {
			parent = default.group;
			name = group;
		};
	else
		template.group = default.group;
	end

	adverts.Messages = adverts.Messages or {};
	for _, v in ipairs(adverts.Messages) do
		local message = {
			type = template.type;
			prefix = template.prefix;
			pr = template.pr;
			pg = template.pg;
			pb = template.pb;
			position = template.position;
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

Plugin.PrintNextAdvert = nil; -- This will be set to a function in Initialise.

function Plugin:Initialise()
	Shared.Message("Initialised My Plugin.");

	local globalName = self.Config.GlobalName or "All";

	local adverts = parseAdverts(globalName, self.Config.Adverts, {
		prefix = "",
		pr = 255,
		pg = 255,
		pb = 255,
		type = "chat",
		r = 255,
		g = 255,
		b = 255,
		position = "top",
	});

	local len = #adverts;

	local randomiseOrder = self.Config.RandomiseOrder;
	local interval = self.Config.Interval;

	local msg_id_func;
	local msg_id = 0;

	if randomiseOrder then
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

	self.PrintNextAdvert = function()
		msg_id_func();
		msg_id = msg_id + 1;

		local msg = adverts[msg_id];

		if msg.type == "chat" then
			Shine:NotifyDualColour(nil,
				msg.pr,	msg.pg,	msg.pb,	msg.prefix,
				msg.r,	msg.g,	msg.b,	msg.message,
				false
			);
		else
			local pos = msg.position;

			local px, py = 0.5, nil;

			if pos == "bottom" then
				py = 0.8;
			else
				py = 0.2;
			end

			Shine.ScreenText.Add(20, {
				X = px,
				Y = py,
				Text = msg.message,
				Duration = 7,
				R = msg.r,
				G = msg.g,
				B = msg.b,
				Alignment = 1,
				Size = 2,
				FadeIn = 1
			});
		end

		msg_id = msg_id + 1;
	end

	self:SimpleTimer(self.Config.Interval, self.PrintNextAdvert);

	self:BindCommand("sh_print_next_advert", "PrintNextAdvert", Plugin.PrintNextAdvert, true, true);

	self.Enabled = true;

	return true;
end

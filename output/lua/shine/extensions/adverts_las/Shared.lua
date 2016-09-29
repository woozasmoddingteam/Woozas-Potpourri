local Shine = Shine;
local Plugin = {}
Plugin.Version = "1.0"
Plugin.PrintName = "AdvertsLas"
Plugin.Conflicts = {
	DisableThem = {
		"adverts"
	}
};

local StringMessage = string.format("string (%i)", kMaxChatLength * 4 + 1);

Shared.RegisterNetworkMessage("ADVERTS_LAS_ADVERT", {
	pr = "integer (0 to 255)";
	pg = "integer (0 to 255)";
	pb = "integer (0 to 255)";
	r = "integer (0 to 255)";
	g = "integer (0 to 255)";
	b = "integer (0 to 255)";
	prefix = StringMessage;
	message = StringMessage;
	group = StringMessage;
});

Shine:RegisterExtension("adverts_las", Plugin);

local Shine = Shine;
local Plugin = {}
Plugin.Version = "1.0"
Plugin.PrintName = "AdvertsLas"
Plugin.Conflicts = {
	DisableThem = {
		"adverts"
	}
};

Shine:RegisterExtension("adverts_las", Plugin);

local Plugin = {
	Version = "2.0",
	NS2Only = false,
	HasConfig = true,
	ConfigName = "EasterEggs.json",
	DefaultConfig = {
		Limit = 2,
		Winners = {},
		Saved = {}
	},
	Conflicts = {
		DisableThem = {
			"jointeam"
		}
	}
}

--[=[
	Has to be loaded always, since if the plugin is enabled on the server,
	it will first run on the client after he has loaded, thus a consistency
	error will occur. Not good.
]=]
Shine.Hook.Add("PostLoadScript", "EasterEggs", function(script)
	if script == "lua/Class.lua" then
		assert(loadfile "lua/shine/extensions/eastereggs/easteregg.lua")(Plugin)
	end
end)

Shine:RegisterExtension("eastereggs", Plugin)

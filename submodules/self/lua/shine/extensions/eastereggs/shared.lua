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
		assert(loadfile "lua/shine/extensions/eastereggs/EasterEgg.lua")(Plugin)
	end
end)

function Plugin:PostLoadScript(script)
	if script == "lua/NS2Utility.lua" then
		local old = CanEntityDoDamageTo
		function CanEntityDoDamageTo(attacker, target, cheats, dev, ff, type)
			return target:isa "EasterEgg" or old(attacker, target, cheats, dev, ff, type)
		end
	end
end

Shine:RegisterExtension("eastereggs", Plugin)

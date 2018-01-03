for _, v in ipairs {
	"Locale",
	"NS2Utility",
	"TechTreeConstants",
	"TechTreeButtons",
	"TechData",
	"MarineCommander",
	"MarineTeam",
} do
	ModLoader.SetupFileHook("lua/"..v..".lua", "lua/FlameSentry/"..v..".lua", "post")
end

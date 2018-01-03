for _, v in ipairs {
	"Locale",
	"NS2Utility",
	"TechTreeConstants",
	"TechTreeButtons",
	"MarineCommander",
	"MarineTeam",
} do
	ModLoader.SetupFileHook("lua/"..v..".lua", "lua/FlameSentry/"..v..".lua", "post")
end
ModLoader.SetupFileHook("lua/TechTreeConstants.lua", "lua/FS_TechTreeConstant.lua", "post")
ModLoader.SetupFileHook("lua/Shared.lua", "lua/FlameSentry.lua", "post")

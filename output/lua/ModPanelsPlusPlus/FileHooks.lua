ModLoader.SetupFileHook("lua/Gamerules.lua", "lua/ModPanelsPlusPlus/Gamerules.lua", "post")

if Shared.GetBuildNumber() < 315 then
	ModLoader.SetupFileHook("lua/ReadyRoomPlayer.lua", "lua/ModPanelsPlusPlus/ReadyRoomPlayer.lua", "replace")
	ModLoader.SetupFileHook("lua/Player.lua", "lua/ModPanelsPlusPlus/Player.lua", "post")
end

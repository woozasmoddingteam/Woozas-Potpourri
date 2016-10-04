--[[
 	ShoulderPatchesExtra
	ZycaR (c) 2016
]]

ModLoader.SetupFileHook( "lua/Player.lua", "lua/spe_Player.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/MenuPoses.lua", "lua/spe_MenuPoses.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/GUIMainMenu_Customize.lua", "lua/spe_CustomizePatches.lua" , "post" )

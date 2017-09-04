--[[
	ShoulderPatchesExtra
	ZycaR (c) 2016
]]

ModLoader.SetupFileHook( "lua/Player.lua", "lua/spe/Player.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/MenuPoses.lua", "lua/spe/MenuPoses.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/GUIMainMenu_Customize.lua", "lua/spe/CustomizePatches.lua" , "post" )

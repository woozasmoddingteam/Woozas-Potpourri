--[[
	ShoulderPatchesExtra
	ZycaR (c) 2016
	Modifications by Las © 2017
]]

ModLoader.SetupFileHook( "lua/Player.lua", "lua/spe/Player.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/MenuPoses.lua", "lua/spe/MenuPoses.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/GUIMainMenu_Customize.lua", "lua/spe/CustomizePatches.lua" , "post" )
ModLoader.SetupFileHook( "lua/menu/MenuElement.lua", "lua/spe/MenuElement.lua" , "post" )

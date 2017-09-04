
--if not string.find(Script.CallStack(), "Main.lua") then
    ModLoader.SetupFileHook( "lua/Shared.lua", "lua/MineMadness/Shared.lua", "post" )
    ModLoader.SetupFileHook( "lua/ServerAdminCommands.lua", "lua/MineMadness/ServerAdminCommands.lua", "post" )
--end

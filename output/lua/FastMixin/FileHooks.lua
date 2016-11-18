--Script.Load("lua/FastMixin/MixinDetector.lua");

ModLoader.SetupFileHook("lua/MixinUtility.lua", "lua/FastMixin/MixinUtility.lua", "replace");
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", "", "halt");

ModLoader.SetupFileHook("lua/MixinUtility.lua", "lua/FastMixin/MixinUtility.lua", "replace");
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", "", "halt");
ModLoader.SetupFileHook("lua/Mixins/BaseModelMixin.lua", "lua/FastMixin/BaseModelMixin.lua", "post");
ModLoader.SetupFileHook("lua/ScoringMixin.lua", "lua/FastMixin/ScoringMixin.lua", "post");

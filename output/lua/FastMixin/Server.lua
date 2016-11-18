Log("DISABLING CLASS GENERATION");
class = nil;

--Script.Load("lua/FastMixin/MixinDetector.lua");

--BeginMixinDetection();

local old = Entity.OnInitialised;
Entity.OnInitialised = function(self)
	old(self);
	Log("Metatable: %s", tostring(getmetatable(self)));
end

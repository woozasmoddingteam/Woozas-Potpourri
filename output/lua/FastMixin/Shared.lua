Log("DISABLING CLASS GENERATION");
local oldclass = class;
local classes = debug.getregistry().__CLASSES;
local classcount = #classes;
local missedcount = 0;
class = function(name)
	local ret = oldclass(name);
	missedcount = missedcount + 1;
	--Log("Declared class %s after mixin detection initialisation! Missed class count: %s", name, missedcount);
	return ret;
end

Script.Load("lua/FastMixin/MixinDetector.lua");

BeginMixinDetection();

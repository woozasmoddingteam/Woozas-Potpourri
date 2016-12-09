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

--[[
local function printSlows(...)
	local args = {...};
	for i = 1, #args do
		local n = args[i];
		local t = _G[n];
		if not t then Log("%s does not exist!", n); goto continue end
		if type(t) ~= "table" then Log("%s is not a table but instead a %s!", n, type(t)); goto continue end
		for k, v in pairs(t) do
			if type(v) == "function" and debug.getinfo(v).what ~= "Lua" then
				Log(n .. ".%s", k);
			end
		end
		::continue::
	end
end

Log("SLOW FUNCTIONS:");
if Server then
	printSlows("Server", "Shared", "_G", "Angles", "AnimationGraph", "Cinematic", "CollisionObject", "Color", "Coords", "Entity", "Event", "HeightMap", "Model", "Move", "Pathing", "RandomUniform", "Render");
elseif Client then
	printSlows("Client", "ClientLoaded");
end
Log("END OF SLOW FUNCTIONS.");
--]]

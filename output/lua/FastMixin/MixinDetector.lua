local oldclass = class;

local reg = debug.getregistry();
local classes = reg.__CLASSES;
if not classes then
	classes = {};
	reg.__CLASSES = classes;
else

class = function(name)
	local oldbasesetter = oldclass(name);
	local cls = _G[name];
	getmetatable(cls).name = name;
	getmetatable(cls).mixins = {};
	classes[#classes+1] = cls;

	return function(base)
		getmetatable(cls).base = base;
		oldbasesetter(base);
	end
end

-- The amount of times a mixin has to be instantiated in a row to be deemed inlinable.
-- A single fail will blacklist it.
local kMixinInliningLimit = 5;

function BeginMixinDetection()
	for i = 1, #classes do
		local cls = classes[i];
		if cls.OnCreate then
			local mixins = {}; -- Keeps track of the mixins
			local old = cls.OnCreate;
			cls.OnCreate = function(self)
				old(self);
				local imixins = getmetatable(self).instance_mixins;
				for i = 1, #imixins do
					local mixin = imixins[i];
					mixins[mixin] = mixins[mixin] + 1;
				end
				local previous = nil;
				for mixin, count in pairs(mixins) do
					if not previous then
						previous = count;
					else
						if 
			end
		end
	end
end

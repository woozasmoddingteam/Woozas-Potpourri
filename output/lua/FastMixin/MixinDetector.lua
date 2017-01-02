Script.Load("lua/MixinUtility.lua");
local classes = debug.getregistry().__CLASSES;

local metatable = {
	__index = function(self, key)
		if rawget(self, key) ~= nil then
			return rawget(self, key);
		else
			return self.__class[key];
		end
	end
}

local detected_classes = {};

function DetectMixins(cls)
	assert(not detected_classes[cls]);
	detected_classes[cls] = true;
	local meta = getmetatable(cls);

	if not cls.OnCreate then
		--Log("INFO: No %s.OnCreate!", meta.name);
		return;
	else
		--Log("INFO: Enabling optimisations for %s.OnCreate", meta.name, cls.OnCreate);
		local old = cls.OnCreate;
		function cls:OnCreate(...)
			if not self.__class then
				self.__mixintypes = {};
				self.__mixindata = setmetatable({__class = meta.mixindata}, metatable);
				self.__class = cls;
				self.__constructing = true;
				old(self, ...);
				self.__constructing = false;
			else
				old(self, ...);
			end
		end
	end

	if not cls.OnInitialized then
		--Log("INFO: No %s.OnInitialized!", meta.name);
	else
		--Log("INFO: Enabling optimisations for %s.OnInitialized", meta.name, cls.OnCreate);
		local old = cls.OnInitialized;
		function cls:OnInitialized(...)
			local preconstruction = self.__constructing;
			self.__constructing = true;
			old(self, ...);
			self.__constructing = preconstruction;
		end
	end
end

function BeginMixinDetection()
	for i = 1, #classes do
		DetectMixins(classes[i]);
	end
end
--]]

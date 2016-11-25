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

local env = setmetatable(
	{InitMixin = InitMixinMixinDetector, HasMixin = HasMixinMixinDetector},
	{__index = _G, __newindex = _G}
);

local detected_classes = {};

function DetectMixins(cls)
	assert(not detected_classes[cls]);
	detected_classes[cls] = true;
	local meta = getmetatable(cls);

	if not cls.OnCreate then
		Log("INFO: No OnCreate in class %s!", meta.name);
		return;
	else
		Log("cls.OnCreate for %s: %s", meta.name, cls.OnCreate);
		local old = cls.OnCreate;
		function cls:OnCreate(...)
			if not self.__class then
				self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
				self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
				self.__class = cls;
				self.__constructing = true;
				old(self, ...);
				self.__constructing = nil;
			end
		end
	end

	if not cls.OnInitialized then
		Log("INFO: No OnInitialized in class %s!", meta.name);
		return;
	else
		Log("cls.OnInitialized for %s: %s", meta.name, cls.OnCreate);
		local old = cls.OnInitialized;
		function cls:OnInitialized(...)
			if self.__class == cls then
				old(self, ...);
			else
				old(self, ...);
			end
		end
	end
end

function BeginMixinDetection()
	for i = 1, #classes do
		DetectMixins(classes[i]);
	end
end
--]]

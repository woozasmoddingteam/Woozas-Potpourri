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

function BeginMixinDetection()
	for i = 1, #classes do
		local cls = classes[i];
		local meta = getmetatable(cls);

		if not cls.OnCreate then
			Log("INFO: No OnCreate in class %s!", meta.name);
		else
			Log("cls.OnCreate for %s: %s", meta.name, cls.OnCreate);
			local old = cls.OnCreate;
			local oldenv = getfenv(old);
			setfenv(old, env);
			function cls:OnCreate()
				if not self.__class then
					self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
					self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
					self.__mixins = {};
					self.__class = cls;
					old(self);
					local tags = {};
					if self:isa("Entity") then
						for i = 1, #self.__mixins do
							local mixin = self.__mixins[i];
							InitMixinForClass(cls, mixin);
							tags[#tags+1] = mixin.type;
						end
					end
					setfenv(old, oldenv);
					function cls:OnCreate()
						if not self.__class then
							self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
							self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
							self.__class = cls;
						end
						old(self);
						for i = 1, #tags do
							Shared.AddTagToEntity(self:GetId(), tags[i]);
						end
					end
				else
					old(self);
				end
			end
		end

		if not cls.OnInitialized then
			Log("INFO: No OnInitialized in class %s!", meta.name);
		else
			Log("cls.OnInitialized for %s: %s", meta.name, cls.OnCreate);
			local old = cls.OnInitialized;
			local oldenv = getfenv(old);
			setfenv(old, env);
			function cls:OnInitialized()
				if self.__class == cls then
					self.__mixins = {};
					old(self);
					local tags = {};
					if self:isa("Entity") then
						for i = 1, #self.__mixins do
							local mixin = self.__mixins[i];
							InitMixinForClass(cls, mixin);
							tags[#tags+1] = mixin.type;
						end
					end
					setfenv(old, oldenv);
					function cls:OnInitialized()
						old(self);
						for i = 1, #tags do
							Shared.AddTagToEntity(self:GetId(), tags[i]);
						end
					end
				else
					old(self);
				end
			end
		end
	end
end
--]]

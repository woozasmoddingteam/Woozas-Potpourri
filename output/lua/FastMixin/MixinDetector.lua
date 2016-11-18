local oldclass = class;

local reg = debug.getregistry();
local classes = reg.__CLASSES;
if not classes then
	classes = {};
	reg.__CLASSES = classes;
end

local metatable = {
	__index = function(self, key)
		if self[key] ~= nil then
			return self[key];
		else
			return self.__class[key];
		end
	end
}

local function GetMixinConstants(self)
	return self.__mixindata
end

local function GetMixinConstant(self, constantName)
	return self.__mixindata[constantName]
end

class = function(name)
	local oldbasesetter = oldclass(name);
	local cls = _G[name];
	local meta = getmetatable(cls);
	meta.name = name;
	classes[#classes+1] = cls;

	cls.__class_mixins = {};
	cls.__class_mixintypes = {};
	cls.__class_mixindata = {};
	cls.GetMixinConstants = GetMixinConstants;
	cls.GetMixinConstant = GetMixinConstant;

	local old = meta.__newindex;
	meta.__newindex = function(self, key, value)
		old(self, key, value);
		if key == "OnCreate" then
			Log("Overriding OnCreate for %s!", name);
			local old_OnCreate = cls.OnCreate; -- In case the original __newindex modifies it
			cls.OnCreate = function(self)
				old_OnCreate(self);
				self.__mixins = {};
				self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
				self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
				Log("Better ONCREATE! %s %s %s", name, tostring(self), self.__mixins);
			end
			meta.__newindex = old; -- Unhook ourselves when done
		end
	end

	return function(base)
		meta.base = base;
		oldbasesetter(base);
	end
end

-- The amount of times a mixin has to be instantiated in a row to be deemed inlinable.
-- A single fail will blacklist it.
local kMixinInliningLimit = 3;

local function hookMixinDetector(old, callback)
	local mixin_state = {}; -- Keeps track of the mixins
	return function(self)
		old(self);
		Log("%s %s", tostring(self), self.__mixins);
		local mixins = self.__mixins;
		if not mixins then
			Log("Invalid instance %s!", self);
			return;
		else
			Log("Valid instance %s!", self);
		end
		for i = 1, #mixins do
			local mixin = mixins[i];
			if mixin_state[mixin] == nil then
				mixin_state[mixin] = 0;
			elseif mixin_state[mixin] ~= false then
				mixin_state[mixin] = mixin_state[mixin] + 1;
			end
		end
		local previous = nil;
		local prev_mixin = nil;
		for mixin, count in pairs(mixin_state) do
			if not previous then
				previous = count;
				prev_mixin = mixin;
			else
				if count > previous then
					mixin_state[prev_mixin] = false;
				elseif count < previous then
					mixin_state[mixin] = false;
				end

				if count >= kMixinInliningLimit then
					callback(mixin_state, old);
					break;
				end
			end
		end
	end
end

function BeginMixinDetection()
	for i = 1, #classes do
		local cls = classes[i];
		if cls.OnCreate then
			local callback = function(mixin_state, original)
				Log("Done inlining for class %s!", getmetatable(cls).name)
				cls.OnCreate = original;
				for mixin, value in pairs(mixin_state) do
					if value then
						Log("Inlining %sMixin!", mixin.type);
						InitMixinForClass(cls, mixin);
					end
				end
			end
			cls.OnCreate = hookMixinDetector(cls.OnCreate, callback);
		end
		if cls.OnInitialized then
			local callback = function(mixin_state, original)
				Log("Done inlining for class %s!", getmetatable(cls).name)
				cls.OnInitialized = original;
				for mixin, value in pairs(mixin_state) do
					if value then
						Log("Inlining %sMixin!", mixin.type);
						InitMixinForClass(cls, mixin);
					end
				end
			end
			cls.OnInitialized = hookMixinDetector(cls.OnInitialized, callback);
		end
	end
end
--]]

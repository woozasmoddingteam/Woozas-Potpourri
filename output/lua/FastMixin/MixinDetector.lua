local classes = debug.getregistry().__CLASSES;

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
		if #mixins == 0 then -- If no mixins are used, we shouldn't wait.
			callback(mixin_state, old);
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


local metatable = {
	__index = function(self, key)
		if rawget(self, key) ~= nil then
			return rawget(self, key);
		else
			return self.__class[key];
		end
	end
}

function BeginMixinDetection()
	for i = 1, #classes do
		local cls = classes[i];
		local meta = getmetatable(cls);

		if not cls.OnCreate then
			Log("No OnCreate in class %s!", meta.name);
		else
			Log("cls.OnCreate for %s: %s", meta.name, cls.OnCreate);
			--[[
			local callback = function(mixin_state, original)
				Log("Done inlining in OnCreate for class %s!", meta.name)
				cls.OnCreate = original;
				for mixin, value in pairs(mixin_state) do
					if value then
						Log("Inlining %sMixin!", mixin.type);
						InitMixinForClass(cls, mixin);
					end
				end
			end
			cls.OnCreate = hookMixinDetector(cls.OnCreate, callback);
			--]]
			local old = cls.OnCreate;
			function cls:OnCreate()
				self.__initialized = true;
				self.__mixins = {};
				self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
				self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
				old(self);
			end
		end

		--[[
		if cls.OnInitialized then
			Log("cls.OnInitialized for %s: %s", meta.name, cls.OnInitialized);
			local callback = function(mixin_state, original)
				Log("Done inlining in OnInitialized for class %s!", meta.name)
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
		--]]
	end
end
--]]

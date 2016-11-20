local classes = debug.getregistry().__CLASSES;

-- The amount of times a mixin has to be instantiated in a row to be deemed inlinable.
-- A single fail will blacklist it.
-- Increase it if the wrong mixins are optimised
-- NB: You **will** decrease the performance on OnCreate by a lot for the initial [kMixinInliningLimit] calls
local kMixinInliningLimit = 3;

local function detectMixins(mixins, cls, mixin_state, hcount)
	if #mixins == 0 then -- If no mixins are used, we shouldn't wait.
		return false;
	end
	for i = 1, #mixins do
		local mixin = mixins[i];
		local count;
		if mixin_state[mixin] == nil then
			mixin_state[mixin] = 1;
			count = 1;
		else
			count = mixin_state[mixin] + 1;
			mixin_state[mixin] = count;
		end

		if count > hcount then -- All the previous ones are invalid
			hcount = count;
		end
	end

	if hcount >= kMixinInliningLimit then
		Log("----------\n\n\nINLINING MIXINS FOR %s!", getmetatable(cls).classname);
		for i = 1, #mixins do
			if mixin_state[mixins[i]] >= kMixinInliningLimit then
				InitMixinForClass(cls, mixin);
			end
		end
		Log("\n\n\n----------");
		return false;
	end

	return hcount;
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
			Log("INFO: No OnCreate in class %s!", meta.name);
		else
			Log("cls.OnCreate for %s: %s", meta.name, cls.OnCreate);
			local old = cls.OnCreate;
			local onCreate_mixin_state = {};
			local hcount = 0; -- highest, look in detectMixins
			function cls:OnCreate()
				if not self.__class then
					self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
					self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
					self.__mixins = {};
					self.__class = cls;
					old(self);
					hcount = detectMixins(self.__mixins, cls, onCreate_mixin_state, hcount);
					if not hcount then -- returns false if done
						meta.fastmixin = true;
						function cls:OnCreate()
							if not self.__class then
								self.__mixintypes = setmetatable({__class = cls.__class_mixintypes}, metatable);
								self.__mixindata = setmetatable({__class = cls.__class_mixindata}, metatable);
								self.__class = cls;
							end
							old(self);
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

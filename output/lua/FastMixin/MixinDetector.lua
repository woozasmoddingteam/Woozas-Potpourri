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
local kMixinInliningLimit = 3;

local function hookMixinDetector(old)
	local mixin_state = {}; -- Keeps track of the mixins
	return function(self)
		old(self);
		local mixins = getmetatable(self).mixins;
		for i = 1, #mixins do
			local mixin = mixins[i];
			if mixin_state[mixin] == nil then
				mixin_state[mixin] = 0;
			elseif mixin_state[mixin] ~= false then
				mixin_state[mixin] = (mixin_state[mixin] or 0) + 1;
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
					for mixin, value in pairs(mixin_state) do
						if value then
							InitMixinForClass(cls, mixin);
						end
					end
					cls.OnCreate = old;
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
			local mixin_state = {}; -- Keeps track of the mixins
			local old = cls.OnCreate;
			cls.OnCreate = function(self)
				old(self);
				local mixins = getmetatable(self).mixins;
				for i = 1, #mixins do
					local mixin = mixins[i];
					if mixin_state[mixin] == nil then
						mixin_state[mixin] = 0;
					elseif mixin_state[mixin] ~= false then
						mixin_state[mixin] = (mixin_state[mixin] or 0) + 1;
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
							for mixin, value in pairs(mixin_state) do
								if value then
									InitMixinForClass(cls, mixin);
								end
							end
							cls.OnCreate = old;
							break;
						end
					end
				end
			end
		end
	end
end

-- Copyright © 2016 Lass Safin. All rights reserved.

assert(class); -- To make sure that the class function has already been initialised

local getinfo = debug.getinfo;
local getupvalue = debug.getupvalue;
local setupvalue = debug.setupvalue;

local poison = {};
local pfunc = function() return poison end
local genPoisonMeta = function() return {
	__add = pfunc,
	__sub = pfunc,
	__mul = pfunc,
	__div = pfunc,
	__mod = pfunc,
	__pow = pfunc,
	__unm = pfunc,
	__concat = pfunc,
	__len = pfunc,
	__eq = pfunc,
	__lt = pfunc,
	__le = pfunc,
	__index = pfunc,
	__newindex = pfunc,
	__call = pfunc
} end
setmetatable(poison, genPoisonMeta());

local wrapTable = function(t)
	return setmetatable({}, {__index = t, __newindex = pfunc});
end

local function InitMixinOverride(self, mixin, options)
	local time = getmetatable(self).time;
	local meta = getmetatable(_G[self:GetClassName()]);

	if time == "OnCreate" then
		table.insert(meta.OnCreateMixins, {mixin, options});
	else
		table.insert(meta.OnInitializedMixins, {mixin, options});
	end
end

local mixin_detector_env = {
	__newindex = pfunc,
	__index = function(self, key)
		if key == "InitMixin" then
			return InitMixinOverride;
		end

		local v = _G[key];

		if type(v) == "function" then
			if getinfo(v).what ~= "Lua" then
				return pfunc;
			else
				isolateFunction(v);
			end
		elseif type(v) == "table" then
			return wrapTable(v);
		end

		return v;
	end
};

local isolated_functions = {};

local function isolateFunction(func)
	if isolated_functions[func] then
		return
	end
	local ups = {};
	isolated_functions[func] = ups;

	local ups[0] = getfenv(func);

	for i = 1, getinfo(func).nups do
		local name, val = getupvalue(func, i);
		ups[i] = val;

		if type(val) == "function" then
			if getinfo(val).what ~= "Lua" then
				setupvalue(func, i, pfunc); -- Don't allow access to external functions
			end
		elseif type(val) == "table" then
			local wrapper = wrapTable(val);
			setupvalue(func, i, wrapper); -- Don't allow writes to upvalues
		end
	end

	setfenv(func, mixin_detector_env);
end

local function freeAllFunctions()
	for func, ups in pairs(isolated_functions) do
		-- Restore the environment
		setfenv(func, ups[0]);

		-- Restore the upvalues
		for i = 1, #ups do
			setupvalue(func, i, ups[i]);
		end
	end
end

-- Detect mixins
local oldclass = class;
class = function(name)
	--Shared.Message("Creating class " .. name);
	local ret = oldclass(name);

	local meta = getmetatable(_G[name]);
	meta.OnCreateMixins = {};
	meta.OnInitializedMixins = {};

	local oldnewindex = meta.__newindex;

	meta.__newindex = function(self, key, value)
		oldnewindex(self, key, value);
		if key == "OnCreate" then
			local classInst = {};
			local meta = genPoisonMeta();
			meta.time = "OnCreate";
			classInt.GetClassName = function() return name end
			setmetatable(classInst, meta);

			isolateFunction(value); -- Isolate
			value(classInst);
			freeAllFunctions(); -- Free
		elseif key == "OnInitialized" then
			local classInst = {};
			local meta = genPoisonMeta();
			meta.time = "OnInitialized";
			classInt.GetClassName = function() return name end
			setmetatable(classInst, meta);

			isolateFunction(value); -- Isolate
			value(classInst);
			freeAllFunctions(); -- Free
		end
	end
	return ret;
end

ModLoader.SetupFileHook("lua/MixinUtility.lua", "lua/FastMixin/MixinUtility.lua", "replace");
ModLoader.SetupFileHook("lua/MixinDispatcherBuilder.lua", "lua/FastMixin/MixinDispatcherBuilder.lua", "replace");

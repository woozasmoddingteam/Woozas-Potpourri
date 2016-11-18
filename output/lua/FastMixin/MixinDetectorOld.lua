
local getinfo = debug.getinfo;
local getupvalue = debug.getupvalue;
local setupvalue = debug.setupvalue;

local garbage_table_meta = {
	__mode = "kv";
};

local poison = {__ISPOISON = true};
local pfunc = function() return poison end
local rettrue = function() return true end
local retfalse = function() return false end
local retzero = function() return 0 end
local retemptystr = function() return "" end

local global_overrides = {
	GetSize = retzero
};

local global_active_overrides = {};

local poison_index = function(self, key)
	if global_overrides[key] then
		Log("Overrode %s", key);
		return global_overrides[key];
	else
		return poison;
	end
end

local genPoisonMeta = function() return {
	__add = pfunc,
	__sub = pfunc,
	__mul = pfunc,
	__div = pfunc,
	__mod = pfunc,
	__pow = pfunc,
	__unm = pfunc,
	__concat = retemptystr,
	__len = retzero,
	__eq = retfalse,
	__lt = retfalse,
	__le = retfalse,
	__index = poison_index,
	__call = pfunc
} end
setmetatable(poison, genPoisonMeta());

local blacklist;
local wrapTable;
local isolateFunction;

-- Required for meta tables
local preemptiveWrap = function(towrap)
	local wrapper = {};
	for k, v in pairs(towrap) do
		if type(v) == "function" then
			Log("Isolating metatable value %s function '%s'!", getinfo(v).what, k);
			local copy = isolateFunction(v);
			wrapper[k] = copy;
		elseif type(v) == "table" then
			Log("Wrapping metatable value table '%s'!", k);
			local metawrapper = wrapTable(v, k); -- Doing a preemptive wrap here would could cause infinite recursion
			wrapper[k] = metawrapper;
		elseif type(v) == "cdata" or type(v) == "userdata" then
			Log("Invalidating cdata/userdata '%s'!", k);
			wrapper[k] = poison;
		else
			wrapper[k] = v;
		end
	end
	return wrapper;
end

local wrappers = setmetatable({}, garbage_table_meta); -- Key: wrapped, Value: wrapper
local wrapped = setmetatable({}, garbage_table_meta); -- Key: wrapper, Value: wrapped

local wrapperMeta = {
	__index = function(self, key)
		local v = rawget(wrapped[self], key);

		if type(v) == "function" then
			Log("Isolating table value %s function '%s'!", getinfo(v).what, key);
			local copy = isolateFunction(v, global_overrides[key]);
			rawset(self, key, copy);
			return copy;
		elseif type(v) == "table" then
			Log("Wrapping table value table '%s'!", key);
			local wrapper = wrapTable(v, self.__name .. "." .. key);
			rawset(self, key, wrapper)
			return wrapper;
		elseif type(v) == "cdata" or type(v) == "userdata" then
			Log("Invalidating table value cdata/userdata '%s'!", key);
			rawset(self, key, poison);
			return poison;
		else
			return v;
		end
	end
};

-- Isn't global! Prototype has already been defined.
wrapTable = function(towrap, name)
	if blacklist[towrap] then
		Log("Trying to wrap blacklisted table %s!", name);
		return towrap;
	end

	if wrappers[towrap] then
		Log("Wrapper %s %s already exists!", wrappers[towrap].__name, name);
		return wrappers[towrap];
	end

	local wrapper = {__ISWRAPPER = true, __name = name};
	wrappers[towrap] = wrapper;
	wrapped[wrapper] = towrap;
	if getmetatable(towrap) then
		local meta = getmetatable(towrap);
		local metawrapper = preemptiveWrap(meta);
		local __index = metawrapper.__index;
		local wrapperMeta__index = wrapperMeta.__index;
		metawrapper.__index = function(self, key)
			local ret = wrapperMeta__index(self, key);
			if ret == nil then
				return __index(self, key);
			else
				return ret;
			end
		end
		setmetatable(wrapper, metawrapper);
	else
		setmetatable(wrapper, wrapperMeta);
	end
	return wrapper;
end

local oldInitMixin;

local function InitMixinOverride(self, mixin, options)
	local cls = self.__class;
	local meta = getmetatable(cls);
	mixin = wrapped[mixin];

	Log("%s: InitMixin(%s, %sMixin, %s)", self.__time, meta.name, mixin.type, options);
	if self.__time == "OnCreate" then
		table.insert(meta.OnCreateMixins, {mixin, options});
	else
		table.insert(meta.OnInitializedMixins, {mixin, options});
	end

	oldInitMixin(self, mixin, options);
end

local isolated_functions = {};

-- Not global!
function isolateFunction(func, default)
	local info = getinfo(func);

	if blacklist[func] then
		Log("Tried to isolate blacklisted function!")
		return default or func;
	elseif global_active_overrides[func] then
		return global_active_overrides[func];
	elseif isolated_functions[func] then
		Log("Tried to isolate an already isolated function");
		return isolated_functions[func];
	end

	if info.what ~= "Lua" then
		return default or pfunc; -- External functions can not be run no matter what.
	end

	local copy = loadstring(string.dump(func)); -- Copy the function; slow, but best solution for keeping the VM separated.

	for i = 1, info.nups do
		local name, val = getupvalue(func, i);

		if type(val) == "function" then
			Log("Isolating upvalue %s function '%s'!", info.what, name);
			setupvalue(copy, i, isolateFunction(val));
		elseif type(val) == "table" then
			Log("Wrapping upvalue table '%s'!", name);
			local wrapper = wrapTable(val, name);
			setupvalue(copy, i, wrapper); -- Don't allow writes to upvalues
		elseif type(val) == "cdata" or type(val) == "userdata" then
			Log("Invalidating upvalue cdata/userdata '%s'!", name);
			setupvalue(copy, i, poison);
		else
			setupvalue(copy, i, val);
		end
	end

	setfenv(copy, wrapTable(_G, "_G"));

	isolated_functions[func] = copy;

	return copy;
end

DETECTING_MIXINS = false;

function DetectMixins(cls)
	assert(not DETECTING_MIXINS, "Can only detect the mixins for one class at a time!");
	DETECTING_MIXINS = true;
	local meta = getmetatable(cls);
	meta.OnCreateMixins = {};
	meta.OnInitializedMixins = {};
	local delim = "--------------";
	local DONE = delim .. "DONE" .. delim;
	delim = delim .. delim;
	if cls.OnCreate then
		Log("%s.OnCreate", meta.name);
		Log(delim);
		local classInst = {__fake = true, __time = "OnCreate", __class = cls};
		wrapped[classInst] = cls;
		setmetatable(classInst, wrapperMeta);

		isolateFunction(cls.OnCreate)(classInst);
		Log(DONE);
	end
	if cls.OnInitialized then
		Log("%s.OnInitialized", meta.name);
		Log(delim);
		local classInst = {__fake = true, __time = "OnInitialized", __class = cls};
		wrapped[classInst] = cls;
		setmetatable(classInst, wrapperMeta);

		isolateFunction(cls.OnInitialized)(classInst);
		Log(DONE);
	end
	local wrappers = setmetatable({}, garbage_table_meta); -- Key: wrapped, Value: wrapper
	local wrapped = setmetatable({}, garbage_table_meta); -- Key: wrapper, Value: wrapped
	DETECTING_MIXINS = false;
end

local function arrayToHash(t)
	local new = {};
	for i = 1, #t do
		new[t[i]] = true;
	end
	return new;
end

-- Not global!
blacklist = arrayToHash {
	isolateFunction,
	Log,
	pcall,
	select,
	pairs,
	ipairs,
	math,
	tostring,
	tonumber,
	unpack,
	string,
	table,
	math,
	os,
	assert,
	error,
	next,
	xpcall,
	type,
	coroutine,
	InitMixinOverride,
	poison,
	getinfo,
	getupvalue,
	setupvalue,
	setmetatable,
	getmetatable,
	wrapTable,
	arrayToHash,
	wrappers,
	wrapped,
	preemptiveWrap,
	HPrint,
	Shared.Message,
}; -- Just to be sure that we can escape from the matrix
setmetatable(blacklist, garbage_table_meta);
blacklist[blacklist] = true; -- Not really needed, or is it?

oldInitMixin = isolateFunction(InitMixin);
global_active_overrides[InitMixin] = InitMixinOverride;

local function GetMixins(cls)
	local meta = getmetatable(cls);
	local t = meta.OnCreateMixins;
	for i = 1, #t do
		Log(t[i][1]);
	end
	t = meta.OnInitializedMixins;
	for i = 1, #t do
		Log(t[i][1]);
	end
end

Script.Load("lua/Table.lua")

local void = function() end
local log = Server and Log or void;

function CreateMixin(mixin)
    if mixin then
        for k in pairs(mixin) do
            mixin[k] = nil
        end
    else
        mixin = {};
    end
	return mixin;
end

function AddMixinNetworkVars(mixin, networkVars)
    if mixin.networkVars then
        for k, v in pairs(mixin.networkVars) do
            if networkVars[k] ~= nil then
                error("Variable " .. k .. " already exists in network vars while adding mixin " .. mixin.type)
            else
            	networkVars[k] = v;
			end
        end
    end
end

function InitMixin(self, mixin, optionalMixinData)

	if self.__constructing then
		local meta = getmetatable(self.__class);
		if not meta.mixintypes[mixin.type] then
			InitMixinForClass(self.__class, mixin, self);
		end
	else
		InitMixinForInstance(self, mixin);
	end
	if self.__is_ent then
		Shared.AddTagToEntity(self:GetId(), mixin.type);
	end

	self.__mixintypes[mixin.type] = true;

	if optionalMixinData then

		for i = 1, #mixin.__arguments do
			local k = mixin.__arguments[i];
			local v = optionalMixinData[k];
			if v ~= nil then
				self.__mixindata[k] = v;
			end
		end

	end

    if mixin.__initmixin then
        mixin.__initmixin(self)
    end

end

-- NB: You can only return __1__ value! I could implement multi-variable return though. Will do if someone wants it.
local function mergeFunctions(a, b)
	local ia = debug.getinfo(a);
	local ib = debug.getinfo(b);

	local args = "";
	if ia.isvararg or ib.isvararg then
		args = "..."
	else
		local arg_count = math.max(ia.nparams, ib.nparams);
		if arg_count > 0 then
			for i = 1, arg_count-1 do
				args = args .. "arg" .. i .. ",";
			end
			args = args .. "arg" .. arg_count;
		end
	end

	local str = ([[
		local a, b = ...;

		assert(type(a) == "function" and type(b) == "function");

		return function(%s)
			local ret = a(%s);
			b(%s);
			return ret;
		end
	]]):format(args, args, args);

	--[[
	local func = debug.getinfo(a);
	Log("a: %s", func.name or "nil");
	local func = debug.getinfo(b);
	Log("b: %s", func.name or "nil");
	Log(str);
	--]]

	return assert(loadstring(str))(a, b);
end

local sink = setmetatable({}, {__newindex = void});

 -- self is an instance of the class that was made prior to this.
 -- This way it can be updated.
function InitMixinForClass(cls, mixin, self)

	local meta = getmetatable(cls);

	if meta.mixintypes[mixin.type] then return end

	self = self or sink;

	-- Have to initialise it for subclasses first
	local subclasses = Script.GetDerivedClasses(meta.name or self.classname);
	for i = 1, #subclasses do
		InitMixinForClass(_G[subclasses[i]], mixin);
	end

	for k, v in pairs(mixin) do

		if type(v) == "function" and k ~= "__initmixin" then

			if not cls[k] then
				table.insert(meta.mixinbackup, k);
				self[k] = v;
				cls[k] = v;
				goto continue;
			end

			meta.mixinbackup[k] = cls[k];

			if mixin.overrideFunctions then
				for i = 1, #mixin.overrideFunctions do
					if mixin.overrideFunctions[i] == k then
						self[k] = v;
						cls[k] = v;
						goto continue;
					end
				end
			end

			local original = cls[k];
			local func = mergeFunctions(original, v);

			self[k] = func;
			cls[k] = func;

		end

		::continue::

	end

	if not mixin.__arguments then
		local args = {};
		mixin.__arguments = args;
		if mixin.defaultConstants then
			for k in pairs(mixin.defaultConstants) do
				table.insert(args, k);
			end
		end
		if mixin.expectedConstants then
			for k in pairs(mixin.expectedConstants) do
				table.insert(args, k);
			end
		end
		if mixin.optionalConstants then
			for k in pairs(mixin.optionalConstants) do
				table.insert(args, k);
			end
		end
	end

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			meta.mixindata[k] = v
		end
	end

	meta.mixintypes[mixin.type] = true;
end

function InitMixinForInstance(self, mixin)
	log("WARNING: InitMixinForInstance(%s (%s), %sMixin)", self, self.classname or self.GetClassName and self:GetClassName() or "[unknown class]", mixin.type);

	if not self.__mixintypes then
		log("WARNING: Improperly initialized!");
		self.__mixintypes = {};
		self.__mixindata = {};
		self.__constructing = false;
	elseif self.__mixintypes[mixin.type] then
		return;
	end

	for k, v in pairs(mixin) do

		if type(v) == "function" and k ~= "__initmixin" then

			if not self[k] then
				self[k] = v;
				goto continue;
			end

			if mixin.overrideFunctions then
				for i = 1, #mixin.overrideFunctions do
					if mixin.overrideFunctions[i] == k then
						self[k] = v;
						goto continue;
					end
				end
			end

			self[k] = mergeFunctions(self[k], v);

		end

		::continue::

	end

	if not mixin.__arguments then
		local args = {};
		mixin.__arguments = args;
		if mixin.defaultConstants then
			for k in pairs(mixin.defaultConstants) do
				table.insert(args, k);
			end
		end
		if mixin.expectedConstants then
			for k in pairs(mixin.expectedConstants) do
				table.insert(args, k);
			end
		end
		if mixin.optionalConstants then
			for k in pairs(mixin.optionalConstants) do
				table.insert(args, k);
			end
		end
	end

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			self.__mixindata[k] = v;
		end
	end
end

function HasMixin(inst, mixin_type)
	return inst and inst.__mixintypes and inst.__mixintypes[mixin_type] or false;
end

function ClassHasMixin(cls, mixin_type)
	return getmetatable(cls).mixintypes[mixin_type];
end

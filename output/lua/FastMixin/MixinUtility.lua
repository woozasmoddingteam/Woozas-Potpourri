Script.Load("lua/Table.lua")

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

	-- The most likely
	---[[
	if self.__constructing then
		local meta = getmetatable(self.__class);
		if not meta.mixintypes[mixin.type] then
			--Log("InitMixinForClass(%s, %sMixin, %s)", meta.name or self.classname or "No classname!", mixin.type, self);
			InitMixinForClass(self.__class, mixin, self);
		end
	else
		InitMixinForInstance(self, mixin);
	end
	--]]
	--InitMixinForInstance(self, mixin);
	if self.__is_ent then
		Shared.AddTagToEntity(self:GetId(), mixin.type);
	end

	self.__mixintypes[mixin.type] = true;

	if optionalMixinData then

		---[[
		for i = 1, #mixin.__arguments do
			local k = mixin.__arguments[i];
			local v = optionalMixinData[k];
			if v ~= nil then
				self.__mixindata[k] = v;
			end
		end
		--]]

		--[[
		for k, v in pairs(optionalMixinData) do
			if self.__mixindata[k] == nil then
				Log("InitMixin(%s, %sMixin, %s): mixindata[%s] wasn't properly set!", self, mixin.type, optionalMixinData, k);
				Log("mixin.__arguments: %s", mixin.__arguments);
				Log("mixin.optionalConstants: %s", mixin.optionalConstants or "nil");
				Log("mixin.defaultConstants: %s", mixin.defaultConstants or "nil");
				Log("mixin.expectedConstants: %s", mixin.expectedConstants or "nil");
			end
			self.__mixindata[k] = v;
		end
		--]]
	end

    if mixin.__initmixin then
        mixin.__initmixin(self)
    end

end

local void = function() end
local sink = setmetatable({}, {__newindex = void});

 -- self is an instance of the class that was made prior to this.
 -- This way it can be updated.
function InitMixinForClass(cls, mixin, self)

	local meta = getmetatable(cls);

	if meta.mixintypes[mixin.type] then return end

	self = self or sink;

	-- Have to initialise it for subclasses first
	-- if meta.name or self.classname then
		local subclasses = Script.GetDerivedClasses(meta.name or self.classname);
		for i = 1, #subclasses do
			InitMixinForClass(_G[subclasses[i]], mixin);
		end
	-- end

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
			local func = function(...)
				local ret = original(...); -- NB: You can only return **1** argument from your functions! This was UWE's decision and not mine.
				v(...);
				return ret;
			end

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
	if not self.__mixintypes then
		--Log("InitMixin(%s (%s), %sMixin, %s): Improperly initialized instance!", self, self.classname, mixin.type, optionalMixinData);
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

			local original = self[k];
			local func = function(...)
				local ret = original(...); -- NB: You can only return **1** from your functions! This was UWE's decision and not mine.
				v(...);
				return ret;
			end

			self[k] = func;

		end

		::continue::

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

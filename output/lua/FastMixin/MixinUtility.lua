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
        for varName, varType in pairs(mixin.networkVars) do
            if networkVars[varName] ~= nil then
                error("Variable " .. varName .. " already exists in network vars while adding mixin " .. mixin.type)
            end
            networkVars[varName] = varType
        end
    end
end

local function GetMixinConstants(self)
	return self.__mixindata
end

local function GetMixinConstant(self, constantName)
	return self.__mixindata[constantName]
end

function InitMixinForClass(cls, mixin)

	for k, v in pairs(mixin) do

		if type(v) == "function" and k ~= "__initmixin" then

			if not cls[k] then
				cls[k] = v;
				goto continue;
			end

			for i = 1, #mixin.overrideFunctions do
				if mixin.overrideFunctions[i] == k then
					cls[k] = v;
					goto continue;
				end
			end

			local original = cls[k];
			cls[k] = function(...)
				v(...);
				return original(...);
			end

		end

		::continue::

	end

	if cls.__mixins then
		cls.__mixins = mixins;
		cls.__mixintypes = {};
		cls.__mixindata = mixin.defaultConstants or {};
		cls.GetMixinConstants = GetMixinConstants;
		cls.GetMixinConstant = GetMixinConstant;
	else
		assert(not cls.__mixintypes[mixin.type], "Tried to load two conflicting mixins with the same type name!");
	end

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			cls.__mixindata[k] = v
		end
	end

	table.insert(inst.__mixins, mixin);
	init.__mixintypes[mixin.type] = true;
end

function InitMixin(inst, mixin, optionalMixinData)
    if not HasMixin(inst, mixin) then

        PROFILE("InitMixin")

        if inst:isa("Entity") then
            Shared.AddTagToEntity(inst:GetId(), mixin.type)
        end

        for k, v in pairs(mixin) do

            if type(v) == "function" and k ~= "__initmixin" then

				if not inst[k] then
					inst[k] = v;
					goto continue;
				end

				if mixin.overrideFunctions then
					for i = 1, #mixin.overrideFunctions do
						if mixin.overrideFunctions[i] == k then
							inst[k] = v;
							goto continue;
						end
					end
				end

				local original = inst[k];
				inst[k] = function(...)
					v(...);
					return original(...);
				end

            end

			::continue::

        end

		if not inst.__mixins then
			inst.__mixins = {};
			inst.__mixintypes = {};
			inst.__mixindata = mixin.defaultConstants or {};
			inst.GetMixinConstants = GetMixinConstants;
			inst.GetMixinConstant = GetMixinConstant;
		else
        	assert(not inst.__mixintypes[mixin.type], "Tried to load two conflicting mixins with the same type name!");
		end

		if mixin.defaultConstants then
			for k, v in pairs(mixin.defaultConstants) do
				inst.__mixindata[k] = v
			end
		end

        table.insert(inst.__mixins, mixin);
		inst.__mixintypes[mixin.type] = true;

		if optionalMixinData then

			for k, v in pairs(optionalMixinData) do
				inst.__mixindata[k] = v
			end

		end

    end

    if mixin.__initmixin then
        mixin.__initmixin(inst)
    end

end

function HasMixin(inst, mixin_type)
	if not inst then
		return;
	end
	return --[[inst.classmeta.__mixintypes[mixin_type] or]] inst.__mixintypes and inst.__mixintypes[mixin_type] or false
end

function ClassHasMixin(cls, mixin_type)
	return getmetatable(cls).__mixintypes[mixin_type] or false;
end

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
	return self.mixindata
end

local function GetMixinConstant(self, constantName)
	return self.mixindata[constantName]
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

	if cls.mixins then
		cls.mixins = mixins;
		cls.mixin_types = {};
		cls.mixindata = mixin.defaultConstants or {};
		cls.GetMixinConstants = GetMixinConstants;
		cls.GetMixinConstant = GetMixinConstant;
	else
		assert(not cls.mixin_types[mixin.type], "Tried to load two conflicting mixins with the same type name!");
	end

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			cls.mixindata[k] = v
		end
	end

	table.insert(inst.mixins, mixin);
	init.mixin_types[mixin.type] = true;
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

				for i = 1, #mixin.overrideFunctions do
					if mixin.overrideFunctions[i] == k then
						inst[k] = v;
						goto continue;
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

		local meta = getmetatable(inst);

		if not meta.mixins then
			meta.mixins = {};
			meta.mixin_types = {};
			meta.mixindata = mixin.defaultConstants or {};
			inst.GetMixinConstants = GetMixinConstants;
			inst.GetMixinConstant = GetMixinConstant;
		else
        	assert(not meta.mixin_types[mixin.type], "Tried to load two conflicting mixins with the same type name!");
		end

		if mixin.defaultConstants then
			for k, v in pairs(mixin.defaultConstants) do
				meta.mixindata[k] = v
			end
		end

        table.insert(meta.mixins, mixin);
		init.mixin_types[mixin.type] = true;

    end

	if optionalMixinData then

		for k, v in pairs(optionalMixinData) do
			inst.mixindata[k] = v
		end

	end

    if mixin.__initmixin then
        mixin.__initmixin(inst)
    end

end

function HasMixin(inst, mixin_type)
	local meta = getmetatable(inst);
	return meta.classmeta.mixin_types[mixin_type] or meta.mixin_types[mixin_type] or false
end

function ClassHasMixin(cls, mixin_type)
	return getmetatable(cls).mixin_types[mixin_type] or false;
end

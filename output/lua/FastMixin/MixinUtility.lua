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

function InitMixinForClass(cls, mixin)

	Log("INLINING %sMixin FOR CLASS %s!", mixin.type, getmetatable(cls).name);

	for k, v in pairs(mixin) do

		if type(v) == "function" and k ~= "__initmixin" then

			if not cls[k] then
				cls[k] = v;
				goto continue;
			end

			if mixin.overrideFunctions then
				for i = 1, #mixin.overrideFunctions do
					if mixin.overrideFunctions[i] == k then
						cls[k] = v;
						goto continue;
					end
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

	assert(not cls.__class_mixintypes[mixin.type], "Tried to load two conflicting mixins with the same type name!");

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			cls.__class_mixindata[k] = v
		end
	end

	cls.__class_mixintypes[mixin.type] = true;
end

local function internalInitMixin(inst, mixin, optionalMixinData)
	if inst.__isent then
		Shared.AddTagToEntity(inst:GetId(), mixin.type);
	elseif inst:isa("Entity") then
		inst.__isent = true;
		Shared.AddTagToEntity(inst:GetId(), mixin.type);
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

	if mixin.defaultConstants then
		for k, v in pairs(mixin.defaultConstants) do
			inst.__mixindata[k] = v
		end
	end

	inst.__mixintypes[mixin.type] = true;
end


function InitMixinMixinDetector(inst, mixin, optionalMixinData)
    PROFILE("InitMixinMixinDetector");

	if not inst.__mixintypes[mixin.type] then

		internalInitMixin(inst, mixin, optionalMixinData);

	    table.insert(inst.__mixins, mixin);

	end

	if optionalMixinData then

		for k, v in pairs(optionalMixinData) do
			inst.__mixindata[k] = v
		end

	end

    if mixin.__initmixin then
        mixin.__initmixin(inst)
    end

end

function InitMixin(inst, mixin, optionalMixinData)
    PROFILE("InitMixin");

	if not inst.__mixintypes or not inst.__mixintypes[mixin.type] then

		internalInitMixin(inst, mixin, optionalMixinData);

	end

	if optionalMixinData then

		for k, v in pairs(optionalMixinData) do
			inst.__mixindata[k] = v
		end

	end

    if mixin.__initmixin then
        mixin.__initmixin(inst)
    end

end


-- For OnInitialized
function HasMixinMixinDetector(inst, mixin_type)
	if mixin_type == "MapBlip" then -- This piece of code makes very heavy assumptions!
		table.insert(inst.__mixins, MapBlipMixin);
	end
	return inst and inst.__mixintypes and inst.__mixintypes[mixin_type] or false
end

function HasMixin(inst, mixin_type)
	return inst and inst.__mixintypes and inst.__mixintypes[mixin_type] or false;
end

function ClassHasMixin(cls, mixin_type) -- Also works with instances of the classes actually
	return cls.__class_mixintypes[mixin_type] or false;
end

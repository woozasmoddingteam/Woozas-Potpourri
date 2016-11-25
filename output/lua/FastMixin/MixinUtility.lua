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

function InitMixin(inst, mixin, optionalMixinData)
    PROFILE("InitMixin");

	if type(inst.__mixintypes) ~= "table" then
		Log("InitMixin: Improperly initialized %s of class %s with at mixin %sMixin!", tostring(inst), inst.classname, mixin.type);
		Log(debug.traceback());
		inst.__mixintypes = {};
		inst.__mixindata = {};
		goto mixin;
	end

	if inst.__mixintypes[mixin.type] then
		goto init;
	end

	::mixin::
	do

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

	::init::

	if optionalMixinData then

		for k, v in pairs(optionalMixinData) do
			inst.__mixindata[k] = v
		end

	end

    if mixin.__initmixin then
        mixin.__initmixin(inst)
    end

end

function HasMixin(inst, mixin_type)
	return inst and inst.__mixintypes and inst.__mixintypes[mixin_type] or false;
end

function ClassHasMixin(cls, mixin_type) -- Also works with instances of the classes actually
	return cls.__class_mixintypes[mixin_type] or false;
end

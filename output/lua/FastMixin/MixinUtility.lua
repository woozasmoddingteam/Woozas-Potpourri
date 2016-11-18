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

function AddMixinNetworkVars(theMixin, networkVars)
    if theMixin.networkVars then
        for varName, varType in pairs(theMixin.networkVars) do
            if networkVars[varName] ~= nil then
                error("Variable " .. varName .. " already exists in network vars while adding mixin " .. theMixin.type)
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


function InitMixin(classInstance, theMixin, optionalMixinData)
    if not HasMixin(classInstance, theMixin) then

        PROFILE("InitMixin")

        if classInstance:isa("Entity") then
            Shared.AddTagToEntity(classInstance:GetId(), theMixin.type)
        end

        for k, v in pairs(theMixin) do

            if type(v) == "function" and k ~= "__initmixin" then

				if not classInstance[k] then
					classInstance[k] = v;
					goto continue;
				end

				for i = 1, #theMixin.overrideFunctions do
					if theMixin.overrideFunctions[i] == k then
						classInstance[k] = v;
						goto continue;
					end
				end

				local original = classInstance[k];
				classInstance[k] = function(...)
					v(...);
					return original(...);
				end

            end

			::continue::

        end

		local mixinlist = classInstance.instance_mixins;
		if not mixinlist then
			mixinlist = {};
			classInstance.instance_mixins = mixinlist;
			classInstance.mixindata = theMixin.defaultConstants or {};
			classInstance.GetMixinConstants = GetMixinConstants;
			classInstance.GetMixinConstant = GetMixinConstant;
		else
        	assert(not mixinlist[theMixin.type], "Tried to load two conflicting mixins with the same type name!");
			if theMixin.defaultConstants then
	            for k, v in pairs(theMixin.defaultConstants) do
	                classInstance.mixindata[k] = v
	            end
	        end
		end

        mixinlist[theMixin.type] = true

        if optionalMixinData then

            for k, v in pairs(optionalMixinData) do
                classInstance.mixindata[k] = v
            end

        end

    end

    if theMixin.__initmixin then
        theMixin.__initmixin(classInstance)
    end

end

function HasMixin(classInstance, mixinTypeName)
    local mixinlist = classInstance.instance_mixins
	return (mixinlist and mixinlist[mixinTypeName]) or false
end

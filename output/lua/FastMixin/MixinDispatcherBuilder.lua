
local callAllFunctionsDef = [[

    local classInstance, allFunctionsTable = ...

    return function(ignoreSelf %s)

            local %s = allFunctionsTable[1](classInstance %s)

            local count = #allFunctionsTable

            for i = 2, count do

                if(ret1 == nil) then
                    %s = allFunctionsTable[i](classInstance %s)
                else
                    allFunctionsTable[i](classInstance %s)
                end
            end

            return %s
    end
]]

local callAllFunctionsDefNoReturn = [[

    local classInstance, allFunctionsTable = ...

    return function(ignoreSelf %s)

            allFunctionsTable[1](classInstance %s)

            local count = #allFunctionsTable

            for i = 2, count do
                allFunctionsTable[i](classInstance %s)
            end
    end
]]

local calfmt = "f%i(classInstance, %s)\n"

local ArgStrings = setmetatable({[0] = "self"}, {

    __index = function(self, argCount)
        --we add comma here to allow 0 arg version to just be an empty string
        local argString = "self, "

        --argCount = argCount-1

        for i = 1, argCount do
            if(i ~= argCount) then
                argString = argString..string.format("arg%i, ", i)
            else
                argString = argString..string.format("arg%i", i)
            end
        end

        rawset(self, argCount, argString)

     return argString
    end
})


function CreateListStringBuilder(formatString, lastFormatString, startString)

    return setmetatable({[0] = ""}, {

        __index = function(self, count)
            local retString = startString or ""

            for i = 1, count do
                if(i ~= count) then
                    retString = retString..string.format(formatString, i)
                else
                    retString = retString..string.format(lastFormatString, i)
                end
            end

            rawset(self, count, retString)

            return retString
        end
    })
end

local ReturnStrings = CreateListStringBuilder("ret%i, ", "ret%i")
ReturnStrings[0] = "dummyRet"
local FuncStrings = CreateListStringBuilder("f%i, ", "f%i")

function makeCallList(count, argsString)

    local list = {}

    for i = 2, count do
        list[i-1] = string.format("f%i(%s)\n", i, argsString)
    end

    return table.concat(list, "")
end

function CreateMixinDispatcher(classInstance, allFunctionsTable, classFunction, functionName)

    return function(...)
        return UpdateMixinDispatcher(functionName, allFunctionsTable, ...)
    end
end

local callAll = [[

    local allFunctionsTable = ...
    local count = #allFunctionsTable
    local %s = unpack(allFunctionsTable)
    local functionName = select(2, ...)

    return function(%s)
            //handle fun stuff like the number mixin functions for SetOrigin changing after its been called
            if(allFunctionsTable[count] == nil or allFunctionsTable[count+1] ~= nil) then
                //UpdateMixinDispatcher will call the new Dispatcher for us and return it result
                local %s = UpdateMixinDispatcher(functionName, allFunctionsTable, %s)
                return %s
            end

            local %s = f1(%s)

            %s
            return %s
    end
]]

local CreateFunctions = {
}

local ArgCounts = {}
local NameCreatedCount = {}

local jit_util = require("jit.util")

local Dispatchers = {}

local function DeferedMakeFunction(chunkName, argCount, returnCount, funcCount)

    local argString = ArgStrings[argCount]
    local returnVars = ReturnStrings[returnCount]
    local funcNameList = FuncStrings[funcCount]

    local retArgs = (returnCount ~= 0 and returnVars) or ""

    local funcBody = string.format(callAll,
                                   funcNameList,
                                   argString,
                                   returnVars, argString,
                                   retArgs,
                                   returnVars, argString,
                                   makeCallList(funcCount, argString),
                                   retArgs)

    return loadstring(funcBody, chunkName)
end

local FunctionInfo = {
    SetOrigin = {1, 0},
    SetAngles = {1, 0},
    SetCoords = {1, 0},
    OnUpdate = {1, 0},
    OnInitialized = {0, 0},
    OnDestroy = {0, 0},
    OnSynchronized = {0, 0},
    OnProcessMove = {1, 0},
    OnUpdatePhysics = {0, 0},
    OnUpdateRender = {0, 0},
    OnInvalidOrigin = {0, 0},
    SetAttachPoint = {1, 0},
    OnEntityChange = {2, 0},

    SetIncludeRelevancyMask = {1, 0},
    SetExcludeRelevancyMask = {1, 0},
}

local argCounts = {}

local function GetMixinInfo(functionName, functionList, classInstance)

    local info = FunctionInfo[functionName]

    local className = (classInstance.GetClassName and classInstance:GetClassName()) or "Mixin"

    --use predefined arg count and return count if one is set for this funcion name
    if(info) then
        return info[1], info[2]
    end

    local maxCount = 0

    for i, func in pairs(functionList) do

        local count = argCounts[func]

        --Check if we have the cached argument count for this function already
        if(not count) then

            local info = jit_util.funcinfo(func)

            count = info.params or 0
            argCounts[func] = count
        end

        maxCount = math.max(maxCount, count)
    end

    local classArgCount = argCounts[functionList[1]]

    if(classArgCount ~= maxCount) then
      --Print("Mixin Param mismatch %s:%s %i %i", className, functionName, classArgCount, maxCount);
    end

    return maxCount, 1

end

function UpdateMixinDispatcher(functionName, allFunctionsTable, self, ...)

    local count = #allFunctionsTable
    local className

    if(self.GetClassName) then
        className = (self.GetClassName and self:GetClassName())
    else
        className = debug.getmetatable(self).__towatch(self)
    end

    local funcName = className.."_"..functionName..count

    if(not Dispatchers[funcName]) then

        local argCount, retCount = GetMixinInfo(functionName, allFunctionsTable, self)

        local func = DeferedMakeFunction(funcName, argCount, retCount, count)

        Dispatchers[funcName] = func(allFunctionsTable, functionName)
    end

    self[functionName] = Dispatchers[funcName]

    return Dispatchers[funcName](self, ...)
end

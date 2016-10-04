--[[
 	ShoulderPatchesExtra
	ZycaR (c) 2016
]]

Script.Load("lua/ConfigFileUtility.lua")
Script.Load("lua/spe_shoulderPatchesEnum.lua")

kDefaultGroupName = "DefaultGroup"

ShoulderPatchesConfig = {}
ShoulderPatchesConfig.ConfigFileName = "ShoulderPatchesConfig.json"
ShoulderPatchesConfig.EmptyPatchName = kEmptyPatchName
ShoulderPatchesConfig.PatchNames = kShoulderPatchNames

function ShoulderPatchesConfig:GetPatchIndexByName(value)
    if value ~= self.EmptyPatchName then
        for index, name in pairs(self.PatchNames) do
            if name == value then return index end
        end
    end
    return kEmptyPatchIndex
end

if Server then

    local kDefaultConfig = {
        PatchGroups = {
            [kDefaultGroupName] = { Empty = true },
            Approved            = { Patch = "Approved" },
            SuperAdmin          = { Patches = {"Lerk", "Dilligaf"} },
            zycar               = { Patch = "ZycaR" },
            nalice              = { Patch = "Nalice" }
        },
        PatchUsers = {
            ["90000000000001"] = {
                Group = Approved,
                Patches = {}
            }
        }
    }

    ShoulderPatchesConfig._config = LoadConfigFile(
        ShoulderPatchesConfig.ConfigFileName,
        kDefaultConfig)

-- Shine config
    local function GetShineUserPatches(client)
        if Shine and Shine.GetUserData then
            local data = Shine:GetUserData(client) or {}
            return data and (data.Patches or { data.Patch })
        end
    end

    local function GetShineGroupName(client)
        if Shine and Shine.GetUserData then
            local data = Shine:GetUserData(client) or {}
            return data and data.Group
        end
    end
    
    local function GetShineGroupPatches(name)
        if Shine and Shine.GetGroupData then
            local data = Shine:GetGroupData(name) or {}
            return data and (data.Patches or { data.Patch })
        end
    end
    
    local function GetShineDefaultGroupPatches(name)
        if Shine and Shine.GetDefaultGroup then
            local data = Shine:GetDefaultGroup() or {}
            return data and (data.Patches or { data.Patch })
        end
    end    
    
    local function GetShinePatches(client)
        if not Shine then return nil end
        
        local patches = {}
        local group = GetShineGroupName(client)
        table.addtable( GetShineUserPatches(client), patches )
        table.addtable( GetShineGroupPatches(group), patches )
        table.addtable( GetShineDefaultGroupPatches(group), patches )

        return patches
    end
-- (end) Shine config

    local function GetShoulderPatches(config, steamId)
        local patches = {}
        
        if not config then
            Shared.Message("Missing or invalid ShoulderPatchesConfig.json file.")
            return {}
        end

        local userData = config.PatchUsers[steamId]
        if userData then
            local groupName = userData.Group or kDefaultGroupName
            local groupData = config.PatchGroups[groupName] or {}
            table.addtable( (userData.Patches or { userData.Patch }), patches )
            table.addtable( (groupData.Patches or { groupData.Patch }), patches )
        end

        local default = config.PatchGroups[kDefaultGroupName] or {}
        table.addtable( (default.Patches or { default.Patch }), patches )
        return patches
    end

    function ShoulderPatchesConfig:GetShoulderPatchIndexes(names)
        local result = { }
        for _, name in ipairs(names) do
            local index = self:GetPatchIndexByName(name)
            if index and index ~= kEmptyPatchIndex then
                table.insertunique(result, index)
            end
        end
        return result
    end

    function ShoulderPatchesConfig:GetShoulderPatches(client)
        local steamId = tostring(client:GetUserId())
    	local names = GetShinePatches(client) or GetShoulderPatches(self._config, steamId)
        local indexes = self:GetShoulderPatchIndexes(names)
    	local result = table.concat(indexes, ",")
        return result
    end

end

if Client then
    local function GetShoulderPatchIndexes(player)
        if player and HasMixin(player, "ShoulderPatches") then
            return StringSplit(player.spePatches or "", ",")
        end
        return { }
    end

    function ShoulderPatchesConfig:GetClientShoulderPatchNames(player)
        local result = { }
        table.insert(result, self.EmptyPatchName)
        for _, index in ipairs(GetShoulderPatchIndexes(player)) do
            local name = self.PatchNames[ tonumber(index) ]
            if name then table.insertunique(result, name) end
        end
        return result
    end

    function ShoulderPatchesConfig:GetClientShoulderPatch(player)
        local index = Client.GetOptionInteger("spe", kEmptyPatchIndex)
        
        if not self.PatchNames[ index ] then
            Client.SetOptionInteger("spe", kEmptyPatchIndex)
            index = kEmptyPatchIndex
        elseif not table.contains(GetShoulderPatchIndexes(player), tostring(index)) then
            index = kEmptyPatchIndex
        end
        return self.PatchNames[ index ] or self.EmptyPatchName, index
    end

    function ShoulderPatchesConfig:SetClientShoulderPatch(name)
        local index = self:GetPatchIndexByName(name)
        Client.SetOptionInteger("spe", index)
        --Shared.Message("SetClientShoulderPatch: ".. tostring(index))
        return index
    end

end

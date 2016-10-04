--[[
 	ShoulderPatchesExtra
	ZycaR (c) 2016
]]
Script.Load("lua/spe_ShoulderPatchesConfig.lua")
Script.Load("lua/spe_ShoulderPatchesMessage.lua")

ShoulderPatchesMixin = CreateMixin( ShoulderPatchesMixin )
ShoulderPatchesMixin.type = "ShoulderPatches"

ShoulderPatchesMixin.kShaderName = "models/marine/patches/ShoulderPatchesExtra.surface_shader"
ShoulderPatchesMixin.kPatchMaps = {
    "models/marine/patches/ShoulderPatchesExtra.dds"
}

ShoulderPatchesMixin.networkVars =
{
    spePatchIndex = "integer (0 to 1024)",
    spePatchEffect = "integer (0 to 1)",
    spePatches = "string (256)",
    speOptionsSent = "boolean"
}

ShoulderPatchesMixin.expectedMixins =
{
	Model = "Needed for setting material parameters"
}

ShoulderPatchesMixin.expectedCallbacks = {}
ShoulderPatchesMixin.optionalCallbacks = {}

function ShoulderPatchesMixin:__initmixin()
    self.spePatchIndex = 0
    self.spePatchEffect = 0
    self.spePatches = nil
    self.speOptionsSent = false
end

-- (start) Debug info
local function __LogClientData(client)
    local steamId = tostring(client:GetUserId())
    Shared.Message(".. SPE SteamID: ".. steamId)
    local player = client:GetControllingPlayer()
    if player then 
        Shared.Message(".. .. spePatches: [" .. player.spePatches .. "]")
        Shared.Message(".. .. spePatchIndex: [" .. tostring(player.spePatchIndex) .. "]")
        Shared.Message(".. .. speOptionsSent: [" .. tostring(player.speOptionsSent) .. "]")
    else
        Shared.Message(".. .. speData: [n/a]")
    end
end
local function OnCommandInfo(client)
    if client and not client:GetIsVirtual() then
        __LogClientData(client)
    end
end
Event.Hook( "Console_spe_info", OnCommandInfo )
-- (end) Debug info

if Server then

    local function OnClientConnect(client)
        if client and not client:GetIsVirtual() then
            local player = client:GetControllingPlayer()
            local patches = ShoulderPatchesConfig:GetShoulderPatches(client)
            if player and patches then
                player.spePatchIndex = 0
                player.spePatchEffect = 0
                player.spePatches = patches
                player.speOptionsSent = false
            end
        end
    end
    Event.Hook("ClientConnect", OnClientConnect)

    function ShoulderPatchesMixin:SetShoulderPatchIndex(value)
        self.speOptionsSent = true
        self.spePatchIndex = value
    end
    
    function ShoulderPatchesMixin:SetShoulderPatchEffect(value)
        self.spePatchEffect = value
    end

end

if Client then

    -- precache shader and textures
    Shared.PrecacheSurfaceShader(ShoulderPatchesMixin.kShaderName)
    for _, texture in ipairs(ShoulderPatchesMixin.kPatchMaps) do
        PrecacheAsset(texture)
    end
    
    function ShoulderPatchesMixin:GetValidShoulderPatchIndex()
        if not self.speOptionsSent and not self._speInternalSent
           and self.spePatches and self.spePatches ~= ""
        then
            self._speInternalSent = true -- prevent sending spam after client connects
            local name, index = ShoulderPatchesConfig:GetClientShoulderPatch(self)
            if self.spePatchIndex ~= index then -- prevent sending same value (like zeroes)
                SendShoulderPatchUpdate(index)
            end
        end
        return self.spePatchIndex
    end
    
    function ShoulderPatchesMixin:OnUpdateRender()
        local model = self:GetRenderModel()
        if model ~= nil then
            model:SetMaterialParameter("spePatchIndex", self:GetValidShoulderPatchIndex())
            model:SetMaterialParameter("spePatchEffect", self.spePatchEffect or 0)
        end
    end
    
end -- Client


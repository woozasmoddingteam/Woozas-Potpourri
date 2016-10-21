-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/AchievementGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
--Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")
Script.Load("lua/IdleMixin.lua")
Script.Load("lua/ParasiteMixin.lua")

class 'WoozArmory' (ScriptActor)

WoozArmory.kMapName = "woozarmory"

WoozArmory.kModelName = PrecacheAsset("models/marine/armory/armory.model")
local kAnimationGraph = PrecacheAsset("models/marine/armory/armory.animation_graph")

-- Looping sound while using the armory
WoozArmory.kResupplySound = PrecacheAsset("sound/NS2.fev/marine/structures/armory_resupply")

WoozArmory.kArmoryBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
WoozArmory.kAttachPoint = "Root"

WoozArmory.kBuyMenuFlash = "ui/marine_buy.swf"
WoozArmory.kBuyMenuTexture = "ui/marine_buymenu.dds"
WoozArmory.kBuyMenuUpgradesTexture = "ui/marine_buymenu_upgrades.dds"
local kLoginAndResupplyTime = 0.3
WoozArmory.kHealAmount = 25
WoozArmory.kResupplyInterval = .8
gArmoryHealthHeight = 1.4
-- Players can use menu and be supplied by armor inside this range
WoozArmory.kResupplyUseRange = 2.5

if Server then
    Script.Load("lua/anniversary/Armory_Server.lua")
elseif Client then
    Script.Load("lua/anniversary/Armory_Client.lua")
end

PrecacheAsset("models/marine/armory/health_indicator.surface_shader")

local networkVars =
{
    -- How far out the arms are for animation (0-1)
    loggedInEast     = "boolean",
    loggedInNorth    = "boolean",
    loggedInSouth    = "boolean",
    loggedInWest     = "boolean",
    deployed         = "boolean"
}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(FlinchMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(LOSMixin, networkVars)
AddMixinNetworkVars(CorrodeMixin, networkVars)
AddMixinNetworkVars(ConstructMixin, networkVars)
AddMixinNetworkVars(ResearchMixin, networkVars)
AddMixinNetworkVars(RecycleMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)

AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

function WoozArmory:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, PowerConsumerMixin)
    InitMixin(self, ParasiteMixin)

    if Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

    -- False if the player that's logged into a side is only nearby, true if
    -- the pressed their key to open the menu to buy something. A player
    -- must use the armory once "logged in" to be able to buy anything.
    self.loginEastAmount = 0
    self.loginNorthAmount = 0
    self.loginWestAmount = 0
    self.loginSouthAmount = 0

    self.timeScannedEast = 0
    self.timeScannedNorth = 0
    self.timeScannedWest = 0
    self.timeScannedSouth = 0

    --self.deployed = true;

	--self.startsBuilt = true;
end

-- Check if friendly players are nearby and facing armory and heal/resupply them
local function LoginAndResupply(self)

    self:UpdateLoggedIn()

    -- Make sure players are still close enough, alive, marines, etc.
    -- Give health and ammo to nearby players.
    if GetIsUnitActive(self) then
        self:ResupplyPlayers()
    end

    return true

end

function WoozArmory:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(WoozArmory.kModelName, kAnimationGraph)

    InitMixin(self, WeldableMixin)
    InitMixin(self, NanoShieldMixin)

    if Server then

        self.loggedInArray = { false, false, false, false }

        -- Use entityId as index, store time last resupplied
        self.resuppliedPlayers = { }

        self:AddTimedCallback(LoginAndResupply, kLoginAndResupplyTime)

        -- This Mixin must be inited inside this OnInitialized() function.
        --if not HasMixin(self, "MapBlip") then
        --    InitMixin(self, MapBlipMixin)
        --end

        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)
        InitMixin(self, SupplyUserMixin)

    elseif Client then

        self:OnInitClient()
        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)

    end

    InitMixin(self, IdleMixin)

	self:SetConstructionComplete();

end

function WoozArmory:GetCanBeUsed(player, useSuccessTable)

    if player:isa("Exo") then
        useSuccessTable.useSuccess = false
    end

end

function WoozArmory:GetCanBeUsedConstructed(byPlayer)
    return not byPlayer:isa("Exo")
end

function WoozArmory:GetRequiresPower()
    return true
end

function WoozArmory:GetTechIfResearched(buildId, researchId)

    local techTree = nil
    if Server then
        techTree = self:GetTeam():GetTechTree()
    else
        techTree = GetTechTree()
    end
    ASSERT(techTree ~= nil)

    -- If we don't have the research, return it, otherwise return buildId
    local researchNode = techTree:GetTechNode(researchId)
    ASSERT(researchNode ~= nil)
    ASSERT(researchNode:GetIsResearch())
    return ConditionalValue(researchNode:GetResearched(), buildId, researchId)

end

function WoozArmory:GetTechButtons(techId)
    return {}
end

function WoozArmory:GetTechAllowed(techId, techNode, player)
	return true, true
end

function WoozArmory:OnUpdatePoseParameters()

    if GetIsUnitActive(self) and self.deployed then

        if self.loginNorthAmount then
            self:SetPoseParam("log_n", self.loginNorthAmount)
        end

        if self.loginSouthAmount then
            self:SetPoseParam("log_s", self.loginSouthAmount)
        end

        if self.loginEastAmount then
            self:SetPoseParam("log_e", self.loginEastAmount)
        end

        if self.loginWestAmount then
            self:SetPoseParam("log_w", self.loginWestAmount)
        end

        if self.scannedParamValue then

            for extension, value in pairs(self.scannedParamValue) do
                self:SetPoseParam("scan_" .. extension, value)
            end

        end

    end

end

local function UpdateArmoryAnim(self, extension, loggedIn, scanTime, timePassed)

    local loggedInName = "log_" .. extension
    local loggedInParamValue = ConditionalValue(loggedIn, 1, 0)

    if extension == "n" then
        self.loginNorthAmount = Clamp(Slerp(self.loginNorthAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "s" then
        self.loginSouthAmount = Clamp(Slerp(self.loginSouthAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "e" then
        self.loginEastAmount = Clamp(Slerp(self.loginEastAmount, loggedInParamValue, timePassed * 2), 0, 1)
    elseif extension == "w" then
        self.loginWestAmount = Clamp(Slerp(self.loginWestAmount, loggedInParamValue, timePassed * 2), 0, 1)
    end

    local scannedName = "scan_" .. extension
    self.scannedParamValue = self.scannedParamValue or { }
    self.scannedParamValue[extension] = ConditionalValue(scanTime == 0 or (Shared.GetTime() > scanTime + 3), 0, 1)

end

function WoozArmory:OnUpdate(deltaTime)

    if Client then
        self:UpdateArmoryWarmUp()
    end

    if GetIsUnitActive(self) and self.deployed then

        -- Set pose parameters according to if we're logged in or not
        UpdateArmoryAnim(self, "e", self.loggedInEast, self.timeScannedEast, deltaTime)
        UpdateArmoryAnim(self, "n", self.loggedInNorth, self.timeScannedNorth, deltaTime)
        UpdateArmoryAnim(self, "w", self.loggedInWest, self.timeScannedWest, deltaTime)
        UpdateArmoryAnim(self, "s", self.loggedInSouth, self.timeScannedSouth, deltaTime)

    end

    ScriptActor.OnUpdate(self, deltaTime)

end

function WoozArmory:GetReceivesStructuralDamage()
    return true
end

function WoozArmory:GetDamagedAlertId()
    return kTechId.MarineAlertStructureUnderAttack
end

function WoozArmory:GetItemList(forPlayer)

    local itemList = {
        kTechId.Welder,
        kTechId.LayMines,
        kTechId.Shotgun,
        kTechId.ClusterGrenade,
        kTechId.GasGrenade,
        kTechId.PulseGrenade
    }

    return itemList

end

function WoozArmory:GetHealthbarOffset()
    return gArmoryHealthHeight
end

if Server then
    --[[ not used anymore since all animation are now client side
    function WoozArmory:OnTag(tagName)
        if tagName == "deploy_end" then
            self.deployed = true
        end
    end
    --]]

end

Shared.RegisterNetworkMessage("WoozArmoryFound");

if Server then
	Server.HookNetworkMessage("WoozArmoryFound", function(client)
		local player = client:GetControllingPlayer();
		local id = GetSteamIdForClientIndex(player:GetClientIndex());
		Shared.Message(player.name .. " (steam id: " .. id .. ") won!");
	end);

	Event.Hook("Console_plantarmory", function(client)
		local ent = CreateEntity("woozarmory", client:GetControllingPlayer():GetOrigin());
		assert(ent);
	end);
end

Shared.LinkClassToMap("WoozArmory", WoozArmory.kMapName, networkVars)

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
Script.Load("lua/CommanderGlowMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/PowerConsumerMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")
Script.Load("lua/IdleMixin.lua")

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
AddMixinNetworkVars(SelectableMixin, networkVars)

AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(PowerConsumerMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

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
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)
    InitMixin(self, PowerConsumerMixin)

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
end

function WoozArmory:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(WoozArmory.kModelName, kAnimationGraph)

    if Server then

        self.loggedInArray = { false, false, false, false }

        -- Use entityId as index, store time last resupplied
        self.resuppliedPlayers = { }

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

	self:SetPoseParam("log_n", 0);
	self:SetPoseParam("log_e", 0);
	self:SetPoseParam("log_w", 0);
	self:SetPoseParam("log_s", 0);

	self:SetPoseParam("scan_n", 0);
	self:SetPoseParam("scan_e", 0);
	self:SetPoseParam("scan_w", 0);
	self:SetPoseParam("scan_s", 0);
end

function WoozArmory:GetCanBeUsed(player, useSuccessTable) end
function WoozArmory:GetCanBeUsedConstructed(byPlayer)
    return true;
end

function WoozArmory:GetRequiresPower()
    return true;
end

Shared.RegisterNetworkMessage("WoozArmoryFound");

if Server then
	function WoozArmory:OnConstructionComplete()
		self.deployed = true;
	end

	Server.HookNetworkMessage("WoozArmoryFound", function(client)
		local player = client:GetControllingPlayer();
		local id = GetSteamIdForClientIndex(player:GetClientIndex());
		Shared.Message(player.name .. " (steam id: " .. id .. ") won!");
	end);

	Event.Hook("Console_plantarmory", function(client)
		local ent = CreateEntity("woozarmory", client:GetControllingPlayer():GetOrigin());
		assert(ent);
	end);

elseif Client then
	function WoozArmory:OnInitClient()

	    if not self.clientConstructionComplete then
	        self.clientConstructionComplete = self.constructionComplete
	    end


	end

	function WoozArmory:OnUse(player)
		if Client.GetLocalPlayer() ~= player then
			return
		end

		Client.SendNetworkMessage("WoozArmoryFound", {});
	end
end

Shared.LinkClassToMap("WoozArmory", WoozArmory.kMapName, networkVars)

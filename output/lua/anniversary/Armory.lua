-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
--Script.Load("lua/ConstructMixin.lua")

Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/IdleMixin.lua")

class 'WoozArmory' (ScriptActor)

WoozArmory.kMapName = "woozarmory"

WoozArmory.kModelName = PrecacheAsset("models/marine/armory/armory.model")
local kAnimationGraph = PrecacheAsset("models/marine/armory/armory.animation_graph")
WoozArmory.kAttachPoint = "Root"

local networkVars = {};

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(GameEffectsMixin, networkVars)
AddMixinNetworkVars(TeamMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(IdleMixin, networkVars)

function WoozArmory:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, DissolveMixin)

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)
end

function WoozArmory:OnInitialized()

    ScriptActor.OnInitialized(self)

    self:SetModel(WoozArmory.kModelName, kAnimationGraph)

    if Server then
        InitMixin(self, StaticTargetMixin)
    elseif Client then
		InitMixin(self, UnitStatusMixin); -- to be removed; removes health bar
	end

    InitMixin(self, IdleMixin)

	self:SetPoseParam("log_n", 0);
	self:SetPoseParam("log_e", 0);
	self:SetPoseParam("log_w", 0);
	self:SetPoseParam("log_s", 0);

	self:SetPoseParam("scan_n", 0);
	self:SetPoseParam("scan_e", 0);
	self:SetPoseParam("scan_w", 0);
	self:SetPoseParam("scan_s", 0);

	local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit);
	self:SetExcludeRelevancyMask(mask);

	self:SetTeamNumber(kTeamInvalid);
end

function WoozArmory:GetCanBeUsed(player, useSuccessTable) end
function WoozArmory:GetCanBeUsedConstructed(byPlayer)
    return true;
end

function WoozArmory:GetCanDie()
	return true;
end

function WoozArmory:GetCanTakeDamage()
	return true;
end

Shared.RegisterNetworkMessage("WoozArmoryFound", {
	entityId = "entityid";
});

if Server then
	Server.HookNetworkMessage("WoozArmoryFound", function(client, msg)
		local player = client:GetControllingPlayer();
		local steamid = GetSteamIdForClientIndex(player:GetClientIndex());
		Shared.Message(player.name .. " (steam id: " .. steamid .. ") won!");
		local woozarmory = Shared.GetEntity(msg.entityId);
		DestroyEntity(woozarmory);
		Shared.Message(type(msg.entityId));
	end);

	Event.Hook("Console_plantarmory", function(client)
		local ent = CreateEntity("woozarmory", client:GetControllingPlayer():GetOrigin());
		assert(ent);
	end);

elseif Client then
	function WoozArmory:OnUse(player)
		if Client.GetLocalPlayer() == player then
			Client.SendNetworkMessage("WoozArmoryFound", {entityId = self:GetId()});
		end
	end
end

Shared.LinkClassToMap("WoozArmory", WoozArmory.kMapName, networkVars)

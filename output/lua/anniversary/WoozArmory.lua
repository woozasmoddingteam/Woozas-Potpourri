Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/ScriptActor.lua")

class 'WoozArmory' (ScriptActor)

WoozArmory.kMapName = "woozarmory"

WoozArmory.kModelName = PrecacheAsset("models/props/descent/descent_arcade_gorgetoy_01.model")

local networkVars = {};

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)

local emptyFunction = function() end

function WoozArmory:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

	if Server then
		assert(not self.callback); -- Assert that we aren't overriding an already existing variable.
		self.callback = emptyFunction;
	end
end

function WoozArmory:OnInitialized()

    ScriptActor.OnInitialized(self);

    self:SetModel(WoozArmory.kModelName);

	local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit);
	self:SetExcludeRelevancyMask(mask);
end

function WoozArmory:GetCanBeUsed(player, useSuccessTable) end

function WoozArmory:GetCanTakeDamage() -- Require for bullet effects somehow...
	return true;
end

Shared.RegisterNetworkMessage("WoozArmoryFound", {
	entityId = "entityid";
});

if Server then
	function WoozArmory:SetCallback(newcallback)
		self.callback = newcallback;
	end

	function WoozArmory:GetCallback()
		return self.callback;
	end

	Server.HookNetworkMessage("WoozArmoryFound", function(client, msg)
		local player = client:GetControllingPlayer();
		local woozarmory = Shared.GetEntity(msg.entityId);
		self.callback(player, woozarmory);
		local steamid = GetSteamIdForClientIndex(player:GetClientIndex());
		Shared.Message(player.name .. " (steam id: " .. steamid .. ") won!");
		DestroyEntity(woozarmory);
	end);

	local function logMessage(player, woozamory)
		local steamid = GetSteamIdForClientIndex(player:GetClientIndex());
		Shared.Message(player.name .. " (steam id: " .. steamid .. ") won!");
	end

	Event.Hook("Console_plantarmory", function(client)
		local ent = CreateEntity("woozarmory", client:GetControllingPlayer():GetOrigin());
		ent:SetCallback(logMessage);
	end);

elseif Client then
	function WoozArmory:OnUse(player)
		if Client.GetLocalPlayer() == player then
			Client.SendNetworkMessage("WoozArmoryFound", {entityId = self:GetId()});
		end
	end
end

Shared.LinkClassToMap("WoozArmory", WoozArmory.kMapName, networkVars)

Script.Load("lua/Mixins/ClientModelMixin.lua");
Script.Load("lua/ScriptActor.lua");
Script.Load("lua/EntityChangeMixin.lua");

class 'SecretGorge' (ScriptActor)

SecretGorge.kMapName = "secretgorge"

SecretGorge.kModelName = PrecacheAsset("models/props/descent/descent_arcade_gorgetoy_01.model")

local networkVars = {};

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
--AddMixinNetworkVars(EntityChangeMixin, networkVars);

local emptyFunction = function() assert(false) end

function SecretGorge:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin);
    InitMixin(self, ClientModelMixin);
	InitMixin(self, EntityChangeMixin); -- May be needed

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

	if Server then
		assert(not self.callback); -- Assert that we aren't overriding an already existing variable.
		self.callback = emptyFunction;
	end
end

function SecretGorge:OnInitialized()

    ScriptActor.OnInitialized(self);

    self:SetModel(SecretGorge.kModelName);

	local mask = bit.bor(kRelevantToTeam1Unit, kRelevantToTeam2Unit);
	self:SetExcludeRelevancyMask(mask);
end

function SecretGorge:GetCanBeUsed(player, useSuccessTable) end

function SecretGorge:GetCanTakeDamage() -- Require for bullet effects somehow...
	return true;
end

function SecretGorge:GetCanSkipPhysics()
	return true;
end

function SecretGorge:GetClientSideAnimationEnabled()
	return false;
end

function SecretGorge:GetIsMapEntity()
	return true;
end

Shared.RegisterNetworkMessage("SecretGorgeFound", {
	entityId = "entityid";
});

if Server then
	function SecretGorge:SetCallback(newcallback)
		self.callback = newcallback;
	end

	function SecretGorge:GetCallback()
		return self.callback;
	end

	Server.HookNetworkMessage("SecretGorgeFound", function(client, msg)
		local player = client:GetControllingPlayer();
		local secretgorge = Shared.GetEntity(msg.entityId);
		secretgorge.callback(player, secretgorge);
		DestroyEntity(secretgorge);
	end);

elseif Client then
	function SecretGorge:OnUse(player)
		if Client.GetLocalPlayer() == player then
			Client.SendNetworkMessage("SecretGorgeFound", {entityId = self:GetId()});
		end
	end
end

Shared.LinkClassToMap("SecretGorge", SecretGorge.kMapName, networkVars)

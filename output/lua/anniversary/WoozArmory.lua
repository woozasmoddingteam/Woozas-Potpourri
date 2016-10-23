Script.Load("lua/Mixins/ClientModelMixin.lua");
Script.Load("lua/ScriptActor.lua");
--Script.Load("lua/EntityChangeMixin.lua");

class 'WoozArmory' (ScriptActor)

WoozArmory.kMapName = "woozarmory"

WoozArmory.kModelName = PrecacheAsset("models/props/descent/descent_arcade_gorgetoy_01.model")

local networkVars = {};

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(ClientModelMixin, networkVars)
--AddMixinNetworkVars(EntityChangeMixin, networkVars);

local emptyFunction = function() assert(false) end

function WoozArmory:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin);
    InitMixin(self, ClientModelMixin);
	--InitMixin(self, EntityChangeMixin); -- May be needed

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

function WoozArmory:GetCanSkipPhysics()
	return true;
end

function WoozArmory:GetClientSideAnimationEnabled()
	return false;
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

	--[[
	-- Special thanks to Katzenfleisch!
	local function getEntitySpawnTraceEndpoint(player, range)
		local startPoint = player:GetEyePos();
		local viewCoords = player:GetViewAngles():GetCoords();
		local endPoint = startPoint + viewCoords.zAxis * range;
		local activeWeapon = self:GetActiveWeapon();

		local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))

		return trace.endPoint;
	end

	local function spawnArmory(self, player, position, normal, direction)
		local ent = CreateEntity("woozarmory", player:GetOrigin());

		local coords = Coords.GetTranslation(position)
		coords.yAxis = normal
		coords.zAxis = direction

		coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
		coords.xAxis:Normalize()

		coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
		coords.zAxis:Normalize()

		ent:SetCoords(coords)
		ent:SetCallback(logMessage);
		return true;
	end
	--]]

	Server.HookNetworkMessage("WoozArmoryFound", function(client, msg)
		local player = client:GetControllingPlayer();
		local woozarmory = Shared.GetEntity(msg.entityId);
		woozarmory.callback(player, woozarmory);
		--local steamid = GetSteamIdForClientIndex(player:GetClientIndex());
		--Shared.Message(player.name .. " (steam id: " .. steamid .. ") won!");
		DestroyEntity(woozarmory);
	end);

	local function logMessage(player, woozamory)
		local steamid = GetSteamIdForClientIndex(player:GetClientIndex());
		Shared.Message(player.name .. " (steam id: " .. steamid .. ") won!");
	end

	Event.Hook("Console_plantarmory", function(client)
		local player = client:GetControllingPlayer();
		local ent = CreateEntity("woozarmory", player:GetOrigin());
		local angles = player:GetViewAngles();
		ent:SetAngles(angles);
		Shared.Message(tostring(angles.roll) .. "|" .. tostring(angles.yaw) .. "|" .. tostring(angles.pitch));
		ent:SetCallback(logMessage);
	end);

	Event.Hook("Console_increase_roll", function(client)

	end);

elseif Client then
	function WoozArmory:OnUse(player)
		if Client.GetLocalPlayer() == player then
			Client.SendNetworkMessage("WoozArmoryFound", {entityId = self:GetId()});
		end
	end
end

Shared.LinkClassToMap("WoozArmory", WoozArmory.kMapName, networkVars)

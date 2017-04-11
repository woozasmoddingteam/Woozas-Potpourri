Log "\n\n\nLoading easter egg!\n\n\n"

--[=[
	We get loaded from two points:
		* eastereggs.entry
		* shared.lua
	The first one is only for Predict,
	the second is for Server and Client.
	Plugin is only valid when we get loaded from shared.lua,
	Predict won't need it anyway, so it's not a problem.
]=]
local Shine = Shine
local Plugin = ...

Script.Load("lua/ScriptActor.lua")

class 'EasterEgg' (ScriptActor)

EasterEgg.kMapName = "easteregg"

EasterEgg.kModelName = PrecacheAsset("models/props/descent/descent_arcade_gorgetoy_01.model")

local networkVars = {}

AddMixinNetworkVars(BaseModelMixin, networkVars)

function EasterEgg:OnCreate()
    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
	InitMixin(self, LiveMixin)
	self:SetMaxHealth(1)
	self:SetMaxArmor(0)
	self:SetHealth(1)
	self:SetArmor(0)

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.None)
    self:SetPhysicsGroup(PhysicsGroup.BigStructuresGroup)

    self:SetModel(EasterEgg.kModelName)
end

function EasterEgg:GetCanSkipPhysics()
	return true
end

function EasterEgg:GetClientSideAnimationEnabled()
	return false
end

function EasterEgg:GetIsMapEntity()
	return true
end

function EasterEgg:GetCanBeHealed()
	return false
end

function EasterEgg:AttemptToKill(_, player)
	if not player:isa "Player" then return false end

	local entry = Plugin.Config.Winners[player:GetSteamId()]
	local limit = entry.limit or Plugin.Config.Limit

	return #entry < limit
end

function EasterEgg:GetName()
	return self.name
end

function EasterEgg:SetName(name)
	self.name = name
end

function EasterEgg:OnKill(_, attacker)
	assert(attacker:isa "Player")

	local Winners = Plugin.Config.Winners

	local id = attacker:GetSteamId()

	Winners[id] = Winners[id] or {}
	Winners[id].name = attacker:GetName()

	table.insert(Winners[id], {
		name = self:GetName(),
		room = self:GetLocationName(),
		pos  = self:GetOrigin(),
		map  = Shared.GetMapName()
	})

	count = count - 1
	Shine:NotifyDualColour(nil, 0x80, 0xB5, 0x8B, "[Easter Eggs] ", 0xA0, 0xEF, 0xEF,
		("Player %s found the easter egg '%s'! %i easter eggs remaining!"):format(attacker:GetName(), count)
	)
end

Shared.LinkClassToMap("EasterEgg", EasterEgg.kMapName, networkVars)

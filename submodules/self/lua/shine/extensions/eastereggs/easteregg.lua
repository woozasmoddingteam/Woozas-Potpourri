--[=[
	We get loaded from two points:
		* eastereggs.entry
		* shared.lua
	The first one is only for Predict,
	the second is for Server and Client.
	Plugin is only valid when we get loaded from shared.lua,
	Predict won't need it anyway, so it's not a problem.
]=]
local Shine
local Plugin

Script.Load("lua/ScriptActor.lua")

class 'EasterEgg' (ScriptActor)

EasterEgg.kMapName = "easteregg"

EasterEgg.kModelName = PrecacheAsset("models/props/descent/descent_arcade_gorgetoy_01.model")

local count = 0

local networkVars = {}

AddMixinNetworkVars(BaseModelMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)

function EasterEgg.Initialise(shine, plugin)
	Shine, Plugin = assert(shine), assert(plugin)
end

function EasterEgg:OnCreate()
    ScriptActor.OnCreate(self)

	if Server then
		count = count + 1
	end

    InitMixin(self, BaseModelMixin)
	InitMixin(self, LiveMixin)
	self:SetMaxHealth(1)
	self:SetMaxArmor(0)
	self:SetHealth(1)
	self:SetArmor(0)

    self:SetLagCompensated(false)

    self:SetPhysicsType(PhysicsType.None)
    self:SetPhysicsGroup(PhysicsGroup.SmallStructuresGroup)

    self:SetModel(EasterEgg.kModelName)
end

if Server then
	function EasterEgg:OnDestroy()
		ScriptActor.OnDestroy(self)

		count = count - 1
	end
end

function EasterEgg.GetCount()
	return count
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
	if not player:isa "Player" then
		return false
	end

	local entry = Plugin.Config.Winners[player:GetSteamId()]
	entry = entry and entry.gorges

	local b = not entry or #entry < Plugin.Config.Limit
	if not b then
		Shine:NotifyError(player, ("You have reached the maximum limit of %s eggs!"):format(Plugin.Config.Limit))
	end

	return b
end

function EasterEgg:GetName()
	return self.name
end

function EasterEgg:SetName(name)
	self.name = name
end

function EasterEgg:GetCanBeUsed(player, t)
	t.useSuccess = false
end

function EasterEgg:GetCanTakeDamage()
	return true
end

function EasterEgg:GetSendDeathMessage()
	return false
end

function EasterEgg:OnKill(attacker, _)
	assert(attacker:isa "Player")

	local Winners = Plugin.Config.Winners

	local id = attacker:GetSteamId()

	Winners[id] = Winners[id] or {gorges = {}}
	Winners[id].name = attacker:GetName()

	local gorges = Winners[id].gorges

	local origin = self:GetOrigin()

	local room = GetLocationForPoint(origin)

	table.insert(gorges, {
		name = self:GetName(),
		room = room and room.name,
		pos  = {
			x = origin.x,
			y = origin.y,
			z = origin.z
		},
		map  = Shared.GetMapName()
	})

	if self:GetName() then
		Shine:NotifyDualColour(nil, 0x80, 0xB5, 0x8B, "[Easter Eggs] ", 0xA0, 0xEF, 0xEF,
			("Player %s killed the easter egg '%s' in room '%s'! %i easter eggs remaining!"):format(attacker:GetName(), self:GetName(), room and room.name, count - 1)
		)
	else
		Shine:NotifyDualColour(nil, 0x80, 0xB5, 0x8B, "[Easter Eggs] ", 0xA0, 0xEF, 0xEF,
			("Player %s killed an easter egg in room '%s'! %i easter eggs remaining!"):format(attacker:GetName(), room and room.name, count - 1)
		)
	end

	Plugin.remove(self)

	Server.DestroyEntity(self)
end

--[=[
	How **not** to do object orientation:
	Basically a lot of code depends on all live entities having the team mixin implicitly.
]=]
function EasterEgg:GetTeamNumber()
	return -1
end

Shared.LinkClassToMap("EasterEgg", EasterEgg.kMapName, networkVars)

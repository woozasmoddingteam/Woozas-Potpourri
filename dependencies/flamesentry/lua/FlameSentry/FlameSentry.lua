Script.Load "lua/Sentry.lua"
Script.Load "lua/Weapons/Marine/Flamethrower.lua"

class 'FlameSentry' (Sentry)

FlameSentry.kMapName			 = "flamesentry"
FlameSentry.kModelName		 = PrecacheAsset("models/marine/flame_sentry/flame_sentry.model")
FlameSentry.kAnimationGraph = PrecacheAsset("models/marine/flame_sentry/flame_sentry.animation_graph")

for _, v in ipairs {
	"kConeWidth",
	"kDamageRadius",
} do
	FlameSentry[v] = Flamethrower[v]
end

FlameSentry.kMuzzleNode = "fxnode_flamesentrymuzzle"
-- Unused?
--FlameSentry.kEyeNode	  = "fxnode_eye2"
--FlameSentry.kLaserNode  = "fxnode_eye2"

local networkVars = {}

if Server then
	local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/flamethrower/attack_loop")
	function FlameSentry:OnCreate()
		Sentry.OnCreate(self)

		self.attackSound:SetAsset(kFireLoopingSound)
	end
end

local function GetAttachPointOrigin(self, node)
	if node == "fxnode_sentrymuzzle" or node == "fxnode_flamethrowermuzzle" then
		return self:flamesentry_GetAttachPointOrigin(self.kMuzzleNode)
	else
		return self:flamesentry_GetAttachPointOrigin(node)
	end
end

local function DoDamage(self, damage, ...)
	self:flamesentry_DoDamage(damage * 2, ...)
end

function FlameSentry:OnInitialized()
	Sentry.OnInitialized(self)

	self:SetModel(self.kModelName, self.kAnimationGraph) -- How constants should **really** be used

	if not self.flamesentry_GetAttachPointOrigin then
		self.flamesentry_GetAttachPointOrigin = self.GetAttachPointOrigin
		self.GetAttachPointOrigin = GetAttachPointOrigin
	end

	--[[ Uncomment to enable damage buff
	if not self.flamesentry_DoDamage then
		self.flamesentry_DoDamage = self.DoDamage
		self.DoDamage = DoDamage
	end
	--]]
end

function FlameSentry:OnGetMapBlipInfo()
	return true, kMinimapBlipType.Sentry, self:GetTeamNumber(), self:GetIsInCombat(), self:GetIsParasisted()
end

function FlameSentry:GetEyePos()
	return self:GetAttachPointOrigin(FlameSentry.kMuzzleNode)
end

function FlameSentry:OverrideLaserLength()
	return kFlamethrowerRange
end

function FlameSentry:GetViewAngles()
	local angles = Angles()
	angles:BuildFromCoords(Coords.GetLookIn(Vector(), self.targetDirection))
	return angles
end

function FlameSentry:GetMeleeOffset()
	return 0
end

if Server then
	local OnDeploy = debug.getupvalue(FlameSentry.OnConstructionComplete, "OnDeploy")
	function FlameSentry:OnConstructionComplete()
		self:AddTimedCallback(OnDeploy, 1.4)
	end

	function FlameSentry:FireBullets()
		if not self.last_attack_effect or Shared.GetTime() - self.last_attack_effect < 2 then
			self:TriggerEffects "flamethrower_attack_start"
			self.last_attack_effect = Shared.GetTime()
		elseif Shared.GetTime() - self.last_attack_effect < 0.5 then
			self:TriggerEffects "flamethrower_attack"
			self.last_attack_effect = Shared.GetTime()
		end
		return Flamethrower.ShootFlame(self, self)
	end
end

Shared.LinkClassToMap("FlameSentry", FlameSentry.kMapName, networkVars)

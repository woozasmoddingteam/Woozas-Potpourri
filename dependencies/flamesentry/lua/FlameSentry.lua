-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\FlameSentry.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--                  Andreas Urwalek (andi@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Mixins/ClientModelMixin.lua")
Script.Load("lua/LiveMixin.lua")
Script.Load("lua/PointGiverMixin.lua")
Script.Load("lua/GameEffectsMixin.lua")
Script.Load("lua/SelectableMixin.lua")
Script.Load("lua/FlinchMixin.lua")
Script.Load("lua/LOSMixin.lua")
Script.Load("lua/TeamMixin.lua")
Script.Load("lua/EntityChangeMixin.lua")
Script.Load("lua/CorrodeMixin.lua")
Script.Load("lua/ConstructMixin.lua")
Script.Load("lua/ResearchMixin.lua")
Script.Load("lua/RecycleMixin.lua")
Script.Load("lua/ScriptActor.lua")
Script.Load("lua/RagdollMixin.lua")
Script.Load("lua/NanoShieldMixin.lua")
Script.Load("lua/SleeperMixin.lua")
Script.Load("lua/StunMixin.lua")
Script.Load("lua/ObstacleMixin.lua")
Script.Load("lua/WeldableMixin.lua")
--Script.Load("lua/LaserMixin.lua")
Script.Load("lua/TargetCacheMixin.lua")
Script.Load("lua/OrdersMixin.lua")
Script.Load("lua/UnitStatusMixin.lua")
Script.Load("lua/DamageMixin.lua")
Script.Load("lua/DissolveMixin.lua")
Script.Load("lua/GhostStructureMixin.lua")
Script.Load("lua/MapBlipMixin.lua")
Script.Load("lua/VortexAbleMixin.lua")
Script.Load("lua/TriggerMixin.lua")
Script.Load("lua/TargettingMixin.lua")
Script.Load("lua/CombatMixin.lua")
Script.Load("lua/CommanderGlowMixin.lua")
Script.Load("lua/InfestationTrackerMixin.lua")
Script.Load("lua/SupplyUserMixin.lua")

local kSpinUpSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_spin_up")
local kSpinDownSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_spin_down")

-- class 'FlameSentry' (ScriptActor)
class 'FlameSentry' (Sentry)

FlameSentry.kMapName = "flamesentry"

-- FlameSentry.kModelName = PrecacheAsset("models/marine/sentry/sentry.model")
-- local kAnimationGraph = PrecacheAsset("models/marine/sentry/sentry.animation_graph")
FlameSentry.kModelName = PrecacheAsset("models/marine/flame_sentry/flame_sentry.model")
local kAnimationGraph = PrecacheAsset("models/marine/flame_sentry/flame_sentry.animation_graph")

local kAttackSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_fire_loop")

local kFlameSentryScanSoundName = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_scan")
FlameSentry.kUnderAttackSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_taking_damage")
FlameSentry.kFiringAlertSound = PrecacheAsset("sound/NS2.fev/marine/voiceovers/commander/sentry_firing")

FlameSentry.kConfusedSound = PrecacheAsset("sound/NS2.fev/marine/structures/sentry_confused")

FlameSentry.kFireShellEffect = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part1.cinematic")
--PrecacheAsset("cinematics/marine/flame_sentry/flame_sentry.cinematic")

FlameSentry.kIdleFlame = PrecacheAsset("cinematics/marine/flame_sentry.cinematic")



-- Balance

kFlameSentryEngagementDistance = 10
kFlameSentryAttackDamageType = kDamageType.Normal
kFlameSentryAttackBaseROF = .15
kFlameSentryAttackRandROF = 0.0
kFlameSentryAttackBulletsPerSalvo = 1
kConfusedFlameSentryBaseROF = 2.0

kFlameSentryDamage = 6.00 -- kFlamethrowerDamage = 8
kFlameSentryEnergyDamage = 1 -- kFlameThrowerEnergyDamage = 3

FlameSentry.kPingInterval = 4
FlameSentry.kFov = 160
FlameSentry.kMaxPitch = 80 -- 160 total
FlameSentry.kMaxYaw = FlameSentry.kFov / 2

FlameSentry.kBaseROF = kFlameSentryAttackBaseROF
FlameSentry.kRandROF = kFlameSentryAttackRandROF
FlameSentry.kSpread = Math.Radians(3)
FlameSentry.kBulletsPerSalvo = kFlameSentryAttackBulletsPerSalvo
FlameSentry.kBarrelScanRate = 60      -- Degrees per second to scan back and forth with no target
FlameSentry.kBarrelMoveRate = 150    -- Degrees per second to move sentry orientation towards target or back to flat when targeted
FlameSentry.kRange = 8 -- kFlamethrowerRange = 9
FlameSentry.kReorientSpeed = .05

FlameSentry.kTargetAcquireTime = 0.15
FlameSentry.kConfuseDuration = 2
FlameSentry.kAttackEffectIntervall = 0.2
FlameSentry.kConfusedAttackEffectInterval = kConfusedFlameSentryBaseROF

-- Animations
FlameSentry.kYawPoseParam = "sentry_yaw" -- FlameSentry yaw pose parameter for aiming
FlameSentry.kPitchPoseParam = "sentry_pitch"

FlameSentry.kMuzzleNode = "fxnode_flamesentrymuzzle"
FlameSentry.kEyeNode = "fxnode_eye2"
FlameSentry.kLaserNode = "fxnode_eye2"

-- FlameSentry.kMuzzleNode = "fxnode_sentrymuzzle"
-- FlameSentry.kEyeNode = "fxnode_eye"
-- FlameSentry.kLaserNode = "fxnode_eye"


if Client then
    Script.Load("lua/FlameSentry_Client.lua")
end

-- prevents attacking during deploy animation for kDeployTime seconds
local kDeployTime = 1.4

--------------------  Flame sentry
local kFireLoopingSound = PrecacheAsset("sound/NS2.fev/marine/flamethrower/attack_loop")

local kConeWidth = 0.14

--------------------

local networkVars =
{
    -- So we can update angles and pose parameters smoothly on client
    targetDirection = "vector",

    confused = "boolean",

    deployed = "boolean",

    attacking = "boolean",

    attachedToBattery = "boolean",

    --------------------  Flame sentry

    createParticleEffects = "boolean",
    animationDoneTime = "float",
    loopingSoundEntId = "entityid",
    range = "integer (0 to 11)",
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
AddMixinNetworkVars(CombatMixin, networkVars)
AddMixinNetworkVars(NanoShieldMixin, networkVars)
AddMixinNetworkVars(StunMixin, networkVars)
AddMixinNetworkVars(ObstacleMixin, networkVars)
--AddMixinNetworkVars(LaserMixin, networkVars)
AddMixinNetworkVars(OrdersMixin, networkVars)
AddMixinNetworkVars(DissolveMixin, networkVars)
AddMixinNetworkVars(GhostStructureMixin, networkVars)
AddMixinNetworkVars(VortexAbleMixin, networkVars)
AddMixinNetworkVars(SelectableMixin, networkVars)
AddMixinNetworkVars(ParasiteMixin, networkVars)

local function BurnSporesAndUmbra(self, startPoint, endPoint)

    local toTarget = endPoint - startPoint
    local distanceToTarget = toTarget:GetLength()
    toTarget:Normalize()

    local stepLength = 2

    for i = 1, 5 do

        -- stop when target has reached, any spores would be behind
        if distanceToTarget < i * stepLength then
            break
        end

        local checkAtPoint = startPoint + toTarget * i * stepLength
        local spores = GetEntitiesWithinRange("SporeCloud", checkAtPoint, kSporesDustCloudRadius)

        local umbras = GetEntitiesWithinRange("CragUmbra", checkAtPoint, CragUmbra.kRadius)
        table.copy(GetEntitiesWithinRange("StormCloud", checkAtPoint, StormCloud.kRadius), umbras, true)
        table.copy(GetEntitiesWithinRange("MucousMembrane", checkAtPoint, MucousMembrane.kRadius), umbras, true)
        table.copy(GetEntitiesWithinRange("EnzymeCloud", checkAtPoint, EnzymeCloud.kRadius), umbras, true)

        local bombs = GetEntitiesWithinRange("Bomb", checkAtPoint, 1.6)
        table.copy(GetEntitiesWithinRange("WhipBomb", checkAtPoint, 1.6), bombs, true)

        for index, bomb in ipairs(bombs) do
            bomb:TriggerEffects("burn_bomb", { effecthostcoords = Coords.GetTranslation(bomb:GetOrigin()) } )
            DestroyEntity(bomb)
        end

        for index, spore in ipairs(spores) do
            self:TriggerEffects("burn_spore", { effecthostcoords = Coords.GetTranslation(spore:GetOrigin()) } )
            DestroyEntity(spore)
        end

        for index, umbra in ipairs(umbras) do
            self:TriggerEffects("burn_umbra", { effecthostcoords = Coords.GetTranslation(umbra:GetOrigin()) } )
            DestroyEntity(umbra)
        end

    end

end

local function CreateFlame(self, player, position, normal, direction)

    -- create flame entity, but prevent spamming:
    local nearbyFlames = GetEntitiesForTeamWithinRange("Flame", self:GetTeamNumber(), position, 1.5)

    if table.count(nearbyFlames) == 0 then

        local flame = CreateEntity(Flame.kMapName, position, player:GetTeamNumber())
        flame:SetOwner(player)

        local coords = Coords.GetTranslation(position)
        coords.yAxis = normal
        coords.zAxis = direction

        coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
        coords.xAxis:Normalize()

        coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
        coords.zAxis:Normalize()

        flame:SetCoords(coords)

    end

end

local function ApplyConeDamage(self, player)

    local eyePos  = player:GetEyePos()
    local ents = {}


    local fireCoords = Coords.GetLookIn(Vector(0,0,0), self.targetDirection)--player:GetViewCoords().zAxis
    local fireDirection = CalculateSpread(fireCoords, 0.001, math.random)
    local extents = Vector(kConeWidth, kConeWidth, kConeWidth)
    local remainingRange = FlameSentry.kRange

    local startPoint = Vector(eyePos)
    local filterEnts = {self, player}

    for i = 1, 20 do

        if remainingRange <= 0 then
            break
        end

        local trace = TraceMeleeBox(self, startPoint, fireDirection, extents, remainingRange, PhysicsMask.Flame, EntityFilterList(filterEnts))

        --DebugLine(startPoint, trace.endPoint, 0.3, 1, 0, 0, 1)

        -- Check for spores in the way.
        if Server and i == 1 then
            BurnSporesAndUmbra(self, startPoint, trace.endPoint)
        end

        if trace.fraction ~= 1 then

            if trace.entity then

                if HasMixin(trace.entity, "Live") then
                    table.insertunique(ents, trace.entity)
                end

                table.insertunique(filterEnts, trace.entity)

            else

                -- Make another trace to see if the shot should get deflected.
                local lineTrace = Shared.TraceRay(startPoint, startPoint + remainingRange * fireDirection, CollisionRep.Damage, PhysicsMask.Flame, EntityFilterOne(player))

                if lineTrace.fraction < 0.8 then

                    fireDirection = fireDirection + trace.normal * 0.55
                    fireDirection:Normalize()

                    if Server then
                        CreateFlame(self, player, lineTrace.endPoint, lineTrace.normal, fireDirection)
                    end

                end

                remainingRange = remainingRange - (trace.endPoint - startPoint):GetLength()
                startPoint = trace.endPoint -- + fireDirection * kConeWidth * 2

            end

        else
            break
        end

    end

    for index, ent in ipairs(ents) do

        if ent ~= player then

            local toEnemy = GetNormalizedVector(ent:GetModelOrigin() - eyePos)
            local health = ent:GetHealth()

            local attackDamage = kFlameSentryDamage

            -- if HasMixin( ent, "Fire" ) then
            --     local time = Shared.GetTime()
            --     if (ent:isa "AlienStructure" or HasMixin(ent, "Maturity")) and ent:GetIsOnFire() then
            --         attackDamage = kFlamethrowerDamage * 2.5
            --     end
            -- end

            self:DoDamage( attackDamage, ent, ent:GetModelOrigin(), toEnemy )

            -- Only light on fire if we successfully damaged them
            if ent:GetHealth() ~= health and HasMixin(ent, "Fire") then
               ent:SetOnFire(player, self)
            end

            if ent.GetEnergy and ent.SetEnergy then
               ent:SetEnergy(ent:GetEnergy() - kFlameSentryEnergyDamage)
            end

            if Server and ent:isa("Alien") then
                ent:CancelEnzyme()
            end

        end

    end

end

-- function FlameSentry:GetViewAngles()
--    local angle = Angles()

--    local coords = self:GetAttachPointCoords(FlameSentry.kMuzzleNode)

--    -- local coords = Coords.GetLookIn(
--    --                          self:GetBarrelPoint(),
--    --                          self:GetLaserAttachCoords().zAxis)

--    angle:BuildFromCoords(coords)

--    angle.pitch = self.barrelPitchDegrees
--    angle.yaw = self.barrelYawDegrees
--    angle.roll = 0
--    return angle
-- end

local function ShootFlame(self, player)

    -- local viewAngles = player:GetViewAngles()
    -- local viewCoords = viewAngles:GetCoords()

    local viewCoords = self:GetAttachPointCoords(FlameSentry.kMuzzleNode)

   -- local viewCoords = Coords.GetLookIn(
   --    self:GetBarrelPoint(),
   --    self:GetLaserAttachCoords().zAxis)--viewAngles:GetCoords()

    viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * (-0.4) + viewCoords.xAxis * (-0.2)
    local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * FlameSentry.kRange

    local trace = Shared.TraceRay(viewCoords.origin, endPoint, CollisionRep.Damage, PhysicsMask.Flame, EntityFilterAll())

    local range = (trace.endPoint - viewCoords.origin):GetLength()
    if range < 0 then
        range = range * (-1)
    end

    if trace.endPoint ~= endPoint and trace.entity == nil then

        local angles = Angles(0,0,0)
        angles.yaw = GetYawFromVector(trace.normal)
        angles.pitch = GetPitchFromVector(trace.normal) + (math.pi/2)

        local normalCoords = angles:GetCoords()
        normalCoords.origin = trace.endPoint
        range = range - 3

    end

    ApplyConeDamage(self, player)

end

function FlameSentry:GetMeleeBase()
    -- Width of box, height of box
    return 1, 0.8
end

--
-- Extra offset from viewpoint to make sure you don't hit anything to your rear.
--
function FlameSentry:GetMeleeOffset()
    return 0.0
end

function FlameSentry:OnCreate()

    ScriptActor.OnCreate(self)

    InitMixin(self, BaseModelMixin)
    InitMixin(self, ClientModelMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, GameEffectsMixin)
    InitMixin(self, FlinchMixin)
    InitMixin(self, TeamMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, SelectableMixin)
    InitMixin(self, EntityChangeMixin)
    InitMixin(self, LOSMixin)
    InitMixin(self, CorrodeMixin)
    InitMixin(self, ConstructMixin)
    InitMixin(self, ResearchMixin)
    InitMixin(self, RecycleMixin)
    InitMixin(self, CombatMixin)
    InitMixin(self, RagdollMixin)
    InitMixin(self, DamageMixin)
    InitMixin(self, StunMixin)
    InitMixin(self, ObstacleMixin)
    InitMixin(self, OrdersMixin, { kMoveOrderCompleteDistance = kAIMoveOrderCompleteDistance })
    InitMixin(self, DissolveMixin)
    InitMixin(self, GhostStructureMixin)
    InitMixin(self, VortexAbleMixin)
    InitMixin(self, ParasiteMixin)

    if Client then
        InitMixin(self, CommanderGlowMixin)
    end

    self.desiredYawDegrees = 0
    self.desiredPitchDegrees = 0
    self.barrelYawDegrees = 0
    self.barrelPitchDegrees = 0

    self.confused = false
    self.attachedToBattery = true -- Faded update

    if Server then

        -- self.attackSound = Server.CreateEntity(SoundEffect.kMapName)
        -- self.attackSound:SetParent(self)
        -- self.attackSound:SetAsset(kAttackSoundName)

    elseif Client then

        self.timeLastAttackEffect = Shared.GetTime()

        -- Play a "ping" sound effect every FlameSentry.kPingInterval while scanning.
        local function PlayScanPing(sentry)

            if GetIsUnitActive(self) and not self.attacking and self.attachedToBattery then
                local player = Client.GetLocalPlayer()
                Shared.PlayPrivateSound(player, kFlameSentryScanSoundName, nil, 1, sentry:GetModelOrigin())
            end
            return true

        end

        self:AddTimedCallback(PlayScanPing, FlameSentry.kPingInterval)

    end

    self:SetLagCompensated(false)
    self:SetPhysicsType(PhysicsType.Kinematic)
    self:SetPhysicsGroup(PhysicsGroup.MediumStructuresGroup)


    -- --------- Flame sentry
    -- self.loopingSoundEntId = Entity.invalidId

    -- if Server then

    --     self.createParticleEffects = false
    --     self.animationDoneTime = 0

    --     self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
    --     self.loopingFireSound:SetAsset(kFireLoopingSound)
    --     self.loopingFireSound:SetParent(self)
    --     self.loopingSoundEntId = self.loopingFireSound:GetId()

    -- elseif Client then

    --     self:SetUpdates(true)
    --     self.lastAttackEffectTime = 0.0

    -- end





	self.lastAttackApplyTime = 0

	self.isShooting = false

	self.timeWeldStarted = 0
    self.timeLastWeld = 0
    self.loopingSoundEntId = Entity.invalidId
	self.range = 10

    if Server then
        self.lastAttackApplyTime = 0

		self.createParticleEffects = false
        self.loopingFireSound = Server.CreateEntity(SoundEffect.kMapName)
        self.loopingFireSound:SetAsset(kFireLoopingSound)
        -- SoundEffect will automatically be destroyed when the parent is destroyed (the Welder).
        self.loopingFireSound:SetParent(self)
        -- self.loopingFireSound:SetCoords(self:GetCoords())
        self.loopingSoundEntId = self.loopingFireSound:GetId()

		--  self.heatUISound = Server.CreateEntity(SoundEffect.kMapName)
		-- self.heatUISound:SetAsset(kHeatUISoundName)
		-- self.heatUISound:SetParent(self)
		-- self.heatUISound:Start()
		-- self.heatUISoundId = self.heatUISound:GetId()

    elseif Client then
        self:SetUpdates(true)
        self.lastAttackEffectTime = 0.0
        self.lastAttackApplyTime = 0
	end



end

function FlameSentry:OnInitialized()

    ScriptActor.OnInitialized(self)

    InitMixin(self, NanoShieldMixin)
    InitMixin(self, WeldableMixin)

    //InitMixin(self, LaserMixin)

    self:SetModel(FlameSentry.kModelName, kAnimationGraph)

    self:SetUpdates(true)

    if Server then

        InitMixin(self, SleeperMixin)

        self.timeLastTargetChange = Shared.GetTime()

        -- This Mixin must be inited inside this OnInitialized() function.
        if not HasMixin(self, "MapBlip") then
            InitMixin(self, MapBlipMixin)
        end

        -- TargetSelectors require the TargetCacheMixin for cleanup.
        InitMixin(self, TargetCacheMixin)
        InitMixin(self, SupplyUserMixin)

        -- configure how targets are selected and validated
        self.targetSelector = TargetSelector():Init(
           self,
           FlameSentry.kRange,
           true,
           { kMarineStaticTargets, kMarineMobileTargets },
           { PitchTargetFilter(self,  -FlameSentry.kMaxPitch, FlameSentry.kMaxPitch), CloakTargetFilter() },
           { function(target) return not target:isa("Cyst") end } )

        InitMixin(self, StaticTargetMixin)
        InitMixin(self, InfestationTrackerMixin)

    elseif Client then

        InitMixin(self, UnitStatusMixin)
        InitMixin(self, HiveVisionMixin)


        -- self.createParticleEffects = false
        -- self:InitIdleTrailCinematic()
        -- self.def_idleflame = Client.CreateCinematic(RenderScene.Zone_Default)
        -- -- self.def_idleflame:SetRepeatStyle(Cinematic.Repeat_Endless)
        -- self.def_idleflame:SetCinematic(FlameSentry.kIdleFlame)
        -- self.def_idleflame:SetParent(self)
        -- self.def_idleflame:SetIsVisible(true)


    end

end

function FlameSentry:OnGetMapBlipInfo()
   local blipType = kMinimapBlipType.Sentry
   local blipTeam = self:GetTeamNumber()
   -- if (isDetectedOnMinimap(self)) then
   --    blipTeam = -1
   -- end
   return true, blipType, blipTeam, false, false
end

function FlameSentry:OnDestroy()

    ScriptActor.OnDestroy(self)

    -- The attackSound was already destroyed at this point, clear the reference.
    if Server then
        self.attackSound = nil
    end

    if (Client) then
       if self.light ~= nil then
          Client.DestroyRenderLight(self.light)
          self.light = nil
       end
    end


    -- Flame sentry extra

    -- -- The loopingFireSound was already destroyed at this point, clear the reference.
    -- if Server then
    --     self.loopingFireSound = nil
    -- elseif Client then

    --     if self.trailCinematic then
    --         Client.DestroyTrailCinematic(self.trailCinematic)
    --         self.trailCinematic = nil
    --     end

    --     if self.pilotCinematic then
    --         Client.DestroyCinematic(self.pilotCinematic)
    --         self.pilotCinematic = nil
    --     end

    -- end





    if Server then
       self.loopingFireSound = nil
    elseif Client then
       if self.trailCinematic then
          Client.DestroyTrailCinematic(self.trailCinematic)
          self.trailCinematic = nil
       end
       -- if self.idleTrailCinematic then
       --    Client.DestroyTrailCinematic(self.idleTrailCinematic)
       --    self.idleTrailCinematic = nil
       -- end
       if self.pilotCinematic then
          Client.DestroyCinematic(self.pilotCinematic)
          self.pilotCinematic = nil
       end
       -- if self.heatDisplayUI then

       --    Client.DestroyGUIView(self.heatDisplayUI)
       --    self.heatDisplayUI = nil
       -- end
    end

end

function FlameSentry:GetCanSleep()
    return self.attacking == false
end

function FlameSentry:GetMinimumAwakeTime()
    return 10
end

function FlameSentry:GetFov()
    return FlameSentry.kFov
end

-- Reduce kFlameSentryEyeHeight so even placed on a ceiling it can shoot downward
local kFlameSentryEyeHeight = Vector(0, 0, 0)
function FlameSentry:GetEyePos()
    -- return self:GetOrigin() + kFlameSentryEyeHeight
   return (self:GetAttachPointOrigin(FlameSentry.kMuzzleNode))
end

function FlameSentry:GetDeathIconIndex()
    return kDeathMessageIcon.Sentry
end

function FlameSentry:GetReceivesStructuralDamage()
    return true
end

function FlameSentry:GetBarrelPoint()
    return self:GetAttachPointOrigin(FlameSentry.kMuzzleNode)
end

function FlameSentry:GetLaserAttachCoords()

    local coords = self:GetAttachPointCoords(FlameSentry.kLaserNode)
    local xAxis = coords.xAxis
    coords.xAxis = -coords.zAxis
    coords.zAxis = xAxis

    return coords
end

function FlameSentry:OverrideLaserLength()
    return FlameSentry.kRange
end

function FlameSentry:GetPlayInstantRagdoll()
    return true
end

function FlameSentry:GetIsLaserActive()
   return GetIsUnitActive(self) and self.deployed and self.attachedToBattery
end

-- -- Faded
-- if (Client) then
--    function FlameSentry:OnUpdateRender()
--       if (self.light ~= nil) then
--          self.light:SetIsVisible(true)
--          self.light:SetCoords(
--             Coords.GetLookIn(
--                self:GetBarrelPoint(),
--                self:GetLaserAttachCoords().zAxis))
--                -- self:GetOrigin(),
--                -- self:GetCoords().zAxis))
--          self.lightTimer = Shared.GetTime()
--       else

--          self.light = Client.CreateRenderLight()

--          self.light:SetType( RenderLight.Type_Spot )
--          self.light:SetColor( Color(.8, .8, 1) )
--          self.light:SetInnerCone( math.rad(7) )
--          self.light:SetOuterCone( math.rad(14) )
--          self.light:SetIntensity( 20 )
--          self.light:SetRadius( 22 )
--          self.light:SetGoboTexture("models/marine/male/flashlight.dds")

--          self.light:SetIsVisible(false)
--       end
--    end
-- end

function FlameSentry:OnUpdatePoseParameters()

    PROFILE("FlameSentry:OnUpdatePoseParameters")

    local pitchConfused = 0
    local yawConfused = 0

    -- alter the yaw and pitch slightly, barrel will swirl around
    if self.confused then

        pitchConfused = math.sin(Shared.GetTime() * 6) * 2
        yawConfused = math.cos(Shared.GetTime() * 6) * 2

    end

    self:SetPoseParam(FlameSentry.kPitchPoseParam, self.barrelPitchDegrees + pitchConfused)
    self:SetPoseParam(FlameSentry.kYawPoseParam, self.barrelYawDegrees + yawConfused)

end

function FlameSentry:OnUpdateAnimationInput(modelMixin)

    PROFILE("FlameSentry:OnUpdateAnimationInput")
    modelMixin:SetAnimationInput("attack", self.attacking)
    modelMixin:SetAnimationInput("powered", self.attachedToBattery)

end

-- used to prevent showing the hit indicator for the commander
function FlameSentry:GetShowHitIndicator()
    return false
end

function FlameSentry:OnWeldOverride(entity, elapsedTime)

    local welded = false

    -- faster repair rate for sentries, promote use of welders
    if entity:isa("Welder") then

        local amount = kWelderSentryRepairRate * elapsedTime
        self:AddHealth(amount)

    elseif entity:isa("MAC") then

        self:AddHealth(MAC.kRepairHealthPerSecond * elapsedTime)

    end

end

function FlameSentry:GetHealthbarOffset()
    return 0.4
end



-- GetEffectManager():AddEffectData("FlamerModEffects", {
--     dragonbreath_muzzle = {
--         flamerMuzzleEffects =
--         {
--            {weapon_cinematic = "cinematics/marine/flamethrower/flame.cinematic", attach_point = FlameSentry.kMuzzleNode},
--         },
--     },
-- })

-- GetEffectManager():AddEffectData("DefFlameSentryEffects", {
--                                     flamesentry_muzzle = {
--                                        flamesentry_Effects =
--                                           {
--                                              {weapon_cinematic = "cinematics/marine/flamethrower/flame.cinematic", attach_point = FlameSentry.kMuzzleNode},
--                                           },
--                                     },
--                                                           })

local function FlamePrimaryAttack(self)
   if not self.createParticleEffects then
      self:TriggerEffects("flamethrower_attack_start")
   end

   self.createParticleEffects = true

   if Server and not self.loopingFireSound:GetIsPlaying() then
      self.loopingFireSound:Start()
   end


   -- Fire the cool flame effect periodically
   -- Don't crank the period too low - too many effects slows down the game a lot.
   if Client then
      if self.lastAttackEffectTime + 0.5 < Shared.GetTime() then
         if self.createParticleEffects then
            self:TriggerEffects("flamethrower_attack")
         -- else
         --    self:TriggerEffects("dragonbreath_muzzle")
         end
         self.lastAttackEffectTime = Shared.GetTime()
      end
   end
end

if Server then

    local function OnDeploy(self)

        self.attacking = false
        self.deployed = true
        return false

    end

    function FlameSentry:OnConstructionComplete()
        self:AddTimedCallback(OnDeploy, kDeployTime)
    end

    function FlameSentry:OnStun(duration)
        self:Confuse(duration)
    end

    function FlameSentry:GetDamagedAlertId()
        return kTechId.MarineAlertSentryUnderAttack
    end



    function FlameSentry:FireBullets()

       -- FlamePrimaryAttack(self)

       ShootFlame(self, self)
       FlamePrimaryAttack(self)
       self.timeOfLastPrimaryAttack = Shared.GetTime()
       -- local fireCoords = Coords.GetLookIn(Vector(0,0,0), self.targetDirection)
       -- local startPoint = self:GetBarrelPoint()

       -- for bullet = 1, FlameSentry.kBulletsPerSalvo do

       --     local spreadDirection = CalculateSpread(fireCoords, FlameSentry.kSpread, math.random)

       --     local endPoint = startPoint + spreadDirection * FlameSentry.kRange

       --     local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOne(self))

       --     if trace.fraction < 1 then

       --         local damage = kFlameSentryDamage
       --         local surface = trace.surface

       --         -- Disable friendly fire.
       --         trace.entity = (not trace.entity or GetAreEnemies(trace.entity, self)) and trace.entity or nil

       --         local blockedByUmbra = trace.entity and GetBlockedByUmbra(trace.entity) or false

       --         if blockedByUmbra then
       --             surface = "umbra"
       --         end

       --         local direction = (trace.endPoint - startPoint):GetUnit()
       --         //Print("FlameSentry %d doing %.2f damage to %s (ramp up %.2f)", self:GetId(), damage, SafeClassName(trace.entity), rampUpFraction)
       --         self:DoDamage(damage, trace.entity, trace.endPoint, direction, surface, false, math.random() < 0.2)

       --     end

       --     bulletsFired = true

       -- end

    end

    -- checking at range 1.8 for overlapping the radius a bit. no LOS check here since i think it would become too expensive with multiple sentries
    function FlameSentry:GetFindsSporesAt(position)
       return #GetEntitiesWithinRange("SporeCloud", position, 1.8) > 0
    end

    function FlameSentry:Confuse(duration)

       if not self.confused then

          self.confused = true
          self.timeConfused = Shared.GetTime() + duration

          StartSoundEffectOnEntity(FlameSentry.kConfusedSound, self)

       end

    end

    -- check for spores in our way every 0.3 seconds
    local function UpdateConfusedState(self, target)

       if not self.confused and target then

          if not self.timeCheckedForSpores then
             self.timeCheckedForSpores = Shared.GetTime() - 0.3
          end

          if self.timeCheckedForSpores + 0.3 < Shared.GetTime() then

             self.timeCheckedForSpores = Shared.GetTime()

             local eyePos = self:GetEyePos()
             local toTarget = target:GetOrigin() - eyePos
             local distanceToTarget = toTarget:GetLength()
             toTarget:Normalize()

             local stepLength = 3
             local numChecks = math.ceil(FlameSentry.kRange/stepLength)

             -- check every few meters for a spore in the way, min distance 3 meters, max 12 meters (but also check sentry eyepos)
             for i = 0, numChecks do

                -- stop when target has reached, any spores would be behind
                if distanceToTarget < (i * stepLength) then
                   break
                end

                local checkAtPoint = eyePos + toTarget * i * stepLength
                if self:GetFindsSporesAt(checkAtPoint) then
                   self:Confuse(FlameSentry.kConfuseDuration)
                   break
                end

             end

          end

       elseif self.confused then

          if self.timeConfused < Shared.GetTime() then
             self.confused = false
          end

       end

    end

    local function UpdateBatteryState(self)

       local time = Shared.GetTime()

       if self.lastBatteryCheckTime == nil or (time > self.lastBatteryCheckTime + 0.5) then

          -- Update if we're powered or not
          self.attachedToBattery = false

          local ents = GetEntitiesForTeamWithinRange("SentryBattery", self:GetTeamNumber(), self:GetOrigin(), SentryBattery.kRange)
          for index, ent in ipairs(ents) do

             if GetIsUnitActive(ent) and ent:GetLocationName() == self:GetLocationName() then

                self.attachedToBattery = true
                break

             end

          end

          self.lastBatteryCheckTime = time

       end

    end

    function FlameSentry:OnUpdate(deltaTime)

       PROFILE("FlameSentry:OnUpdate")

       ScriptActor.OnUpdate(self, deltaTime)

       UpdateBatteryState(self)

        if self.timeNextAttack == nil or (Shared.GetTime() > self.timeNextAttack) then

           -- FlamePrimaryAttack(self)

            local initialAttack = self.target == nil

            local prevTarget = nil
            if self.target then
                prevTarget = self.target
            end

            self.target = nil

            if GetIsUnitActive(self) and self.attachedToBattery and self.deployed then
                self.target = self.targetSelector:AcquireTarget()
            end

            if self.target then

                local previousTargetDirection = self.targetDirection
                self.targetDirection = GetNormalizedVector(self.target:GetEngagementPoint() - self:GetAttachPointOrigin(FlameSentry.kMuzzleNode))

                -- Reset damage ramp up if we moved barrel at all
                if previousTargetDirection then
                    local dotProduct = previousTargetDirection:DotProduct(self.targetDirection)
                    if dotProduct < .99 then

                        self.timeLastTargetChange = Shared.GetTime()

                    end
                end

                -- Or if target changed, reset it even if we're still firing in the exact same direction
                if self.target ~= prevTarget then
                    self.timeLastTargetChange = Shared.GetTime()
                end

                -- don't shoot immediately
                if not initialAttack then

                    self.attacking = true
                    self:FireBullets()

                end

            else

                self.attacking = false
                self.timeLastTargetChange = Shared.GetTime()

                -- -- Flame sentry extra
                self.createParticleEffects = false

                if Server then
                   self.loopingFireSound:Stop()
                end
                -- --
            end

            UpdateConfusedState(self, self.target)
            -- slower fire rate when confused
            local confusedTime = ConditionalValue(self.confused, kConfusedFlameSentryBaseROF, 0)

            -- Random rate of fire so it can't be gamed

            if initialAttack and self.target then
                self.timeNextAttack = Shared.GetTime() + FlameSentry.kTargetAcquireTime
            else
                self.timeNextAttack = confusedTime + Shared.GetTime() + FlameSentry.kBaseROF + math.random() * FlameSentry.kRandROF
            end

            if not GetIsUnitActive() or self.confused or not self.attacking or not self.attachedToBattery then

                -- if self.attackSound:GetIsPlaying() then
                --     self.attackSound:Stop()
                -- end

            elseif self.attacking then

                -- if not self.attackSound:GetIsPlaying() then
                --     self.attackSound:Start()
                -- end

            end

        end

    end

elseif Client then

   -- local kDefFlameIdle = PrecacheAsset("cinematics/marine/flame_sentry.cinematic")
    local function UpdateAttackEffects(self, deltaTime)

       -- if (self.attacking) then
       --    ShootFlame(self, self)
       --    FlamePrimaryAttack(self)
       -- else
       --    self.createParticleEffects = false
       -- end

       -- FlamePrimaryAttack(self)

        local intervall = ConditionalValue(self.confused, FlameSentry.kConfusedAttackEffectInterval, FlameSentry.kAttackEffectIntervall)
        if self.attacking and (self.timeLastAttackEffect + intervall < Shared.GetTime()) then

            -- if self.confused then
            --     self:TriggerEffects("sentry_single_attack")
            -- end

            -- plays muzzle flash and smoke
            self:TriggerEffects("sentry_attack")

            self.timeLastAttackEffect = Shared.GetTime()

            -- FlamePrimaryAttack(self)
        end


    end

    function FlameSentry:OnUpdate(deltaTime)

        ScriptActor.OnUpdate(self, deltaTime)

        if GetIsUnitActive(self) and self.deployed and self.attachedToBattery then

           -- FlamePrimaryAttack(self)
            -- Swing barrel yaw towards target
            if self.attacking then

                if self.targetDirection then

                    local invFlameSentryCoords = self:GetAngles():GetCoords():GetInverse()
                    self.relativeTargetDirection = GetNormalizedVector( invFlameSentryCoords:TransformVector( self.targetDirection ) )
                    self.desiredYawDegrees = Clamp(math.asin(-self.relativeTargetDirection.x) * 180 / math.pi, -FlameSentry.kMaxYaw, FlameSentry.kMaxYaw)
                    self.desiredPitchDegrees = Clamp(math.asin(self.relativeTargetDirection.y) * 180 / math.pi, -FlameSentry.kMaxPitch, FlameSentry.kMaxPitch)

                end

                UpdateAttackEffects(self, deltaTime)

            -- Else when we have no target, swing it back and forth looking for targets
            else

                local sin = math.sin(math.rad((Shared.GetTime() + self:GetId() * .3) * FlameSentry.kBarrelScanRate))
                self.desiredYawDegrees = sin * self:GetFov() / 2

                -- Swing barrel pitch back to flat
                self.desiredPitchDegrees = 0

            end

            -- swing towards desired direction
            self.barrelPitchDegrees = Slerp(self.barrelPitchDegrees, self.desiredPitchDegrees, FlameSentry.kBarrelMoveRate * deltaTime)
            self.barrelYawDegrees = Slerp(self.barrelYawDegrees , self.desiredYawDegrees, FlameSentry.kBarrelMoveRate * deltaTime)

        end

    end

    -- function FlameSentry:OnKill(damage, attacker, doer, point, direction)
    --    if (Shared.GetCheatsEnabled()) then
    --       local params = {}
    --       params[kEffectHostCoords] = Coords.GetLookIn( self:GetOrigin(), self:GetCoords().zAxis )
    --       params[kEffectSurface] = "metal"

    --       self:TriggerEffects("grenade_explode", params)
    --       for _, ent in ipairs(GetEntitiesWithMixinWithinRange("Live", self:GetOrigin(), 8)) do
    --          if HasMixin(ent, "Live") and HasMixin(ent, "Fire") then
    --             ent:SetOnFire(ent, self)
    --          end
    --       end
    --    end
    --    if Sentry.OnKill then
    --       Sentry.OnKill(self, damage, attacker, doer, point, direction)
    --    end
    -- end
end

-- TODO: conserver HP/AP when taking sentry
Shared.LinkClassToMap("FlameSentry", FlameSentry.kMapName, networkVars)

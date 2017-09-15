-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Flamethrower_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http:--www.unknownworlds.com =====================

local kTrailLength = 8
local kImpactEffectRate = 0.3
local kSmokeEffectRate = 1.5
local kPilotEffectRate = 0.3

local kFlameImpactCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_impact3.cinematic")
local kFlameSmokeCinematic = PrecacheAsset("cinematics/marine/flamethrower/flame_trail_light.cinematic")
local kPilotCinematicName = PrecacheAsset("cinematics/marine/flamethrower/pilot.cinematic")

-- local kFirstPersonTrailCinematics =
--    {
--       PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part1.cinematic"),
--       PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic"),
--       PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic"),
--       PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part2.cinematic"),
--       PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part3.cinematic"),
--       PrecacheAsset("cinematics/marine/flamethrower/flame_trail_1p_part3.cinematic"),
--    }

local kTrailCinematics =
   {
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part1.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part3.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_trail_part3.cinematic"),
   }

local kFadeOutCinematicNames =
   {
      PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part1.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part2.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic"),
      PrecacheAsset("cinematics/marine/flamethrower/flame_residue_1p_part3.cinematic"),
   }

local function UpdateSound(self)

   -- Only update when held in inventory
   if self.loopingSoundEntId ~= Entity.invalidId and self.def_old_owner ~= nil then

      local player = Client.GetLocalPlayer()
      local viewAngles = player:GetViewAngles()
      local yaw = viewAngles.yaw

      local soundEnt = Shared.GetEntity(self.loopingSoundEntId)
      if soundEnt then

         if soundEnt:GetIsPlaying() and self.lastYaw ~= nil then

            -- 180 degree rotation = param of 1
            local rotateParam = math.abs((yaw - self.lastYaw) / math.pi)

            -- Use the maximum rotation we've set in the past short interval
            if not self.maxRotate or (rotateParam > self.maxRotate) then

               self.maxRotate = rotateParam
               self.timeOfMaxRotate = Shared.GetTime()

            end

            if self.timeOfMaxRotate ~= nil and Shared.GetTime() > self.timeOfMaxRotate + .75 then

               self.maxRotate = nil
               self.timeOfMaxRotate = nil

            end

            if self.maxRotate ~= nil then
               rotateParam = math.max(rotateParam, self.maxRotate)
            end

            soundEnt:SetParameter("rotate", rotateParam, 1)

         end

      else
         Print("FlameSentry:OnUpdate(): Couldn't find sound ent on client")
      end

      self.lastYaw = yaw

   end

end

function FlameSentry:OnUpdate(deltaTime)

   Entity.OnUpdate(self, deltaTime)

   UpdateSound(self)

end

function FlameSentry:ProcessMoveOnWeapon(input)

   Entity.ProcessMoveOnWeapon(self, input)

   UpdateSound(self)

end

function FlameSentry:OnProcessSpectate(deltaTime)

   Entity.OnProcessSpectate(self, deltaTime)

   UpdateSound(self)

end

local function _UpdatePilotEffect(self, visible)

   if visible then

      if not self.pilotCinematic then

         self.pilotCinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
         self.pilotCinematic:SetCinematic(kPilotCinematicName)
         self.pilotCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)

      end

      local viewModelEnt = self.def_old_owner:GetViewModelEntity()
      local renderModel = viewModelEnt and viewModelEnt:GetRenderModel()

      if renderModel then

         local attachPointIndex = viewModelEnt:GetAttachPointIndex(FlameSentry.kMuzzleNode)

         if attachPointIndex >= 0 then

            local attachCoords = viewModelEnt:GetAttachPointCoords(FlameSentry.kMuzzleNode)
            self.pilotCinematic:SetCoords(attachCoords)

         end

      end

   else

      if self.pilotCinematic then
         Client.DestroyCinematic(self.pilotCinematic)
         self.pilotCinematic = nil
      end

   end

end


local kEffectType = enum({'FirstPerson', 'ThirdPerson', 'None'})

function FlameSentry:OnUpdateRender()


   if (self.light ~= nil) then
      self.light:SetIsVisible(true)
      self.light:SetCoords(
         Coords.GetLookIn(
            self:GetBarrelPoint(),
            self:GetLaserAttachCoords().zAxis))
      -- self:GetOrigin(),
      -- self:GetCoords().zAxis))
      self.lightTimer = Shared.GetTime()
   else

      self.light = Client.CreateRenderLight()

      self.light:SetType( RenderLight.Type_Spot )
      self.light:SetColor( Color(.8, .8, 1) )
      self.light:SetInnerCone( math.rad(7) )
      self.light:SetOuterCone( math.rad(14) )
      self.light:SetIntensity( 20 )
      self.light:SetRadius( 22 )
      self.light:SetGoboTexture("models/marine/male/flashlight.dds")

      self.light:SetIsVisible(false)
   end

   -- Entity.OnUpdateRender(self)
   local parent = self.def_old_owner--self:GetOwner()
   local localPlayer = Client.GetLocalPlayer()

   -- if parent and parent:GetIsLocalPlayer() then
      -- local viewModel = parent:GetViewModelEntity()
      -- if viewModel and viewModel:GetRenderModel() then
      --     viewModel:InstanceMaterials()
      --     viewModel:GetRenderModel():SetMaterialParameter("heatAmount" .. self:GetExoWeaponSlotName(), self.heatAmount)
      -- end

      -- local heatDisplayUI = self.heatDisplayUI
      -- if not heatDisplayUI then
      --     heatDisplayUI = Client.CreateGUIView(242, 720)
      --     heatDisplayUI:Load("lua/ModularExo_GUI" .. self:GetExoWeaponSlotName():gsub("^%l", string.upper) .. "FlamerDisplay.lua")
      --     heatDisplayUI:SetTargetTexture("*exo_railgun_" .. self:GetExoWeaponSlotName())
      --     self.heatDisplayUI = heatDisplayUI
      -- end
      -- heatDisplayUI:SetGlobal("heatAmount" .. self:GetExoWeaponSlotName(), self.heatAmount)
   -- else
      -- if self.heatDisplayUI then
      --     Client.DestroyGUIView(self.heatDisplayUI)
      --     self.heatDisplayUI = nil
      -- end
   -- end

   local effectToLoad = (parent ~= nil and localPlayer ~= nil and parent == localPlayer and localPlayer:GetIsFirstPerson()) and kEffectType.FirstPerson or kEffectType.ThirdPerson
   if self.effectLoaded ~= effectToLoad then
      if self.trailCinematic then
         Client.DestroyTrailCinematic(self.trailCinematic)
         self.trailCinematic = nil
      end
      if effectToLoad ~= kEffectType.None then
         self:InitTrailCinematic(effectToLoad, parent)
      end
      self.effectLoaded = effectToLoad
   end
   if self.trailCinematic then
      self.trailCinematic:SetIsVisible(self.createParticleEffects == true and not self.confused)
      if self.createParticleEffects then
         self:CreateImpactEffect(self.def_old_owner)
      end
   end

   -- ------ Idle trail
   -- effectToLoad = (parent ~= nil and localPlayer ~= nil and parent == localPlayer and localPlayer:GetIsFirstPerson()) and kEffectType.FirstPerson or kEffectType.ThirdPerson
   -- if self.effectLoaded ~= effectToLoad then
   --    if self.idleTrailCinematic then
   --       Client.DestroyTrailCinematic(self.idleTrailCinematic)
   --       self.idleTrailCinematic = nil
   --    end
   --    if effectToLoad ~= kEffectType.None then
   --       self:InitIdleTrailCinematic(effectToLoad, parent)
   --    end
   --    self.effectLoaded = effectToLoad
   -- end
   -- if self.idleTrailCinematic then
   --    self.idleTrailCinematic:SetIsVisible(self.createParticleEffects == false)
   --    -- if self.createParticleEffects then
   --    --    self:CreateImpactEffect(self.def_old_owner)
   --    -- end
   -- end

   -- -- _UpdatePilotEffect(self, effectToLoad == kEffectType.FirstPerson and self.clip > 0 and self:GetIsActive())
end


function FlameSentry:InitTrailCinematic(effectType, player)

   self.trailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)

   local minHardeningValue = 0.5
   local numFlameSegments = 30

   if effectType == kEffectType.ThirdPerson then

      self.trailCinematic:SetCinematicNames(kTrailCinematics)

      self.trailCinematic:AttachTo(self, TRAIL_ALIGN_X,  Vector(0, 0, 0), self:GetAttachPointIndex(FlameSentry.kMuzzleNode))
   end

   self.trailCinematic:SetFadeOutCinematicNames(kFadeOutCinematicNames)
   self.trailCinematic:SetIsVisible(false)
   self.trailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
   self.trailCinematic:SetOptions( {
                                      numSegments = numFlameSegments,
                                      collidesWithWorld = true,
                                      visibilityChangeDuration = 0.2,
                                      fadeOutCinematics = true,
                                      stretchTrail = false,
                                      trailLength = kTrailLength,
                                      minHardening = minHardeningValue,
                                      maxHardening = 2,
                                      hardeningModifier = 0.8,
                                      trailWeight = 0.3
                                   } )


end

-- function FlameSentry:InitIdleTrailCinematic(effectType, player)

--    self.idleTrailCinematic = Client.CreateTrailCinematic(RenderScene.Zone_Default)

--    local minHardeningValue = 0.5
--    local numFlameSegments = 10

--    if effectType == kEffectType.ThirdPerson then

--       self.idleTrailCinematic:SetCinematicNames(kTrailCinematics)

--       self.idleTrailCinematic:AttachTo(self, TRAIL_ALIGN_X,  Vector(0, 0, 0), self:GetAttachPointIndex("fxnode_flamesentrymuzzle"))
--    end

--    self.idleTrailCinematic:SetFadeOutCinematicNames(kFadeOutCinematicNames)
--    self.idleTrailCinematic:SetIsVisible(false)
--    self.idleTrailCinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
--    self.idleTrailCinematic:SetOptions( {
--                                       numSegments = numFlameSegments,
--                                       collidesWithWorld = true,
--                                       visibilityChangeDuration = 0.2,
--                                       fadeOutCinematics = true,
--                                       stretchTrail = false,
--                                       trailLength = kTrailLength,
--                                       minHardening = minHardeningValue,
--                                       maxHardening = 2,
--                                       hardeningModifier = 0.8,
--                                       trailWeight = 0.2
--                                    } )


-- end

function FlameSentry:CreateImpactEffect(player)

   if (not self.timeLastImpactEffect or self.timeLastImpactEffect + kImpactEffectRate < Shared.GetTime()) and player then

      self.timeLastImpactEffect = Shared.GetTime()

      -- local viewAngles = player:GetViewAngles()
      -- local viewCoords = viewAngles:GetCoords()
      local viewCoords = Coords.GetLookIn(
         self:GetBarrelPoint(),
         self:GetLaserAttachCoords().zAxis)--viewAngles:GetCoords()


      viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * (-0.4) + viewCoords.xAxis * (-0.2)
      local endPoint = self:GetBarrelPoint(player) + viewCoords.xAxis * (-0.2) + viewCoords.yAxis * (-0.3) + viewCoords.zAxis * self:GetRange()

      local trace = Shared.TraceRay(viewCoords.origin, endPoint, CollisionRep.Default, PhysicsMask.Flame, EntityFilterAll())

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

         Shared.CreateEffect(nil, kFlameImpactCinematic, nil, normalCoords)

      end

   end

end

--[[ disabled, causes bad performance
   function FlameSentry:CreateSmokeEffect(player)

   if not self.timeLastLightningEffect or self.timeLastLightningEffect + kSmokeEffectRate < Shared.GetTime() then

   self.timeLastLightningEffect = Shared.GetTime()

   local viewAngles = player:GetViewAngles()
   local viewCoords = viewAngles:GetCoords()

   viewCoords.origin = self:GetBarrelPoint(player) + viewCoords.zAxis * 1 + viewCoords.xAxis * (-0.4) + viewCoords.yAxis * (-0.3)

   local cinematic = kFlameSmokeCinematic

   local effect = Client.CreateCinematic(RenderScene.Zone_Default)
   effect:SetCinematic(cinematic)
   effect:SetCoords(viewCoords)

   end

   end
]]

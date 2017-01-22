local cameraDistance = 0.01 -- leave this very low
local cameraFractionLagTime = 0.2 --  how long the camera stays at a "zoomed in" state once it's forced closer
local cameraFractionZoomSpeed = 20.0 -- how fast the camera can zoom back out
local cameraSize = 0.05 -- radius of how big the "feeler" is to see if a camera fits
local aimingDistanceMax = 50 -- how far the player can "aim" before we give up

function Alien:GetThirdPersonOffset()
  return Vector(0,0.5,-2.0) -- only default
end
function Alien:GetFirstPersonFov()
  return Client.GetEffectiveFov(self)
end
function Alien:GetThirdPersonFov()
  return kDefaultFov
end
function Alien:GetTooCloseDistance()
  return 0.6
end
function Alien:NeedsCrosshairOverride()
  return true
end


function Alien:GetThirdPersonViewOffset(origin)
    if not origin then
      origin = self:GetOrigin()
    end
    if self:GetIsThirdPerson() then 
        
        local _time = Shared.GetTime()
        if not self.cameraFraction then
          self.cameraFraction = 1
        end 
        if not self.cameraFractionTime then
          self.cameraFractionTime = _time
        end
        
        -- override the origin of the camera
        origin = self:GetEyePos()
        
        --gotta find a spot that actually fits the camera
        local cameraSizeOffset = Vector(0, cameraSize * 0.5, 0)
        local position = Vector(0, 0, 0)
        local viewCoords = self:GetViewAngles():GetCoords().zAxis   
        local viewDirection = GetNormalizedVector( viewCoords)
        local viewSideDirection = GetNormalizedVector( self:GetViewAngles():GetCoords().xAxis )
        local offset3rd = self:GetThirdPersonOffset()
        local offset = self:GetCoords().yAxis * offset3rd.y + viewDirection * offset3rd.z + viewSideDirection * offset3rd.x
        local startPoint = origin + cameraSizeOffset
        local endPoint = origin + offset + cameraSizeOffset
        local trace = Shared.TraceCapsule(startPoint, endPoint, cameraSize, 0, CollisionRep.LOS, PhysicsMask.Movement, EntityFilterAll())
        
        
        local deltaTime = _time - self.cameraFractionTime
        local fraction = Clamp(self.cameraFraction + deltaTime/cameraFractionZoomSpeed, self.cameraFraction, trace.fraction)
        
        if trace.fraction <= self.cameraFraction then
          self.cameraFractionTime = _time + cameraFractionLagTime
          self.cameraFraction = trace.fraction
          fraction = trace.fraction
        else
          self.cameraFraction = fraction
        end
        
        return origin + offset * fraction
    end
    return origin
end

-- this is huge. we override WHERE OUR CAMERA POINTS when we are in 3rd person
function Alien:GetLookingCoords()
    local origCoords = self:GetViewCoords() 
    if self:GetIsThirdPerson() then
    
        local origin = self:GetEyePos()
        local thirdPersonPos = self:GetThirdPersonViewOffset(origin)
        local offset = self:GetViewAngles():GetCoords().zAxis  * aimingDistanceMax
        local startPoint = thirdPersonPos
        local endPoint =   thirdPersonPos + offset
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.LOS, PhysicsMask.Movement, EntityFilterOne(player))
        
        if trace.fraction < 0.01 then
          return origCoords
        end
        
        local lookedAtPoint = trace.endPoint
        
        local cameraCoords = Coords.GetLookIn(origCoords.origin,  GetNormalizedVector(lookedAtPoint - origCoords.origin))
        cameraCoords.origin = self:GetEyePos()
        return cameraCoords
    end
    return origCoords
end

function Alien:Reload()

  if not self.reloadTime or Shared.GetTime() - self.reloadTime > 0.3 then
    if self:GetIsThirdPerson() then
      self.wantsThirdperson = false
    else
      self.wantsThirdperson = true
      self.cameraFraction = 0.1
      self.cameraFractionTime = Shared.GetTime()
    end 
    self.reloadTime = Shared.GetTime()
  end
  
end

function Alien:OnPostUpdateCamera(deltaTime)
  if self.GetIsThirdPerson and self:GetIsThirdPerson() then 
    if self:GetThirdPersonViewOffset():GetLength() < self:GetTooCloseDistance() then
      self:SetOpacity(0,"cloak")
    end
  end
end



function Alien:PlayerCameraCoordsAdjustment(cameraCoords)
    local origOrigin = cameraCoords.origin
    local newOrigin = self:GetThirdPersonViewOffset(origOrigin)
    
    if (origOrigin - newOrigin):GetLength() < self:GetTooCloseDistance() then
      self:SetOpacity(0,"cloak")
    end
    
    cameraCoords.origin = newOrigin
    return  cameraCoords

end


local originalOnUpdateAnimationInput = Alien.OnUpdateAnimationInput
function Alien:OnUpdateAnimationInput(modelMixin)
    originalOnUpdateAnimationInput(self, modelMixin)
    
    if self.wantsThirdperson then 
      self:SetCameraDistance(cameraDistance)
      self:SetFov(self:GetThirdPersonFov())
    else
      self:SetCameraDistance(0)
      self:SetFov(self:GetFirstPersonFov())
    end
end

local origOnDestroy = Alien.OnDestroy
function Alien:OnDestroy()
    if Client then
      self:SetCameraDistance(0)
      self:SetFov(self:GetFirstPersonFov())
    end
    origOnDestroy(self)
end

function Alien:GetAnimateDeathCamera()
  if self.GetIsThirdPerson and self:GetIsThirdPerson() then 
    return false
  end
  return true
end

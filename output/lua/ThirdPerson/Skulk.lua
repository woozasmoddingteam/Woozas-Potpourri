
local kLeapVerticalForce = 10.8
local kLeapTime = 0.2
local kLeapForce = 7.6

Skulk.kMaxSneakOffset = 0.55 --0.55 was the original number. Return of the sneaky skulks!

function Skulk:GetThirdPersonOffset()
  local z = -1.5 - self:GetVelocityLength() / self:GetMaxSpeed(true) * 0.4
  return Vector(0, 0.9, z) 
end

function Skulk:GetFirstPersonFov()
  return kSkulkFov
end

-- Tilt the camera based on the wall the Skulk is attached to.
function Skulk:PlayerCameraCoordsAdjustment(cameraCoords)
    
    local viewModelTiltAngles = Angles()
    viewModelTiltAngles:BuildFromCoords(Alien.PlayerCameraCoordsAdjustment(self, cameraCoords))

    if self.currentCameraRoll then
        viewModelTiltAngles.roll = viewModelTiltAngles.roll + self.currentCameraRoll
    end

    local viewModelTiltCoords = viewModelTiltAngles:GetCoords()
    viewModelTiltCoords.origin = cameraCoords.origin

    return viewModelTiltCoords

end


-- fix leaping into ground (more of a problem now that we are third person)
local originalOnLeap = Skulk.OnLeap
function Skulk:OnLeap()
    local velocity = self:GetVelocity() * 0.5
    local forwardVec = self:GetViewAngles():GetCoords().zAxis
     -- don't jump into the ground, ya dummy
    if not self:GetCanWallJump() and forwardVec.y < 0 then
      forwardVec.y = 0
    end
    
    local newVelocity = velocity + GetNormalizedVectorXZ(forwardVec) * kLeapForce
    
    local forwardY = forwardVec.y
    
    -- Add in vertical component.
    newVelocity.y = kLeapVerticalForce * forwardY + kLeapVerticalForce * 0.5 + ConditionalValue(velocity.y < 0, velocity.y, 0)
    
    self:SetVelocity(newVelocity)
    
    self.leaping = true
    self.wallWalking = false
    self:DisableGroundMove(0.2)
    
    self.timeOfLeap = Shared.GetTime()
end


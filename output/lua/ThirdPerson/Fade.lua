
function Fade:GetThirdPersonOffset()
  local z = -1.1 - self:GetVelocityLength() / self:GetMaxSpeed(true) * 0.6
  local y = 0.5
  if self.GetCrouchAmount then
    y = y + self:GetCrouchAmount() *0.4
  end
  return Vector(0, y, z) 
end

function Fade:GetFirstPersonFov()
  return kFadeFov
end

function Fade:GetEyePos()
  return self:GetOrigin() + self.viewOffset + Vector(0, self.cameraYOffset, 0)
end


function Gorge:GetThirdPersonOffset()
  local z = -1.8 - self:GetVelocityLength() / self:GetMaxSpeed(true) * 0.4
  return Vector(0, 0.9, z) 
end

function Gorge:GetFirstPersonFov()
  return kGorgeFov
end

function Gorge:GetTooCloseDistance()
  return 0.8
end
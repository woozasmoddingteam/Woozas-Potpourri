
function Lerk:GetThirdPersonOffset()
  local z = -1.0 - self:GetVelocityLength() / self:GetMaxSpeed(false) * 0.5
  return Vector(0, 0.9, z) 
end

function Lerk:GetFirstPersonFov()
  return kLerkFov
end


-- Tilt the camera based on the wall the Lerk is attached to.
function Lerk:PlayerCameraCoordsAdjustment(cameraCoords)
    
    local viewModelTiltAngles = Angles()
    viewModelTiltAngles:BuildFromCoords(Alien.PlayerCameraCoordsAdjustment(self, cameraCoords))

    if self.currentCameraRoll and Client.GetOptionBoolean("CameraAnimation", false) then
        viewModelTiltAngles.roll = viewModelTiltAngles.roll + self.currentCameraRoll
    end

    local viewModelTiltCoords = viewModelTiltAngles:GetCoords()
    viewModelTiltCoords.origin = cameraCoords.origin

    return viewModelTiltCoords

end


local kMaxGlideRoll = math.rad(30)
function Lerk:GetDesiredAngles()

    if self:GetIsWallGripping() then
        return self:GetAnglesFromWallNormal( self.wallGripNormalGoal )
    end

    local desiredAngles = Alien.GetDesiredAngles(self)

    if not self:GetIsOnGround() and not self:GetIsWallGripping() then   
        if self.gliding then
            desiredAngles.pitch = self.viewPitch
        end 
        local diff = RadianDiff( self:GetAngles().yaw, self.viewYaw )
        diff = math.atan2(math.sin(diff), math.cos(diff))
        if math.abs(diff) < 0.001 then
            diff = 0
        end
        desiredAngles.roll = Clamp( diff, -kMaxGlideRoll, kMaxGlideRoll)   
        -- Log("%s: yaw %s, viewYaw %s, diff %s, roll %s", self, self:GetAngles().yaw, self.viewYaw , diff, desiredAngles.roll)
    end
    
    return desiredAngles

end
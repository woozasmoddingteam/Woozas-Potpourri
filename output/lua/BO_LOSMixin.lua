
if (Server) then
   local BO_LOS_delay = 3
   -- this causes an issue: when the distance is too big (going to ready room, moving through phase gate) MarkNearbyDirty(self) will miss previous revealed entities.
   local LOSMixinSetOrigin = LOSMixin.SetOrigin
   function LOSMixin:SetOrigin(origin)

      if (not self.BO_beaconTime or self.BO_beaconTime + BO_LOS_delay < Shared.GetTime()) then
         return LOSMixinSetOrigin(self, origin)
      end
      return
   end

   local LOSMixinOnUpdate = LOSMixin.OnUpdate
   function LOSMixin:OnUpdate(deltaTime)
      if (not self.BO_beaconTime or self.BO_beaconTime + BO_LOS_delay < Shared.GetTime()) then
         LOSMixinOnUpdate(self, deltaTime)
      end
   end

   local LOSMixinOnProcessMove = LOSMixin.OnProcessMove
   function LOSMixin:OnProcessMove(input)
      if (not self.BO_beaconTime or self.BO_beaconTime + BO_LOS_delay < Shared.GetTime()) then
         LOSMixinOnProcessMove(self, input)
      end
   end

end

local function EnableOnUpdateIfNearby(self)
   local webables = GetEntitiesWithMixinForTeamWithinRange("Webable", GetEnemyTeamNumber(self:GetTeamNumber()),
                                                           self:GetOrigin(), 6)

   if (webables and #webables > 0) then
      if (not self.BO_update_state) then
         self.BO_update_state = true
         self:SetUpdates(true)
      end
   else
      if (self.BO_update_state) then
         self.BO_update_state = false
         self:SetUpdates(false)
      end
   end
   return true
end

local webOnCreate = Web.OnCreate
function Web:OnCreate()
   webOnCreate(self)
   self:AddTimedCallback(EnableOnUpdateIfNearby, 0.5)
end

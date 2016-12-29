if (Server) then
   -- local ClogOnClogFallDone = Clog.OnClogFallDone
   -- function Clog:OnClogFallDone(parentId, surfaceNormal)
   --    local ret = nil

   --    if (ClogOnClogFallDone) then
   --       ret = ClogOnClogFallDone(self, parentId, surfaceNormal)
   --    end
   --    Log("Clog:OnClogFallDone -> SetUpdates(false) for clog " .. tostring(self:GetId()))
   --    self:SetUpdates(false)
   --    return ret
   -- end

   local function clogDisableUpdates(self)
      if (self and self:isa("Clog") and self:GetIsAlive()) then
         if (not self.isClogFalling) then
            -- Log("Clog:OnCreate() -> SetUpdates(false) for clog " .. tostring(self:GetId()))
            self:SetUpdates(false)
         end
      end
      return
   end

   local ClogOnCreate = Clog.OnCreate
   function Clog:OnCreate()
      ClogOnCreate(self)
      -- For the case where we create a clog on a chain connected with the first one (who get killed)
      Entity.AddTimedCallback(self, clogDisableUpdates, 10)
   end
end

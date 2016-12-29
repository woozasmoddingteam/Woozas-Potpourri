if (Server) then

   -- local function clogDisableOnUpdate(clog)
   --    if (clog and clog:isa("Clog") and clog:GetIsAlive() and ) then
   --       clog:SetUpdates(false)
   --       Log("clog:SetUpdates(false) for clog " .. tostring(clog:GetId()))
   --    end
   --    return
   -- end

   local function clogFallMixin_recur_setUpdates(ent)
      if (ent and ent.BO_clog_updated ~= true) then -- Safety
         if (ent:isa("Clog")) then
            ent:SetUpdates(true)
            -- Log("ClogFallMixin:OnDestroy() -> clog:SetUpdates(true) for clog " .. tostring(ent:GetId()))
         end

         ent.BO_clog_updated = true
         for _, attachedId in ipairs(ent.attachedClogIds) do
            local entity = Shared.GetEntity(attachedId)
            if entity and HasMixin(entity, "ClogFall") then
               clogFallMixin_recur_setUpdates(entity)
            end
         end
         ent.BO_clog_updated = nil
      end
   end

   local ClogFallMixinOnDestroy = ClogFallMixin.OnDestroy
   function ClogFallMixin:OnDestroy()
      -- Log("ClogFallMixin:OnDestroy() called for clog " .. tostring(self:GetId()))

      -- local ents = GetEntitiesForTeam("Clog", self:GetTeamNumber())
      -- for _, ent in ipairs(ents) do
      --    -- ent:SetUpdates(true)
      --    Log("ClogFallMixin:OnDestroy() -> clog:SetUpdates(true) for clog " .. tostring(ent:GetId()))
      -- end

      clogFallMixin_recur_setUpdates(self)
      local ret = ClogFallMixinOnDestroy(self)
      return ret
   end

   -- local ClogFallMixinOnUpdate = ClogFallMixin.OnUpdate
   -- function ClogFallMixin:OnUpdate(deltaTime)
   --    if (ClogFallMixinOnUpdate) then
   --       ClogFallMixinOnUpdate(self, deltaTime)
   --    end
   --    if (self:isa("Clog") and not self.isClogFalling) then
   --       self:SetUpdates(false)
   --       Log("ClogFallMixinOnUpdate: -> SetUpdates(false) for clog " .. tostring(self:GetId()))
   --    end
   -- end

end

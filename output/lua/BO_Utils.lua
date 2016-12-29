if (Server) then
   function BO_ResetRelevancyMask(self)
      if (self and self.UpdateIncludeRelevancyMask) then
         self:UpdateIncludeRelevancyMask()
      end
      if (self and self:isa("Weapon") and self.SetIncludeRelevancyMask) then
         self:SetIncludeRelevancyMask(0)
      end
      if (self and self:isa("Weapon") and self.SetRelevancy) then
         self:SetRelevancy(false)
      end
      return
   end

   function BO_SetIncludeRelevancyMask(self)
      local mask = self.BO_relevancy_mask

      self.BO_relevancy_mask = nil
      if (self and mask and self.SetIncludeRelevancyMask) then
         self:SetIncludeRelevancyMask(mask)
      end
      return
   end
end

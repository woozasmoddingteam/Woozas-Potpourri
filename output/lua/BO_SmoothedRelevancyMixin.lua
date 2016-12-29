-- turn it off by setting to zero. global to make it easy to hotload-console it
SmoothedRelevancyMixin.kTimeToMax = 1.4--0.7
SmoothedRelevancyMixin.kMaxShrink = kMaxRelevancyDistance - 5

-- BO: added constant
SmoothedRelevancyMixin.kMinDistInstanstRelePercent = 0.1 -- 0.5

if (Server) then
   local function UpdateRelevancy(self)

      if self.smoothedRelevancyStart then

         local dt = Shared.GetTime() - self.smoothedRelevancyStart
         if SmoothedRelevancyMixin.kTimeToMax > 0 then
            local fraction = 1 - math.min(1, dt / SmoothedRelevancyMixin.kTimeToMax)
            local relevancyDecrease = SmoothedRelevancyMixin.kMaxShrink * fraction
            self:ConfigureRelevancy(Vector.origin, -relevancyDecrease)
         end
         if dt >= SmoothedRelevancyMixin.kTimeToMax then
            self.smoothedRelevancyStart = nil
         end
      end

      -- stop the callback if we are no longer in need of smoothing
      return nil ~= self.smoothedRelevancyStart

   end

   function SmoothedRelevancyMixin:StartSmoothedRelevancy(destinationOrigin)

      if not self.smootherRelevancyStart then
         -- should be slightly shorter than the server tick rate in order to be
         -- sure to be called at least once every network update
         self:AddTimedCallback(UpdateRelevancy, 0.024)
      end

      self.smoothedRelevancyStart = Shared.GetTime()

      if destinationOrigin then
         -- if we are jumping to a close target pos, don't shrink target relevancy
         -- as much - that way, we don't loose/reload as many entities
         -- we use a simple formula - at 1.5 max relevancy distance, we loose all.
         -- at 0.5 max relevancy distance, we don't shrink any, and linear in between
         local dist = (self:GetOrigin() - destinationOrigin):GetLength()
         local alreadyDoneFrac = Clamp(1 - (dist - SmoothedRelevancyMixin.kMinDistInstanstRelePercent * kMaxRelevancyDistance) / kMaxRelevancyDistance, 0, 1)
         -- we increase our starting relevancy by pretending we started earlier
         self.smoothedRelevancyStart = self.smoothedRelevancyStart - alreadyDoneFrac * SmoothedRelevancyMixin.kTimeToMax
      end

      UpdateRelevancy(self)

   end
end

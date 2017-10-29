local GetDistance

debug.replaceupvalue(Web.UpdateWebOnProcessMove, "CheckForIntersection", function(self, fromPlayer)

	if not self.endPoint then
		self.endPoint = self:GetOrigin() + self.length * self:GetCoords().zAxis
	end

	if fromPlayer then

		-- need to manually check for intersection here since the local players physics are invisible and normal traces would fail
		local playerOrigin = fromPlayer:GetOrigin()
		local extents = fromPlayer:GetExtents()
		local fromWebVec = playerOrigin - self:GetOrigin()
		local webDirection = -self:GetCoords().zAxis
		local dotProduct = webDirection:DotProduct(fromWebVec)

		local minDistance = - extents.z
		local maxDistance = self.length + extents.z

		if dotProduct >= minDistance and dotProduct < maxDistance then

			local horizontalDistance, verticalDistance = GetDistance(self, fromPlayer)

			local horizontalOk = horizontalDistance <= extents.z
			local verticalOk = verticalDistance >= 0 and verticalDistance <= extents.y * 2

			--DebugPrint("horizontalDistance %s  verticalDistance %s", ToString(horizontalDistance), ToString(verticalDistance))

			if horizontalOk and verticalOk then

				fromPlayer:SetWebbed(kWebbedDuration)

				--FIXME Web seems to not have Owner applied, because this is running in ProcessMove
				--	Owner only accessible on ServerVM ...
				if HasMixin( fromPlayer, "ParasiteAble" ) and HasMixin( self, "Owner" ) then
					--TODO Modify ParasiteMixin to specify a duration
					local WebOwner = self:GetOwner() or nil
					fromPlayer:SetParasited( WebOwner, kWebbedParasiteDuration )
				end

			end

		end

	elseif Server then

		local trace = Shared.TraceRay(self:GetOrigin(), self.endPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterNonWebables())
		if trace.entity and not trace.entity:isa("Player") then
			trace.entity:SetWebbed(kWebbedDuration)
		end

	end

end)

debug.replacemethod("Web", "ModifyDamageTaken", function(self, damageTable, attacker, doer, damageType, hitPoint)
	if damageType ~= kDamageType.Flame then
		damageTable.damage = 0
	end
	if doer ~= nil and (doer:isa "ClusterGrenade" or doer:isa "ClusterFragment") then
		damageTable.damage = damageTable.damage * 0.1
	end
end)

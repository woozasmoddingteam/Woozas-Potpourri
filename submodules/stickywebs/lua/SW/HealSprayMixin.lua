local kHealCylinderWidth, kRange, GetEntitiesInCylinder

debug.replaceupvalue(HealSprayMixin.OnTag, "GetEntitiesInCone", function(self, player)
	local range = 0

	local viewCoords = player:GetViewCoords()
	local fireDirection = viewCoords.zAxis

	local startPoint = viewCoords.origin + viewCoords.yAxis * kHealCylinderWidth * 0.2
	local lineTrace1 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Flame, EntityFilterAll())
	if (lineTrace1.endPoint - startPoint):GetLength() > range then
		range = (lineTrace1.endPoint - startPoint):GetLength()
	end

	startPoint = viewCoords.origin - viewCoords.yAxis * kHealCylinderWidth * 0.2
	local lineTrace2 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Flame, EntityFilterAll())
	if (lineTrace2.endPoint - startPoint):GetLength() > range then
		range = (lineTrace2.endPoint - startPoint):GetLength()
	end

	startPoint = viewCoords.origin - viewCoords.xAxis * kHealCylinderWidth * 0.2
	local lineTrace3 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Flame, EntityFilterAll())
	if (lineTrace3.endPoint - startPoint):GetLength() > range then
		range = (lineTrace3.endPoint - startPoint):GetLength()
	end

	startPoint = viewCoords.origin + viewCoords.xAxis * kHealCylinderWidth * 0.2
	local lineTrace4 = Shared.TraceRay(startPoint, startPoint + kRange * fireDirection, CollisionRep.LOS, PhysicsMask.Flame, EntityFilterAll())
	if (lineTrace4.endPoint - startPoint):GetLength() > range then
		range = (lineTrace4.endPoint - startPoint):GetLength()
	end

	return GetEntitiesInCylinder(self, player, viewCoords, range, kHealCylinderWidth)
end)

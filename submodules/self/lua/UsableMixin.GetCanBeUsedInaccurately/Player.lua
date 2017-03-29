local function getLocal(f, n)
	local index = 1;
	while assert(debug.getupvalue(f, index)) ~= n do
		index = index + 1;
	end
	local n, v = debug.getupvalue(f, index); -- This n is the same as the previous n
	return v;
end

local kUseBoxSize = getLocal(Player.PerformUseTrace, "kUseBoxSize");
local kDownwardUseRange = getLocal(Player.PerformUseTrace, "kDownwardUseRange");
local GetIsValidUseOfPoint = getLocal(Player.PerformUseTrace, "GetIsValidUseOfPoint");
local GetCanEntityBeUsedWithNoUsablePoint = getLocal(Player.PerformUseTrace, "GetCanEntityBeUsedWithNoUsablePoint");

local function GetCanBeUsedInaccurately(self, ent)
	if HasMixin(ent, "Usable") and ent.GetCanBeUsedInaccurately then
		local t = {b = true};
		ent:GetCanBeUsedInaccurately(self, t);
		return t.b;
	else
		return false;
	end
end

function Player:PerformUseTrace()

    local startPoint = self:GetEyePos()
    local viewCoords = self:GetViewAngles():GetCoords()

    -- To make building low objects like an infantry portal easier, increase the use range
    -- as we look downwards. This effectively makes use trace in a box shape when looking down.
    local useRange = kPlayerUseRange
    local sinAngle = viewCoords.zAxis:GetLengthXZ()
    if viewCoords.zAxis.y < 0 and sinAngle > 0 then

        useRange = kPlayerUseRange / sinAngle
        if -viewCoords.zAxis.y * useRange > kDownwardUseRange then
            useRange = kDownwardUseRange / -viewCoords.zAxis.y
        end

    end

    -- Get possible useable entities within useRange that have an attach point.
    local ents = GetEntitiesWithMixinWithinRange("Usable", self:GetOrigin(), useRange)
    for e = 1, #ents do

        local entity = ents[e]
        -- Filter away anything on the enemy team. Allow using entities not on any team.
        if (not HasMixin(entity, "Team") or self:GetTeamNumber() == entity:GetTeamNumber()) and GetCanBeUsedInaccurately(self, entity) then

            local usablePoints = entity:GetUsablePoints()
            if usablePoints then

                for p = 1, #usablePoints do

                    local usablePoint = usablePoints[p]
                    local success = GetIsValidUseOfPoint(self, entity, usablePoint, useRange)
                    if success then
                        return entity, usablePoint
                    end

                end

            end

        end

    end

    -- If failed, do a regular trace with entities that don't have usable points.
    local viewCoords = self:GetViewAngles():GetCoords()
    local endPoint = startPoint + viewCoords.zAxis * useRange
    local activeWeapon = self:GetActiveWeapon()

    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdollsAndBabblers, EntityFilterTwo(self, activeWeapon))

    if trace.fraction < 1 and trace.entity ~= nil then

        -- Only return this entity if it can be used and it does not have a usable point (which should have been
        -- caught in the above cases).
        if GetCanEntityBeUsedWithNoUsablePoint(self, trace.entity) then
            return trace.entity, trace.endPoint
        end

    end

    -- Called in case the normal trace fails to allow some tolerance.
    -- Modify the endPoint to account for the size of the box.
    local maxUseLength = (kUseBoxSize - -kUseBoxSize):GetLength()
    endPoint = startPoint + viewCoords.zAxis * (useRange - maxUseLength / 2)
    local traceBox = Shared.TraceBox(kUseBoxSize, startPoint, endPoint, CollisionRep.Move, PhysicsMask.AllButPCsAndRagdollsAndBabblers, EntityFilterTwo(self, activeWeapon))
    -- Only return this entity if it can be used and it does not have a usable point (which should have been caught in the above cases).
    if traceBox.fraction < 1 and traceBox.entity ~= nil and GetCanBeUsedInaccurately(self, traceBox.entity) and GetCanEntityBeUsedWithNoUsablePoint(self, traceBox.entity) then

        local direction = startPoint - traceBox.entity:GetOrigin()
        direction:Normalize()

        -- Must be generally facing the entity.
        if viewCoords.zAxis:DotProduct(direction) < -0.5 then
            return traceBox.entity, traceBox.endPoint
        end

    end

    return nil, Vector(0, 0, 0)

end

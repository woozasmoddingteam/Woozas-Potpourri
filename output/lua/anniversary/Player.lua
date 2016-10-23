local kUseBoxSize = Vector(0.5, 0.5, 0.5)
local kDownwardUseRange = 2.2


local function GetIsValidUseOfPoint(self, entity, usablePoint, useRange)

    if GetPlayerCanUseEntity(self, entity) then

        local viewCoords = self:GetViewAngles():GetCoords()
        local toUsePoint = usablePoint - self:GetEyePos()

        return toUsePoint:GetLength() < useRange and viewCoords.zAxis:DotProduct(GetNormalizedVector(toUsePoint)) > 0.8

    end

    return false

end

--[[
    Will return true if the passed in entity can be used by self and
    the entity has no attach points to use.
]]
local function GetCanEntityBeUsedWithNoUsablePoint(self, entity)

    if HasMixin(entity, "Usable") then

        -- Ignore usable points if a Structure has not been built.
        local usablePointOverride = HasMixin(entity, "Construct") and not entity:GetIsBuilt()

        local usablePoints = entity:GetUsablePoints()
        if usablePointOverride or (not usablePoints or #usablePoints == 0) and GetPlayerCanUseEntity(self, entity) then
            return true, nil
        end

    end

    return false, nil

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
        if not HasMixin(entity, "Team") or self:GetTeamNumber() == entity:GetTeamNumber() then

            local usablePoints = entity:GetUsablePoints()
            if usablePoints then

                for p = 1, #usablePoints do

                    local usablePoint = usablePoints[p]
                    local success = GetIsValidUseOfPoint(self, entity, usablePoint, useRange)
                    if success then
						--Shared.Message("Success with usable points! Entity: " .. debug.typename(entity));
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

    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))

    if trace.fraction < 1 and trace.entity ~= nil then

        -- Only return this entity if it can be used and it does not have a usable point (which should have been
        -- caught in the above cases).
        if GetCanEntityBeUsedWithNoUsablePoint(self, trace.entity) then
			--Shared.Message("Success with no usable points! Entity: " .. debug.typename(trace.entity));
            return trace.entity, trace.endPoint
        end

    end

    -- Called in case the normal trace fails to allow some tolerance.
    -- Modify the endPoint to account for the size of the box.
    local maxUseLength = (kUseBoxSize - -kUseBoxSize):GetLength()
    endPoint = startPoint + viewCoords.zAxis * (useRange - maxUseLength / 2)
    local traceBox = Shared.TraceBox(kUseBoxSize, startPoint, endPoint, CollisionRep.Move, PhysicsMask.AllButPCs, EntityFilterTwo(self, activeWeapon))
    -- Only return this entity if it can be used and it does not have a usable point (which should have been caught in the above cases).
	local entity = traceBox.entity;
    if traceBox.fraction < 1 and entity ~= nil and not entity:isa("SecretGorge") and GetCanEntityBeUsedWithNoUsablePoint(self, entity) then

        local direction = startPoint - entity:GetOrigin()
        direction:Normalize()

        -- Must be generally facing the entity.
        if viewCoords.zAxis:DotProduct(direction) < -0.5 then
			--Shared.Message("Success with no usable points and extended tolerance! Entity: " .. debug.typename(entity));
            return entity, traceBox.endPoint
        end

    end

    return nil, Vector(0, 0, 0)

end

-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory_Server.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local function OnDeploy(self)

    self.deployed = true
    return false

end

local kDeployTime = 3

function WoozArmory:OnConstructionComplete()
	Shared.Message("WoozArmory built");
    self:AddTimedCallback(OnDeploy, kDeployTime)
end

-- west/east = x/-x
-- north/south = -z/z

local indexToUseOrigin =
{
    -- West
    Vector(Armory.kResupplyUseRange, 0, 0),
    -- North
    Vector(0, 0, -Armory.kResupplyUseRange),
    -- South
    Vector(0, 0, Armory.kResupplyUseRange),
    -- East
    Vector(-Armory.kResupplyUseRange, 0, 0)
}

function WoozArmory:UpdateLoggedIn()
	Shared.Message("DEBUG: WoozArmory:UpdateLoggedIn");

    local players = GetEntitiesForTeamWithinRange("Marine", self:GetTeamNumber(), self:GetOrigin(), 2 * Armory.kResupplyUseRange)
    local armoryCoords = self:GetAngles():GetCoords()

    for i = 1, 4 do

        local newState = false

        if GetIsUnitActive(self) then

            local worldUseOrigin = self:GetModelOrigin() + armoryCoords:TransformVector(indexToUseOrigin[i])

            for playerIndex, player in ipairs(players) do

                -- See if valid player is nearby
                local isPlayerVortexed = HasMixin(player, "VortexAble") and player:GetIsVortexed()
                if not isPlayerVortexed and player:GetIsAlive() and (player:GetModelOrigin() - worldUseOrigin):GetLength() < Armory.kResupplyUseRange then

                    newState = true
                    break

                end

            end

        end

        if newState ~= self.loggedInArray[i] then

            if newState then
                self:TriggerEffects("armory_open")
            else
                self:TriggerEffects("armory_close")
            end

            self.loggedInArray[i] = newState

        end

    end

    -- Copy data to network variables (arrays not supported)
    self.loggedInWest = self.loggedInArray[1]
    self.loggedInNorth = self.loggedInArray[2]
    self.loggedInSouth = self.loggedInArray[3]
    self.loggedInEast = self.loggedInArray[4]

end

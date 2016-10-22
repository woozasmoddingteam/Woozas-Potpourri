-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Armory_Client.lua
--
--    Created by:   Charlie Cleveland (charlie@unknownworlds.com)
--
-- A Flash buy menu for marines to purchase weapons and armory from.
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

local kHealthIndicatorModelName = PrecacheAsset("models/marine/armory/health_indicator.model")

function WoozArmory:OnInitClient()

    if not self.clientConstructionComplete then
        self.clientConstructionComplete = self.constructionComplete
    end


end

local first = true;

function WoozArmory:GetWarmupCompleted()
	if first then
		Shared.Message(debug.traceback());
		first = false;
	end
    return not self.timeConstructionCompleted or (self.timeConstructionCompleted + 0.7 < Shared.GetTime())
end

function WoozArmory:OnUse(player)
	if Client.GetLocalPlayer() ~= player then
		return
	end

	Client.SendNetworkMessage("WoozArmoryFound", {});
end

function WoozArmory:UpdateArmoryWarmUp()

    if self.clientConstructionComplete ~= self.constructionComplete and self.constructionComplete then
        self.clientConstructionComplete = self.constructionComplete
        self.timeConstructionCompleted = Shared.GetTime()
    end

end

local kUpVector = Vector(0, 1, 0)

function WoozArmory:OnUpdateRender()

    PROFILE("WoozArmory:OnUpdateRender")

    local player = Client.GetLocalPlayer()
    local showHealthIndicator = false

    if player then
        showHealthIndicator = GetIsUnitActive(self) and GetAreFriends(self, player) and (player:GetHealth()/player:GetMaxHealth()) ~= 1 and player:GetIsAlive() and not player:isa("Commander")
    end

    if not self.healthIndicator then

        self.healthIndicator = Client.CreateRenderModel(RenderScene.Zone_Default)
        self.healthIndicator:SetModel(kHealthIndicatorModelName)

    end

    self.healthIndicator:SetIsVisible(showHealthIndicator)

    -- rotate model if visible
    if showHealthIndicator then

        local time = Shared.GetTime()
        local zAxis = Vector(math.cos(time), 0, math.sin(time))

        local coords = Coords.GetLookIn(self:GetOrigin() + 2.9 * kUpVector, zAxis)
        self.healthIndicator:SetCoords(coords)

    end

end

function WoozArmory:OnDestroy()

    if self.healthIndicator then
        Client.DestroyRenderModel(self.healthIndicator)
        self.healthIndicator = nil
    end

    ScriptActor.OnDestroy(self)

end

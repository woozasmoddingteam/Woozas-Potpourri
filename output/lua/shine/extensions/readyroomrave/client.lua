--[[
    Shine ReadyRoomRave Plugin
]]

local Plugin = Plugin
local Shine = Shine


function Plugin:Initialise()

    self.cinematic = nil

    self:CreateCommands()

    self.Enabled = true

    return true
end


function Plugin:UpdateClient()
    local player = Client.GetLocalPlayer()
    local gameTime = PlayerUI_GetGameStartTime()

    if gameTime ~= 0 then
        gameTime = math.floor(Shared.GetTime()) - PlayerUI_GetGameStartTime()
    end
    if player ~= nil and gameTime > 0 and self.cinematic ~= nil then
        Client.DestroyCinematic(self.cinematic)
        self.cinematic = nil
    end
end


function Plugin:ReceiveCreateSpray(message)
    local origin = Vector(message.originX, message.originY, message.originZ)
    local coords = Angles(message.pitch, message.yaw, message.roll):GetCoords(origin)
    Client.CreateTimeLimitedDecal(message.path, coords, 1.5)
end


function Plugin:ReceiveRaveCinematic(message)
    local coords = Coords()
    coords.origin = message.origin
    if self.cinematic ~= nil or message.stop == true then
        self:StopRaveCinematic()
    else
        self.cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.cinematic:SetCinematic("cinematics/RAVE.cinematic")
        self.cinematic:SetCoords(coords)
        self.cinematic:SetIsVisible(true)
        self.cinematic:SetRepeatStyle(Cinematic.Repeat_Loop)
    end
end


function Plugin:StopRaveCinematic()
    if self.cinematic ~= nil then
        Client.DestroyCinematic(self.cinematic)
        self.cinematic = nil
    end
end



function Plugin:Cleanup()

    self.cinematic = nil

    self.BaseClass.Cleanup( self )

    self.Enabled = false
end

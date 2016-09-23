--[[
    Shine ReadyRoomRave Plugin
]]

local Shine = Shine
local Plugin = Plugin

Plugin.Version = "1.0"
Plugin.HasConfig = false --Does this plugin have a config file?
Plugin.ConfigName = "readyroomrave.json" --What's the name of the file?
Plugin.DefaultState = true --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = false --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.
Plugin.DefaultConfig = {}
Plugin.CheckConfig = false --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = false --Should we check the types of values in the config to make sure they match our default's types?


function Plugin:Initialise()

    self.commandTime = -999
    self.tauntVolume = 1
    self.musicVolume = 0.4
    self.raveVolume = 0.6

    self:PrecacheAssets()

    self:CreateCommands()

    self.Enabled = true
    return true
end

local soundList = {
    "mess",
    "better",
    "dead",
    "dance",
    "dosomething",
    "ayumi",
    "nancy",
}

function Plugin:PrecacheAssets()
    for _, sound in ipairs(soundList) do
        PrecacheAsset("sound/comtaunts.fev/taunts/" .. sound)
    end
    PrecacheAsset("cinematics/RAVE.cinematic")
end


function Plugin:OnConsoleSound(client, name)
    local player = client:GetControllingPlayer()
    local origin = player:GetOrigin()

    if client == nil or name == nil then return end

    -- spam protection
    if (Shared.GetTime() - self.commandTime < 3.5) then return end

    if name == "ayumi" or name == "nancy" then
        -- only during pregame or in readyroom
        if not ( GetGamerules():GetGameState() < kGameState.Started or player:GetIsPlaying() == false or Shared.GetCheatsEnabled() ) then return end

        StartSoundEffectAtOrigin("sound/comtaunts.fev/taunts/" .. name, origin, self.musicVolume)
        self.commandTime = Shared.GetTime()
    else
        for _,v in pairs(soundList) do
            if name == v then
                StartSoundEffectAtOrigin("sound/comtaunts.fev/taunts/" .. name, origin, self.tauntVolume)
                self.commandTime = Shared.GetTime()
                return
            end
        end
        Shared.Message(" Error: Sound " .. name .. " does not exist")
    end

end


function Plugin:OnConsoleRave(client)
    local player = client:GetControllingPlayer()
    local origin = player:GetOrigin()

    if client == nil then return end

    -- spam protection
    if (Shared.GetTime() - self.commandTime < 3.5) then return end

    -- only during pregame or in readyroom
    if not ( GetGamerules():GetGameState() < kGameState.Started or player:GetIsPlaying() == false or Shared.GetCheatsEnabled() ) then return end

    StartSoundEffectAtOrigin("sound/comtaunts.fev/taunts/nancy", origin, self.raveVolume)
    -- local nearbyPlayers = GetEntitiesWithinRange("Player", origin, 20)
    -- for p = 1, #nearbyPlayers do
    --    self:SendNetworkMessage( nearbyPlayers[p], "RaveCinematic", { origin = origin, stop = false }, true )
    -- end
    self:SendNetworkMessage( nil, "RaveCinematic", { origin = origin, stop = false }, true ) -- send to everyone
    self.commandTime = Shared.GetTime()
end


function Plugin:SetGameState( Gamerules, GameState )
    if GameState > kGameState.PreGame and GameState <= kGameState.Started then
        self:SendNetworkMessage( nil, "RaveCinematic", { origin = Vector(0,0,0), stop = true }, true )
    end
end


function Plugin:OnConsoleCreateSpray(client)
    if client == nil then return end
    local player = client:GetControllingPlayer()
    local origin = player:GetOrigin()
    local playerIndex = nil

    -- only during pregame or in readyroom
    if not ( GetGamerules():GetGameState() < kGameState.Started or player:GetIsPlaying() == false or Shared.GetCheatsEnabled() ) then return end

    -- spam protection
    if (Shared.GetTime() - self.commandTime < 3.5) then return end

    -- user needs to have a decal set in the shine user config
    local decalPath = nil
    local userData = Shine:GetUserData( Server.GetOwner(player):GetUserId() )
    if not userData then return end

    if userData.Decal and userData.Decal[1] then
        decalPath = userData.Decal[1]
    else
        local groupData = Shine:GetGroupData( userData.Group )
        if groupData and groupData.Decal and groupData.Decal[1] then
            decalPath = groupData.Decal[1]
        else
            return
        end
    end

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())

    if trace.fraction ~= 1 then
        local coords = Coords.GetTranslation(trace.endPoint)
        coords.origin = player:GetEyePos()
        coords.yAxis = trace.normal
        coords.zAxis = coords.yAxis:GetPerpendicular()
        coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)

        local angles = Angles()
        angles:BuildFromCoords(coords)

        local nearbyPlayers = GetEntitiesWithinRange("Player", origin, 20)
        for p = 1, #nearbyPlayers do
            self:SendNetworkMessage( nearbyPlayers[p], "CreateSpray", { originX = coords.origin.x, originY = coords.origin.y, originZ = coords.origin.z,
            yaw = angles.yaw, pitch = angles.pitch, roll = angles.roll, path = ToString(decalPath) }, true )
        end
    end
end


function Plugin:CreateCommands()

    local function OnConsoleSound( Client, Name )
        self:OnConsoleSound( Client, Name )
    end
    self:BindCommand( "sh_sound", "sound", OnConsoleSound, false, false )
    :AddParam{ Type = "string", Optional = true, TakeRestOfLine = true, Default = "dance", MaxLength = 100, Help = "[mess|better|dead|dance|dosomething] or [nancy|ayumi](pregame only)" }
    :Help( "<soundname> Plays the specified sound if it exists." )

    local function OnConsoleRave( Client )
        self:OnConsoleRave( Client )
    end
    self:BindCommand( "sh_rave", "rave", OnConsoleRave, false, false )
    :Help( "Starts a rave." )

    local function OnConsoleCreateSpray( Client )
        self:OnConsoleCreateSpray( Client )
    end
    self:BindCommand( "sh_spray", "spray", OnConsoleCreateSpray, false, false ):Help( "Sprays a decal." )
end


function Plugin:Cleanup()

    self.BaseClass.Cleanup( self )

    self.Enabled = false
end

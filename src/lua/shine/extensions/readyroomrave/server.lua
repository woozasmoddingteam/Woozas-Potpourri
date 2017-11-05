--[[
    Shine ReadyRoomRave Plugin
]]

local Shine = Shine
local Plugin = Plugin

Plugin.Version = "1.2"
Plugin.HasConfig = true --Does this plugin have a config file?
Plugin.ConfigName = "readyroomrave.json" --What's the name of the file?
Plugin.DefaultState = true --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = false --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.
Plugin.DefaultConfig = {
    tauntVolume = 1,
    musicVolume = 0.4,
    raveVolume = 0.6,
    maxSprayDistance = 4,
}
Plugin.CheckConfig = true --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = true --Should we check the types of values in the config to make sure they match our default's types?


function Plugin:Initialise()

    self.commandTime = -999

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

	StartSoundEffectAtOrigin("sound/comtaunts.fev/taunts/" .. name, origin, self.Config.musicVolume or 0.4)
	self.commandTime = Shared.GetTime()
    else
	for _,v in pairs(soundList) do
	    if name == v then
		StartSoundEffectAtOrigin("sound/comtaunts.fev/taunts/" .. name, origin, self.Config.tauntVolume or 1)
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

    StartSoundEffectAtOrigin("sound/comtaunts.fev/taunts/nancy", origin, self.Config.raveVolume or 0.6)
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


function Plugin:GetDecalPath(client)
    if client == nil then return end
    local player = client:GetControllingPlayer()

    -- user needs to have a decal set in the shine user config
    local userData = Shine:GetUserData( Server.GetOwner(player):GetUserId() )
    if not userData then return end

    -- check user config first
    if userData.Decal and userData.Decal[1] then
	return userData.Decal[1]
    end

    -- now check user's group config
    local groupData = Shine:GetGroupData( userData.Group )
    if groupData and groupData.Decal and groupData.Decal[1] then
	return groupData.Decal[1]
    end

    -- no decal configured, return nil
    return
end


function Plugin:OnConsoleCreateSpray(client)
    if client == nil then return end
    local player = client:GetControllingPlayer()
    local origin = player:GetOrigin()
    local maxSprayDistance = self.Config.maxSprayDistance or 4

    -- only during pregame or in readyroom
    if not ( GetGamerules():GetGameState() < kGameState.Started or player:GetIsPlaying() == false or Shared.GetCheatsEnabled() ) then return end

    -- spam protection
    if (Shared.GetTime() - self.commandTime < 3.5) then return end

    local decalPath = self:GetDecalPath(client)
    if decalPath == nil then return end

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Default, PhysicsMask.Bullets, EntityFilterAll())

    if trace.fraction ~= 1 then
	local direction = startPoint - trace.endPoint
	local distance = direction:GetLength()
	direction:Normalize()
	if distance > maxSprayDistance then return end

	local coords = Coords.GetIdentity()
	if trace.normal:CrossProduct(Vector(0,1,0)):GetLength() < 0.35 then
	    -- we are looking at the floor, a slope or the ceiling, so rotate decal to face us
	    local isFacingUp = trace.normal:DotProduct(Vector(0,1,0)) > 0
	    coords.origin = trace.endPoint - 0.5 * trace.normal
	    coords.yAxis = trace.normal
	    if isFacingUp then
		coords.xAxis = direction
	    else
		coords.xAxis = -direction
	    end
	    coords.zAxis = coords.xAxis:CrossProduct(coords.yAxis)
	    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
	else
	    -- we are looking at a wall, decal is always upright
	    coords.origin = trace.endPoint - 0.5 * direction
	    coords.yAxis = trace.normal
	    coords.zAxis = coords.yAxis:GetPerpendicular()
	    coords.xAxis = coords.yAxis:CrossProduct(coords.zAxis)
	end

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
    self:BindCommand( "sh_sound", "sound", OnConsoleSound, true, false )
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

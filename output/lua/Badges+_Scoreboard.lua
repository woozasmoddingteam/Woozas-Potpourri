--Badge_Client.lua Hooks

local clientIdToBadge = {}
local clientIdToBadgeName = {}

local function OnReceiveBadge( message )	
	if not clientIdToBadge[ message.clientIndex ] then clientIdToBadge[ message.clientIndex ] = {} end
	if not clientIdToBadgeName[ message.clientIndex ] then clientIdToBadgeName[ message.clientIndex ] = {} end
	
	local badge = kBadges[ message.badge ]
	if badge ~= "disabled" then
		clientIdToBadge[ message.clientIndex ][ message.badgerow ] = "ui/badges/" .. badge .. ".dds"
		clientIdToBadgeName[ message.clientIndex ][ message.badgerow ] = badge
	else
		clientIdToBadge[ message.clientIndex ][ message.badgerow ] = nil
		clientIdToBadgeName[ message.clientIndex ][ message.badgerow ] = nil
	end
end
addReceiveBadgeHook( OnReceiveBadge )

local function joinTwoTables( t1, t2 )
   for _, t in ipairs( t2 ) do
      table.insert( t1, t )
   end
   return t1
end

local OldBadges_GetBadgeTextures = Badges_GetBadgeTextures
function Badges_GetBadgeTextures( clientId, usecase )
	local textures = {}
	local texturenames = {}
	
	local badgeModTextures = clientIdToBadge[ clientId ]
	local badgeNames = clientIdToBadgeName[ clientId ]
	if badgeModTextures then
		for badgerow, badgeModTexture in pairs( badgeModTextures ) do
			table.insert( textures, badgeModTexture )
			table.insert( texturenames, badgeNames[ badgerow ] )
		end
    end
    
    local hivetextures, hivetexturenames = OldBadges_GetBadgeTextures( clientId, usecase )
    textures = joinTwoTables( textures, hivetextures )
	if hivetexturenames then 
		texturenames = joinTwoTables( texturenames, hivetexturenames )
	end
    
    return textures, texturenames
end

local badgeNameToFormalName = {}

local oldGetBadgeFormalName = GetBadgeFormalName
function GetBadgeFormalName( name )
	local formalName = sBadgeExists(name) and badgeNameToFormalName[kBadges[name]]
	return formalName or oldGetBadgeFormalName( name )
end

local function OnReceiveBadgeName( message )
	badgeNameToFormalName[message.badge] = message.badgename
end

Client.HookNetworkMessage( "BadgeName", OnReceiveBadgeName )
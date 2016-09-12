Script.Load( "lua/Badges+_Shared.lua" )

-- temp cache of often used function
local TableInsert = table.insertunique
local TableContains = table.contains

-- The currently selected badge for each player on the server
local kPlayerBadges = {}
-- Badges defined by the server operator or other mods
local sServerBadges = {}
-- ClientTable
local Users = {}

function AvoidEmptyBadge( Client, Badge, Row )
    if getClientBadgeEnum( Client, Row ) == kBadges.None then
       setClientBadgeEnum( Client, kBadges[ Badge ], Row ) 
    end
end

function GiveBadge( userId, sBadgeName, row )
	if not ( userId or sBadgeName ) then return false end
  
	if row then row = tonumber( row ) end
	if not row or row < 1 or row > 10 then row = 5 end
	
	if not sServerBadges[ userId ] then sServerBadges[ userId ] = {} end
	
	local sClientBadges = sServerBadges[ userId ][ row ]
	if not sClientBadges then sClientBadges = {} end
	
	if sBadgeExists( sBadgeName ) then
		TableInsert( sClientBadges, sBadgeName )
		sServerBadges[ userId ][ row ] = sClientBadges
		
		local client = Users[ userId ]
		if client then
			Server.SendNetworkMessage( client, "Badge", BuildBadgeMessage( -1, kBadges[ sBadgeName ], row ), true )
			AvoidEmptyBadge( client, sBadgeName, row )
		end
		
		return true
	end
	return false
end

local function BroadcastBadge( id, kBadge, row )
	Server.SendNetworkMessage( "Badge", BuildBadgeMessage( id, kBadge, row ), true)
end

function setClientBadgeEnum( client, kBadge, row )
	local id = client:GetId()	
	if not row or row < 1 or row > 10 then row = 5 end
	
	if not kPlayerBadges[ id ] then kPlayerBadges[ id ] = {} end
	kPlayerBadges[ id ][ row ] = kBadge
	
	BroadcastBadge( id, kBadge, row )
end

function getClientBadgeEnum( client, row )
	if not client then return end
	if not row or row < 1 or row > 10 then row = 5 end	
	local id = client:GetId()
	
	local kPlayerBadge = kPlayerBadges[ id ] and kPlayerBadges[ id ][ row ]
	if kPlayerBadge then
		return kPlayerBadge
	else
		return kBadges.None
	end
end

local function GetBadgeStrings( client, callback, row )
	local steamid = client.GetUserId and client:GetUserId() or 0
	if steamid < 1 then return end
	
	Users[ steamid ] = client
	
	local sClientBadges = sServerBadges[ steamid ] or {}
	
	callback( sClientBadges )
end

function foreachBadge( f )
	for id, kPlayerRowBadges in pairs( kPlayerBadges ) do
		for row, kPlayerBadge in pairs( kPlayerRowBadges ) do
			f( id, kPlayerBadge, row )
		end
	end
end

local function OnRequestBadge( client, message )
	local kBadge = message.badge
	local row = message.badgerow or 5
	
	if kBadge == getClientBadgeEnum( client, row ) then return end
	if client and kBadge then
		local function RequestCallback( sClientBadges )
			sClientBadges = sClientBadges[ row ] or {}
			if #sClientBadges > 0 and client.GetId then
				local authorized = TableContains( sClientBadges, kBadges[ kBadge ] ) 
				if authorized then
					setClientBadgeEnum( client, kBadge, row )
				else                    
					setClientBadgeEnum( client, kBadges[ sClientBadges[ 1 ] ], row )
				end
			end
		end
		GetBadgeStrings( client, RequestCallback )
	end
end
Server.HookNetworkMessage( "Badge", OnRequestBadge )

local function OnClientConnect( client )
	foreachBadge( BroadcastBadge )
	local function RequestCallback( sClientBadges )		
		for row, sClientRowBadges in pairs( sClientBadges ) do
			for _, sClientBadge in ipairs( sClientRowBadges ) do
				Server.SendNetworkMessage( client, "Badge", BuildBadgeMessage( -1, kBadges[ sClientBadge ], row ), true)
			end
		end
	end
	GetBadgeStrings( client, RequestCallback )
end
Event.Hook( "ClientConnect", OnClientConnect )

local function OnClientDisconnect( client )
	kPlayerBadges[ client:GetId() ] = nil
	if client.GetUserId then Users[ client:GetUserId() ] = nil end
end
Event.Hook( "ClientDisconnect", OnClientDisconnect )

Script.Load( "lua/Badges+_ParseConfig.lua" )
Script.Load( "lua/Badges+_Shared.lua" )

-- temp cache of often used function
local StringFormat = string.format
local TableInsert = table.insertunique
local TableContains = table.contains

--Badges+ functions
local sServerBadges = {}
	
function GetBadgeStrings( callback )
	local sClientBadges = sServerBadges
	callback( sClientBadges )
end

function GetClientOwnBadge( badge, row )
	return sServerBadges[ row ] and TableContains( sServerBadges[ row ], badge )
end

local receiveBadges = {}
function addReceiveBadgeHook( func )
	TableInsert(receiveBadges, func )
end

local function OnReceiveBadge( message )
	if message.clientIndex == -1 then
		local row = message.badgerow
		local sBadge = kBadges[ message.badge ]
		
		if not sServerBadges[ row ] then sServerBadges[ row ] = {} end
		TableInsert( sServerBadges[ row ], sBadge )
		
		local SavedBadge = Client.GetOptionString( StringFormat("Badge%s", row ), "" )
		-- default to first badge if we haven't selected one
		if SavedBadge == "" or SavedBadge == sBadge then
			Client.SetOptionString( StringFormat("Badge%s", row), "" )
			Shared.ConsoleCommand( StringFormat( "badge \"%s\" %s", sBadge, row ))
		end 
	else
		for i, func in ipairs( receiveBadges ) do
			func( message )
		end
	end
end
Client.HookNetworkMessage( "Badge", OnReceiveBadge )

local function OnLoadComplete()
	for i = 1, 10 do
		local sSavedBadge = Client.GetOptionString( StringFormat("Badge%s", i), "" )
		if sSavedBadge and sSavedBadge ~= "" and Client.GetIsConnected() then
			if sBadgeExists( sSavedBadge ) then
				Client.SendNetworkMessage( "Badge", { badge = kBadges[ sSavedBadge ], badgerow = i }, true )
			else
				Client.SetOptionString( StringFormat("Badge%s", i), "" )
			end
		end
	end
end
Event.Hook( "LoadComplete", OnLoadComplete )

local function OnClientDisconnected()
	sServerBadges = {}
end
Event.Hook( "ClientDisconnected", OnClientDisconnected )

Script.Load( "lua/Badges+_Scoreboard.lua" )
Script.Load( "lua/Badges+_MainMenu.lua" )
Script.Load( "lua/Badges+_ConsoleCommands.lua" )
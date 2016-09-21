-- temp cache of often used function
local StringFormat = string.format

local function OnConsoleBadges()
	local function RequestCallback(sClientBadges)
		Print( "--Available Badges--" )
		for i, sBadgeRows in pairs( sClientBadges ) do
			Print( StringFormat( "Badge-Row %s:", i ))
			for _, sBadge in ipairs( sBadgeRows ) do
				Print( sBadge )
			end
			Print( "-------------" )
		end
	end
	GetBadgeStrings( RequestCallback )
end
Event.Hook( "Console_badges", OnConsoleBadges )

local function OnConsoleBadge( sRequestedBadge, Row)
	Row = tonumber( Row )
	if not Row or Row < 0 or Row > 10 then Row = 3 end
	
	local sSavedBadge = Client.GetOptionString( StringFormat( "Badge%s", Row ), "" )
	
	if not sRequestedBadge or StringTrim( sRequestedBadge ) == "" then
		Print( StringFormat( "Saved Badge: %s", sSavedBadge ))
	elseif sRequestedBadge == "-" then
		Client.SetOptionString( StringFormat("Badge%s", Row ), "" )
		SelectBadge( "None", Row )
	elseif sRequestedBadge ~= sSavedBadge and GetClientOwnBadge( sRequestedBadge, Row ) then
		Client.SetOptionString( StringFormat( "Badge%s", Row ), sRequestedBadge )
		SelectBadge( sRequestedBadge, Row )
		Client.SendNetworkMessage( "Badge", { badge = kBadges[ sRequestedBadge ], badgerow = Row }, true)
	elseif sRequestedBadge == sSavedBadge then
		Print( "You already have selected the requested badge" )
	else
		Print( "Either you don't own the requested badge at this server or it doesn't exist." )
	end
end
Event.Hook( "Console_badge", OnConsoleBadge )

local function OnConsoleAllBadges()
	Print( "--All Badges--" )
	for _, sBadge in ipairs( kBadges ) do
		Print( ToString( sBadge ) )
	end
end
Event.Hook( "Console_allbadges", OnConsoleAllBadges )

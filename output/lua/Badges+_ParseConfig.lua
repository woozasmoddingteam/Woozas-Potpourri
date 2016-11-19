local JsonDecode = json.decode
local StringFormat = string.format
local TableInsert = table.insertunique

-- Parse the server admin file
do	
	local function LoadConfigFile(fileName)
		Shared.Message( StringFormat( "Loading Badge config://%s", fileName ))
		local openedFile = io.open( StringFormat( "config://%s", fileName ), "r" )
		if openedFile then
		
			local parsedFile = openedFile:read( "*all" )
			io.close( openedFile )
			return parsedFile
			
		end
		return nil
	end
	
	local function ParseJSONStruct( struct )
		return JsonDecode( struct ) or {}
	end

	local serverAdmin = ParseJSONStruct( LoadConfigFile( "ServerAdmin.json" ))
	if serverAdmin.users then
		for _, user in pairs(serverAdmin.users) do
			local userId = user.id
			for i = 1, #user.groups do
				-- Check if the group has a badge assigned
				local groupName = user.groups[ i ]
				local group = serverAdmin.groups[ groupName ]
				if group then
					local sGroupBadges = group.badges or {}
					if group.badge then
						TableInsert( sGroupBadges, group.badge )
					end 
					
					-- Assign all badges for the group
					for i, sGroupBadge in ipairs( sGroupBadges ) do
						if not GiveBadge( userId, sGroupBadge ) then
							Print( StringFormat( "%s is configured for a badge that non-existent or reserved badge: %s", groupName, sGroupBadge ))
						end
					end
				end
				
				-- Attempt to assign the group name otherwise
				GiveBadge( userId, groupName )
			end
		end
	end
end
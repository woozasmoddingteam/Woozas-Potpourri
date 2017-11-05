Log "Overriding server sponitor!"
local void = function() end
function ServerSponitor()
	return {
		Initialize = void,
		ListenToTeam = void,
		OnEntityKilled = void,
		Update = void,
		OnEndMatch = void,
		OnJoinTeam = void,
		OnStartMatch = void
	}
end

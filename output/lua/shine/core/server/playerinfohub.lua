--[[
	Shine PlayerInfoHub
]]
local Shine = Shine

local StringFormat = string.format
local JsonDecode = json.decode

local Add = Shine.Hook.Add

Shine.PlayerInfoHub = {}
local PlayerInfoHub = Shine.PlayerInfoHub

PlayerInfoHub.SteamData = {}
PlayerInfoHub.GeoData = {}
PlayerInfoHub.ENSLData = {}

local function Call( Name, Client, ... )
	if not Shine:IsValidClient( Client ) then return end
	Shine.Hook.Call( Name, Client, ... )
end

local Queue = {}
local current = 0
local last = 0
local working = false

local function ProcessQueue()
	PROFILE("PlayerInfoHub:ProcessQueue()")
	working = true
	current = current + 1

	local node = Queue[current]

	local function OnSuccess( Response )
		node[2](Response)

		if current < last then
			ProcessQueue()
		else
			working = false
		end
	end

	local function OnTimeout()
		node[3]()

		if current < last then
			ProcessQueue()
		else
			working = false
		end
	end

	Shine.TimedHTTPRequest(node[1], "GET", OnSuccess, OnTimeout, 15)
end

local function AddToHTTPQueue( Address, OnSuccess, OnTimeout)
	last = last + 1
	Queue[last] = {
		Address,
		OnSuccess,
		OnTimeout
	}

	if not working then ProcessQueue() end
end

--[[
--Datatypes:
 - STEAMPLAYTIME
 - STEAMBADGES
 - STEAMBANS
 - GEOIP
 - ENSL
 ]]
PlayerInfoHub.Requests = {
	STEAMPLAYTIME = {},
	STEAMBADGES = {},
	STEAMBANS = {},
	GEODATA = {},
	ENSL = {}
}

PlayerInfoHub.HiveQueue = {}

function PlayerInfoHub:Request( Name, DataType)
	if not Name or not DataType then return end

	if type(DataType) == "table" then
		for _, type in ipairs(DataType) do
			table.insert(self.Requests[type], Name)
		end
	else
		table.insert(self.Requests[DataType], Name)
	end


	for _, client in ipairs(Shine.GetAllClients()) do
		self:OnConnect(client)
	end
end

function PlayerInfoHub:RemoveRequest( Name, DataType)
	if not DataType then
		for _, type in pairs(self.Requests) do
			for i, name in ipairs(type) do
				if name == Name then
					table.remove(type, i)
				end
			end
		end
	else
		for i, name in ipairs(self.Requests[DataType]) do
			if name == Name then
				table.remove(self.Requests[DataType], i)
			end
		end
	end
end

function PlayerInfoHub:OnConnect( Client )
	PROFILE("PlayerInfoHub:OnConnect()")
	if not Shine:IsValidClient( Client ) then return end

	local SteamId = Client:GetUserId()
	if not SteamId or SteamId <= 0 then return end

	local SteamId64 = StringFormat( "%s%s", 76561, SteamId + 197960265728 )

	if not self.SteamData[ SteamId ] then
		self.SteamData[ SteamId ] = {}
		self.SteamData[ SteamId ].Badges = {}
	end

	local HiveData = self:GetHiveData( SteamId )
	if not HiveData then
		if self.HiveQueue[ SteamId ] == nil then
			self.HiveQueue[ SteamId ] = true
			Shine.Timer.Create( StringFormat("HiveRequest%s", SteamId), 5, 1, function()
				PlayerInfoHub.HiveQueue[ SteamId ] = false
				Call( "OnReceiveHiveData", Client, nil )
			end )
		end
	elseif self.HiveQueue[ SteamId ] == false then
		Call( "OnReceiveHiveData", Client, HiveData )
	end

	--[[
	-- Status:
	 - -2 = Fetching
	 - -1 = Timeout
	 ]]
	if self.Requests.STEAMPLAYTIME[1] then
		local function CallEvent()
			if (not PlayerInfoHub.Requests.STEAMBADGES[1] or PlayerInfoHub.SteamData[ SteamId ].Badges.Normal ~= -2) and
					(not PlayerInfoHub.Requests.STEAMBANS[1] or PlayerInfoHub.SteamData[ SteamId ].Bans ~= -2) then
				Call( "OnReceiveSteamData", Client, PlayerInfoHub.SteamData[ SteamId ] )
			end
		end

		if not self.SteamData[ SteamId ].PlayTime then
			PlayerInfoHub.SteamData[ SteamId ].PlayTime = -2

			AddToHTTPQueue( StringFormat( "http://api.steampowered.com/IPlayerService/GetOwnedGames/v1/?key=2EFCCE2AF701859CDB6BBA3112F95972&SteamId=%s&appids_filter[0]=4920", SteamId64 ), function( Response )
				local Temp = JsonDecode( Response )

				Temp = Temp and Temp.response and Temp.response.games and Temp.response.games[1]
				if not Temp then
					PlayerInfoHub.SteamData[ SteamId ].PlayTime = 0
					return
				else
					PlayerInfoHub.SteamData[ SteamId ].PlayTime = Temp.playtime_forever and Temp.playtime_forever * 60 or 0
				end

				CallEvent()
			end, function()
				PlayerInfoHub.SteamData[ SteamId ].PlayTime = -1
				CallEvent()
			end )
		elseif self.SteamData[ SteamId ].PlayTime ~= -2 then
			CallEvent()
		end
	end

	if self.Requests.STEAMBANS[1] then
		local function CallEvent()
			if (not PlayerInfoHub.Requests.STEAMPLAYTIME[1] or PlayerInfoHub.SteamData[ SteamId ].PlayTime ~= -2) and
					(not PlayerInfoHub.Requests.STEAMBADGES[1] or PlayerInfoHub.SteamData[ SteamId ].Badges.Normal ~= -2) then
				Call( "OnReceiveSteamData", Client, PlayerInfoHub.SteamData[ SteamId ] )
			end
		end

		if not self.SteamData[ SteamId ].Bans then
			self.SteamData[ SteamId ].Bans = -2
			AddToHTTPQueue( StringFormat( "http://api.steampowered.com/ISteamUser/GetPlayerBans/v1/?key=2EFCCE2AF701859CDB6BBA3112F95972&steamids=%s", SteamId64 ),function( Response )
				local data = JsonDecode( Response )
				PlayerInfoHub.SteamData[ SteamId ].Bans = data and data.players and data.players[1] or 0
				CallEvent()
			end, function()
				PlayerInfoHub.SteamData[ SteamId ].Bans = -1
				CallEvent()
			end)
		elseif self.SteamData[ SteamId ].Bans ~= -2 then
			CallEvent()
		end
	end
	
	if self.Requests.ENSL[1] then
		local function CallEvent()
			Call( "OnReceiveENSLData", Client, PlayerInfoHub.ENSLData[ SteamId ] )
		end

		if not self.ENSLData[ SteamId ] then
			self.ENSLData[ SteamId ] = -2
			AddToHTTPQueue( StringFormat( "http://www.ensl.org/api/v1/users/show/%s.steamid", SteamId ),function( Response )
				local data = JsonDecode( Response )

				--The ENSL page does not respond in json if the given id
				--does not exsist in the db but with a full error page.
				if data and not data.id then data = nil end

				PlayerInfoHub.ENSLData[ SteamId ] = data or 0
				CallEvent()
			end, function()
				PlayerInfoHub.ENSLData[ SteamId ] = -1
				CallEvent()
			end)
		elseif self.ENSLData[ SteamId ] ~= -2 then
			CallEvent()
		end
	end

	if self.Requests.GEODATA[1] then
		if not self.GeoData[ SteamId ] then
			self.GeoData[ SteamId ] = -2

			AddToHTTPQueue( StringFormat( "http://geoip.nekudo.com/api/%s", IPAddressToString( Server.GetClientAddress( Client ) ) ), function( Response )
				local data = JsonDecode( Response )
				PlayerInfoHub.GeoData[ SteamId ] = data or 0
				Call( "OnReceiveGeoData", Client, PlayerInfoHub.GeoData[ SteamId ] )
			end, function()
				PlayerInfoHub.GeoData[ SteamId ] = -1
				Call( "OnReceiveGeoData", Client, PlayerInfoHub.GeoData[ SteamId ] )
			end)
		elseif self.GeoData[ SteamId ] ~= -2 then
			Call( "OnReceiveGeoData", Client, PlayerInfoHub.GeoData[ SteamId ] )
		end
	end

	if self.Requests.STEAMBADGES[1] then
		local function CallEvent()
			if (not PlayerInfoHub.Requests.STEAMPLAYTIME[1] or PlayerInfoHub.SteamData[ SteamId ].PlayTime ~= -2) and
					(not PlayerInfoHub.Requests.STEAMBANS[1] or PlayerInfoHub.SteamData[ SteamId ].Bans ~= -2) then
				Call( "OnReceiveSteamData", Client, PlayerInfoHub.SteamData[ SteamId ] )
			end
		end

		if not self.SteamData[ SteamId ].Badges.Normal then
			PlayerInfoHub.SteamData[ SteamId ].Badges.Normal = -2

			AddToHTTPQueue( StringFormat( "http://api.steampowered.com/IPlayerService/GetBadges/v1/?key=2EFCCE2AF701859CDB6BBA3112F95972&SteamId=%s", SteamId64 ),function( Response )
				PlayerInfoHub.SteamData[ SteamId ].Badges.Normal = 0
				PlayerInfoHub.SteamData[ SteamId ].Badges.Foil = 0

				local data = JsonDecode( Response )
				local badgedata = data and data.response.badges
				if badgedata then
					for _, badge in ipairs(badgedata) do
						if badge.appid == 4920 then
							if badge.border_color == 1 then
								PlayerInfoHub.SteamData[ SteamId ].Badges.Foil = 1
							else
								PlayerInfoHub.SteamData[ SteamId ].Badges.Normal = badge.level
							end
						end
					end
				end

				CallEvent()
			end, function()
				PlayerInfoHub.SteamData[ SteamId ].Badges.Normal = -1
				PlayerInfoHub.SteamData[ SteamId ].Badges.Foil = -1
				CallEvent()
			end )
		elseif PlayerInfoHub.SteamData[ SteamId ].Badges.Normal ~= -2 then
			CallEvent()
		end
	end

end

Add( "ClientConnect", "GetPlayerInfo", function( Client )
	PlayerInfoHub:OnConnect( Client )
end )

Shine.Hook.SetupClassHook("ScoringMixin", "SetPlayerLevel", "OnSetPlayerLevel", "PassivePost")
Add("OnSetPlayerLevel", "HiveRequestFinished", function(Player)
	local Client = Player.GetClient and Player:GetClient()
	local SteamId = Client and Client:GetUserId()

	if SteamId then
		Shine.Timer.Destroy(StringFormat("HiveRequest%s", SteamId))
		PlayerInfoHub.HiveQueue[ SteamId ] = false
		Call( "OnReceiveHiveData", Client, GetHiveDataBySteamId(SteamId) )
	end
end)

function PlayerInfoHub:GetHiveData( SteamId )
	if Shine.IsNS2Combat or not GetHiveDataBySteamId then return end

	local data = GetHiveDataBySteamId(SteamId)
	if data then
		--Fix for hive2 using a new format
		data.playTime = data.time_played
		return data
	end
end

function PlayerInfoHub:GetSteamData( SteamId )
	return self.SteamData[ SteamId ]
end

function PlayerInfoHub:GetGeoData( SteamId )
	return self.GeoData[ SteamId ]
end

function PlayerInfoHub:GetENSLData( SteamId )
	return self.ENSLData[ SteamId ]
end

--[[
-- Returns if the requests have been finsihed for given SteamId
-- If a Name is give it will only check for requst registered with the given name
 ]]
function PlayerInfoHub:GetIsRequestFinished( SteamId, Name )

	if not Name then
		return (not self.Requests.STEAMPLAYTIME[1] or self.SteamData[ SteamId ].Playtime ~= -2 ) and
				(not self.Requests.STEAMBADGES[1] or self.SteamData[ SteamId ].Badges.Normal ~= -2) and
				(not self.Requests.STEAMBANS[1] or self.SteamData[ SteamId ].Bans ~= -2) and
				(not self.Requests.ENSL[1] or self.ENSLData[ SteamId ].Bans ~= -2) and
				(not self.Requests.GEODATA[1] or self.GeoData[ SteamId ] ~= -2) and self.HiveQueue[ SteamId ] == false
	else
		local result = self.HiveQueue[ SteamId ] == false
		if not result then return false end --avoid any not needed for loop via if checks

		for _, name in ipairs(self.Requests.STEAMPLAYTIME) do
			if name == Name then
				result = self.SteamData[ SteamId ].Playtime ~= -2
				break
			end
		end
		if not result then return false end

		for _, name in ipairs(self.Requests.STEAMBADGES) do
			if name == Name then
				result = self.SteamData[ SteamId ].Badges.Normal ~= -2
				break
			end
		end
		if not result then return false end

		for _, name in ipairs(self.Requests.STEAMBANS) do
			if name == Name then
				result = self.SteamData[ SteamId ].Bans ~= -2
				break
			end
		end
		if not result then return false end

		for _, name in ipairs(self.Requests.GEODATA) do
			if name == Name then
				result = self.GeoData[ SteamId ] ~= -2
				break
			end
		end

		for _, name in ipairs(self.Requests.ENSL) do
			if name == Name then
				result = self.ENSLData[ SteamId ] ~= -2
				break
			end
		end

		return result
	end
end
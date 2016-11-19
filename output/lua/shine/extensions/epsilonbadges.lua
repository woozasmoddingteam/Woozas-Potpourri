--[[
    Shine Epsilon Badges
]]
local Shine = Shine
local InfoHub = Shine.PlayerInfoHub

local Plugin = {}

local Notify = Shared.Message

Plugin.Version = "1.5"

Plugin.HasConfig = true

Plugin.ConfigName = "EpsilonBadges.json"
Plugin.DefaultConfig =
{
    Flags = true,
    FlagsRow = 2,
    SteamBadges = true,
    SteamBadgesRow = 5,
    ENSLTeams = false,
    ENSLTeamsRow = 4,
    Debug = false
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	self.Enabled = true
	
    if self.Config.Flags then
        InfoHub:Request("epsilonbadges", "GEODATA")
    end

    if self.Config.ENSLTeams then
        InfoHub:Request("epsilonbadges", "ENSL")
    end

    if self.Config.SteamBadges then
        InfoHub:Request("epsilonbadges", "STEAMBADGES")
    end
	
	return true
end

function Plugin:SetBadge( Client, Badge, Row, Name )
    if not ( Badge or Client ) then return end
    
    if not GiveBadge then
		if self.Enabled then
			Notify( "[ERROR]: The epsilonbadges plugin does not work without the Badges+ Mod !" )
            Shine:UnloadExtension( "epsilonbadges" )
        end
        return
    end
 
    local ClientId = Client:GetUserId()
    if ClientId <= 0 then return end
    
    local SetBadge = GiveBadge( ClientId, Badge, Row )
    if not SetBadge then return end
    
    SetFormalBadgeName( Badge, Name)
    
    return true
end

local SteamBadges = {
    "steam_Rookie",
    "steam_Squad Leader",
    "steam_Veteran",
    "steam_Commander",
    "steam_Special Ops"
}

local SteamBadgeName = {
    "Steam NS2 Badge - Rookie",
    "Steam NS2 Badge - Squad Leader",
    "Steam NS2 Badge - Veteran",
    "Steam NS2 Badge - Commander",
    "Steam NS2 Badge - Special Ops"
}

function Plugin:OnReceiveSteamData( Client, SteamData )
    if not self.Config.SteamBadges then return end
    
    if SteamData.Badges.Normal and SteamData.Badges.Normal > 0 then
        self:SetBadge( Client, SteamBadges[SteamData.Badges.Normal], self.Config.SteamBadgesRow,
            SteamBadgeName[SteamData.Badges.Normal] )
    end
        
    if SteamData.Badges.Foil and SteamData.Badges.Foil == 1 then
        self:SetBadge( Client, "steam_Sanji Survivor", self.Config.SteamBadgesRow, "Steam NS2 Badge - Sanji Survivor" )
    end
end

function Plugin:OnReceiveGeoData( Client, GeoData )
    if not self.Config.Flags then return end

    if self.Config.Debug then
        Print(string.format("Epsilon Badge Debug: Received GeoData of %s\n%s ", Client:GetUserId(), type(GeoData) == "table" and table.ToString(GeoData) or GeoData))
    end
    
    local Nationality = type(GeoData) == "table" and GeoData.country and GeoData.country.code or "UNO"
    local Country = type(GeoData) == "table" and GeoData.country and GeoData.country.name or "Unknown"

    local SetBagde = self:SetBadge( Client, Nationality, self.Config.FlagsRow,
        string.format("Nationality - %s", Country) )
    
    if not SetBagde then
        Nationality = "UNO"
        self:SetBadge( Client, Nationality, self.Config.FlagsRow,
            string.format("Nationality - %s", Country) )
    end
end

function Plugin:OnReceiveENSLData( Client, Data )
    if not self.Config.ENSLTeams then return end

	if type(Data) ~= "table" then return end

	local Teamname = Data.team and Data.team.name

	if Teamname then
		self:SetBadge( Client, Teamname, self.Config.ENSLTeamsRow, string.format("ENSL Team - %s", Teamname))
	end
end

function Plugin:Cleanup()
    InfoHub:RemoveRequest("epsilonbadges")

    self.BaseClass.Cleanup( self )

    self.Enabled = false
end

Shine:RegisterExtension( "epsilonbadges", Plugin )
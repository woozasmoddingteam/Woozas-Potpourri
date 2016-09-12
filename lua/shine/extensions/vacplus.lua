local Shine = Shine
local InfoHub = Shine.PlayerInfoHub

local Plugin = {}

Plugin.Version = "1.0"
Plugin.HasConfig = true

Plugin.ConfigName = "VACPlus.json"
Plugin.DefaultConfig =
{
    CheckVACBans = true,
    CheckCommunityBans = true,
    CheckEconomyBans = true,
    CheckENSLGatherBans = false,
    CheckENSLMutes = false,
    CheckENSLBans = false,
    AutoBan = true,
    BanTime = 60,
    MaxDaysSinceLastSteamBan = 180,
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
    self.Enabled = true

    if self.Config.CheckVACBans or self.Config.CheckCommunityBans or self.Config.CheckEconomyBans then
        InfoHub:Request( "VAC+", "STEAMBANS")
    end

    if self.Config.CheckENSLGatherBans or self.Config.CheckENSLMutes or self.Config.CheckENSLBans then
	    InfoHub:Request( "VAC+", "ENSL")
    end

    return true
end

function Plugin:OnReceiveSteamData( Client, Data )
    if Shine:HasAccess( Client, "sh_ignorevacbans" ) then return end

    if type(Data.Bans) ~= "table" or Data.Bans.DaysSinceLastBan == 0 or
            (self.Config.MaxDaysSinceLastSteamBan > 0 and Data.Bans.DaysSinceLastBan > self.Config.MaxDaysSinceLastSteamBan) then
        return
    end

    if Data.Bans.VACBanned and self.Config.CheckVACBans then
        self:Kick( Client, 1 )
    end

    if Data.Bans.CommunityBanned and self.Config.CheckCommunityBans then
        self:Kick( Client, 2 )
    end

    if Data.Bans.EconomyBan ~= "none" and self.Config.CheckEconomyBans then
        self:Kick( Client, 3 )
    end
end

function Plugin:OnReceiveENSLData( Client, Data )
    if Shine:HasAccess( Client, "sh_ignorevacbans" ) then return end

    if type(Data) ~= "table" or not Data.bans then
        return
    end

    if Data.bans.gather and self.Config.CheckENSLGatherBans then
        self:Kick( Client, 4 )
    end

    if Data.bans.mute and self.Config.CheckENSLMutes then
        self:Kick( Client, 5 )
    end

    if Data.bans.site and self.Config.CheckENSLBans then
        self:Kick( Client, 6 )
    end
end

local BanTypes = {
    "VAC banned", "Steam Community banned", "Steam Economy banned",
	"ENSl Gather banned", "ENSL muted", "ENSL banned"
}

function Plugin:Kick( Client, BanType )
	local time = BanType > 3 and "" or string.format("less than %s days ago", self.Config.MaxDaysSinceLastSteamBan)
    local reason = string.format("The given user has been %s %s", BanTypes[BanType],time)

    if self.Config.AutoBan then
        Shared.ConsoleCommand( string.format("sh_ban %s %s %s",Client:GetUserId(), self.Config.BanTime, reason ))
    else
        Shared.ConsoleCommand( string.format("sh_kick %s %s",Client:GetUserId(), reason ))
    end
end

function Plugin:Cleanup()
    InfoHub:RemoveRequest( "VAC+" )

    self.BaseClass.Cleanup( self )

    self.Enabled = false
end

Shine:RegisterExtension( "vacplus", Plugin )
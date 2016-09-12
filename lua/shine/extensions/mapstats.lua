local Shine = Shine
local Plugin = {}

Plugin.Version = "1.0"
Plugin.HasConfig = true

Plugin.ConfigName = "Mapstats.json"
Plugin.DefaultConfig = {
	Ignore = {}
}
Plugin.CheckConfig = true

function Plugin:Initialise()
	self.Enabled = true
	local mapname = Shared.GetMapName()

	if self.Config.Ignore[mapname] then
		return false, "The mapstats plugin was set to ignore the czrrent map"
	end

	self.Logpath = string.format("config://shine/logs/mapstats/%s.txt", mapname)
	return true
end

function Plugin:EndGame( Gamerules, WinningTeam )
	local Log = Shine.ReadFile(self.Logpath) or "Date Roundtime Winner AlienSkill MarineSkill"
	local _, team1skill, team2skill = Gamerules.playerRanking:GetAveragePlayerSkill()

	local Entry = table.concat({
		Shine.GetDate(),
		string.DigitalTime(Shared.GetTime() - Gamerules.gameStartTime),
		WinningTeam and Shine:GetTeamName(WinningTeam:GetTeamNumber(), true) or "Draw",
		team2skill,
		team1skill,
	}, " ")

	Log = table.concat({Log, Entry}, "\r\n")
	Shine.WriteFile(self.Logpath, Log)
end

Shine:RegisterExtension( "mapstats", Plugin )


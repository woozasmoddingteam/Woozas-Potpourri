--[[
--Original idea and design by Andrew Krigline (https://github.com/akrigline)
--Original source can be found at https://github.com/akrigline/EnforceTeamSize
]]
local Shine = Shine
local Plugin = {}

Plugin.HasConfig = true
Plugin.ConfigName = "EnforceTeamSizes.json"

--[[
--TeamNumbers:
 - 1: Marines
 - 2: Aliens
 - 3: Spec
 ]]
Plugin.DefaultConfig = {
	Teams = {
		Team1 = {
			MaxPlayers = 8,
			TooManyMessage = "The %s have currently too many players. Please spectate until the round ends.",
			InformAboutFreeSpace = {3},
			InformMessage = "A player left the %s. So you can join up now."
		},
		Team2 = {
			MaxPlayers = 8,
			TooManyMessage = "The %s have currently too many players. Please spectate until the round ends.",
			InformAboutFreeSpace = {3},
			InformMessage = "A player left the %s. So you can join up now."
		},
		IgnoreBots = true
	},
	MessageNameColor = {0, 255, 0 }
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Notify(Player, Message, OldTeam)
	Shine:NotifyDualColour( Player, self.Config.MessageNameColor[1], self.Config.MessageNameColor[2],
		self.Config.MessageNameColor[3], "[EnforcedTeamSizes]", 255, 255, 255,
	   Message, true, Shine:GetTeamName(OldTeam, true) )
end

function Plugin:ClientDisconnect( Client )
	local Player = Client:GetControllingPlayer()
	if not Player then return end

	self:PostJoinTeam( GetGamerules(), Player, Player:GetTeamNumber() )
end

function Plugin:GetNumPlayers(Team)
	local players, _, bots = Team:GetNumPlayers()
	if not self.Config.IgnoreBots then return players end

	return players - bots
end

function Plugin:PostJoinTeam( Gamerules, _, OldTeam )
	if OldTeam < 0 then return end

	if self.Config.Teams.Team1 and self.Config.Teams.Team2 then
		if self:GetNumPlayers(Gamerules:GetTeam(kTeam1Index)) >= self.Config.Teams.Team1.MaxPlayers and
				self:GetNumPlayers(Gamerules:GetTeam(kTeam2Index)) >= self.Config.Teams.Team2.MaxPlayers then
			Server.AddTag("ignore_playnow")
		else
			Server.RemoveTag("ignore_playnow")
		end
	end

	local TeamIndex = string.format("Team%s", OldTeam)
	if self.Config.Teams[TeamIndex] and #self.Config.Teams[TeamIndex].InformAboutFreeSpace ~= 0 and
			self:GetNumPlayers(Gamerules:GetTeam(OldTeam)) + 1 == self.Config.Teams[TeamIndex].MaxPlayers then
		for _, i in ipairs(self.Config.Teams[TeamIndex].InformAboutFreeSpace) do
			local Team = Gamerules:GetTeam(i)
			local Players = Team and Team:GetPlayers()
			if Players and #Players ~= 0 then
				self:Notify(Players, self.Config.Teams[TeamIndex].InformMessage
						or "A player left the %s team. So you can join up now.", OldTeam)
			end
		end
	end
end

function Plugin:JoinTeam( Gamerules, Player, NewTeam, _, ShineForce )
	local TeamIndex = string.format("Team%s", NewTeam)
	if ShineForce or NewTeam == kTeamReadyRoom or not self.Config.Teams[TeamIndex] then return end

	--Check if team is above MaxPlayers
	if self:GetNumPlayers(Gamerules:GetTeam(NewTeam)) >= self.Config.Teams[TeamIndex].MaxPlayers then
		--Inform player
		self:Notify(Player, self.Config.Teams[TeamIndex].TooManyMessage, NewTeam)
		return false
	end
end

--Restrict teams also at voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	local  Gamerules = GetGamerules()
	local team1Max = self.Config.Teams.Team1 and self.Config.Teams.Team1.MaxPlayers or 1000
	local team2Max = self.Config.Teams.Team1 and self.Config.Teams.Team1.MaxPlayers or 1000
	local max = math.min( team1Max, team2Max )

	if max == 1000 then return end

	for i = 1, 2 do
		for j = #TeamMembers[i], max + 1, -1 do
			--Move player into the ready room
			pcall( Gamerules.JoinTeam, Gamerules, TeamMembers[i][j], kTeamReadyRoom, nil, true )
			--remove the player's entry in the table
			TeamMembers[i][j] = nil
		end
	end
end

Shine:RegisterExtension("enforceteamsizes", Plugin )
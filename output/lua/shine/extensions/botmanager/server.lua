local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "BotManager.json"
Plugin.DefaultConfig =
{
	MaxBots = 12,
	CommanderBots = false,
	CommanderBotsStartDelay = 180,
	LoginCommanderBotAtLogout = false,
	AllowPlayersToReplaceComBots = true
}
Plugin.CheckConfig = true

do
	Shine.Hook.SetupClassHook("TeamBrain", "GetNumAssignedToEntity", "ActivePreGetNumAssignedToEntity", "ActivePre")
	Shine.Hook.SetupClassHook("PlayerRanking", "GetTrackServer", "ActivePreGetTrackServer", "ActivePre")
end

function Plugin:Initialise()
	self.Enabled = true

	self.MaxBots = self.Config.MaxBots
	self.CommanderBots = self.Config.CommanderBots

	self.dt.AllowPlayersToReplaceComBots = self.CommanderBots and self.Config.AllowPlayersToReplaceComBots
	self.dt.LoginCommanderBotAtLogout = self.CommanderBots and self.Config.LoginCommanderBotAtLogout

	self:CreateCommands()

	return true
end

--Fixes for bots
function Plugin:ActivePreGetNumAssignedToEntity(TeamBrain, entId)
	if not TeamBrain.entId2memory[entId] then return 0 end
end

function Plugin:CheckGameStart( Gamerules )
	local State = Gamerules:GetGameState()

	if State > kGameState.PreGame then return end

	local NumCommanderBots = #gCommanderBots
	local StartDelay = self.Config.CommanderBotsStartDelay or 0
	if StartDelay > 0 and NumCommanderBots > 0 and not self.StartTime then
		self.StartTime = Shared.GetTime() + StartDelay
	end

	if self.StartTime then
		if Shared.GetTime() < self.StartTime then

			if NumCommanderBots == 0 then
				self.StartTime = nil
				return
			end

			return false
		else
			self.StartTime = nil
		end
	end
end

--Filter bots for voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	for i = 1, 2 do
		for j = #TeamMembers[i], 1, -1 do
			local Player = TeamMembers[i][j]
			local Client = Player:GetClient()

			if not Client or Client:GetIsVirtual() then
				--remove the player's entry in the table
				table.remove(TeamMembers[i], j)
			end
		end
	end
end

function Plugin:OnFirstThink()
	self:SetMaxBots(self.MaxBots, self.CommanderBots)
end

function Plugin:SetMaxBots(bots, com)
	local Gamerules = GetGamerules()

	if not Gamerules or not Gamerules.SetMaxBots then return end

	Gamerules:SetMaxBots(bots, com)
end

--avoid that ppl loose hive skill for loosing against bots
function Plugin:ActivePreGetTrackServer()
	local team1PlayerNum, _, team1BotNum  = gameRules:GetTeam1():GetNumPlayers()
	local team2PlayerNum, _, team2BotNum = gameRules:GetTeam2():GetNumPlayers()

	team1PlayerNum = team1PlayerNum - team1BotNum
	team2PlayerNum = team2PlayerNum - team2BotNum

	local diff = math.abs(team1PlayerNum - team2PlayerNum)

	if diff > 2 or team1PlayerNum == 0 or team2PlayerNum == 0 then return false end
end

function Plugin:CreateCommands()
	local function MaxBots( _, Number, SaveIntoConfig )
		self:SetMaxBots( Number, self.Config.CommanderBots )

		self.MaxBots = Number

		if SaveIntoConfig then
			self.Config.MaxBots = Number
			self:SaveConfig()
		end
	end
	local ShowNewsCommand = self:BindCommand( "sh_maxbots", "maxbots", MaxBots )
	ShowNewsCommand:AddParam{ Type = "number", Min = 0, Error = "Please specify the amount of bots you want to set.", Help = "Maximum number of bots"  }
	ShowNewsCommand:AddParam{ Type = "boolean", Default = false, Help = "true = save change", Optional = true  }
	ShowNewsCommand:Help( "Sets the maximum amount of bots currently allowed at this server." )

	local function ComBots( _, Enable, SaveIntoConfig )
		self:SetMaxBots( self.MaxBots, Enable )

		self.CommanderBots = Enable
		self.dt.AllowPlayersToReplaceComBots = self.CommanderBots and self.Config.AllowPlayersToReplaceComBots

		if SaveIntoConfig then
			self.Config.CommanderBots = Enable
			self:SaveConfig()
		end
	end
	local ShowNewsCommand = self:BindCommand( "sh_enablecombots", "enablecombots", ComBots )
	ShowNewsCommand:AddParam{ Type = "boolean", Error = "Please specify if you want to enable commander bots", Help = "true = add commander bots"  }
	ShowNewsCommand:AddParam{ Type = "boolean", Default = false, Help = "true = save change", Optional = true  }
	ShowNewsCommand:Help( "Sets if teams should be filled with commander bots or not" )

end

function Plugin:Cleanup()
	self:SetMaxBots(0, false)

	self.BaseClass.Cleanup( self )
	self.Enabled = false
end



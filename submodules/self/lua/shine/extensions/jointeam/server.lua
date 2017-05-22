--The plugin table registered in shared.lua is passed in as the global "Plugin".
local Plugin = Plugin
local avgglobal=0
local avgteam1=0
local avgteam2=0
local playersinfo
local Shine=Shine
local totPlayersMarines=0
local totPlayersAliens=0
local notify
local tag="[JoinTeam]"
Plugin.avgglobal = avgglobal
Plugin.avgteam1 = avgteam1
Plugin.avgteam2 = avgteam2
Plugin.playersinfo= playersinfo 
Plugin.totPlayersMarines =totPlayersMarines
Plugin.totPlayersAliens =totPlayersAliens
Plugin.tag=tag
Plugin.NotifyPrefixColour = {
	0, 150, 255
}
--local rseed =math.randomseed( os.time() )

Plugin.HasConfig = true
Plugin.ConfigName = "JoinTeam.json" 
Plugin.DefaultConfig = {
    InformPlayer = true,
	ForcePlayer = true,
}
Plugin.CheckConfig = true


--Shine hook, when a player try to join a team
--return without arguments allow the player to join the team
--return false, 0 prevent the player is not authorized to join the team
function Plugin:JoinTeam( Gamerules, Player, NewTeam, force, ShineForce ) -- jointeam is hook on server side only
	if(self.Config.ForcePlayer == true) then
		--TO DO, do something about the NS2 vote randomize ready room. 
		--This vote don't use the force value :x
		if(force) then
			--Print("Jointeam: You Have been forced to join the team X  by NS2")
			return
		elseif(ShineForce) then
			--Print("Jointeam: You Have been forced to join the team X  by Shine")
			return
		end
		
		if(NewTeam < 1) or (NewTeam > 2) then --join spec or RR
			--Print("Jointeam: If you want to go into the RR or spectate, I let you do")
			return
		end
		 
		local gamerules = GetGamerules()
		local team1Players = gamerules.team1:GetNumPlayers()
        local team2Players = gamerules.team2:GetNumPlayers()
            
			-- check if trying to join the team with the more players
            if (team1Players > team2Players) and (NewTeam == gamerules.team1:GetTeamNumber()) then
				--Shine:NotifyColour( Player, 255, 0, 0, string.format("there is too many players in this team %s", Shine:GetTeamName(NewTeam, true)))
                return false, 0
            elseif (team2Players > team1Players) and (NewTeam == gamerules.team2:GetTeamNumber()) then
				--Shine:NotifyColour( Player, 255, 0, 0, string.format("there is too many players in this team %s", Shine:GetTeamName(NewTeam, true)))
                return false, 0
            end
			
			--check if trying to join the team with less players
			--TO DO check if there is many people in RR and if enough of them can improve the balance, then also restrict the join.
			if (team1Players > team2Players) and (NewTeam == gamerules.team2:GetTeamNumber()) then
				self.NotifyPrefixColour=self.NotifyEqual
				self:NotifyTranslated(Player, "OK_LESS_PLAYER")
                self:NotifyTranslated(Player, "OK_ALIENS")
				return 
            elseif (team2Players > team1Players) and (NewTeam == gamerules.team1:GetTeamNumber()) then
				self.NotifyPrefixColour=self.NotifyEqual
				self:NotifyTranslated(Player, "OK_LESS_PLAYER")
                self:NotifyTranslated(Player, "OK_MARINES")
                return 
            end
			
			
			local playerskill=Shared.GetEntity(Player.playerInfo.playerId):GetPlayerSkill()
			--It let us only the case where the number of players in each team is equal.
			
			local canjoin = self:GetCanJoinTeam(self.avgteam1, self.avgteam2, team1Players, team2Players, playerskill)
			
			
			if(NewTeam == gamerules.team1:GetTeamNumber()) then
			-- try to join marines
				if(canjoin == 0) then
					self.NotifyPrefixColour=self.NotifyGood
					self:NotifyTranslated(Player, "OK_CHOICE")
					return
				elseif(canjoin == 1) then
					self.NotifyPrefixColour=self.NotifyGood
					self:NotifyTranslated(Player, "OK_MARINES")
					return
				elseif(canjoin == 2) then
					self.NotifyPrefixColour=self.NotifyBad
					self:NotifyTranslated(Player, "ERROR_1")
					self:NotifyTranslated(Player, "ERROR_2")
					return false, 0
				elseif(canjoin == 3) then
					self.NotifyPrefixColour=self.NotifyEqual
					self:NotifyTranslated(Player, "OK_MARINES")
					return
				elseif(canjoin == 4) then
					self.NotifyPrefixColour=self.NotifyBad
					self:NotifyTranslated(Player, "ERROR_1")
					self:NotifyTranslated(Player, "ERROR_2")
					return false, 0
				elseif(canjoin == 5) then
					self.NotifyPrefixColour=self.NotifyEqual
					self:NotifyTranslated(Player, "OK_CHOICE")
					return
				elseif(canjoin == 7) then
					Print("%s Bot can always join the team of their choice! Are you a bot?", self.tag)
					return
				else --6
					Print("%s GetCanJoinTeam error", self.tag)
					return
				end
			else --aliens
				if(canjoin == 0) then
					self.NotifyPrefixColour=self.NotifyGood
					self:NotifyTranslated(Player, "OK_CHOICE")
					return
				elseif(canjoin == 1) then
					self.NotifyPrefixColour=self.NotifyBad
					self:NotifyTranslated(Player, "ERROR_1")
					self:NotifyTranslated(Player, "ERROR_2")
					return false, 0
				elseif(canjoin == 2) then
					self.NotifyPrefixColour=self.NotifyGood
					self:NotifyTranslated(Player, "OK_ALIENS")
					return
				elseif(canjoin == 3) then
					self.NotifyPrefixColour=self.NotifyBad
					self:NotifyTranslated(Player, "ERROR_1")
					self:NotifyTranslated(Player, "ERROR_2")
					return false, 0
				elseif(canjoin == 4) then
					self.NotifyPrefixColour=self.NotifyEqual
					self:NotifyTranslated(Player, "OK_ALIENS")
					return
				elseif(canjoin == 5) then
					self.NotifyPrefixColour=self.NotifyEqual
					self:NotifyTranslated(Player, "OK_CHOICE")
					return
				elseif(canjoin == 7) then
					Print("%s Bot can always join the team of their choice! Are you a bot?", self.tag)
					return
				else --6
					Print("%s GetCanJoinTeam function error", self.tag)
					return
				end
			end
			
		
		Print("%s JoinTeam function error", self.tag)
		return   
	else
		return
	end
end

function Plugin:PostJoinTeam( Gamerules, Player, OldTeam, NewTeam, Force, ShineForce )
	self:updateValues()
end

function Plugin:ClientConfirmConnect( Client )
	--Print("ClientConfirmConnect - update AVG values")
	Shine.Timer.Simple( 4, function (Timer ) --Delayed because sometimes skill values are not yet initialized//
		self:updateValues()
	    self:SendNetworkMessage( Client, "DisplayScreenText", { show = true }, true )
		
	end)
end

function Plugin:ClientDisconnect( Client )
	--Print("Player disconnect - update AVG values")
	self:updateValues()
end

function Plugin:updateValues()
	playersinfo = Shared.GetEntitiesWithClassname("PlayerInfoEntity")
	--first create an Array with the skills values and teams associate
	local totPlayer=playersinfo:GetSize()
	local skills = {}
	local teams = {}
	for i, Ent in ientitylist( playersinfo ) do
		local playerskill=Ent.playerSkill
		if(Ent.teamNumber ~= 3 ) then --not spectating
			table.insert(teams, Ent.teamNumber)
			table.insert(skills, playerskill)
			--Print(string.format("Playername: %s steamid: %s teamname: %s skill: %d", Ent.playerName,  tostring( Ent.steamId ), Shine:GetTeamName( Ent.teamNumber, true ), Ent.playerSkill))
		end
	end
	self:RefreshGlobalsValues(teams, skills, totPlayer)
	
end



--Refresh the AVG skill of the connected players, the marines, the aliens and ignore spectators skill
function Plugin:RefreshGlobalsValues(teams, skills, totPlayer)
		
		local totPlayersMarines=0
		local totPlayersAliens=0
		local avg=0
		local avgt1=0
		local avgt2=0
		
		for key,teamNumber in ipairs(teams) do
			if(skills[key] ~= nil and skills[key] ~= -1) then   --ignore bots and players without skill
				if(teamNumber == 1 ) then --Marines 
					totPlayersMarines=totPlayersMarines+1
					avgt1=avgt1+skills[key]
					avg=avg+skills[key]
				elseif (teamNumber == 2 ) then --Aliens
					totPlayersAliens=totPlayersAliens+1
					avgt2=avgt2+skills[key]
					avg=avg+skills[key]
				elseif (teamNumber ==  3) then --Spectate
					--Ignore the players in spectators
					totPlayer=totPlayer-1
				else --ReadyRoom (4)
					avg=avg+skills[key]
				end
			end
		end
		
		if totPlayer ~= 0 then
			avg=avg/totPlayer			
		end
		if totPlayersMarines ~= 0 then
			avgt1=avgt1/totPlayersMarines
		end
		if totPlayersAliens ~= 0 then
			avgt2=avgt2/totPlayersAliens
		end
		self.avgglobal = avg
		self.avgteam1 = avgt1
		self.avgteam2 = avgt2
		self.totPlayersMarines=totPlayersMarines
		self.totPlayersAliens=totPlayersAliens
		
		
		--Update datatable values
		self.dt.avgteam1=avgt1
		self.dt.avgteam2=avgt2
		self.dt.totPlayersMarines=totPlayersMarines
		self.dt.totPlayersAliens=totPlayersAliens
		self.dt.triggertextupdate=(self.dt.triggertextupdate+1)%10
		--Print("%s RefreshGlobalsValues(): G: %d - %d M: %d - %d A: %d - %d", self.tag, totPlayer, self.avgglobal, totPlayersMarines, avgt1, totPlayersAliens, avgt2)
		
end


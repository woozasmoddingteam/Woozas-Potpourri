local Plugin = {}
Plugin.NotifyBad = { 255,0,0 }
Plugin.NotifyGood = { 0,255,0 }
Plugin.NotifyEqual = { 0, 150, 255 }



function Plugin:SetupDataTable()
    self:AddDTVar( "integer (0 to 10000)", "avgteam1", 0 )
    self:AddDTVar( "integer (0 to 10000)", "avgteam2", 0 )
	self:AddDTVar( "integer (0 to 100)", "totPlayersMarines", 0 )
	self:AddDTVar( "integer (0 to 100)", "totPlayersAliens", 0 )
	--The below var is used, to hide directly the text when you join spectator and directly shows it back when you re-join the RR
	self:AddDTVar( "integer (0 to 10)", "triggertextupdate", 0)
	self:AddDTVar( "boolean", "inform", true )
	self:AddNetworkMessage( "DisplayScreenText", { show = "boolean" }, "Client" )
end

Shine:RegisterExtension( "jointeam", Plugin )




function Plugin:Initialise()
	Print("Shine plugin Jointeam loaded version 20170306_18:35")
	if(Server) then
			self.dt.inform=self.Config.InformPlayer
	end

	--self:CreateCommands()
	self.Enabled = true
	return true
end

function Plugin:CreateCommands()
	local Commands = Plugin.Commands

	local function Runtest()
		Print("testing plugin Jointeam...")
		Script.Load( "test/test_init.lua")
		return true
	end
	
	self:BindCommand( "sh_jointeam_ut", "jointeam_ut", Runtest, false )
end



function Plugin:NetworkUpdate( Key, OldValue, NewValue )

 if Client then
	self:UpdateScreenTextStatus()
 end
 
end

--The function define if a player witch team(s), he can join.
--The value returned is:
	-- 0: Can join any team
	-- 1: can join only marines and improve balance
	-- 2: can join only aliens and improve balance
	-- 3: can join marines and decrease balance (but less than aliens)
	-- 4: can join aliens and decrease balance (but less than  marines)
	-- 5: can join any team and decrease the balance identically whatever the team he choose
	-- 6: can join anyteam, function malfunctionned.
	-- 7: playerskill == -1, the player is probably a bot

--For testing we must pass all arguments, instead of using plugins variables
function Plugin:GetCanJoinTeam(avgt1, avgt2, numPlayert1, numPlayert2, playerskill)

	if(playerskill == -1) then
		return 7
	end
	
	local newavgt1=(avgt1*numPlayert1+playerskill)/(numPlayert1+1)
	local newavgt2=(avgt2*numPlayert2+playerskill)/(numPlayert2+1)

	--Print("Skill: %d  t1(count/avg/newavg): %d/%d/%d t2(count/avg/newavg): %d/%d/%d", playerskill, numPlayert1, avgt1, newavgt1, numPlayert2, avgt2, newavgt2 )

	local deltaCurrent = math.abs((avgt1-avgt2))
	local deltaT1 = math.abs((newavgt1-avgt2))
	local deltaT2 = math.abs((newavgt2-avgt1))

	if((deltaT1 <= deltaCurrent) and (deltaT2 <= deltaCurrent)) then
		--Improve balance when joining anyteam
		return 0	
	elseif((deltaT1 <= deltaCurrent) and (deltaT2 > deltaCurrent)) then
		--Improve balance when joining marines team only 
		return 1
	elseif((deltaT1 > deltaCurrent) and (deltaT2 <= deltaCurrent)) then
		--Improve balance when joining aliens team only 
		return 2
	elseif((deltaT1 > deltaCurrent) and (deltaT2 > deltaCurrent)) then
		--Never improve balance when joining, we need to find the team where he does less damage
		if(deltaT1 < deltaT2) then
			return 3
		elseif(deltaT1 > deltaT2)then
			return 4
		else --deltaT1 == deltaT2
			return 5
		end
	else
	--Should never be reach
		return 6
	end
	
	

end


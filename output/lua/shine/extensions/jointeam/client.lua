local Plugin = Plugin
local Shine = Shine
local SGUI = Shine.GUI
local screentext_current
local screentext_JoinM
local screentext_JoinA
Plugin.screentext_current=screentext_current
Plugin.screentext_JoinM=screentext_JoinM
Plugin.screentext_JoinA=screentext_JoinA
Plugin.current_color= { 0, 150, 255}
Plugin.JoinM_color= { 0, 150, 255}
Plugin.JoinA_color= { 0, 150, 255}

function Plugin:Initialise()
	--dealing with the menu
	local old = MainMenu_OnCloseMenu;
	function MainMenu_OnCloseMenu()
	  old();
	  --Print("Menu was closed!");
	  local teamnumber = Client.GetLocalClientTeamNumber()
	  --close menu when client is in RR returns 0 or -1 for some obscure reasons
	  if((teamnumber == 0 or teamnumber == -1) and self.screentext_current ~= nil and self.screentext_JoinM ~= nil and self.screentext_JoinA ~= nil) then --RR
		  self.screentext_current.Obj:SetIsVisible(true)
		  self.screentext_JoinM.Obj:SetIsVisible(true)
		  self.screentext_JoinA.Obj:SetIsVisible(true)
	  end
	end
	self.oldOnClose = old;
	local old = MainMenu_OnOpenMenu;
	function MainMenu_OnOpenMenu()
		  old();
		  --Print("Menu was opened!");
		  if(self.screentext_current ~= nil and self.screentext_JoinM ~= nil and self.screentext_JoinA ~= nil) then
			  self.screentext_current.Obj:SetIsVisible(false)
			  self.screentext_JoinM.Obj:SetIsVisible(false)
			  self.screentext_JoinA.Obj:SetIsVisible(false)
		  end
	end
	self.oldOnOpen = old;
	--end dealing with the menu

	return true
end

function Plugin:UpdateScreenTextStatus()
	if(self.dt.inform == true) then
		--On postjoin server hook, the datatable values are updated and I just have to check the team of the player
		--to know if I must show the message
		local teamnumber = Client.GetLocalClientTeamNumber()
		--teamnumber
		-- -1 = just connect, no team
		-- 0 = RR
		-- 1 = Marines
		-- 2 = Alien
		-- 3 = Spectate
		local player=Client.GetLocalPlayer()
		--Print(player.playerSkill)
		if(teamnumber == -1 or teamnumber == 0) then
			local playerskill=player.playerSkill
			
			if(playerskill ~= -1) then
				
				local avgt1=self.dt.avgteam1
				local avgt2=self.dt.avgteam2
				local totPlayersMarines=self.dt.totPlayersMarines
				local totPlayersAliens=self.dt.totPlayersAliens
				local newavgt1=(avgt1*totPlayersMarines+playerskill)/(totPlayersMarines+1)
				local newavgt2=(avgt2*totPlayersAliens+playerskill)/(totPlayersAliens+1)
				local deltaCurrent = math.abs((avgt1-avgt2))
				local deltaT1 = math.abs((newavgt1-avgt2))
				local deltaT2 = math.abs((newavgt2-avgt1))
				
				local canjoin=self:GetCanJoinTeam(avgt1, avgt2, totPlayersMarines, totPlayersAliens, playerskill)
				if(canjoin==0 or canjoin==7) then
					self.JoinM_color=self.NotifyGood
					self.JoinA_color=self.NotifyGood
				elseif(canjoin==1 or canjoin==3) then
					self.JoinM_color=self.NotifyGood
					self.JoinA_color=self.NotifyBad
				elseif(canjoin==2 or canjoin==4) then
					self.JoinM_color=self.NotifyBad
					self.JoinA_color=self.NotifyGood
				elseif(canjoin==5 or canjoin==6) then
					self.JoinM_color=self.NotifyEqual
					self.JoinA_color=self.NotifyEqual
				end
				
					self.screentext_current =Shine.ScreenText.Add( "screentext_current", {
								X =0.6,
								Y = 0.5,
								Text = string.format("%s M: %d Delta: %d A: %d", self:GetPhrase( "TEXT_CURRENT" ), avgt1, deltaCurrent, avgt2),
								R = self.current_color[1],
								G = self.current_color[2],
								B = self.current_color[3],
								Alignment = 0
							})
					self.screentext_current.Obj:SetIsVisible(true)
					
					self.screentext_JoinM =Shine.ScreenText.Add( "screentext_JoinM", {
										X =0.6,
										Y = 0.55,
										Text = string.format("%s M %d Delta: %d  A: %d", self:GetPhrase( "TEXT_JOIN_M" ), newavgt1,deltaT1,avgt2),
										R = self.JoinM_color[1],
										G = self.JoinM_color[2],
										B = self.JoinM_color[3],
										Alignment = 0
									})
					self.screentext_JoinM.Obj:SetIsVisible(true)
					
					
					self.screentext_JoinA =Shine.ScreenText.Add( "screentext_JoinA", {
										X =0.6,
										Y = 0.6,
										Text = string.format("%s M %d Delta: %d  A: %d", self:GetPhrase( "TEXT_JOIN_A" ), avgt1, deltaT2,newavgt2),
										R = self.JoinA_color[1],
										G = self.JoinA_color[2],
										B = self.JoinA_color[3],
										Alignment = 0
									})
					self.screentext_JoinA.Obj:SetIsVisible(true)
			else
				--The player has no skill value (bot, or new players)
				if(self.screentext_current) then
				self.screentext_current.Obj:SetIsVisible(false)
				self.screentext_JoinM.Obj:SetIsVisible(false)
				self.screentext_JoinA.Obj:SetIsVisible(false)
				end
			end
		else --player just connect or is not in ReadyRoom
			if(self.screentext_current) then
			self.screentext_current.Obj:SetIsVisible(false)
			self.screentext_JoinM.Obj:SetIsVisible(false)
			self.screentext_JoinA.Obj:SetIsVisible(false)
			end
		end
	
	end
end


function Plugin:ReceiveDisplayScreenText( Data )
         if(Data.show == true) then
			self:UpdateScreenTextStatus()
		else
			if(self.screentext_current) then
				self.screentext_current.Obj:SetIsVisible(false)
				self.screentext_JoinM.Obj:SetIsVisible(false)
				self.screentext_JoinA.Obj:SetIsVisible(false)
			end
		end
end


function Plugin:Cleanup()
	Shine.ScreenText.Remove("screentext_current")
	self.screentext_current = nil

	Shine.ScreenText.Remove("screentext_JoinM")
	self.screentext_JoinM = nil
	
	Shine.ScreenText.Remove("screentext_JoinA")
	self.screentext_JoinA = nil

	self.BaseClass.Cleanup( self )
	
	MainMenu_OnOpenMenu = self.oldOnOpen;
	MainMenu_OnCloseMenu = self.oldOnClose;
	

	self.Enabled = false
	
end
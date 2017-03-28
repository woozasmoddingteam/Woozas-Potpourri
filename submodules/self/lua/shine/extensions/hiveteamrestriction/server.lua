--[[
    Shine Hive Team Restriction - Server
]]
Script.Load( "lua/shine/core/server/playerinfohub.lua" )

local Shine = Shine
local InfoHub = Shine.PlayerInfoHub

local StringFormat = string.format

local Plugin = Plugin

Plugin.Version = "1.0"
Plugin.NS2Only = true

Plugin.Conflicts = {
	DisableThem = {
		"norookies",
		"rookiesonly"
	}
}

Plugin.HasConfig = true
Plugin.ConfigName = "HiveTeamRestriction.json"

Plugin.DefaultConfig = {
    AllowSpectating = true,
    ShowSwitchAtBlock = false,
	CheckKD = {
		Enable = false,
		Min = 0.5,
		Max = 3,
	},
    CheckPlayTime = {
        Enable = true,
	    Min = 350,
	    Max = 0,
	    UseSteamPlayTime = true
    },
	CheckSkillRating = {
		Enable = true,
		Min = 1000,
		Max = 0
	},
	CheckLevel = {
		Enable = false,
		Min = 20,
		Max = 0
	},
	CheckWL = {
		Enable = false,
		Min = 1,
		Max = 3
	},
    ShowInform = true,
    InformMessage = "This server is Hive stats restricted",
    BlockMessage = "You don't fit to the Hive stats limits on this server:",
    KickMessage = "You will be kicked in %s seconds",
	WaitMessage = "Please wait while your Hive stats are getting fetched",
    Kick = true,
    Kicktime = 60,
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

Plugin.PrintName = "Hive Team Restriction"
Plugin.NotifyPrefixColour = { 100, 255, 100 }

function Plugin:Initialise()
	self.Enabled = true

    self:CheckForSteamTime()
    self:BuildBlockMessage()

    return true
end

function Plugin:CheckForSteamTime()
	if self.Config.CheckPlayTime.Enable and self.Config.CheckPlayTime.UseSteamPlayTime then
		InfoHub:Request( self.PrintName, "STEAMPLAYTIME" )
	end
end

function Plugin:ClientConfirmConnect( Client )
    local Player = Client:GetControllingPlayer()
    if self.Config.ShowInform and Player then self:Notify( Player, self.Config.InformMessage ) end
end

function Plugin:ClientDisconnect( Client )
    local SteamId = Client:GetUserId()
    if not SteamId or SteamId <= 0 then return end

    self:DestroyTimer(StringFormat( "Kick_%s", SteamId ))
end

function Plugin:JoinTeam( _, Player, NewTeam, _, ShineForce )
    if ShineForce or self.Config.AllowSpectating and NewTeam == kSpectatorIndex or NewTeam == kTeamReadyRoom then
        self:DestroyTimer( StringFormat( "Kick_%s", Player:GetSteamId() ))
        return
    end

	return self:Check( Player )
end

function Plugin:OnReceiveSteamData( Client )
    self:AutoCheck( Client )
end

function Plugin:OnReceiveHiveData( Client )
    self:AutoCheck( Client )
end

function Plugin:AutoCheck( Client )
	if self.Config.AllowSpectating then return end

    local Player = Client:GetControllingPlayer()
    local SteamId = Client:GetUserId()

    if not Player or not InfoHub:GetIsRequestFinished( SteamId, self.PrintName ) then return end

    self:Check( Player )
end

function Plugin:Notify( Player, Message, Format, ... )
	if not Player or not Message then return end

	if Shine.IsType(Message, "table") then
		for i, line in ipairs(Message) do
			if i == 1 then
				Shine:NotifyDualColour( Player, 100, 255, 100, StringFormat("[%s]",self.PrintName),
						255, 255, 255, line )
		    else
	            Shine:NotifyColour(Player, 255, 255, 255, line )
		    end
        end
	else
		Shine:NotifyDualColour( Player, 100, 255, 100, StringFormat("[%s]", self.PrintName),
				255, 255, 255, Message, Format, ... )
	end

end

--The Extravalue might be usefull for childrens of this plugin
function Plugin:Check( Player, Extravalue, Silent )
    PROFILE("HiveTeamRestriction:Check()")
    if not Player then return end

	local Client = Player:GetClient()
    if not Shine:IsValidClient( Client ) or Shine:HasAccess( Client, "sh_ignorestatscheck" ) then return end
    
    local SteamId = Client:GetUserId()
    if not SteamId or SteamId < 1 then return end
	
    if not InfoHub:GetIsRequestFinished( SteamId, self.PrintName ) then
        self:Notify( Player, self.Config.WaitMessage )
        return false
    end

    local Playerdata = InfoHub:GetHiveData( SteamId )

    --check hive timeouts
    if not Playerdata then return end

    local passed = self:CheckValues( Playerdata, SteamId, Extravalue )

    if passed == false then
	    if not Silent then
		    self:Notify( Player, self.BlockMessage)
		    if self.Config.ShowSwitchAtBlock then
			    self:SendNetworkMessage( Client, "ShowSwitch", {}, true )
		    end
		    self:Kick( Player )
	    end

	    return false
    else
		self:DestroyTimer( StringFormat( "Kick_%s", SteamId ))
    end
end

function Plugin:CheckValues( Playerdata, SteamId )
	local Config = self.Config

	if not self.Passed then self.Passed = {} end
	if self.Passed[SteamId] then return self.Passed[SteamId] end

	--check if Player fits to the PlayTime
	if Config.CheckPlayTime.Enable then
		local Playtime = Playerdata.playTime

		if Config.CheckPlayTime.UseSteamPlayTime then
			local SteamTime = InfoHub:GetSteamData( SteamId ).PlayTime
			if SteamTime and SteamTime > Playtime then
				Playtime = SteamTime
			end
		end


		if Playtime < Config.CheckPlayTime.Min * 3600 or
				(Config.CheckPlayTime.Max > 0 and Playtime > Config.CheckPlayTime.Max * 3600) then
			self.Passed[SteamId] = false
			return false
		end
	end

	if Config.CheckSkillRating.Enable then
		local Skill = Playerdata.skill
		if Skill < Config.CheckSkillRating.Min or
				( Config.CheckSkillRating.Max > 0 and Skill > Config.CheckSkillRating.Max ) then
			self.Passed[SteamId] = false
			return false
		end
	end

	if Config.CheckWL.Enable then
		local Wins = Playerdata.wins
		local Looses = Playerdata.loses
		if Looses < 1 then Looses = 1 end
		local WL = Wins / Looses

		if WL < Config.CheckWL.Min or
				( Config.CheckWL.Max > 0 and WL > Config.CheckWL.Max ) then
			self.Passed[SteamId] = false
			return false
		end
	end

	if Config.CheckLevel.Enable then
		local Level = Playerdata.level
		if Level < Config.CheckLevel.Min or
				( Config.CheckLevel.Max > 0 and Level > Config.CheckLevel.Max ) then
			self.Passed[SteamId] = false
			return false
		end
	end

	if Config.CheckKD.Enable then
		local Deaths = Playerdata.deaths
		local Kills = Playerdata.kills
		if Deaths < 1 then Deaths = 1 end
		local KD = Kills / Deaths

		if KD < Config.CheckKD.Min or
				( Config.CheckKD.Max > 0 and KD > Config.CheckKD.Max ) then
			self.Passed[SteamId] = false
			return false
		end
	end

	self.Passed[SteamId] = true
	return true
end

function Plugin:BuildBlockMessage()
	local MessageLines = {
		self.Config.BlockMessage
	}
	local Config = self.Config

	if Config.CheckPlayTime.Enable then
		MessageLines[#MessageLines + 1] = "Playtime (in hours):"
		MessageLines[#MessageLines + 1] = StringFormat("    Min: %s", Config.CheckPlayTime.Min)
		if Config.CheckPlayTime.Max > 0 then
			MessageLines[#MessageLines + 1] = StringFormat("    Max: %s", Config.CheckPlayTime.Max)
		end
	end

	if Config.CheckSkillRating.Enable then
		MessageLines[#MessageLines + 1] = "Hive rating:"
		MessageLines[#MessageLines + 1] = StringFormat("    Min: %s", Config.CheckSkillRating.Min)
		if Config.CheckSkillRating.Max > 0 then
			MessageLines[#MessageLines + 1] = StringFormat("    Max: %s", Config.CheckSkillRating.Max)
		end
	end

	if Config.CheckWL.Enable then
		MessageLines[#MessageLines + 1] = "Hive W/L ratio:"
		MessageLines[#MessageLines + 1] = StringFormat("    Min: %s", Config.CheckWL.Min)
		if Config.CheckWL.Max > 0 then
			MessageLines[#MessageLines + 1] = StringFormat("    Max: %s", Config.CheckWL.Max)
		end
	end

	if Config.CheckLevel.Enable then
		MessageLines[#MessageLines + 1] = "Hive level:"
		MessageLines[#MessageLines + 1] = StringFormat("    Min: %s", Config.CheckLevel.Min)
		if Config.CheckLevel.Max > 0 then
			MessageLines[#MessageLines + 1] = StringFormat("    Max: %s", Config.CheckLevel.Max)
		end
	end

	if Config.CheckKD.Enable then
		MessageLines[#MessageLines + 1] = "Hive K/D ratio:"
		MessageLines[#MessageLines + 1] = StringFormat("    Min: %s", Config.CheckKD.Min)
		if Config.CheckKD.Max > 0 then
			MessageLines[#MessageLines + 1] = StringFormat("    Max: %s", Config.CheckKD.Max)
		end
	end

	self.BlockMessage = MessageLines
end

Plugin.DisconnectReason = "You didn't fit to the set hive stats restrictions"
function Plugin:Kick( Player )
    if not self.Config.Kick then return end
    
    local Client = Player:GetClient()
    if not Shine:IsValidClient( Client ) then return end
    
    local SteamId = Client:GetUserId() or 0
    if SteamId <= 0 then return end
    
    if self:TimerExists( StringFormat( "Kick_%s", SteamId )) then return end
    
    self:Notify( Player, StringFormat( self.Config.KickMessage, self.Config.Kicktime ))
        
    self:CreateTimer( StringFormat( "Kick_%s", SteamId ), 1, self.Config.Kicktime, function( Timer )
        if not Shine:IsValidClient( Client ) then
            Timer:Destroy()
            return
        end
		
		local Player = Client:GetControllingPlayer()
		
        local Kicktimes = Timer:GetReps()
        if Kicktimes == 10 then self:Notify( Player, StringFormat( self.Config.KickMessage, Kicktimes ) ) end
        if Kicktimes <= 5 then self:Notify( Player, StringFormat( self.Config.KickMessage, Kicktimes ) ) end
        if Kicktimes <= 0 then
            Shine:Print( "Client %s [ %s ] was kicked by %s. Kicking...", true, Player:GetName(), SteamId, self.PrintName)
            Client.DisconnectReason = self.DisconnectReason
            Server.DisconnectClient( Client )
        end    
    end)    
end

--Restrict teams also at voterandom
function Plugin:PreShuffleOptimiseTeams ( TeamMembers )
	for i = 1, 2 do
		for j = #TeamMembers[i], 1, -1 do
			local Player = TeamMembers[i][j]

			if self:Check(Player, nil, true) == false then
				--Move player into the ready room
				pcall( Gamerules.JoinTeam, Gamerules, Player, kTeamReadyRoom, nil, true )

				--remove the player's entry in the table
				table.remove(TeamMembers[i], j)
			end
		end
	end
end

function Plugin:Cleanup()
    InfoHub:RemoveRequest(self.PrintName)

    self.BaseClass.Cleanup( self )

    self.Enabled = false
end
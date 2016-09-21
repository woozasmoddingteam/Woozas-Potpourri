--[[
    Shine No Rookies - Server
]]
local Plugin = Plugin

Plugin.Version = "1.0"

Plugin.ConfigName = "RookiesOnly.json"
Plugin.DefaultConfig =
{
    Mode = 1, -- 1: Level 2: Playtime
    MaxPlaytime = 20,
    MaxLevel = 5,
    ShowInform = false,
    InformMessage = "This server is rookies only",
    AllowSpectating = true,
    BlockMessage = "This server is rookies only",
    Kick = true,
    Kicktime = 20,
    KickMessage = "You will be kicked in %s seconds",
    WaitMessage = "Please wait while we fetch your stats.",
    ShowSwitchAtBlock = false,
	MaxBots = 12,
	CommanderBots = true,
	UseRookieOnlyMode = true,
	CommanderBotSwapping = true
}

Plugin.PrintName = "Rookies Only"
Plugin.DisconnectReason = "You are not a rookie anymore"

Plugin.Conflicts = {
	DisableUs = {
		"hiveteamrestriction",
		"norookies"
	}
}

--Setup Hooks
do
	local SetupClassHook = Shine.Hook.SetupClassHook

	SetupClassHook("NS2Gamerules", "OnCommanderLogout", "PreOnCommanderLogout", "ActivePre")
	SetupClassHook("NS2Gamerules", "OnCommanderLogin", "PreOnCommanderLogin", "ActivePre")
	SetupClassHook("NS2Gamerules", "GetCanJoinTeamNumber", "PostGetCanJoinTeamNumber", function (OldFunc, ...)
		local a, b = OldFunc( ... )

		local Hook = Shine.Hook.Call("PostActiveGetCanJoinTeamNumber", a, b)

		return Hook or a, b
	end)
end

function Plugin:Initialise()
    self.Enabled = true

    --These checks should not be needed but better be on the safe side
    self.Config.MaxPlaytime = math.min( 100 , self.Config.MaxPlaytime)
    self.Config.MaxLevel = math.min( 10 , self.Config.MaxLevel)

    self:CheckForSteamTime()
    self:BuildBlockMessage()

    return true
end

function Plugin:OnFirstThink()

	local gamerules = GetGamerules()

	if not gamerules then
		self.Enabled = false
		return
	end

	if self.Config.UseRookieOnlyMode and gamerules.SetRookieMode then
		gamerules:SetRookieMode(true)
	end

	if self.Config.MaxBots > 0 and gamerules.SetMaxBots then
		gamerules:SetMaxBots(self.Config.MaxBots , self.Config.CommanderBots)
	end
end

function Plugin:PreOnCommanderLogout()
	if not self.Config.CommanderBotSwapping then
		return true
	end
end

function Plugin:OnCommanderLogin()
	if not self.Config.CommanderBotSwapping then
		return true
	end
end

function Plugin:PostActiveGetCanJoinTeamNumber( _, Reason )
	if Reason and Reason > 0 then
		return true
	end
end

function Plugin:CheckForSteamTime() --This plugin does not use steam times at all
end

function Plugin:BuildBlockMessage()
    self.BlockMessage = self.Config.BlockMessage
end

function Plugin:CheckValues( Playerdata, SteamId )
	if not self.Passed then self.Passed = {} end
	if self.Passed[SteamId] then return self.Passed[SteamId] end

    if self.Config.Mode == 1 then
        if self.Config.MaxLevel > 0 and Playerdata.level < self.Config.MaxLevel then
            self.Passed[SteamId] = true
            return true
        end
    elseif self.Config.MaxPlaytime > 0 and Playerdata.playTime < self.Config.MaxPlaytime * 3600 then
	    self.Passed[SteamId] = true
        return true
    end

	self.Passed[SteamId] = false
	return false
end

function Plugin:Cleanup()
	local gamerules = GetGamerules()

	if gamerules then
		if self.Config.MaxBots > 0 and gamerules.SetMaxBots then
			gamerules:SetMaxBots(0 , false)
		end

		if self.Config.UseRookieOnlyMode and gamerules.SetRookieMode then
			gamerules:SetRookieMode(false)
		end
	end

	InfoHub:RemoveRequest(self.PrintName)

	self.BaseClass.Cleanup( self )

	self.Enabled = false
end

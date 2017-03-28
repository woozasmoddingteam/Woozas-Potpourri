--[[
    Shine BotManager
]]

local Shine = Shine
local Notify = Shared.Message

local Plugin = {}
Plugin.Version = "0.2"

function Plugin:SetupDataTable()
	self:AddDTVar( "boolean", "AllowPlayersToReplaceComBots", true )
	self:AddDTVar( "boolean", "LoginCommanderBotAtLogout", false )
end

do
	if Server then
		Shine.Hook.SetupClassHook("NS2Gamerules", "OnCommanderLogout", "PreOnCommanderLogout", "PassivePre")
		Shine.Hook.SetupClassHook("NS2Gamerules", "OnCommanderLogout", "PostGetRookieMode", "PassivePost")
		Shine.Hook.SetupClassHook("NS2Gamerules", "OnCommanderLogin", "PreGetRookieMode", "PassivePre")
		Shine.Hook.SetupClassHook("NS2Gamerules", "OnCommanderLogin", "PostGetRookieMode", "PassivePost")
	end

	Shine.Hook.Add( "Think", "LoadBotManageHooks", function()
		local SetupGlobalHook = Shine.Hook.SetupGlobalHook

		if GetTeamHasCommander then
			SetupGlobalHook("GetTeamHasCommander", "PreGetRookieMode", "PassivePre")
			SetupGlobalHook("GetTeamHasCommander", "PostGetRookieMode", "PassivePost")

			Shine.Hook.SetupClassHook("GameInfo", "GetRookieMode", "GetRookieMode", "ActivePre")

			Shine.Hook.Remove( "Think", "LoadBotManageHooks")
		end
	end)

end

function Plugin:Initialise()
	self.Enabled = true
	return true
end

function Plugin:PreGetRookieMode()
	self.OverrideRookieMode = true
end

function Plugin:PreOnCommanderLogout()
	self.OverrideRookieMode = self.dt.LoginCommanderBotAtLogout
end

function Plugin:PostGetRookieMode()
	self.OverrideRookieMode = false
end

function Plugin:GetRookieMode(GameInfo)
	if self.OverrideRookieMode and self.dt.AllowPlayersToReplaceComBots ~= GameInfo.rookieMode then
		return true
	end
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
	self.Enabled = false
end

Shine:RegisterExtension( "botmanager", Plugin )

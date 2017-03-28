--[[
    Shine Auto performance profiling
]]

local Shine = Shine
local Notify = Shared.Message

local Plugin = {}
Plugin.Version = "1.1"

Plugin.HasConfig = true
Plugin.ConfigName = "AutoPerfProfile.json"
Plugin.DefaultConfig =
{
	LogPerf = true,
	LogTraces = false
}
Plugin.CheckConfig = true

function Plugin:Initialise()
	self.Enabled = true

	--enable trace tracking
	if self.Config.LogTraces then
		Shared.ConsoleCommand("tt on")
		Shared.ConsoleCommand("tr_log")
	end

	return true
end

function Plugin:SetGameState( Gamerules, NewState, OldState )
	if not self.Config.LogPerf then return end

	if NewState == kGameState.Started then
		Shared.ConsoleCommand("p_logall")
	end
end

function Plugin:Cleanup()
	if self.Config.LogPerf then
		Shared.ConsoleCommand("p_endlog")
	end

	self.BaseClass.Cleanup( self )
	self.Enabled = false
end

Shine:RegisterExtension( "autoperfprofile", Plugin )


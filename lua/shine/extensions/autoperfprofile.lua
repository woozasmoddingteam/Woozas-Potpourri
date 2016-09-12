--[[
    Shine Auto performance profiling
]]

local Shine = Shine
local Notify = Shared.Message

local Plugin = {}
Plugin.Version = "1.0"

Plugin.HasConfig = false

function Plugin:Initialise()
	self.Enabled = true
	return true
end

function Plugin:SetGameState( Gamerules, NewState, OldState )
	if NewState == kGameState.Started then
		Shared.ConsoleCommand("p_logall")
	elseif NewState > kGameState.Started then
		Shared.ConsoleCommand("p_endlog")
	end
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
	self.Enabled = false
end

Shine:RegisterExtension( "autoperfprofile", Plugin )


--[[
    Shine PasswordReset
]]

local Shine = Shine
local Notify = Shared.Message

local Plugin = {}
Plugin.Version = "1.0"

Plugin.HasConfig = true
Plugin.ConfigName = "PasswordReset.json"
Plugin.DefaultConfig =
{
    MinPlayer = 0,
    ResetTime = 10,
    DefaultPassword = ""    
}
Plugin.CheckConfig = true

function Plugin:Initialise()
    self.Enabled = true
    return true
end


function Plugin:ClientConnect()
    self:DestroyAllTimers()
end

function Plugin:ClientDisconnect()
    if Shine.GetHumanPlayerCount() > self.Config.MinPlayer then return end
    self:SimpleTimer( self.Config.ResetTime * 60, function()
	if Shine.GetHumanPlayerCount() > self.Config.MinPlayer then return end
        Notify( "[PasswordReset] Reseting password to default one" )
        Server.SetPassword( tostring( self.Config.DefaultPassword ) or "" )
    end )
end

function Plugin:Cleanup()
    self.BaseClass.Cleanup( self )
    self.Enabled = false
end

Shine:RegisterExtension( "passwordreset", Plugin )
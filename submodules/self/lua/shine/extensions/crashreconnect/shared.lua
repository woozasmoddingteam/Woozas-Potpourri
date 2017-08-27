local Shine = Shine

local Plugin = {}
Plugin.Version = "1.2"
Plugin.DefaultState = true

function Plugin:Initialise()
	self.Enabled = true
	return true
end

Shine:RegisterExtension("crashreconnect", Plugin)
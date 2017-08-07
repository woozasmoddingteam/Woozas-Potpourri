local Plugin = {}
Plugin.Version = "1.0"

function Plugin:Initialise()
	self.Enabled = true
	return true
end

Shine:RegisterExtension("crashreconnect", Plugin)

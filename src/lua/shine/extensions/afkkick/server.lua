local Plugin = Plugin

function Plugin:Initialise()
	AFKMixin.OnProcessMove = nil

	self.Enabled = true
	return true
end

local reason = string.format("You were AFK for too long (%i)! Sorry.", Plugin.AFKTimeKick)

function Plugin:ReceiveKick(client)
	Server.DisconnectClient(client, reason)
end

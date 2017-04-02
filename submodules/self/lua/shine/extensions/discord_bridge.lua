local Shine = Shine
local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	outbound = "localhost:64999/discordbridge_to"
	inbound  = "localhost:64999/discordbridge_from"
}

local function fromDiscord(msg)
	Shine:NotifyColour(nil, 50, 170, 120, msg)
	Shared.SendHTTPRequest(self.inbound, "POST", fromDiscord)
end

function Plugin:Initialise()
	self.botaddress = self.Config.address
	self.Enabled = true
	Shared.SendHTTPRequest(self.inbound, "POST", fromDiscord)

	return true
end

function Plugin:PlayerSay(client, message)
	if not message.teamOnly then
		local name = client:GetControllingPlayer().name
		Shared.SendHTTPRequest(self.outbound .. "?**" .. name .. "**: " .. message.message, "POST")
	end
end

Shine:RegisterExtension("discord_bridge", Plugin)

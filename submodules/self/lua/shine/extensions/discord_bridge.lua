local Shine = Shine
local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	address = "localhost:8080/discordbridge"
}

local function discordSay(client, msg)
	Shine:NotifyColour(nil, 50, 170, 120, msg)
end

function Plugin:Initialise()
	self.botaddress = self.Config.address
	local command = self:BindCommand("sh_discord_say", {}, discordSay, false, true)
	command:AddParam {
		Type = "string",
		TakeRestOfLine = true
	}

	self.Enabled = true
	return true
end

function Plugin:PlayerSay(client, message)
	if not message.teamOnly then
		Shared.SendHTTPRequest(self.botaddress, "POST", {
            player = assert(client:GetControllingPlayer().name),
            message  = assert(message.message),
            server = "playground"
        })
	end
end

Shine:RegisterExtension("discord_bridge", Plugin)

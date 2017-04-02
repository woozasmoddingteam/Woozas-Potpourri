local Shine = Shine
local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	outbound = "localhost:64999",
	inbound  = "localhost:64998"
}

local inbound
local outbound

local function fromDiscord(msg)
	Shine:NotifyColour(nil, 50, 170, 120, msg)
	Shared.SendHTTPRequest(inbound, "POST", fromDiscord)
end

function Plugin:Initialise()
	inbound = self.Config.inbound
	outbound = self.Config.outbound
	self.Enabled = true
	Shared.SendHTTPRequest(inbound, "POST", fromDiscord)

	return true
end

function Plugin:PlayerSay(client, message)
	if not message.teamOnly then
		local player = client:GetControllingPlayer()
		local name = player:GetName()
		local team = player:GetTeam().name
		Shared.SendHTTPRequest(outbound, "POST", {str = "__<" .. team .. ">__ **" .. name .. "**: " .. message.message})
	end
end

Shine:RegisterExtension("discord_bridge", Plugin)

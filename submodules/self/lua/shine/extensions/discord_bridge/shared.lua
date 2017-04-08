local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	outbound = "localhost:64999/to",
	inbound  = "localhost:64999/from",
	language = "enGB",
}

Shine:RegisterExtension("discord_bridge", Plugin)

--[[
	Apheriox Discord plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "Discord.json"

local webUrl = "https://discord.gg/0v5uwb6jDlQ7tKWs"

Plugin.DefaultConfig = {
	ShowMenuEntry = true
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	self:CreateCommands()

	self.dt.ShowMenuEntry = self.Config.ShowMenuEntry

	self.Enabled = true

	return true
end

function Plugin:ShowDiscord( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "Apheriox Discord"
	}, true )
end

function Plugin:CreateCommands()

	local function Discord( Client )
		if not Client then return end

		self:ShowDiscord( Client )
	end
	local DiscordCommand = self:BindCommand( "sh_discord", "discord", Discord, true )
	DiscordCommand:Help( "Shows the hidden Apheriox Discord Page" )

	local function ShowDiscord( _, Target )
		self:ShowDiscord( Target )
	end
	local ShowDiscordCommand = self:BindCommand( "sh_showdiscord", "showdiscord", ShowDiscord)
	ShowDiscordCommand:AddParam{ Type = "client" }
	ShowDiscordCommand:Help( "<player> Shows the Discord page to the given player." )


end

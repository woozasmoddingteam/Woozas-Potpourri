--[[
	NS2 Trader plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "trader_bot.json"

local webUrl = "https://steamcommunity.com/profiles/76561198278971888"

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

function Plugin:Showtrader_bot( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "NS2 Trader"
	}, true )
end

function Plugin:CreateCommands()

	local function Trade_bot( Client )
		if not Client then return end

		self:ShowDiscord( Client )
	end
	local DiscordCommand = self:BindCommand( "sh_trader_bot", "trader_bot", Trader_bot, true )
	DiscordCommand:Help( "Shows the NS2 Trader Page" )

	local function ShowTrader_bot( _, Target )
		self:ShowDiscord( Target )
	end
	local ShowDiscordCommand = self:BindCommand( "sh_showtrader_bot", "trader_bot", Trader_bot)
	ShowDiscordCommand:AddParam{ Type = "client" }
	ShowDiscordCommand:Help( "<player> Shows the NS2 Trader page to the given player." )
	

end



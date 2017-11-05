--[[
	Apheriox Trader plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "Trader.json"

local webUrl = "http://steamcommunity.com/profiles/76561198278971888/"

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

function Plugin:ShowTrader( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "NS2 Trader"
	}, true )
end

function Plugin:CreateCommands()

	local function Trader( Client )
		if not Client then return end

		self:ShowTrader( Client )
	end
	local TraderCommand = self:BindCommand( "sh_trader", "trader", Trader, true )
	TraderCommand:Help( "Shows the Stream Profile page of the NS2 Trader" )

	local function ShowTrader( _, Target )
		self:ShowTrader( Target )
	end
	local ShowTraderCommand = self:BindCommand( "sh_showtrader", "showtrader", ShowTrader)
	ShowTraderCommand:AddParam{ Type = "client" }
	ShowTraderCommand:Help( "<player> Shows the Trader page to the given player." )


end

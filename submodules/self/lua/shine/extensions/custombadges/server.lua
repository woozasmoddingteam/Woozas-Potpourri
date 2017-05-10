--[[
	Apheriox custombadges Tutorial.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "CustomBadgesTutorial.json"

local webUrl = "http://apheriox.com/custom-badges-tutorial/"

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

function Plugin:Showcustombadges( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "Apheriox custombadges Tutorial"
	}, true )
end

function Plugin:CreateCommands()

	local function custombadges( Client )
		if not Client then return end

		self:Showcustombadges( Client )
	end
	local custombadgesCommand = self:BindCommand( "sh_custombadges", "custombadges", custombadges, true )
	custombadgesCommand:Help( "Shows Apheriox custom badges Site" )

	local function Showcustombadges( _, Target )
		self:Showcustombadges( Target )
	end
	local ShowcustombadgesCommand = self:BindCommand( "sh_showcustombadges", "showcustombadges", Showcustombadges)
	ShowcustombadgesCommand:AddParam{ Type = "client" }
	ShowcustombadgesCommand:Help( "<player> Shows the Apheriox custom badges  Tutorial to the player" )
	

end



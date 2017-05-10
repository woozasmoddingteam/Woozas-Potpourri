--[[
	Apheriox Donation plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "Donation.json"

local webUrl = "http://apheriox.com/news/donations/
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

function Plugin:ShowDonation( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "Apheriox Donation"
	}, true )
end

function Plugin:CreateCommands()

	local function Donation( Client )
		if not Client then return end

		self:ShowDonation( Client )
	end
	local DonationCommand = self:BindCommand( "sh_donation", "donation", Donation, true )
	DonationCommand:Help( "Shows the hidden Apheriox Donation Page" )

	local function ShowDonation( _, Target )
		self:ShowDonation( Target )
	end
	local ShowDonationCommand = self:BindCommand( "sh_showdonation", "showdonation", ShowDonation)
	ShowDonationCommand:AddParam{ Type = "client" }
	ShowDonationCommand:Help( "<player> Shows the Donation page to the given player." )
	

end



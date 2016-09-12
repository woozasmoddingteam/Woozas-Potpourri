--[[
	Wooza Approved plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "Approved.json"

local webUrl = "http://apheriox.com/showthread.php/2493-Wooza-Approved"

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

function Plugin:ShowApproved( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "Wooza Approved"
	}, true )
end

function Plugin:CreateCommands()

	local function Approved( Client )
		if not Client then return end

		self:ShowApproved( Client )
	end
	local ApprovedCommand = self:BindCommand( "sh_approved", "approved", Approved, true )
	ApprovedCommand:Help( "Shows the hidden Apheriox Donation Page" )

	local function ShowApproved( _, Target )
		self:ShowApproved( Target )
	end
	local ShowApprovedCommand = self:BindCommand( "sh_showapproved", "showapproved", ShowApproved)
	ShowApprovedCommand:AddParam{ Type = "client" }
	ShowApprovedCommand:Help( "<player> Shows the Wooza Approved page to the given player." )
	

end



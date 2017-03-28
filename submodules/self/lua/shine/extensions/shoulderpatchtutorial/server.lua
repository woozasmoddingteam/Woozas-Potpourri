--[[
	Apheriox ShoulderPatchTutorial plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "ShoulderPatchTutorial.json"

local webUrl = "http://apheriox.com/showthread.php/2856-HOW-TO-Create-your-own-Shoulder-Patch?p=4187#post4187"

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

function Plugin:ShowShoulderPatchTutorial( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "Wooza's Shoulder Patch Tutorial"
	}, true )
end

function Plugin:CreateCommands()

	local function ShoulderPatchTutorial( Client )
		if not Client then return end

		self:ShowShoulderPatchTutorial( Client )
	end
	local ShoulderPatchTutorialCommand = self:BindCommand( "sh_shoulderpatchtutorial", "shoulderpatchtutorial", ShoulderPatchTutorial, true )
	ShoulderPatchTutorialCommand:Help( "Shows the ShoulderPatchTutorial Tutorial" )

	local function ShowShoulderPatchTutorial( _, Target )
		self:ShowShoulderPatchTutorial( Target )
	end
	local ShowShoulderPatchTutorialCommand = self:BindCommand( "sh_showshoulderpatchtutorial", "showshoulderpatchtutorial", ShowShoulderPatchTutorial)
	ShowShoulderPatchTutorialCommand:AddParam{ Type = "client" }
	ShowShoulderPatchTutorialCommand:Help( "<player> Shows the ShoulderPatchTutorial page to the given player." )
	

end



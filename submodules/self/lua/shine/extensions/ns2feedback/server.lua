--[[
	Shine NS2Feedback plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "NS2Feedback.json"

local webUrl = "http://ns2.bplaced.net/feedback.html"

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

function Plugin:ShowFeedback( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "NS2 Feedback"
	}, true )
end

function Plugin:CreateCommands()

	local function Feedback( Client )
		if not Client then return end

		self:ShowFeedback( Client )
	end
	local FeedbackCommand = self:BindCommand( "sh_feedback", "Feedback", Feedback, true )
	FeedbackCommand:Help( "Shows the NS2 feedback pack." )

	local function ShowFeedback( _, Target )
		self:ShowFeedback( Target )
	end
	local ShowFeedbackCommand = self:BindCommand( "sh_showfeedback", "showfeedback", ShowFeedback )
	ShowFeedbackCommand:AddParam{ Type = "client" }
	ShowFeedbackCommand:Help( "<player> Shows the NS2 feedback page to the given player." )

end


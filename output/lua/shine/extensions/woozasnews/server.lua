--[[
	Shine Wooza's News plugin.
]]
local Shine = Shine
local Plugin = Plugin

Plugin.HasConfig = true
Plugin.ConfigName = "WoozaNews.json"

local webUrl = "http://steamcommunity.com/groups/Apheriox#announcements"

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

function Plugin:ShowWoozanews( Client )
	if not Shine:IsValidClient( Client ) then return end

	Shine.SendNetworkMessage( Client, "Shine_Web", {
		URL = webUrl,
		Title = "Wooza's News"
	}, true )
end

function Plugin:CreateCommands()

	local function Woozanews( Client )
		if not Client then return end

		self:ShowWoozanews( Client )
	end
	local WoozanewsCommand = self:BindCommand( "sh_woozanews", "woozanews", Woozanews, true )
	WoozanewsCommand:Help( "Shows Wooza's News Page" )

	local function ShowWoozanews( _, Target )
		self:ShowWoozanews( Target )
	end
	local ShowWoozanewsCommand = self:BindCommand( "sh_showwoozanews", "showwoozanews", ShowWoozanews )
	ShowWoozanewsCommand:AddParam{ Type = "client" }
	ShowWoozanewsCommand:Help( "<player> Shows Wooza's News to the given player." )

end


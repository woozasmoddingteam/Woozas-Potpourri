--[[
	Shine Custom Text Commands
]]

local Shine = Shine 
local Plugin = {}

local StringFormat = string.format
local unpack = unpack
local pairs = pairs

Plugin.Version = "1.0"

Plugin.HasConfig = true
Plugin.ConfigName = "CustomTextCommands.json"
Plugin.DefaultConfig = {
	MesagerName = "Shine",
	MessagerNameColor = { 255, 255, 255 },
	Commands = {
		hishine = "Hi\nThanks for talking to me ;)"
	}
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	self.Enabled = true
	self:CreateCommands()
	return true
end

function Plugin:Notify( Player, Message, Format, ... )
	local MesagerName = self.Config.MesagerName
	local r,g,b = unpack( self.Config.MessagerNameColor )
	Shine:NotifyDualColour( Player, r, g, b, MesagerName, 255, 255, 255, Message, Format, ... )
end

function Plugin:CreateCommands()
	local Commands = self.Config.Commands
	for name, output in pairs( Commands ) do
		local commandname = StringFormat( "sh_cc_%s", name )
		local function TempFunc( Client )
			local Player = Client:GetControllingPlayer()
			if Player then
				self:Notify( Player, output )
			end
		end
		self:BindCommand( commandname, name, TempFunc, true )
	end
end

Shine:RegisterExtension( "customtextcommands", Plugin )
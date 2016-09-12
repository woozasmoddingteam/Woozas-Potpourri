--[[
	Apheriox Custom Badges Tutorial.
]]

local Plugin = Plugin
local Shine = Shine

function Plugin:Initialise()
	self:UpdateMenuEntry( self.dt.ShowMenuEntry )
	
	self.Enabled = true

	return true
end

function Plugin:UpdateMenuEntry( NewValue )
	if not self.MenuEntry then
		Shine.VoteMenu:EditPage( "Main", function( Menu )
			self.MenuEntry = Menu:AddSideButton( "Badges Tutorial", function()
				Menu.GenericClick( "sh_custombadges" )
			end )

			self.MenuEntry:SetIsVisible( NewValue )
		end )
	else
		self.MenuEntry:SetIsVisible( NewValue )
	end
end

function Plugin:Cleanup()
	self:UpdateMenuEntry( false )

	self.BaseClass.Cleanup( self )

	self.Enabled = false
end



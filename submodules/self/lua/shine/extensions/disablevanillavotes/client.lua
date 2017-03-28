--[[
	DisableVanillaVotes - Client
	Inspired by the TF plugin from ShamelessCookie which can be found here:
	https://github.com/ShamelessCookie/tactical-freedom/blob/master/output/lua/shine/extensions/tf_disablestockvoting.lua
 ]]

local Plugin = Plugin
local Shine = Shine

function Plugin:ReceiveMessage( Data )
	local ButtonBound = Shine.VoteButtonBound
	local VoteButton = ButtonBound and ( Shine.VoteButton or "M" ) or
			"votemenu button not bound! Please use 'bind key sh_votemenu' in the console to bind it to the given key"

	local Message = string.format(Data.Message, VoteButton)

	Shine.AddChatText( self.dt.R, self.dt.G, self.dt.B, "[Vote Disabled]", 1, 1, 1, Message )
end
--[[
	ShoulderPatchesExtra
	ZycaR (c) 2016
]]

Script.Load("lua/spe/ShoulderPatchesMixin.lua")

local ns2_OnInitialized = Player.OnInitialized
function Player:OnInitialized()
    InitMixin(self, ShoulderPatchesMixin)
    ns2_OnInitialized(self)
end

if Server then

    -- Copy patches data from player to spectator and back for respawn purpose
    local ns2_CopyPlayerDataFrom = Player.CopyPlayerDataFrom
    function Player:CopyPlayerDataFrom(player)
	ns2_CopyPlayerDataFrom(self, player)
	self.spePatchIndex = player.spePatchIndex
	self.spePatchEffect = player.spePatchEffect
	self.spePatches = player.spePatches
	self.speOptionsSent = player.speOptionsSent
    end

end

-- Modder's version of AddMixinNetworkVars()
Shared.LinkClassToMap("Player", nil, ShoulderPatchesMixin.networkVars)

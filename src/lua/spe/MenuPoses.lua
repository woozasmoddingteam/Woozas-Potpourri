--[[
	ShoulderPatchesExtra
	ZycaR (c) 2016
]]

Script.Load("lua/spe/ShoulderPatchesConfig.lua")

local old = MenuPoses.Update

local model
local function new(self, deltaTime)
    old(self, deltaTime)

    -- set parameters to properly render menu poses patch
    local model = model.renderModel
    if MainMenu_GetIsOpened() and model ~= nil then
		local player = Client.GetLocalPlayer()
		local name, index = ShoulderPatchesConfig:GetClientShoulderPatch(player)
		model:SetMaterialParameter("spePatchIndex", index)
		model:SetMaterialParameter("spePatchEffect", player and player.spePatchEffect or 0)
    end
end

debug.replacemethod("MenuPoses", "Update", new)

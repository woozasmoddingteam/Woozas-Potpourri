
function GhostModelUI_GetTunnelText()
	
	local player = Client.GetLocalPlayer()

	if player and player.GetGhostModelTechId and player:GetGhostModelTechId() == kTechId.GorgeTunnel and not player:GetCrouching() then
		return "Crouch while building to preserve the oldest entrance"
	end
    return ""
end
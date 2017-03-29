--[[
 	ShoulderPatchesExtra
	ZycaR (c) 2016
	
NOTE: Shared message from clients to server.
Should be included in any file working with message
]]

if not kSetShoulderPatchMessage then

    kSetShoulderPatchMessage = {
        spePatchIndex = "integer (0 to 1024)",
    }

    Shared.RegisterNetworkMessage("SetShoulderPatch", kSetShoulderPatchMessage)
    
    if Client then
        function SendShoulderPatchUpdate(index)
            if MainMenu_IsInGame and MainMenu_IsInGame() then
                Client.SendNetworkMessage("SetShoulderPatch", { 
                    spePatchIndex = index
                }, true)
            end
        end
    end

    if Server then
        local function OnSetShoulderPatch(client, message)
            local player = client and client:GetControllingPlayer()
            if player and HasMixin(player, "ShoulderPatches") then
                player:SetShoulderPatchIndex(message.spePatchIndex or 0)
                
                
                local steamId = tostring(client:GetUserId())
                Shared.Message(".. SPE SteamID: ".. steamId .. " - Index: ".. tostring(message.spePatchIndex))
            end
        end
        Server.HookNetworkMessage("SetShoulderPatch", OnSetShoulderPatch)
    end

end

if not kShoulderPatchEffectMessage then

    kShoulderPatchEffectMessage = {
        spePatchEffect = "integer (0 to 1)",
    }
    Shared.RegisterNetworkMessage("ShoulderPatchEffect", kShoulderPatchEffectMessage)
    
    if Client then
        function SendShoulderPatchEffect(effect)
            Client.SendNetworkMessage("ShoulderPatchEffect", { 
                spePatchEffect = effect
            }, true)
        end

        local function OnCommandEffect(effect)
            return function() 
                Shared.Message("SPE Effect Command:" .. tostring(effect))
                SendShoulderPatchEffect(effect)
            end
        end
        Event.Hook( "Console_spe_default", OnCommandEffect(0.0) )
        Event.Hook( "Console_spe_rotate", OnCommandEffect(1.0) )
        
    end

    if Server then
        local function OnShoulderPatchEffect(client, message)
            local player = client and client:GetControllingPlayer()
            if player and HasMixin(player, "ShoulderPatches") then
                player:SetShoulderPatchEffect(message.spePatchEffect or 0)
            end
        end
        Server.HookNetworkMessage("ShoulderPatchEffect", OnShoulderPatchEffect)
    end

end
Shared.RegisterNetworkMessage("LocalVoiceChatSettings", {
	global = "boolean"
})

if Server then
	local voiceSettings = {}

	Server.HookNetworkMessage("LocalVoiceChatSettings", function(client, msg)
		voiceSettings[client:GetId()] = msg.global
	end)

	local kMaxWorldSoundDistance = 30

	function NS2Gamerules:GetCanPlayerHearPlayer(listenerPlayer, speakerPlayer, channelType)

		if listenerPlayer:GetClientMuted(speakerPlayer:GetClientIndex()) then
			return false
		end

		if channelType == nil or channelType == VoiceChannel.Global then
			return
				listenerPlayer:GetTeamNumber() == speakerPlayer:GetTeamNumber()
				or Server.GetConfigSetting("alltalk")
				or Server.GetConfigSetting("pregamealltalk") and not self:GetGameStarted()
		end

		if listenerPlayer:GetDistanceSquaredToEntity(speakerPlayer) < (kMaxWorldSoundDistance^2) then
			return voiceSettings[speakerPlayer:GetClientIndex()] or listenerPlayer:GetTeamNumber() == speakerPlayer:GetTeamNumber()
		end

		return Shared.GetCheatsEnabled() and Shared.GetDevMode()

	end

end


local teamonly = {
	global = false
}

local notteamonly = {
	global = true
}

function GUIVoiceChat:SendKeyEvent(key, down, amount)

    local player = Client.GetLocalPlayer()

    if down then
        if not ChatUI_EnteringChatMessage() then
            if not player:isa("Commander") then
                if GetIsBinding(key, "VoiceChat") then
                    self.recordBind = "VoiceChat"
                    self.recordEndTime = nil
                    Client.VoiceRecordStartGlobal()
                elseif GetIsBinding(key, "LocalVoiceChat") then
                    self.recordBind = "LocalVoiceChat"
                    self.recordEndTime = nil
					Client.SendNetworkMessage("LocalVoiceChatSettings", notteamonly)
                    Client.VoiceRecordStartEntity(player, Vector.origin)
                elseif GetIsBinding(key, "LocalVoiceChatTeam") then
                    self.recordBind = "LocalVoiceChatTeam"
                    self.recordEndTime = nil
					Client.SendNetworkMessage("LocalVoiceChatSettings", teamonly)
                    Client.VoiceRecordStartEntity(player, Vector.origin)
                end
            else
                if GetIsBinding(key, "VoiceChatCom") then
                    self.recordBind = "VoiceChatCom"
                    self.recordEndTime = nil
                    Client.VoiceRecordStartGlobal()
                end
            end
        end
    else
        if self.recordBind and GetIsBinding( key, self.recordBind ) then
            self.recordBind = nil
            self.recordEndTime = Shared.GetTime() + Client.GetOptionFloat("recordingReleaseDelay", 0.15)
        end
    end

end

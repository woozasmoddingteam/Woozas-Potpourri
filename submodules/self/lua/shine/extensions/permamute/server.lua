--[[
    Shine permamute plugin
]]
local Shine = Shine
local Plugin = Plugin
local StringFormat = string.format
Plugin.Version = "1.0"
Plugin.HasConfig = true --Does this plugin have a config file?
Plugin.ConfigName = "permamute.json" --What's the name of the file?
Plugin.DefaultState = true --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = false --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.

Plugin.DefaultConfig = {
    AllTalkLocal = true,
    AllTalk = false,
    AllTalkSpectator = false,
    AllTalkPreGame = false,
    PermamuteFile = "config://PermamutedPlayers.json"
}

Plugin.CheckConfig = true --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = true --Should we check the types of values in the config to make sure they match our default's types?

--[[
local function Dump(variable, name, depth)
    if name == nil then
        name = "(this)"
    end

    if depth == nil then
        depth = 0
    end

    if type(variable) == "nil" then
        Shared.Message(name .. ' = (nil)')
        -- _G._G = _G
        -- function, userdata, thread, cdata
    elseif type(variable) == "number" then
        Shared.Message(name .. ' = ' .. variable)
    elseif type(variable) == "boolean" then
        if variable then
            Shared.Message(name .. ' = true')
        else
            Shared.Message(name .. ' = false')
        end
    elseif type(variable) == "string" then
        Shared.Message(name .. ' = "' .. variable .. '"')
    elseif type(variable) == "table" then
        Shared.Message(name .. ' = (' .. type(variable) .. ')')

        for i, v in pairs(variable) do
            if type(i) ~= "userdata" then
                if v == _G then
                    Shared.Message(name .. "." .. i)
                elseif v ~= variable then
                    if depth >= 5 then
                        Shared.Message(name .. "." .. i .. " (...)")
                    else
                        Dump(v, name .. '.' .. i, depth + 1)
                    end
                else
                    Shared.Message(name .. "." .. i)
                end
            end
        end
    else
        Shared.Message(name .. ' = (' .. type(variable) .. ')')
    end
end
]]

function Plugin:Initialise()
    self.PermamutedPlayers = Shine.LoadJSONFile(self.Config.PermamuteFile) or {}

    self:CreateCommands()

    self.Enabled = true

    return true
end

function Plugin:IsClientPermamuted(Client, ChannelType)
    local ClientID = "" .. Client:GetUserId() or 0
    local PermamuteData = self.PermamutedPlayers[ClientID]
    if not PermamuteData or not PermamuteData[ChannelType] then
        return false
    end
    if PermamuteData[ChannelType] == true then return true end
    if PermamuteData[ChannelType] > os.time() then return true end
    self:CheckRemoveClientFromPermamute(Client)
    return false
end

function Plugin:CheckRemoveClientFromPermamute(Client)
    local ClientID = "" .. Client:GetUserId() or 0
    local PermamuteData = self.PermamutedPlayers[ClientID]
    local canBeRemoved = true

    for channel, value in pairs(PermamuteData) do
        if PermamuteData[channel] == true or PermamuteData[channel] > os.time() then
            canBeRemoved = false
        end
    end

    if canBeRemoved then
        self.PermamutedPlayers[ClientID] = nil
        Shine.SaveJSONFile(self.PermamutedPlayers, self.Config.PermamuteFile)
    end
end

function Plugin:PlayerSay(Client, Message)
    if self:IsClientPermamuted(Client, "chat") then
        local ClientID = "" .. Client:GetUserId() or 0
        local now = os.time()
        local Duration = self.PermamutedPlayers[ClientID]["chat"] or now -- thats the time of unmute
        if Duration == true then Duration = now end
        Duration = Duration - now
        local DurationString = string.TimeToDuration(Duration)

        self:SendNetworkMessage(Client, "PermamuteNotifcation", {
            str = StringFormat("Your text communication was disabled by an admin %s", DurationString);
            }, true);
        return ""
    end
end

local function IsPregameAllTalk(self, Gamerules)
    return self.Config.AllTalkPreGame and Gamerules:GetGameState() == kGameState.NotStarted
end

local function IsSpectatorAllTalk(self, Listener)
    return self.Config.AllTalkSpectator and Listener:GetTeamNumber() == (kSpectatorIndex or 3)
end

-- Will need updating if it changes in NS2Gamerules...
local MaxWorldSoundDistance = 30 * 30
local DisableLocalAllTalkClients = {}

function Plugin:RemoveAllTalkPreference(Client)
    DisableLocalAllTalkClients[Client] = nil
end

function Plugin:ReceiveEnableLocalAllTalk(Client, Data)
    DisableLocalAllTalkClients[Client] = not Data.Enabled
end

Plugin.SpamProtect = 0

function Plugin:CanPlayerHearPlayer(Gamerules, Listener, Speaker, ChannelType)
    local SpeakerClient = Server.GetOwner(Speaker)

    if SpeakerClient and self:IsClientPermamuted(SpeakerClient, "voice") then
        Shared.Message("is muted")
        if (os.clock() > self.SpamProtect) then
            local ClientID = "" .. SpeakerClient:GetUserId() or 0
            local now = os.time()
            local Duration = self.PermamutedPlayers[ClientID]["voice"] or now -- thats the time of unmute
            if Duration == true then Duration = now end
            Duration = Duration - now
            local DurationString = string.TimeToDuration(Duration)

            self:SendNetworkMessage(SpeakerClient, "PermamuteNotifcation", {
                str = StringFormat("Your voice communication was disabled by an admin %s", DurationString);
                }, true);
            self.SpamProtect = os.clock() + 5
        end
        return false
    end

    -- Check if the listerner has the speaker muted.
    if Listener:GetClientMuted(Speaker:GetClientIndex()) then return false end

    -- local chat
    if ChannelType and ChannelType ~= VoiceChannel.Global then
        local ListenerClient = Server.GetOwner(Listener)
        -- Default behaviour for those that have chosen to disable it.
        if (ListenerClient and DisableLocalAllTalkClients[ListenerClient]) or (SpeakerClient and DisableLocalAllTalkClients[SpeakerClient]) then return false end
        -- Assume non-global means local chat, so "all-talk" means true if distance check passes.
        if self.Config.AllTalkLocal or self.Config.AllTalk or IsPregameAllTalk(self, Gamerules) or IsSpectatorAllTalk(self, Listener) then return Listener:GetDistanceSquared(Speaker) < MaxWorldSoundDistance end
        return false
    end

    -- if cheats AND dev mode is on, they can hear each other
    if Shared.GetCheatsEnabled() and Shared.GetDevMode() then return true end

    -- alltalk
    if self.Config.AllTalk or IsPregameAllTalk(self, Gamerules) or IsSpectatorAllTalk(self, Listener) then return true end

    -- If both players have the same team number, they can hear each other
    if Listener:GetTeamNumber() == Speaker:GetTeamNumber() then return true end

    return false
end

function Plugin:CreateCommands()
    local function PermamutePlayer(Client, Target, ChannelType, Duration)
        ChannelType = string.lower(ChannelType)

        if ChannelType ~= "voice" and ChannelType ~= "chat" and ChannelType ~= "text" and ChannelType ~= "both" and ChannelType ~= "all"  then
            Shared.Message("<Target> <voice|chat|text|both|all> [duration]")
            Shared.Message("Failed to specify type of permamute (voice|chat|text|both|all).")
            return
        end

        local Player = Client and Client:GetControllingPlayer()
        local PlayerName = Player and Player:GetName() or "Console"
        local ID = Client and Client:GetUserId() or 0
        local TargetPlayer = Target:GetControllingPlayer()
        local TargetName = TargetPlayer and TargetPlayer:GetName() or "<unknown>"
        local TargetID = "" .. Target:GetUserId() or 0
        local DurationString = string.TimeToDuration(Duration)

        if TargetID == 0 then
            Shared.Message("<Target> <voice|chat|text|both|all> [duration]")
            Shared.Message("Invalid Target")
            return
        end

        if not self.PermamutedPlayers[TargetID] then self.PermamutedPlayers[TargetID] = {} end
        if ChannelType == "voice" or ChannelType == "both" or ChannelType == "all"  then
            self.PermamutedPlayers[TargetID]["voice"] = Duration == 0 and true or os.time() + Duration
        end
        if ChannelType == "chat" or ChannelType == "text" or ChannelType == "both" or ChannelType == "all" then
            self.PermamutedPlayers[TargetID]["chat"] = Duration == 0 and true or os.time() + Duration
        end
        Shine.SaveJSONFile(self.PermamutedPlayers, self.Config.PermamuteFile)

        Shine:AdminPrint(nil, "%s[%s] permamuted %s of %s[%s] %s", true, PlayerName, ID, ChannelType, TargetName, TargetID, DurationString)
        Shine:CommandNotify(Client, "permamuted %s for %s %s.", true, ChannelType, TargetName, DurationString)
    end

    local PermamuteCommand = self:BindCommand("sh_permamute", "permamute", PermamutePlayer)

    PermamuteCommand:AddParam{
        Type = "client"
    }

    PermamuteCommand:AddParam{
        Type = "string",
        TakeRestOfLine = false,
        MaxLength = 5,
        Optional = false,
        Help = "voice | chat | text | both | all",
        Default = "voice"
    }

    PermamuteCommand:AddParam{
        Type = "time",
        Round = true,
        Min = 0,
        Optional = true,
        Help = "Duration, i.e. 2h30m or 7d",
        Default = 0
    }

    PermamuteCommand:Help("Permamutes the given player chat or voice. If no duration is given, the effect is permanent.")


    local function UnpermamutePlayer(Client, Target, ChannelType)
        local TargetPlayer = Target:GetControllingPlayer()
        local TargetName = TargetPlayer and TargetPlayer:GetName() or "<unknown>"
        local TargetID = "" .. Target:GetUserId() or 0

        if not self.PermamutedPlayers[TargetID] then
            Shared.Message(StringFormat("%s is not permamuted.", TargetName))
            return
        end

        if ChannelType == nil or ChannelType == "" or ChannelType == "both" or ChannelType == "all" then
            self.PermamutedPlayers[TargetID] = nil
        else
            ChannelType = string.lower(ChannelType)

            if ChannelType ~= "voice" and ChannelType ~= "chat" and ChannelType ~= "text" then
                Shared.Message("<Target> [voice|chat|text]")
                Shared.Message(StringFormat("Type %s is unknown (must be voice or chat or both)", ChannelType))
                return
            end

            if ChannelType == "text" then ChannelType = "chat" end

            self.PermamutedPlayers[TargetID][ChannelType] = nil
            self:CheckRemoveClientFromPermamute(Target)
        end

        Shine.SaveJSONFile(self.PermamutedPlayers, self.Config.PermamuteFile)
        local Player = Client and Client:GetControllingPlayer()
        local PlayerName = Player and Player:GetName() or "Console"
        local ID = Client and Client:GetUserId() or 0
        Shine:AdminPrint(nil, "%s[%s] un-permamuted %s[%s]%s", true, PlayerName, ID, TargetName, TargetID, ChannelType and " (" .. ChannelType .. ")" or "")
        Shine:CommandNotify(Client, "un-permamuted %s%s.", true, TargetName, ChannelType and " (" .. ChannelType .. ")" or "")
    end

    local UnpermamuteCommand = self:BindCommand("sh_unpermamute", "unpermamute", UnpermamutePlayer)

    UnpermamuteCommand:AddParam{
        Type = "client"
    }

    UnpermamuteCommand:AddParam{
        Type = "string",
        TakeRestOfLine = false,
        MaxLength = 5,
        Optional = true,
        default = "all",
        Help = "chat or voice or both. leave empty for both"
    }

    UnpermamuteCommand:Help("Stops permamuting the given player.")
end

function Plugin:Cleanup()
    self.BaseClass.Cleanup(self)
    self.Enabled = false
end

--[[
    Shine discord bridge plugin
]]

local Shine = Shine
local Plugin = {}

Plugin.Version = "3.0.0"
Plugin.HasConfig = true --Does this plugin have a config file?
Plugin.ConfigName = "DiscordBridge.json" --What's the name of the file?
Plugin.DefaultState = true --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = false --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.
Plugin.CheckConfig = true --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = false --Should we check the types of values in the config to make sure they match our default's types?
Plugin.DefaultConfig = {
    DiscordBridgeURL = "",
    ServerIdentifier = "",
    SendPlayerAllChat = true,
    SendPlayerJoin = true,
    SendPlayerLeave = true,
    SendMapChange = true,
    SendRoundWarmup = false,
    SendRoundPregame = false,
    SendRoundStart = true,
    SendRoundEnd = true,
    SendAdminPrint = false,
    SpamMinIntervall = 0.5,
}

local fieldSep = ""


function Plugin:Initialise()
    if self.Config.DiscordBridgeURL == "" then
        return false, "You have not provided a path to the discord bridge server. See readme."
    end

    if string.UTF8Sub( self.Config.DiscordBridgeURL, 1, 7 ) ~= "http://" then
        return false, "The website url of your config is not legit, only http is supported."
    end

    if self.Config.ServerIdentifier == "" then
        return false, "You have not provided an identifier for the server. See readme."
    end

    if self.Config.SendAdminPrint then
        self:SimpleTimer( 0.5, function()
            self.OldServerAdminPrint = ServerAdminPrint
            function ServerAdminPrint(client, message)
                self.OldServerAdminPrint(client, message)
                Plugin.SendToDiscord(self, "adminprint", {msg = message})
            end
        end)
    end

    Log("Discord Bridge Version %s loaded", Plugin.Version)
    self.StartTime = os.clock()
    self.lastGameStateChangeTime = Shared.GetTime()
    self.lastChatMessageSendTime = os.clock()
    self.queuedChatMessages = {}

    self:OpenConnection()

    self.Enabled = true
    return self.Enabled
end


function Plugin:HandleDiscordChatMessage(data)
    local chatMessage = string.UTF8Sub(data.msg, 1, kMaxChatLength)
    if not chatMessage or string.len(chatMessage) <= 0 then return end
    local playerName = data.user
    if not playerName then return end
    Shine:NotifyDualColour(nil, 114, 137, 218, "(Discord) " .. playerName .. ":", 181, 172, 229, chatMessage)
end


function Plugin:HandleDiscordRconMessage(data)
    Shared.ConsoleCommand(data.msg)
end


function Server.GetActiveModTitle(activeModNum)
    local activeId = Server.GetActiveModId( activeModNum )
    for modNum = 1, Server.GetNumMods() do
        local modId = Server.GetModId( modNum )
        if modId == activeId then
            return Server.GetModTitle( modNum )
        end
    end
    return "<unknown mod>"
end


local function CollectActiveMods()
    local modIds = {}
    for modNum = 1, Server.GetNumActiveMods() do
        table.insert(modIds, {
            id = Server.GetActiveModId( modNum ),
            name = Server.GetActiveModTitle( modNum ),
        })
    end
    return modIds
end


function Plugin:HandleDiscordInfoMessage(data)
    local gameTime = Shared.GetTime() - self.lastGameStateChangeTime

    local teams = {}
    for _, team in ipairs( GetGamerules():GetTeams() ) do
        local numPlayers, numRookies = team:GetNumPlayers()
        local teamNumber = team:GetTeamNumber()

        local playerList = {}
        local function addToPlayerlist(player)
            table.insert(playerList, player:GetName())
        end
        team:ForEachPlayer(addToPlayerlist)

        teams[teamNumber] = {numPlayers=numPlayers, numRookies=numRookies, players = playerList}
    end

    local message = {
        serverIp       = IPAddressToString( Server.GetIpAddress() ),
        serverPort     = Server.GetPort(),
        serverName     = Server.GetName(),
        version        = Shared.GetBuildNumber(),
        mods           = CollectActiveMods(),
        map            = Shared.GetMapName(),
        state          = kGameState[GetGameInfoEntity():GetState()],
        gameTime       = tonumber( string.format( "%.2f", gameTime ) ),
        numPlayers     = Server.GetNumPlayersTotal(),
        maxPlayers     = Server.GetMaxPlayers(),
        numRookies     = teams[kTeamReadyRoom].numRookies + teams[kTeam1Index].numRookies + teams[kTeam2Index].numRookies + teams[kSpectatorIndex].numRookies,
        teams = teams,
    }

    local jsonData, jsonError = json.encode( message )
    if jsonData and not jsonError then
        Plugin:SendToDiscord("info", {sub = data.msg, msg = jsonData})
    end

    return true
end


Plugin.ResponseHandlers = {
    chat = Plugin.HandleDiscordChatMessage,
    rcon = Plugin.HandleDiscordRconMessage,
    info = Plugin.HandleDiscordInfoMessage,
}


function Plugin:ParseDiscordResponse(data)
    -- when the response is empty the server has another pending response and we can just close this connection
    if data == "" then
        return
    end

    local fields = StringSplit(data, fieldSep)
    if #fields == 3 then
        local response = {
            type = fields[1],
            user = fields[2],
            msg  = fields[3],
        }

        local ResponseHandler = self.ResponseHandlers[response.type]
        if ResponseHandler then
            sendsResponse = ResponseHandler(self, response)
            if sendsResponse then return end
        else
            Log("unknown response type %s", response.type)
        end
    else
        Log("discordbridge: unknown response: >" .. data .. "<")
        return
    end

    self:SimpleTimer( self.Config.SpamMinIntervall , function()
        self:OpenConnection()
    end)
end


local function responseParser(data)
    Plugin:ParseDiscordResponse(data)
end


function Plugin:SendToDiscord(type, payload)
    payload.id = self.Config.ServerIdentifier
    payload.type = type
    Shared.SendHTTPRequest( self.Config.DiscordBridgeURL, "POST", payload, responseParser)
end


function Plugin:OpenConnection()
    self:SendToDiscord("init", {})
end


function Plugin:PlayerSay(client, message)
	if not message.teamOnly and self.Config.SendPlayerAllChat and message.message ~= "" then
        local player = client:GetControllingPlayer()
        local payload = {
            plyr = player:GetName(),
            sid = player:GetSteamId(),
            team = player:GetTeamNumber(),
            msg = message.message
        }
        table.insert(self.queuedChatMessages, payload)
	end
end


function Plugin:Think()
    if #self.queuedChatMessages > 0 and  os.clock() > self.lastChatMessageSendTime + self.Config.SpamMinIntervall then
        self.lastChatMessageSendTime = os.clock()
        local payload = table.remove(self.queuedChatMessages, 1)
        self:SendToDiscord("chat", payload)
    end
end


function Plugin:ClientConfirmConnect(client)
    if self.Config.SendPlayerJoin
        and (os.clock() - self.StartTime) > 120 -- prevent overflow
    then
        local player = client:GetControllingPlayer()
        local numPlayers = Server.GetNumPlayersTotal()
        local maxPlayers = Server.GetMaxPlayers()
        self:SendToDiscord("player", {
            sub = "join",
            plyr = player:GetName(),
            sid = player:GetSteamId(),
            pc = numPlayers .. "/" .. maxPlayers,
            msg = ""
        })
    end
end


function Plugin:ClientDisconnect(client)
    if self.Config.SendPlayerLeave then
        local player = client:GetControllingPlayer()
        local numPlayers = math.max(Server.GetNumPlayersTotal() -1, 0)
        local maxPlayers = Server.GetMaxPlayers()
        self:SendToDiscord("player", {
            sub = "leave",
            plyr = player:GetName(),
            sid = player:GetSteamId(),
            pc = numPlayers .. "/" .. maxPlayers,
            msg = ""
        })
    end
end


function Plugin:SetGameState(GameRules, NewState, OldState)
    local CurState = kGameState[NewState]
    local mapName = "'" .. Shared.GetMapName() .. "'"
    local numPlayers = Server.GetNumPlayersTotal()
    local maxPlayers = Server.GetMaxPlayers()
    local roundTime = Shared.GetTime()
    local playerCount = numPlayers .. "/" .. maxPlayers

    self.lastGameStateChangeTime = Shared.GetTime()

    if self.Config.SendMapChange and CurState == 'NotStarted' and roundTime < 5 then
        self:SendToDiscord("status", {sub = "changemap", msg = "Changed map to " .. mapName})
    end

    if self.Config.SendRoundWarmup and CurState == 'WarmUp' then
        self:SendToDiscord("status", {sub = "warmup", msg = "WarmUp started on " .. mapName, pc = playerCount})
    end

    if self.Config.SendRoundPreGame and CurState == 'PreGame' then
        self:SendToDiscord("status", {sub = "pregame", msg = "PreGame started on " .. mapName, pc = playerCount})
    end

    if self.Config.SendRoundStart and CurState == 'Started' then
        self:SendToDiscord("status", {sub = "roundstart", msg = "Round started on " .. mapName, pc = playerCount})
    end

    if self.Config.SendRoundEnd then
        if CurState == 'Team1Won' then
            self:SendToDiscord("status", {sub = "marinewin", msg = "Marines won on " .. mapName, pc = playerCount})
        elseif CurState == 'Team2Won' then
            self:SendToDiscord("status", {sub = "alienwin", msg = "Aliens won on " .. mapName, pc = playerCount})
        elseif CurState == 'Draw' then
            self:SendToDiscord("status", {sub = "draw", msg = "Draw on " .. mapName, pc = playerCount})
        end
    end
end


function Plugin:Cleanup()

    if self.Config.SendAdminPrint then
        ServerAdminPrint = self.OldServerAdminPrint
    end

    self.BaseClass.Cleanup( self )
    self.Enabled = false
end


Shine:RegisterExtension("discordbridge", Plugin)

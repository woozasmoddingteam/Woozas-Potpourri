--[[
    Shine wonitor plugin
]]

local Shine = Shine
local Plugin = Plugin

Plugin.Version = "2.0"
Plugin.HasConfig = true --Does this plugin have a config file?
Plugin.ConfigName = "wonitor.json" --What's the name of the file?
Plugin.DefaultState = true --Should the plugin be enabled when it is first added to the config?
Plugin.NS2Only = true --Set to true to disable the plugin in NS2: Combat if you want to use the same code for both games in a mod.
Plugin.DefaultConfig = {
    WonitorURL = "",
    ServerIdentifier = "",
    SendWonitorStats = true,
    SendNS2PlusStats = false,
    SendNS2PlusStatsKillFeed = false,
    ShowMenuEntry = true,
    MenuEntryUrl = "",
    MenuEntryName = "Wonitor"
}
Plugin.CheckConfig = true --Should we check for missing/unused entries when loading?
Plugin.CheckConfigTypes = true --Should we check the types of values in the config to make sure they match our default's types?
local verbose = false


function Plugin:Initialise()

    self:CreateCommands()

    if self.Config.WonitorURL == "" then
        return false, "You have not provided a path to the wonitor server. See readme."
    end

    if string.UTF8Sub( self.Config.WonitorURL, 1, 7 ) ~= "http://" then
        return false, "The website url of your config is not legit, only http is supported."
    end

    Shine.Hook.SetupClassHook( "NS2Gamerules", "EndGame", "OnEndGame", "PassivePost" )

    self.dt.ShowMenuEntry = self.Config.ShowMenuEntry
    self.dt.MenuEntryName = self.Config.MenuEntryName

    self.Enabled = true
    self.LastGameState = kGameState.NotStarted
    self.GameStartTime = 0

    return true
end


local function Dump(variable, name, depth)
    if name == nil then name = "(this)" end
    if depth == nil then depth = 0 end

    if type(variable) == "nil" then
        Shared.Message(name .. ' = (nil)')
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
        Shared.Message(name .. ' = (' .. type(variable).. ')')
        for i, v in pairs( variable ) do
            if type(i)~="userdata" then
                if v == _G then
                    Shared.Message(name .. "." .. i)
                elseif v~=variable then
                    if depth >= 5 then
                        Shared.Message(name .. "." .. i .. " (...)")
                    else
                        Dump(v, name .. '.' .. i, depth+1)
                    end
                else -- _G._G = _G
                   Shared.Message(name .. "." .. i)
                end
            end
        end
    else -- function, userdata, thread, cdata
        Shared.Message(name .. ' = (' .. type(variable).. ')')
    end
end


function Plugin:SetGameState( Gamerules, GameState ) -- appends to NS2Gamerules:SetGameState(state) via Shine GlobalHooks
    if (verbose) then
        Shared.Message( string.format(" Wonitor GameState: new State %d", GameState ) )
    end

    if GameState == self.LastGameState then return end

    if GameState == kGameState.NotStarted then

        if (verbose) then
            Shared.Message(" Wonitor GameState: Not Started")
        end

        -- if self.LastGameState == kGameState.PreGame then
            -- commander dropped out or reset after endgame
        -- end

        -- if self.LastGameState == kGameState.Started then
            -- round was restarted
            -- TODO log attempts?
        -- end

    end

    if GameState == kGameState.PreGame then
        -- round is about to start
        if (verbose) then
            Shared.Message(" Wonitor GameState: PreGame")
        end
    end

    if GameState == kGameState.Countdown then
        -- round is about to start
        if (verbose) then
            Shared.Message(" Wonitor GameState: Countdown")
        end
    end

    if GameState == kGameState.Started then
        -- round started
        if (verbose) then
            Shared.Message(" Wonitor GameState: Started")
        end
        self.GameStartTime = Shared.GetTime()
    end

    if GameState == kGameState.Team1Won or GameState == kGameState.Team2Won or GameState == kGameState.Draw then
        -- round ended
        if (verbose) then
            Shared.Message( string.format(" Wonitor GameState: Round Ended %d", GameState ) )
        end

        local winningTeam = nil
        if GameState == kGameState.Team1Won then
            winningTeam = Gamerules:GetTeam1()
        elseif GameState == kGameState.Team2Won then
            winningTeam = Gamerules:GetTeam2()
        end
        self:ReportEndGame( Gamerules, winningTeam )
        self.GameStartTime = 0
    end

    self.LastGameState = GameState
end


local function BoolToInt( bool )
    if bool then
        return 1
    else
        return 0
    end
end


local function Round(num, n)
    local mult = 10^(n or 0)
    return math.floor(num * mult + 0.5) / mult
end


local function FormatCoordinates( coordsString )
    if type(coordsString) ~= "string" then return coordsString end
    local result = ""
    local coords = StringSplit(coordsString, " ")
    for i , coord in ipairs( coords ) do
        local decpointpos = string.find(coord, ".", 1, true) or #coord
        result = result .. string.sub(coord, 1, decpointpos+2)
        if i < 3 then
             result = result .. " "
        end
    end
    return result
end


function Plugin:OnEndGame( Gamerules, WinningTeam ) -- appends to NS2Gamerules:EndGame(WinningTeam) via SetupClassHook
    if self.Config.SendNS2PlusStats and CHUDGetLastRoundStats then
        if (verbose) then
            Shared.Message(" Wonitor: Saving NS2+ Stats")
        end

        if not CHUDGetLastRoundStats then return end -- NS2+ mod not loaded

        local NS2PlusStats = CHUDGetLastRoundStats()
        -- Dump(NS2PlusStats)
        if next(NS2PlusStats) == nil then
            if (verbose) then
                Shared.Message(" Wonitor: No data gathered for this round")
            end
            return
        end

        local data = {}
        data.RoundInfo       = NS2PlusStats.RoundInfo
        data.Locations       = NS2PlusStats.Locations
        data.MarineCommStats = NS2PlusStats.MarineCommStats
        data.ServerInfo      = NS2PlusStats.ServerInfo
        data.PlayerStats     = NS2PlusStats.PlayerStats
        local Research       = NS2PlusStats.Research
        local Buildings      = NS2PlusStats.Buildings
        local KillFeed       = NS2PlusStats.KillFeed

        local function compressPlayerRoundStats(pStats)
            return {
                pStats.timePlayed,
                pStats.timeBuilding,
                pStats.commanderTime,
                pStats.kills,
                pStats.assists,
                pStats.deaths,
                pStats.killstreak,
                pStats.hits,
                pStats.onosHits,
                pStats.misses,
                pStats.playerDamage,
                pStats.structureDamage,
                pStats.score,
            }
        end

        local function compressPlayerClassStats(cStats)
            local status = {}
            for _ , classStat in ipairs( cStats ) do
                table.insert(status, {
                    classStat.statusId,
                    classStat.classTime,
                })
            end
            return status
        end

        local function compressPlayerWeaponStats(wStats)
            return {
                wStats.teamNumber,
                wStats.hits,
                wStats.onosHits,
                wStats.misses,
                wStats.playerDamage,
                wStats.structureDamage,
                wStats.kills,
            }
        end

        if type(data.PlayerStats == "table") then
            for _ , playerStat in pairs( data.PlayerStats ) do
                -- compress the data for transmission
                playerStat[1] = compressPlayerRoundStats(playerStat[1])
                playerStat[2] = compressPlayerRoundStats(playerStat[2])
                playerStat.status = compressPlayerClassStats(playerStat.status)

                for weapon , weaponStat in pairs( playerStat.weapons ) do
                    playerStat.weapons[weapon] = compressPlayerWeaponStats(weaponStat)
                end
            end
        end

        data.Research = {}
        if type(Research == "table") then
            for _ , researchEvent in ipairs( Research ) do
                -- compress the data for transmission
                table.insert(data.Research, {
                    Round(researchEvent.gameTime, 2),
                    researchEvent.teamNumber,
                    researchEvent.researchId,
                })
            end
        end

        data.Buildings = {}
        if type(Buildings == "table") then
            for _ , buildingEvent in ipairs( Buildings ) do
                -- compress the data for transmission
                if buildingEvent.techId ~= "Cyst" then
                    table.insert(data.Buildings, {
                        Round(buildingEvent.gameTime, 2),
                        buildingEvent.teamNumber,
                        buildingEvent.techId,
                        BoolToInt(buildingEvent.destroyed),
                        BoolToInt(buildingEvent.built),
                        BoolToInt(buildingEvent.recycled),
                    })
                end
            end
        end

        if self.Config.SendNS2PlusStatsKillFeed then
            data.KillFeed = {}
            if type(KillFeed == "table") then
                for _ , killEvent in ipairs( KillFeed ) do
                    -- compress the data for transmission
                    table.insert(data.KillFeed, {
                        Round(killEvent.gameTime,2),
                        killEvent.victimClass,
                        killEvent.victimSteamID,
                        killEvent.victimLocation,
                        FormatCoordinates(killEvent.victimPosition),
                        killEvent.killerWeapon,
                        killEvent.killerTeamNumber,
                        killEvent.killerClass,
                        killEvent.killerSteamID,
                        killEvent.killerLocation,
                        FormatCoordinates(killEvent.killerPosition),
                        killEvent.doerLocation,
                        FormatCoordinates(killEvent.doerPosition)
                    })
                end
            end
        end
        self:SendData( "NS2PlusStats", data )
    end
end


function Plugin:ReportEndGame( Gamerules, winningTeam )
    if self.Config.SendWonitorStats then
        if (verbose) then
            Shared.Message(" Wonitor: ReportEndGame")
        end

        local gameTime = Shared.GetTime() - self.GameStartTime
        local winningTeamType = winningTeam and winningTeam.GetTeamType and winningTeam:GetTeamType() or kNeutralTeamType
        local numHives = Gamerules:GetTeam2():GetNumCapturedTechPoints();
        local numCCs   = Gamerules:GetTeam1():GetNumCapturedTechPoints();
        local teams = Gamerules:GetTeams()
        local teamStats = {}
        local teamSkill = 0;

        local function SumTeamSkill( player )
            if not HasMixin(player, "Scoring") then return end
            local skill = player:GetPlayerSkill()
            if  skill ~= -1 then
                teamSkill = teamSkill + skill
            end
        end

        for teamIndex, team in ipairs( teams ) do
            local numPlayers, numRookies = team:GetNumPlayers()

            local teamNumber = team:GetTeamNumber()
            local teamInfo = GetEntitiesForTeam("TeamInfo", teamNumber)
            local kills = 0
            local rtCount = 0
            if table.count(teamInfo) > 0 then
                kills = teamInfo[1]:GetKills()
                rtCount = teamInfo[1]:GetNumCapturedResPoints()
            end

            teamSkill = 0
            team:ForEachPlayer( SumTeamSkill )

            teamStats[teamIndex] = {numPlayers=numPlayers, numRookies=numRookies, teamSkill=teamSkill, rtCount=rtCount, kills=kills}
        end

        local gameInfo = GetGameInfoEntity()

        local InitialHiveTechIdString = "None"
        if Gamerules.initialHiveTechId then
            InitialHiveTechIdString = EnumToString( kTechId, Gamerules.initialHiveTechId )
        end

        local function CollectActiveModIds()
            local modIds = {}
            for modNum = 1, Server.GetNumActiveMods() do
                modIds[modNum] = Server.GetActiveModId( modNum )
            end
            return modIds
        end

        local Params = {
            -- server
            serverIp       = IPAddressToString( Server.GetIpAddress() ),
            serverPort     = Server.GetPort(),
            serverName     = Server.GetName(),
            isRookieServer = Server.GetHasTag("rookie_only"), --Server.GetIsRookieFriendly(),
            isTournamentMode = Gamerules.tournamentMode,
            version        = Shared.GetBuildNumber(),
            modIds         = CollectActiveModIds(),
            time           = Shared.GetGMTString( false ),

            -- round
            map             = Shared.GetMapName(),
            length          = tonumber( string.format( "%.2f", gameTime ) ),
            startLocation1  = Gamerules.startingLocationNameTeam1,
            startLocation2  = Gamerules.startingLocationNameTeam2,
            startPathDistance = Gamerules.startingLocationsPathDistance,
            startHiveTech   = InitialHiveTechIdString,
            winner          = winningTeamType,

            -- players
            numPlayers1     = teamStats[1].numPlayers,
            numPlayers2     = teamStats[2].numPlayers,
            numPlayersRR    = teamStats[3].numPlayers,
            numPlayersSpec  = teamStats[4].numPlayers,
            numPlayers      = Server.GetNumPlayers(), -- gameInfo:GetNumPlayersTotal(), Server.GetNumPlayers(), Server.GetNumPlayersTotal()
            maxPlayers      = Server.GetMaxPlayers(),

            numRookies1     = teamStats[1].numRookies,
            numRookies2     = teamStats[2].numRookies,
            numRookiesRR    = teamStats[3].numRookies,
            numRookiesSpec  = teamStats[4].numRookies,
            numRookies      = teamStats[1].numRookies+teamStats[2].numRookies+teamStats[3].numRookies+teamStats[4].numRookies,

            skillTeam1      = teamStats[1].teamSkill,
            skillTeam2      = teamStats[2].teamSkill,
            averageSkill    = gameInfo:GetAveragePlayerSkill(),
            killsTeam1      = teamStats[1].kills,
            killsTeam2      = teamStats[2].kills,
            kills           = teamStats[1].kills+teamStats[2].kills,

            -- buildings
            numRTs1         = teamStats[1].rtCount,
            numRTs2         = teamStats[2].rtCount,
            numRTs          = teamStats[1].rtCount+teamStats[2].rtCount,
            numHives        = numHives,
            numCCs          = numCCs,
            numTechPointsCaptured = numHives+numCCs,

            --upgrades
            biomassLevel    = Gamerules:GetTeam2():GetBioMassLevel()
        }
        self:SendData( "MatchEnd", Params )
    end
end


local function OnRecieve(data)
    if (verbose) then
        Shared.Message(" Wonitor: response:" .. data)
    end
end


function Plugin:SendData( messageType, Params )
    if messageType == nil then return end
    if Params == nil then Params = {} end

    -- NOTE for backwards compatibility
    Params.messageType = messageType
    Params.serverId    = self.Config.ServerIdentifier

    local jsonData, jsonError = json.encode( Params )
    if jsonData and not jsonError then
        if (verbose) then
            Shared.Message(" Wonitor: Sending to server")
        end
        Shared.SendHTTPRequest( self.Config.WonitorURL, "POST", { messageType = messageType, serverId = self.Config.ServerIdentifier, data = jsonData }, OnRecieve )
    end
end


function Plugin.ShowWonitorStats( Client )
	if not Shine:IsValidClient( Client ) then return end
    Plugin:SendNetworkMessage( Client, "OpenWebpageInSteam", { URL = Plugin.Config.MenuEntryUrl }, true )
end


function Plugin:CreateCommands()
     self:BindCommand( "sh_wonitor", "wonitor", Plugin.ShowWonitorStats, true )
         :Help( "Shows Wonitor Site" )
end


function Plugin:Cleanup()
    self.LastGameState = nil
    self.GameStartTime = nil

    self.BaseClass.Cleanup( self )

    self.Enabled = false
end

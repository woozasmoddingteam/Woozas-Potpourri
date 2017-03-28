
local timeWaveSpawnEnds = 0
local kNoEggsColor = Color(1, 0, 0, 1)
local kWhite = Color(1, 1, 1, 1)
local function OnSetTimeWaveSpawnEnds(message)
    timeWaveSpawnEnds = message.time
end
Client.HookNetworkMessage("SetTimeWaveSpawnEnds", OnSetTimeWaveSpawnEnds)


local function AlienUI_GetWaveSpawnTime()

    if timeWaveSpawnEnds > 0 then
        return timeWaveSpawnEnds - Shared.GetTime()
    end
    
    return 0
    
end
function GUIAlienSpectatorHUD:Update(deltaTime)

    PROFILE("GUIAlienSpectatorHUD:Update")
    
    local waitingForTeamBalance = PlayerUI_GetIsWaitingForTeamBalance()

    local isVisible = not waitingForTeamBalance and GetPlayerIsSpawning()
    self.spawnText:SetIsVisible(isVisible)
    self.eggIcon:SetIsVisible(isVisible)
    
    if isVisible then
    
        local timeToWave = math.floor(AlienUI_GetWaveSpawnTime())
        local timeToGestate = timeToWave + kEmbryoGestateTime + 1
        
        if timeToWave == 0 then
            self.spawnText:SetText(Locale.ResolveString("WAITING_TO_SPAWN"))
        elseif timeToWave < 0 then
            if timeToGestate >= 0 then
              self.spawnText:SetText(string.format(Locale.ResolveString("SPAWNING") .. " %d", ToString(timeToGestate)))
            end
        else
            self.spawnText:SetText(string.format(Locale.ResolveString("NEXT_SPAWN_IN"), ToString(timeToWave)))
        end
        
        local eggCount = AlienUI_GetEggCount()
        
        self.eggCount:SetText(string.format("x %s", ToString(eggCount)))
        
        local hasEggs = eggCount > 0
        self.eggCount:SetColor(hasEggs and kWhite or kNoEggsColor)
        self.eggIcon:SetColor(hasEggs and kWhite or kNoEggsColor)
        
    end
    
    
end
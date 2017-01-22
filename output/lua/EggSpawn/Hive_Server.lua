
local function GetEggsPerHatch(self)
    return math.floor(ScaleWithPlayerCount(kEggsPerHatch, #GetEntitiesForTeam("Player", self:GetTeamNumber()), true))
end

local function SpawnEgg(self, eggCount)

    if self.eggSpawnPoints == nil or #self.eggSpawnPoints == 0 then
    
        --Print("Can't spawn egg. No spawn points!")
        return nil
        
    end

    if not eggCount then
        eggCount = 0
    end

    for i = 1, #self.eggSpawnPoints do

        local position = eggCount == 0 and table.random(self.eggSpawnPoints) or self.eggSpawnPoints[i]  

        -- Need to check if this spawn is valid for an Egg and for a Skulk because
        -- the Skulk spawns from the Egg.
        local validForEgg = GetCanEggFit(position)

        if validForEgg then
        
            local egg = CreateEntity(Egg.kMapName, position, self:GetTeamNumber())
            egg:SetHive(self)
            

            if egg ~= nil then
            
                -- Randomize starting angles
                local angles = self:GetAngles()
                angles.yaw = math.random() * math.pi * 2
                egg:SetAngles(angles)
                
                -- To make sure physics model is updated without waiting a tick
                egg:UpdatePhysicsModel()
                
                self.timeOfLastEgg = Shared.GetTime()
                
                return egg
                
            end
            
        end

    
    end
    
    return nil
    
end

-- fix kEggsPerHatch to be a sliding scale instead of just 2
-- sadly this function does a whole bunch of dumb things
function Hive:PerformActivation(techId, position, normal, commander)

    local success = false
    local continue = true
    

    if techId == kTechId.ShiftHatch then
    
        local egg = nil
    
        for j = 1, GetEggsPerHatch(self) do    
            egg = SpawnEgg(self, eggCount)        
        end
        
        success = egg ~= nil
        continue = not success
        
        if egg then
            egg.manuallySpawned = true
        end
        
        if success then
            self:TriggerEffects("hatch")
        end
        
    elseif techId == kTechId.Drifter then
    
        success = CreateDrifter(self, commander) ~= nil
        continue = not success
    
    end
    
    return success, continue

end
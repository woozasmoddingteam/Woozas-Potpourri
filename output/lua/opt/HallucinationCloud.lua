if Server then

    -- Create a table of lifeform tables, each one corresponding to a lifeform type, and the list of
    -- players on that team that are that lifeform type.  Lifeforms are arranged in descending order
    -- of likeliness that the player is skulk.  Obviously skulks are the most obvious choices, and
    -- dead players and onos the least likely.
    local lifeformTypes = { kTechId.Skulk, kTechId.Embryo, kTechId.Gorge, kTechId.AlienCommander, kTechId.Lerk, kTechId.Fade, kTechId.AlienSpectator, kTechId.Onos }
    local function GetPlayerNamesByLifeform()
        lifeformPlayers = {}
        local players = GetGamerules():GetTeam2():GetPlayers()
        for _, player in pairs(players) do
            if not player.isHallucination then
                for _, lifeformType in pairs(lifeformTypes) do
                    local techId = player:GetTechId()
                    if techId == lifeformType then
                        if not lifeformPlayers[lifeformType] then
                            lifeformPlayers[lifeformType] = {}
                        end
                        table.insert(lifeformPlayers[lifeformType], player)
                        break
                    end
                end
            end
        end
        return lifeformPlayers
    end

    -- From the table created in the above function, find the player with the lowest lifeform, and
    -- return them.  If there is a tie, pick a random player.  Also, remove the entry once it is
    -- picked, to avoid duplicates.
    -- For example, it will return skulk-player names, or if there are no more skulk names, gorge
    -- names, and so on and so forth.
    local function GetLowestLifeformPlayerFromTable(playerTable)
        local changeMade = true
        while changeMade do
            changeMade = false
            for i=1, #lifeformTypes do
                local tech = lifeformTypes[i]
                if playerTable[tech] ~= nil and #playerTable[tech] > 0 then
                    local index = math.random(1, #playerTable[tech])
                    local player = playerTable[tech][index]
                    table.remove(playerTable[tech], index)
                    changeMade = true
                    if not player then
                        break
                    else
                        return player
                    end
                end
            end
        end
        return nil -- apparently this team is empty???  Should never happen but... meh.
    end

	local function AllowedToHallucinate(entity)

	    local allowed = true
	    if entity.timeLastHallucinated and entity.timeLastHallucinated + kHallucinationCloudCooldown > Shared.GetTime() then
	        allowed = false
	    else
	        entity.timeLastHallucinated = Shared.GetTime()
	    end

	    return allowed

	end


    function HallucinationCloud:Perform()

        -- kill all hallucinations before, to prevent unreasonable spam
        for _, hallucination in ipairs(GetEntitiesForTeam("Hallucination", self:GetTeamNumber())) do
            hallucination.consumed = true
            hallucination:Kill()
        end

        for _, playerHallucination in ipairs(GetEntitiesForTeam("Alien", self:GetTeamNumber())) do

            if playerHallucination.isHallucination then
                playerHallucination:TriggerEffects("death_hallucination")
                DestroyEntity(playerHallucination)
            end

        end

        local drifter = GetEntitiesForTeamWithinRange("Drifter", self:GetTeamNumber(), self:GetOrigin(), HallucinationCloud.kRadius)[1]
        if drifter then

            if AllowedToHallucinate(drifter) then

                local angles = drifter:GetAngles()
                angles.pitch = 0
                angles.roll = 0
                local origin = GetGroundAt(self, drifter:GetOrigin() + Vector(0, .1, 0), PhysicsMask.Movement, EntityFilterOne(drifter))

                local hallucination = CreateEntity(Hallucination.kMapName, origin, self:GetTeamNumber())
                self:RegisterHallucination(hallucination)
                hallucination:SetEmulation(GetHallucinationTechId(kTechId.Drifter))
                hallucination:SetAngles(angles)

                local randomDestinations = GetRandomPointsWithinRadius(drifter:GetOrigin(), 4, 10, 10, 1, 1, nil, nil)
                if randomDestinations[1] then
                    hallucination:GiveOrder(kTechId.Move, nil, randomDestinations[1], nil, true, true)
                end

            end

        end

        -- search for alien in range, cloak them and create a hallucination
        local hallucinatePlayers = {}
        local numHallucinatePlayers = 0
        for _, alien in ipairs(GetEntitiesForTeamWithinRange("Alien", self:GetTeamNumber(), self:GetOrigin(), HallucinationCloud.kRadius)) do

            if alien:GetIsAlive() and not alien:isa("Embryo") and not HasMixin(alien, "PlayerHallucination") then

                table.insert(hallucinatePlayers, alien)
                numHallucinatePlayers = numHallucinatePlayers + 1

            end

        end

        -- sort by techId, so the higher life forms are prefered
        local function SortByTechId(alienOne, alienTwo)
            return alienOne:GetTechId() > alienTwo:GetTechId()
        end

        table.sort(hallucinatePlayers, SortByTechId)

        -- limit max num of hallucinations to 1/3 of team size
        local teamSize = self:GetTeam():GetNumPlayers()
        local maxAllowedHallucinations = math.max(1, math.floor(teamSize * kPlayerHallucinationNumFraction), kMaxHallucinations)
        local hallucinationsCreated = 0

        for index, alien in ipairs(hallucinatePlayers) do

            if AllowedToHallucinate(alien) then

                local newAlienExtents = LookupTechData(alien:GetTechId(), kTechDataMaxExtents)
                local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(newAlienExtents)

                local spawnPoint = GetRandomSpawnForCapsule(newAlienExtents.y, capsuleRadius, alien:GetModelOrigin(), 0.5, 5)

                if spawnPoint then

                    local hallucinatedPlayer = CreateEntity(alien:GetMapName(), spawnPoint, self:GetTeamNumber())

                    -- make drifter keep a record of any hallucinations created from its cloud, so they
                    -- die when drifter dies.
                    self:RegisterHallucination(hallucinatedPlayer)

                    if alien:isa("Alien") then
                        hallucinatedPlayer:SetVariant(alien:GetVariant())
                    end
                    hallucinatedPlayer.isHallucination = true
                    InitMixin(hallucinatedPlayer, PlayerHallucinationMixin)
                    InitMixin(hallucinatedPlayer, SoftTargetMixin)
                    InitMixin(hallucinatedPlayer, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

                    hallucinatedPlayer:SetName(alien:GetName())
                    hallucinatedPlayer:SetHallucinatedClientIndex(alien:GetClientIndex())

                    hallucinationsCreated = hallucinationsCreated + 1

                end

            end

            if hallucinationsCreated >= maxAllowedHallucinations then
                break
            end

        end

        -- if we still haven't created enough hallucinations, fill in the rest with skulks.
        local remaining = maxAllowedHallucinations - hallucinationsCreated
        if remaining > 0 then
            local extents = LookupTechData(kTechId.Skulk, kTechDataMaxExtents)
            local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
            local playerNamesByLifeform = GetPlayerNamesByLifeform()

            for i=1, remaining do
                local spawnPoint = GetRandomSpawnForCapsule(extents.y, capsuleRadius, self:GetOrigin(), 0.0, HallucinationCloud.kRadius)
                if spawnPoint then
                    local hallucination = CreateEntity(Skulk.kMapName, spawnPoint, self:GetTeamNumber())

                    -- make drifter keep a record of any hallucinations created from its cloud, so they
                    -- die when drifter dies.
                    self:RegisterHallucination(hallucination)

                    hallucination.isHallucination = true
                    InitMixin(hallucination, PlayerHallucinationMixin)
                    InitMixin(hallucination, SoftTargetMixin)
                    InitMixin(hallucination, OrdersMixin, { kMoveOrderCompleteDistance = kPlayerMoveOrderCompleteDistance })

                    -- use existing player names.  Try to pick skulk names as that would be more believeable (other team tends to notice
                    -- who the onos is and when they died.  Would be a dead-giveaway that a skulk is hallucinated if they recognize it as
                    -- the onos player.  If no players are skulks, try gorge-player-names.  If no gorges... lerks.  And so on...
                    local namePlayer = GetLowestLifeformPlayerFromTable(playerNamesByLifeform)
                    if namePlayer then
                        hallucination:SetName(namePlayer:GetName())
                        hallucination:SetHallucinatedClientIndex(namePlayer:GetClientIndex())
                        local client = namePlayer:GetClient()
                        if client then
                            hallucination:SetVariant(client.variantData.skulkVariant or kSkulkVariant.normal)
                        end
                    end
                end
            end
        end

        for _, resourcePoint in ipairs(GetEntitiesWithinRange("ResourcePoint", self:GetOrigin(), HallucinationCloud.kRadius)) do

            if resourcePoint:GetAttached() == nil and GetIsPointOnInfestation(resourcePoint:GetOrigin()) then

                local hallucination = CreateEntity(Hallucination.kMapName, resourcePoint:GetOrigin(), self:GetTeamNumber())
                self:RegisterHallucination(hallucination)
                hallucination:SetEmulation(kTechId.HallucinateHarvester)
                hallucination:SetAttached(resourcePoint)

            end

        end

        for _, techPoint in ipairs(GetEntitiesWithinRange("TechPoint", self:GetOrigin(), HallucinationCloud.kRadius)) do

            if techPoint:GetAttached() == nil then

                local coords = techPoint:GetCoords()
                coords.origin = coords.origin + Vector(0, 2.494, 0)
                local hallucination = CreateEntity(Hallucination.kMapName, techPoint:GetOrigin(), self:GetTeamNumber())
                self:RegisterHallucination(hallucination)
                hallucination:SetEmulation(kTechId.HallucinateHive)
                hallucination:SetAttached(techPoint)
                hallucination:SetCoords(coords)

            end

        end

    end

end

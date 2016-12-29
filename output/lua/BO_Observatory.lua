
-- Pushed the 15/11/16 at 20h47

if (Server) then
   Script.Load("lua/BO_Utils.lua")

   local BO_beacon_smooth_duration = 1.5

   ---------------- BeaconOpti: Untouched RespawnPlayer function (used as a fallback)

   local function GetIsPlayerNearby(self, player, toOrigin)
      return (player:GetOrigin() - toOrigin):GetLength() < Observatory.kDistressBeaconRange
   end

   local function GetPlayersToBeacon(self, toOrigin)

      local players = { }

      for index, player in ipairs(self:GetTeam():GetPlayers()) do

         -- Don't affect Commanders or Heavies
         if player:isa("Marine") then

            -- Don't respawn players that are already nearby.
            if not GetIsPlayerNearby(self, player, toOrigin) then

               if player:isa("Exo") then
                  table.insert(players, 1, player)
               else
                  table.insert(players, player)
               end

            end

         end

      end

      return players

   end

   -- Spawn players at nearest Command Station to Observatory - not initial marine start like in NS1. Allows relocations and more versatile tactics.
   local function RespawnPlayer(self, player, distressOrigin)

      -- Always marine capsule (player could be dead/spectator)
      local extents = HasMixin(player, "Extents") and player:GetExtents() or LookupTechData(kTechId.Marine, kTechDataMaxExtents)
      local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
      local range = Observatory.kDistressBeaconRange
      local spawnPoint = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, distressOrigin, 2, range, EntityFilterAll())

      if spawnPoint then

         if HasMixin(player, "SmoothedRelevancy") then
            player:StartSmoothedRelevancy(spawnPoint)
         end

         player:SetOrigin(spawnPoint)
         if player.TriggerBeaconEffects then
            player:TriggerBeaconEffects()
         end

      end

      return spawnPoint ~= nil, spawnPoint

   end

   --------------------

   local spawn_iterator = 1
   local ObservatoryTriggerDistressBeacon = Observatory.TriggerDistressBeacon
   function Observatory:TriggerDistressBeacon()
      spawn_iterator = 1

      local it = 0
      local nb_added = 0
      local step = 0
      local entities = {}
      local nb_entities = 0
      local nearest_CC = nil

      Log("BeaconOpti mod: TriggerDistressBeacon() called")
      Log("BeaconOpti mod: Starting smooth relevancy changes ...")
      -- Include all Human players beaconned
      nb_added = 0
      for _, p in ipairs(GetEntitiesForTeam("Marine", 1))
      do
         if (p and p.GetIsAlive and p:GetIsAlive()) then
            table.insert(entities, p)
            nb_added = nb_added + 1
            if (p.GetWeapons) then -- Just for safety
               for i, weapon in ipairs(p:GetWeapons()) do
                  table.insert(entities, weapon)
               end
            end
         end
      end
      Log("BeaconOpti mod: Adding " .. tostring(nb_added) .. " marines (and all weapons)")

      -- but only aliens nearby the beacon location
      -- Edit: Take all the aliens: before the 3s delay the aliens are out of relevancy range
      --       so we need to take them into account (and in tunnels)
      nb_added = 0
      for _, p in ipairs(GetEntitiesForTeamWithinRange("Alien", 2, self:GetDistressOrigin(),
                                                       kMaxRelevancyDistance))
      do
         if (p and p.GetIsAlive and p:GetIsAlive()) then
            table.insert(entities, p)
            nb_added = nb_added + 1
            if (p.GetWeapons) then -- Just for safety
               for i, weapon in ipairs(p:GetWeapons()) do
                  table.insert(entities, weapon)
               end
            end
         end
      end
      Log("BeaconOpti mod: Adding " .. tostring(nb_added) .. " aliens (and all weapons)")

      -- nb_added = 0
      -- -- Weapons (aliens (lerkBite, etc ...) and marines (Rifle, pistol, axe, builder, etc)
      -- for _, p in ipairs(GetEntitiesForTeam("Weapon", 1))
      -- do
      --    if (p) then
      --       table.insert(entities, p)
      --       nb_added = nb_added + 1
      --    end
      -- end
      -- Log("BeaconOpti: Adding " .. tostring(nb_added) .. " weapons")

      -- and the marines building
      nb_added = 0
      for _, p in ipairs(GetEntitiesWithMixinForTeamWithinRange("PowerConsumer", 1, self:GetDistressOrigin(),
                                                                kMaxRelevancyDistance))
      do
         if (p and p.GetIsAlive and p:GetIsAlive()) then
            table.insert(entities, p)
            nb_added = nb_added + 1
         end
      end
      Log("BeaconOpti mod: Adding " .. tostring(nb_added) .. " buildings (powerConsumer)")

      -- Include the CC into relevancy too (it is not a PowerConsumer)
      nearest_CC = GetNearest(self:GetOrigin(), "CommandStation", self:GetTeamNumber(), function(ent) return ent:GetIsBuilt() and ent:GetIsAlive() end)
      if nearest_CC then
         table.insert(entities, nearest_CC)
         Log("BeaconOpti mod: Adding " .. tostring(1) .. " CommandStation")
      end

      nb_entities = #entities
      -- All entities must be loaded at X% of the beacon delay (so there so room left for stuff to be done)
      step = (Observatory.kDistressBeaconTime * 1.00) / nb_entities
      for _, ent in ipairs(entities)
      do
         local mask = nil

         if (HasMixin(ent, "PowerConsumer")) then
            -- If it is a building, only marines need to have them
            -- The com is probably already over the base and aliens in it
            mask = bit.bor(kRelevantToTeam1, 0)
            mask = bit.bor(mask, kRelevantToTeam1Commander)
            mask = bit.bor(mask, kRelevantToTeam2Commander)
         else
            mask = bit.bor(kRelevantToTeam1, kRelevantToTeam2)
            mask = bit.bor(mask, kRelevantToTeam1Commander)
            mask = bit.bor(mask, kRelevantToTeam2Commander)
         end

         -- Log("BeaconOpti mod: SmoothBeacon: '" .. EntityToString(ent) .. "(" .. ent:GetId() .. ")" .. "'"
         --     .. " will be added to relevancy mask for everyone in: "
         --        .. tostring(it) .. "")
         ent.BO_relevancy_mask = mask
         ent.BO_beaconTime = Shared.GetTime() + Observatory.kDistressBeaconTime
         Entity.AddTimedCallback(ent, BO_SetIncludeRelevancyMask, it)
         Entity.AddTimedCallback(ent, BO_ResetRelevancyMask, Observatory.kDistressBeaconTime + 6)
         it = it + step
      end
      return ObservatoryTriggerDistressBeacon(self)
   end

   local function BO_RespawnPlayer(self, player, distressOrigin)
      local spawnPoint = nil
      local location = GetLocationForPoint(distressOrigin, self)
      if (location) then
         -- local TP = GetTechPointForLocation(location.name)
         local techpoint_id = FindNearestEntityId("TechPoint", distressOrigin)
         if (techpoint_id) then
            local points = getBeaconSpawnPoints()[techpoint_id]
            local extents = HasMixin(player, "Extents") and player:GetExtents() or LookupTechData(kTechId.Marine, kTechDataMaxExtents)
            local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
            local range = Observatory.kDistressBeaconRange

            local nb_players = GetGamerules():GetTeam(kTeam1Index):GetNumPlayers()
            if (points and #points > 0) then
               local step = Clamp(math.floor(#points / nb_players), 1, 4)
               while (spawn_iterator < #points) do

                  local orig = points[spawn_iterator]

                  -- Log("Testing orig: " .. orig.x .. ":" .. orig.y .. ":" .. orig.z)
                  spawnPoint = ValidateSpawnPoint(orig, capsuleHeight, capsuleRadius, EntityFilterAll(), orig)
                  if spawnPoint then

                     if HasMixin(player, "SmoothedRelevancy") then
                        player:StartSmoothedRelevancy(spawnPoint)
                     end

                     player:SetOrigin(spawnPoint)
                     -- Log("Spawn SUCCESS")
                     if player.TriggerBeaconEffects and math.random() < 0.6 then
                        player:TriggerBeaconEffects()
                     end

                     spawn_iterator = spawn_iterator + step
                     break
                  else
                     -- Move to the next possible spawn orig faster (strong chances points closed are crownd)
                     spawn_iterator = spawn_iterator + 1
                  end
               end
            end
         end
      end

      -- if (not spawnPoint) then
      --    Log("Spawn FAILED")
      -- end
      return spawnPoint ~= nil, spawnPoint
   end

   local function BO_BeaconPlayer(player)

      if (not player or not player:isa("Player") or not player:GetIsAlive()) then
         return
      end

      local distressOrigin = player.BO_distress_orig
      local kDistressBeaconRange = Observatory.kDistressBeaconRange

      ---------------------- BO code added to PerformDistressBeacon
      local success, respawnPoint = nil, nil
      success, respawnPoint = BO_RespawnPlayer(nil, player, distressOrigin)
      if (not success) then -- Fallback
         Log("BeaconOpti mod: Failed to place player " .. player:GetName() .. ". Fallback to ns2 code")
         for i = 1, 10 do
            success, respawnPoint = RespawnPlayer(nil, player, distressOrigin)
            if (success) then
               break
            end
         end
         if (not success) then
            local nearestPP = GetNearest(distressOrigin, "PowerPoint")
            Log("BeaconOpti mod: Failed to place player " .. player:GetName() .. ". Fallback to backup code")
            if (nearestPP) then
               for i = 1, 10 do
                  success, respawnPoint = RespawnPlayer(nil, player, nearestPP:GetOrigin())
                  if (success) then
                     Log("BeaconOpti mod: backup code SUCCESS")
                     break
                  end
               end
            end
         end
      end

      ----------------------

      if (not success) then -- Urgency fallback (should not happen)
         local successfullPositions = GetEntitiesForTeamWithinRange("Marine", 1, distressOrigin, kDistressBeaconRange)
         Log("BeaconOpti mod: Regular code failed too to place player " .. player:GetName() .. ". Last resort: teleport at the same pos than an other marine")
         if (#successfullPositions > 0) then
            if player:isa("Exo") then
               player:SetOrigin(successfullPositions[math.random(1, #successfullPositions)]:GetOrigin())
            else
               player:SetOrigin(successfullPositions[math.random(1, #successfullPositions)]:GetOrigin())
               if player.TriggerBeaconEffects then
                  player:TriggerBeaconEffects()
               end

            end

            -- end
         end
      end

      player.BO_distress_orig = nil
      return
   end

   local function BO_IPRespawnPlayer(ip)
      if (ip and ip:GetIsAlive()) then
         ip:FinishSpawn()
      end
   end

   function Observatory:PerformDistressBeacon()

      self.distressBeaconSound:Stop()

      local anyPlayerWasBeaconed = false
      local successfullPositions = {}
      local successfullExoPositions = {}
      local failedPlayers = {}

      Log("BeaconOpti mod: PerformDistressBeacon called")
      local distressOrigin = self:GetDistressOrigin()
      if distressOrigin then

         Log("BeaconOpti mod: PerformDistressBeacon called: origin found")
         local IPs = GetEntitiesForTeamWithinRange("InfantryPortal", self:GetTeamNumber(), distressOrigin, kInfantryPortalAttachRange + 1)
         local players_to_beacon = GetPlayersToBeacon(self, distressOrigin)
         local beacon_time_it = 0
         local step = BO_beacon_smooth_duration / 20

         for index, player in ipairs(players_to_beacon) do

            anyPlayerWasBeaconed = true
            player.BO_distress_orig = distressOrigin
            -- Log("BeaconOpti mod: PerformDistressBeacon: player [" .. player:GetName() .. "] getting beaconned in " .. tostring(beacon_time_it) .. "s")
            Entity.AddTimedCallback(player, BO_BeaconPlayer, beacon_time_it)
            beacon_time_it = beacon_time_it + step

            -- ---------------------- BO code added to PerformDistressBeacon
            -- local success, respawnPoint = nil, nil
            -- success, respawnPoint = BO_RespawnPlayer(self, player, distressOrigin)
            -- if (not success) then -- Fallback
            --    Log("BO mod: Failed to place player " .. player:GetName() .. ". Fallback to ns2 code")
            --    success, respawnPoint = RespawnPlayer(self, player, distressOrigin)
            -- end
            -- ----------------------

            -- if success then

            --    anyPlayerWasBeaconed = true
            --    if player:isa("Exo") then
            --       table.insert(successfullExoPositions, respawnPoint)
            --    end

            --    table.insert(successfullPositions, respawnPoint)

            -- else
            --    table.insert(failedPlayers, player)
            -- end

         end

         -- Also respawn players that are spawning in at infantry portals near command station (use a little extra range to account for vertical difference)
         for index, ip in ipairs(IPs) do

            -- ip:FinishSpawn()
            -- Log("BeaconOpti mod: PerformDistressBeacon: IPs FinishSpawn() called in " .. tostring(beacon_time_it) .. "s")
            Entity.AddTimedCallback(ip, BO_IPRespawnPlayer, beacon_time_it)
            local spawnPoint = ip:GetAttachPointOrigin("spawn_point")
            table.insert(successfullPositions, spawnPoint)
            beacon_time_it = beacon_time_it + step

         end
      end



      local usePositionIndex = 1
      local numPosition = #successfullPositions

      for i = 1, #failedPlayers do

         local player = failedPlayers[i]

         if player:isa("Exo") then
            player:SetOrigin(successfullExoPositions[math.random(1, #successfullExoPositions)])
         else

            player:SetOrigin(successfullPositions[usePositionIndex])
            if player.TriggerBeaconEffects then
               player:TriggerBeaconEffects()
            end

            usePositionIndex = Math.Wrap(usePositionIndex + 1, 1, numPosition)

         end

      end

      if anyPlayerWasBeaconed then
         self:TriggerEffects("distress_beacon_complete")
      end
   end

end



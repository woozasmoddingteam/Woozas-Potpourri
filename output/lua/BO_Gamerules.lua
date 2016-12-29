if (Server) then
   local BO_beacon_spawnpoints = {}

   function getBeaconSpawnPoints()
      return BO_beacon_spawnpoints
   end

   local function sortByProximity(orig, points)
      local i = 1
      local sorted_points = {}

      for _, point in ipairs(points)
      do
         i = 0
         local added = false
         local t1 = orig:GetDistanceTo(point)
         for it, point2 in ipairs(sorted_points) do
            local t2 = orig:GetDistanceTo(point2)
            if (t1 < t2) then
               table.insert(sorted_points, it, point)
               added = true
               break
            end
         end
         if (added == false) then
            table.insert(sorted_points, #sorted_points + 1, point)
         end
      end
      return (sorted_points)
   end

   -- Create structure, weapon, etc. near player.
   local function BO_GenFakeEntities(orig, number)
      local techId = kTechId.Marine
      local mapName = Marine.kMapName
      local entities = {}
      local extents = LookupTechData(kTechId.Marine, kTechDataMaxExtents)
      local capsuleHeight, capsuleRadius = GetTraceCapsuleFromExtents(extents)
      local range = Observatory.kDistressBeaconRange
      local position = nil

      number = number or 1
      for i = 1, number do

         local success = false
         -- Persistence is the path to victory.
         for index = 1, 180 do

            teamNumber = 1
            position = GetRandomSpawnForCapsule(capsuleHeight, capsuleRadius, orig, 2, range, EntityFilterAll())
            -- position = CalculateRandomSpawn(nil, orig, techId, true, 1, kDistressBeaconRange, 3)
            if position then
               success = true

               for e = 1, #entities do -- Only spawn away from already found origin
                  if (position:GetDistanceTo(entities[e]) < 1) then
                     -- Check if we are in the same location room
                     if (GetLocationForPoint(orig) and GetLocationForPoint(orig) == GetLocationForPoint(position))
                     then
                        success = false
                        break
                     end
                  end
               end

               if (success) then
                  table.insert(entities, position)
                  break
               end
            end

         end

         -- if not success then
         --    Print("Create %s: Couldn't find space for entity", EnumToString(kTechId, techId))
         -- end
      end

      return entities
   end

   local GamerulesOnMapPostLoad = Gamerules.OnMapPostLoad
   function Gamerules:OnMapPostLoad()
      if (GamerulesOnMapPostLoad) then
         GamerulesOnMapPostLoad(self)
      end

      local TP_entry = nil
      local entities = {}
      local nb_cached_points = 150
      local nb_points_found = 0
      local init_start = os.clock()

      Log("BeaconOpti mod: Caching of beacon teleport points starting ...")
      BO_beacon_spawnpoints = {}
      for i, TP in ientitylist(Shared.GetEntitiesWithClassname("TechPoint")) do
         TP_entry = {}
         entities = BO_GenFakeEntities(TP:GetOrigin() + Vector(0, 1, 0), nb_cached_points)
         nb_points_found = #entities

         -- if (entities and #entities > 0) then
         --    TP_entry = entities
         --    -- -- Shared.SortEntitiesByDistance(TP:GetOrigin(), entities)
         --    -- for _, ent in ipairs(entities) do
         --    --    table.insert(TP_entry, ent)
         --    -- end
         -- end

         TP_entry = sortByProximity(TP:GetOrigin(), entities)
         for _, ent in ipairs(entities) do
            -- Log("Testing orig: " .. orig.x .. ":" .. orig.y .. ":" .. orig.z)
            table.insert(TP_entry, ent)
         end
         BO_beacon_spawnpoints[TP:GetId()] = TP_entry
         Log("BeaconOpti mod: -> " .. tostring(nb_points_found)
             .. " points found for TP " .. tostring(TP:GetId())
                .. " (name: " .. TP:GetLocationName() .. ")")
      end
      Log("BeaconOpti mod: Caching of beacon teleport points DONE (took "
             .. tostring(os.clock() - init_start) .. "s)")
   end

   -- local function OnMapPostLoad()
   --    -- Does not works, TechPoints entities are not available at this point
   -- end

   -- Event.Hook("MapPostLoad", OnMapPostLoad)
end

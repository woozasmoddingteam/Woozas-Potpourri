
if (Server) then
   Script.Load("lua/BO_Utils.lua")

   local refresh = 0
   local refresh_delay = 5
   local NS2GamerulesOnUpdate = NS2Gamerules.OnUpdate
   function NS2Gamerules:OnUpdate(timePassed)
      refresh = refresh + timePassed
      if (refresh > refresh_delay) then
         refresh = 0

         local step = 0.05
         local it = 0
         local mask = nil

         mask = bit.bor(kRelevantToTeam1, kRelevantToTeam2)
         mask = bit.bor(mask, kRelevantToTeam1Commander)
         mask = bit.bor(mask, kRelevantToTeam2Commander)
         if (kGameState.Started ~= self:GetGameState()) then
            -- Log("BeaconOpti mod: Refresh relevancy during pregame")
            for _, p in ipairs(GetEntities("Player"))
            do
               if (p and p.GetIsAlive and p:GetIsAlive()) then
                  if (p.GetWeapons) then -- Just for safety
                     for i, weapon in ipairs(p:GetWeapons()) do
                        weapon.BO_relevancy_mask = mask
                        Entity.AddTimedCallback(weapon, BO_SetIncludeRelevancyMask, it)
                        it = it + step
                     end
                  end
                  Entity.AddTimedCallback(p, BO_SetIncludeRelevancyMask, it)
                  it = it + step
               end
            end
            -- Log("BeaconOpti mod: Nb added: " .. tostring(it / step))

            -- for _, entname in ipairs(ent_list) do
            --    for _, ent in ipairs(GetEntities(entname)) do
            --       if (state == kGameState.Started) then
            --          Entity.AddTimedCallback(ent, BO_ResetRelevancyMask, it)
            --       else
            --          local mask = nil

            --          mask = bit.bor(kRelevantToTeam1, kRelevantToTeam2)
            --          mask = bit.bor(mask, kRelevantToTeam1Commander)
            --          mask = bit.bor(mask, kRelevantToTeam2Commander)

            --          ent.BO_relevancy_mask = mask
            --          Entity.AddTimedCallback(ent, BO_SetIncludeRelevancyMask, it)
            --          it = it + step
            --       end
            --    end
            -- end
            refresh = Clamp(it, 5, it+1)
         end
      end
      NS2GamerulesOnUpdate(self, timePassed)
   end

   local last_callback_fired = 0
   local NS2GamerulesSetGameState = NS2Gamerules.SetGameState
   function NS2Gamerules:SetGameState(state)
      local ent_list = {"Player", "Weapon"}
      local step = 0.1
      local it = math.max(last_callback_fired - Shared.GetTime(), 0)

      if (state ~= self:GetGameState()) then
         -- It takes the last time to prevent a reset to be done during a SetIncludeRelevancyMask() call
         -- for SetGameState() call several time in a really short interval
         if (state == kGameState.Started) then
            it = it + math.max(10, refresh_delay+1)
            Log("BeaconOpti mod: Game started, reseting all relevancy with defaults in " .. tostring(it) .. "s")
            -- else
            --    Log("BeaconOpti mod: Game state changed, setting relevancy for each players/weapons it = " .. tostring(it))
         end
         for _, entname in ipairs(ent_list) do
            for _, ent in ipairs(GetEntities(entname)) do
               if (state == kGameState.Started) then
                  Entity.AddTimedCallback(ent, BO_ResetRelevancyMask, it)
                  -- else
                  --    local mask = nil

                  --    mask = bit.bor(kRelevantToTeam1, kRelevantToTeam2)
                  --    mask = bit.bor(mask, kRelevantToTeam1Commander)
                  --    mask = bit.bor(mask, kRelevantToTeam2Commander)

                  --    ent.BO_relevancy_mask = mask
                  --    Entity.AddTimedCallback(ent, BO_SetIncludeRelevancyMask, it)
                  --    it = it + step
               end
            end
         end

         last_callback_fired = Shared.GetTime() + it
      end

      return NS2GamerulesSetGameState(self, state)
   end
end

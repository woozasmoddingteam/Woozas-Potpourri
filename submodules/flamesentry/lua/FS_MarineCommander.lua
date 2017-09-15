-- local gMarineMenuButtons =
--    {

--       [kTechId.BuildMenu] = { kTechId.CommandStation, kTechId.Extractor, kTechId.InfantryPortal, kTechId.Armory,
--                               kTechId.RoboticsFactory, kTechId.ArmsLab, kTechId.None, kTechId.None },

--       [kTechId.AdvancedMenu] = { kTechId.Sentry, kTechId.Observatory, kTechId.PhaseGate, kTechId.PrototypeLab,
--                                  kTechId.FlameSentry, kTechId.SentryBattery, kTechId.None, kTechId.None },

--       [kTechId.AssistMenu] = { kTechId.AmmoPack, kTechId.MedPack, kTechId.NanoShield, kTechId.Scan,
--                                kTechId.PowerSurge, kTechId.CatPack, kTechId.WeaponsMenu, kTechId.None, },

--       [kTechId.WeaponsMenu] = { kTechId.DropShotgun, kTechId.DropGrenadeLauncher, kTechId.DropFlamethrower, kTechId.DropWelder,
--                                 kTechId.DropMines, kTechId.DropJetpack, kTechId.DropHeavyMachineGun, kTechId.AssistMenu}


--    }

local oldMarineCommanderGetButtonTable = MarineCommander.GetButtonTable
function MarineCommander:GetButtonTable()
   local already_added = false
   local menuButtons = oldMarineCommanderGetButtonTable(self)

   for i, v in ipairs(menuButtons[kTechId.AdvancedMenu]) do
      if v == kTechId.FlameSentry then
         already_added = true
         break
      end
   end

   if not already_added then
      -- if menuButtons[kTechId.AdvancedMenu][5] == kTechId.SentryBattery
      -- and menuButtons[kTechId.AdvancedMenu][6] == kTechId.None then
      --    -- Shift the battery to the right, and add the FlameSentry
      --    menuButtons[kTechId.AdvancedMenu][5] = kTechId.FlameSentry
      --    menuButtons[kTechId.AdvancedMenu][6] = kTechId.SentryBattery
      -- else
         for i, v in ipairs(menuButtons[kTechId.AdvancedMenu]) do
            if v == kTechId.None then
               menuButtons[kTechId.AdvancedMenu][i] = kTechId.FlameSentry
               break
            end
         end
      --    -- Take first free slot
      -- end
   end
   return menuButtons
end

-- FlameSentry: Same as vanilla, but with menuButtons using the function GetButtonTable() instead
-- Top row always the same. Alien commander can override to replace.
function MarineCommander:GetQuickMenuTechButtons(techId)

   -- Top row always for quick access
   local marineTechButtons = { kTechId.BuildMenu, kTechId.AdvancedMenu, kTechId.AssistMenu, kTechId.RootMenu }
   local menuButtons = self:GetButtonTable()[techId]

   if not menuButtons then
      menuButtons = {kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None, kTechId.None }
   end

   table.copy(menuButtons, marineTechButtons, true)

   -- Return buttons and true/false if we are in a quick-access menu
   return marineTechButtons

end


-- kTechIdToMaterialOffset[kTechId.FlameSentry] = kTechIdToMaterialOffset[kTechId.Sentry]

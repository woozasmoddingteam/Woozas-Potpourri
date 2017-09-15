Script.Load("lua/FS_TechIdAdjustement.lua")
Script.Load("lua/FS_MarineCommander.lua")
Script.Load("lua/FS_TechTreeButtons.lua")
Script.Load("lua/FS_MarineTeam.lua")


local origBuildClassToGrid = BuildClassToGrid
function BuildClassToGrid()
   local grid = origBuildClassToGrid()
   grid["FlameSentry"] = grid["Sentry"]
   return grid
end

table.insert(kGeneralEffectData.spawn.spawnEffects, 1, {
                cinematic = "cinematics/marine/structures/spawn_building.cinematic",
                classname = "FlameSentry"})
table.insert(kGeneralEffectData.spawn.spawnSoundEffects, 1, {
                sound = "sound/NS2.fev/marine/structures/generic_spawn",
                classname = "FlameSentry", done = true})
table.insert(kGeneralEffectData.deploy.deploySoundEffects, 1, {
                sound = "sound/NS2.fev/marine/structures/sentry_deploy",
                classname = "FlameSentry", done = true})
table.insert(kDamageEffects.damaged.damagedEffects, 1, {
                cinematic = "cinematics/marine/sentry/hurt_severe.cinematic",
                classname = "FlameSentry", flinch_severe = true, done = true})
table.insert(kDamageEffects.damaged.damagedEffects, 1, {
                cinematic = "cinematics/marine/sentry/hurt.cinematic",
                classname = "FlameSentry", flinch_severe = false, done = true})


if (Client) then
   local localeResolveString = Locale.ResolveString
   function Locale.ResolveString(text)
      if (text == "FLAME_SENTRY_TURRET") then
         return "Flame Sentry"
      else
         return localeResolveString(text)
      end
   end
end


-------------------------------------- Little bonus:
-------------------------------------- Trigger the hidden taunt animation on the "ta_taunt" console command


local kAlienTauntSounds =
{
      [kTechId.Skulk] = "sound/NS2.fev/alien/voiceovers/chuckle",
      [kTechId.Gorge] = "sound/NS2.fev/alien/gorge/taunt",
      [kTechId.Lerk] = "sound/NS2.fev/alien/lerk/taunt",
      [kTechId.Fade] = "sound/NS2.fev/alien/fade/taunt",
      [kTechId.Onos] = "sound/NS2.fev/alien/onos/taunt",
      [kTechId.Embryo] = "sound/NS2.fev/alien/common/swarm",
      [kTechId.ReadyRoomEmbryo] = "sound/NS2.fev/alien/common/swarm",
}

for _, tauntSound in pairs(kAlienTauntSounds) do
   PrecacheAsset(tauntSound)
end

local function GetLifeFormSound(player)

   if player and (player:isa("Alien") or player:isa("ReadyRoomEmbryo")) then
      return kAlienTauntSounds[player:GetTechId()] or ""
    end

    return ""
end

-- local alienGetMaxSpeed = Alien.GetMaxSpeed
-- function Alien:GetMaxSpeed(possible)
--    if self.TA_taunt and self.TA_taunt + 2 > Shared.GetTime() then
--       return 0
--    else
--       return alienGetMaxSpeed(self, possible)
--    end
-- end

-- local playerAdjustMove = Player.AdjustMove
-- function Player:AdjustMove(input)
--    if self.TA_taunt and self.TA_taunt + 2 > Shared.GetTime() then
--       input.move:Scale(0)
--    else
--       return playerAdjustMove(self, input)
--    end
--    return input
-- end

local alienOnUpdateAnimationInput = Alien.OnUpdateAnimationInput
function Alien:OnUpdateAnimationInput(modelMixin)
   if self.TA_taunt and self.TA_taunt + 2 > Shared.GetTime() then
      Player.OnUpdateAnimationInput(self, modelMixin)
      modelMixin:SetAnimationInput("move", "taunt")
   else
      alienOnUpdateAnimationInput(self, modelMixin)
   end
end

local function TA_Taunt(client)
   local player = nil
   if (Client) then
      player = Client.GetLocalPlayer()
   elseif (Server and client) then
      player = client:GetControllingPlayer()
   end
   if (player and player.GetIsAlive and player:GetIsAlive() and player:isa("Alien"))
   then
      if (not player.TA_taunt or player.TA_taunt + 2 < Shared.GetTime()) then
         player.TA_taunt = Shared.GetTime()

         if (Server) then
            taunt_sound = Server.CreateEntity(SoundEffect.kMapName)
            taunt_sound:SetAsset(GetLifeFormSound(player))
            taunt_sound:SetParent(player)
            taunt_sound:Start()
         end
      end
   end
end

Event.Hook("Console_ta_taunt", TA_Taunt)

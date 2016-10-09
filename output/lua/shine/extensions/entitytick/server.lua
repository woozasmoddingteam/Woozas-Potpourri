-- Defines
local Plugin = Plugin

function NS2Gamerules:UpdateCustomNetworkSettings()
end

local PlayerData = {}
local function getSteamId(player)
  return GetSteamIdForClientIndex(player.clientIndex)
end

function createPlayerData()
  local data = {}
  
  return data
end

function getPlayerData(player)
  if (player.data) then
    return player.data
  end

  local steamId = getSteamId(player)
  
  if (not steamId) then
    return nil
  end
  
  local result = PlayerData[steamId]
  
  if (result == nil) then
    result = createPlayerData()
    PlayerData[steamId] = result
  end
  
  player.data = result

  return result
end

--
function Plugin:Initialise()
  self.BaseClass.Initialise(self)

	self:CreateCommands()

	self.Enabled = true
  
  Shine.Timer.Create("RefreshRate", 1, 1,
    function()
      self:ResetRate()
      self:RefreshRate()
    end)
  
  -- Check entity count to lower rate every 30 seconds
  Shine.Timer.Create("RefreshRate", 30, -1,
    function()
      self:RefreshRate()
    end)
  
  self:InitMoveSaver()

  -- Reset rate upon game state change (start round, end rount, etc)
  this = self
  oldNS2GamerulesSetGameState = Shine.ReplaceClassMethod("NS2Gamerules", "SetGameState",
    function(self, player, useSuccessTable)
      if state ~= self.gameState then
        this:ResetRate()
      end
    
      oldNS2GamerulesSetGameState(self, player, useSuccessTable)
    end)

	return true
end

function Plugin:InitMoveSaver()
  ---- Move
  local function giveMoveAllowance(self)
    self.allowMove = 60
  end
   
  local function onProcessMove(self, input, funct)
    -- Handle move exceptions
    local data = getPlayerData(self)
   
    -- Consider allowing movement when all mandatory states are met
    if self:GetIsAlive() and not self:GetIsCommander() and self:GetIsOnGround() and data then
      -- Allow movement shortly after game state change
      local gameStarted = GetGamerules():GetGameStarted()
      if (data.gameStarted ~= gameStarted) then
        data.gameStarted = gameStarted
       
        if (gameStarted) then
          giveMoveAllowance(self)
        end
      end
   
      local isCrouching = self.GetCrouching and self:GetCrouching() or false //bit.band(input.commands, Move.Crouch) ~= 0 or bit.band(input.commands, Move.MovementModifier) ~= 0
      local wep = self:GetActiveWeapon()
      local isReloading = wep and wep.reloading
     
      -- Allow movement when player moving or activating certain binds
      if not (input.move:GetLength() ~= 0 or self:GetVelocity():GetLengthXZ() ~= 0 or (input.commands ~= 0 and input.commands ~= Move.PrimaryAttack and input.commands ~= Move.SecondaryAttack) or self.jumping or self:isa("Exo")) then
        -- Check second level reasoning
        local isAttacking = bit.band(input.commands, Move.PrimaryAttack) ~= 0 or bit.band(input.commands, Move.SecondaryAttack) ~= 0
       
        if data.wasCrouching ~= isCrouching or data.wasAttacking ~= isAttacking then
          data.wasCrouching = isCrouching
          data.wasAttacking = isAttacking
          giveMoveAllowance(self)
        end
       
        if not ((self.allowMove and self.allowMove > 0) or isReloading or isCrouching or self:isa("Fade")) then        
          if not isAttacking then -- When a marine, only shortcircuit when not attacking
            if isAttacking then
              -- Call all of the light weight tasks
              local viewModel = self:GetViewModelEntity()
              if viewModel then
                viewModel:ProcessMoveOnModel()
              end
            end
           
            return
          end
        end
      end
     
      if self.allowMove and self.allowMove ~= 0 then
        self.allowMove = self.allowMove - 1
      end
    end
   
    funct(self, input)
  end
   
  oldPlayerOnProcessMove = Shine.ReplaceClassMethod("Player", "OnProcessMove", function(self, input)
    -- oldPlayerOnProcessMove(self, input)
    onProcessMove(self, input, oldPlayerOnProcessMove)
  end)
   
  -- Spawning and jumping out of the hive needs a few ticks to settle
  oldPlayerOnCreate = Shine.ReplaceClassMethod("Player", "OnCreate",
  function(self)
    oldPlayerOnCreate(self)
    giveMoveAllowance(self)
  end)
end

function Plugin:CreateCommands()
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
  
  self:SetRate(30, 26, 20)
end

--
function Plugin:SetRate(tickrate, moverate, sendrate)
  -- Daft order requirement
  if (moverate > self:GetMoveRate()) then
    Shared.ConsoleCommand(string.format("sh_tickrate %i", tickrate))
    Shared.ConsoleCommand(string.format("sh_moverate %i", moverate))
    Shared.ConsoleCommand(string.format("sh_sendrate %i", sendrate))
  else
    Shared.ConsoleCommand(string.format("sh_sendrate %i", sendrate))
    Shared.ConsoleCommand(string.format("sh_moverate %i", moverate))
    Shared.ConsoleCommand(string.format("sh_tickrate %i", tickrate))
  end

  Shared.Message(string.format("Tick Rate Changed %i %i %i", tickrate, moverate, sendrate))
  
  self.moverate = moverate
end

function Plugin:GetMoveRate()
  return (self.moverate or 0)
end

function Plugin:ResetRate()
  self:SetRate(30, 26, 20)
end

function Plugin:RefreshRate()
 -- Shared.Message("Tick Rate Checked")

  local perfData = Shared.GetServerPerformanceData()
 -- Shared.Message(perfData:GetNumPlayers())
  if (perfData:GetNumPlayers() > 24) then  -- Handle > 24 players
    if (self:GetMoveRate() >= 26) then  -- Base - Activate immediately
      self:SetRate(30, 23, 18)
    elseif (self:GetMoveRate() >= 23) then  -- Limit 1 - Activate > 1350 entities
      if (perfData:GetEntityCount() >= 1200) then
        self:SetRate(21, 21, 17)
      end
    end
  end
end
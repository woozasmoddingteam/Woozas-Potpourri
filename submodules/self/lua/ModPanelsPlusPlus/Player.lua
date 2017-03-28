if Server then

	local index = 1
	while assert(debug.getupvalue(Player.OnUpdatePlayer, index)) ~= "UpdateChangeToSpectator" do
		index = index + 1
	end

	local function UpdateChangeToSpectator(self)

	    if not self:GetIsAlive() and not self:isa("Spectator") then
	        local time = Shared.GetTime()
	        if self.timeOfDeath ~= nil and (time - self.timeOfDeath > kFadeToBlackTime) and (not self.concedeSequenceActive) then

	            -- Destroy the existing player and create a spectator in their place (but only if it has an owner, ie not a body left behind by Phantom use)
	            local owner = Server.GetOwner(self)
	            if owner then

					if self:GetTeamNumber() == kTeamReadyRoom then
						self:GetTeam():ReplaceRespawnPlayer(self, nil, nil)
					else
		                local spectator = self:Replace(self:GetDeathMapName())
		                spectator:GetTeam():PutPlayerInRespawnQueue(spectator)

						-- Queue up the spectator for respawn.
						local killer = self.killedBy and Shared.GetEntity(self.killedBy) or nil
		                if killer then
		                    spectator:SetupKillCam(self, killer)
		                end
					end

	            end

	        end

	    end

	end

	debug.setupvalue(Player.OnUpdatePlayer, index, UpdateChangeToSpectator)

end

do
	local index = 1
	while assert(debug.getupvalue(Player.HandleButtons, index)) ~= "AttemptToUse" do
		index = index + 1
	end

	--[[
	    Check to see if there's a ScriptActor we can use. Checks any usable points returned from
	    GetUsablePoints() and if that fails, does a regular trace ray. Returns true if we processed the action.
	]]
	local function AttemptToUse(self, timePassed)

	    PROFILE("Player:AttemptToUse")

	    assert(timePassed >= 0)

	    -- Cannot use anything unless playing the game (a non-spectating player).
	    if
	        Shared.GetTime() - self.timeOfLastUse < kUseInterval
	        or self:isa("Spectator")
	        or GetIsVortexed(self)
	        then
	        return false
	    end

	    -- Trace to find use entity.
	    local entity, usablePoint = self:PerformUseTrace()

	    -- Use it.
	    if entity then

	        -- if the game isn't started yet, check if the entity is usuable in non-started game
	        -- (allows players to select commanders before the game has started)
	        if not self:GetGameStarted() and not (entity.GetUseAllowedBeforeGameStart and entity:GetUseAllowedBeforeGameStart()) then
	            return false
	        end

	        -- Use it.
	        if self:UseTarget(entity, kUseInterval) then

	            self:SetIsUsing(true)
	            self.timeOfLastUse = Shared.GetTime()
	            return true

	        end

	    end

	end

	debug.setupvalue(Player.HandleButtons, index, AttemptToUse)
end

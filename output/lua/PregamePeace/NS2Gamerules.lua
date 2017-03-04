if Server then
	function NS2Gamerules:KillEnemiesNearCommandStructureInPreGame(timePassed)

		if self:GetGameState() < kGameState.Countdown then

			local commandStations = Shared.GetEntitiesWithClassname("CommandStructure")
			for _, ent in ientitylist(commandStations) do

				local enemyPlayers = GetEntitiesForTeamWithinRange("Player", GetEnemyTeamNumber(ent:GetTeamNumber()), ent:GetOrigin(), 2);
				for e = 1, #enemyPlayers do

					local enemy = enemyPlayers[e]
					local health = enemy:GetMaxHealth() * 0.2 * timePassed
					local armor = enemy:GetMaxArmor() * 0.2 * timePassed
					local damage = health + armor
					enemy:TakeDamage(damage, nil, nil, nil, nil, armor, health, kDamageType.Normal)

					if not enemy.lastReturnToBaseSend or enemy.lastReturnToBaseSend + 5 < Shared.GetTime() then
						Server.SendNetworkMessage(enemy, "TeamMessage", { type = kTeamMessageTypes.ReturnToBase, data =  0 }, true)
						enemy.lastReturnToBaseSend = Shared.GetTime()
					end

				end

			end

		end

	end
end

--[[
Shared.LinkClassToMap("NS2Gamerules", nil, {
	gameState = "enum kGameState"
});
--]]

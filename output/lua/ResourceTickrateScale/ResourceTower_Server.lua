local lcommanderactiveworth = 1
--This variable is how many players worth is a commander. If its set to '1' then
--there is correct scaling.
--This means that the teamwith a commander will get a slight resource penalty
--when compared to a team without a commander if the value is > 1
--Recommended to be at least '1' else the team with a commander will get a bonus
--because the commander isn't counted as a player and you risk dividing by 0

function ResourceTower:OnUpdate(deltaTime)

    ScriptActor.OnUpdate(self, deltaTime)

    if self:GetIsCollecting() then

        if not self.timeLastCollected then
            self.timeLastCollected = Shared.GetTime()
        end

--Scale based on team player ratios
        local lourteam = self:GetTeam()
        local lenemyteam = GetGamerules():GetTeam1()
        local lourcommander = 0
        if lourteam:GetCommander() then lourcommander = lcommanderactiveworth end
        local lenemycommander = 0
        if lenemyteam:GetCommander() then lenemycommander = lcommanderactiveworth end
        --If we are humans enemy team must be aliens or else we are alien
        if lourteam == lenemyteam then lenemyteam = GetGamerules():GetTeam2() end

        local lteamratio =  math.sqrt((lourteam:GetNumPlayers() + lourcommander) / (lenemyteam:GetNumPlayers() + lenemycommander))
        local ResourceInterval = kResourceTowerResourceInterval * lteamratio

        if self.timeLastCollected + ResourceInterval < Shared.GetTime() then

            self:CollectResources()
            self.timeLastCollected = Shared.GetTime()

        end

    else
        self.timeLastCollected = nil
    end

end

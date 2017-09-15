
Script.Load("lua/MarineTeam.lua")

local MarineTeamInitTechTree = MarineTeam.InitTechTree
function MarineTeam:InitTechTree()
   MarineTeamInitTechTree(self)
   self.techTree:AddBuildNode(kTechId.FlameSentry, kTechId.RoboticsFactory, kTechId.None, true)
   self.techTree:SetComplete()
end

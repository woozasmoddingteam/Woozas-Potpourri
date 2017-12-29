local Shine  = Shine
local Plugin = Plugin

local function void() end

local invalid = Entity.invalidId
local commander = {
	GetId = function()
		return invalid
	end
}

function Plugin:Surrender(team)
	local gamerules = GetGamerules()

	if team == 1 then -- special case for marines
		local marines = gamerules.team1
		if kNS2OptiConfig then
			kTechData[kTechId.InfantryPortal][kTechDataImplemented] = false
		end
		local tree = marines:GetTechTree()
		tree:SetTechChanged()
		local ips = GetEntitiesForTeam("InfantryPortal", 1)
		local recycle = tree:GetTechNode(kTechId.Recycle)
		for _, ip in ipairs(ips) do
			ip:SetResearching(recycle, marines:GetCommander() or commander)
			ip.PerformAction = void
		end
	else
		gamerules.team2.conceded = true
	end

	Shine.SendNetworkMessage("TeamConceded", {teamNumber = team})

	self.Surrendered = true
end

function Plugin:EndGame()
	if kNS2OptiConfig then
		kTechData[kTechId.InfantryPortal][kTechDataImplemented] = true
	end
	self.Surrendered = false
end

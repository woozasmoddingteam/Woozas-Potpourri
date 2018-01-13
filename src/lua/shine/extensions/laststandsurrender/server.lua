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

	Shine.SendNetworkMessage("TeamConceded", {teamNumber = team})

	if team == 1 then -- special case for marines
		Print "Team voted to surrender!"
		local marines = gamerules.team1
		if kNS2OptiConfig then
			kTechData[kTechId.InfantryPortal][kTechDataImplemented] = false
		end
		local tree = marines:GetTechTree()
		tree:SetTechChanged()
		local ips = GetEntitiesForTeam("InfantryPortal", 1)
		local recycle = tree:GetTechNode(kTechId.Recycle)
		for _, ip in ipairs(ips) do
			ip:SetResearching(recycle, commander)
			ip.PerformAction = void
		end
		Shine:NotifyColour(nil, 240, 30, 30, "IPs have been recycled")
	else
		gamerules.team2.conceded = true
	end

	self.Surrendered = true
end

function Plugin:EndGame()
	if kNS2OptiConfig then
		kTechData[kTechId.InfantryPortal][kTechDataImplemented] = true
	end
	self.Surrendered = false
end

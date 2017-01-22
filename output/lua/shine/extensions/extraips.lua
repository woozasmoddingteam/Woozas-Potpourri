--[[
	Shine ExtraIps Plugin
]]
local Shine = Shine
local StringFormat = string.format

local Plugin = {}
Plugin.Version = "1.0"
Plugin.NS2Only = true

Plugin.HasConfig = true
Plugin.ConfigName = "ExtraIps.json"
Plugin.DefaultConfig =
{
	MinPlayers = { 18, 26 }
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	local Gamemode = Shine.GetGamemode()
	if Gamemode ~= "ns2" and Gamemode ~= "mvm" then        
		return false, StringFormat( "The ExtraIps plugin does not work with %s.", Gamemode )
	end

	self.Enabled = true
	return true
end

local count = 0
local takenInfantryPortalPoints = {}

local function SpawnInfantryPortal(self, techPoint, force)
	
	if Plugin.Enabled and not force and count > 0 then return end
	
    local techPointOrigin = techPoint:GetOrigin() + Vector(0, 2, 0)
    
    local spawnPoint
    
    -- First check the predefined spawn points. Look for a close one.
    for p = 1, #Server.infantryPortalSpawnPoints do
		
		if not takenInfantryPortalPoints[p] then 
			local predefinedSpawnPoint = Server.infantryPortalSpawnPoints[p]
			if (predefinedSpawnPoint - techPointOrigin):GetLength() <= kInfantryPortalAttachRange then
				spawnPoint = predefinedSpawnPoint
				takenInfantryPortalPoints[p] = true
				break
			end
		end
        
    end
    
    if not spawnPoint then
		
        spawnPoint = GetRandomBuildPosition( kTechId.InfantryPortal, techPointOrigin, kInfantryPortalAttachRange )
        spawnPoint = spawnPoint and spawnPoint - Vector( 0, 0.6, 0 )
		
    end
    
    if spawnPoint then
    
        local ip = CreateEntity(InfantryPortal.kMapName, spawnPoint, self:GetTeamNumber())
        
        SetRandomOrientation(ip)
        ip:SetConstructionComplete()
        
		count = count + 1
    end
    
end

function Plugin:OnFirstThink()
	Shine.Hook.ReplaceLocalFunction( MarineTeam.SpawnInitialStructures, "SpawnInfantryPortal", SpawnInfantryPortal )

	Shine.Hook.SetupClassHook( "MarineTeam", "SpawnInitialStructures", "OnSpawnInitialStructures", "PassivePost")
	Shine.Hook.SetupClassHook( "MarineTeam", "ResetTeam", "PreMarineTeamReset", "PassivePre")
end

function Plugin:PreMarineTeamReset()
	count = 0
	takenInfantryPortalPoints = {}
end

function Plugin:OnSpawnInitialStructures( Team, TechPoint )
	local MinPlayers = self.Config.MinPlayers
	local _, PlayerCount = Shine.GetAllPlayers()
	
	for i = 1, #MinPlayers do
		if PlayerCount >= MinPlayers[i] then 
			SpawnInfantryPortal(Team, TechPoint, true)
		end
	end
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
	self.Enabled = false
end

Shine:RegisterExtension( "extraips", Plugin )
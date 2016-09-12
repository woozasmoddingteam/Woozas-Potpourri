local Plugin = Plugin

Plugin.HasConfig = true 
Plugin.ConfigName = "PregamePlus.json"

Plugin.DefaultConfig = {
	CheckLimit = true,
	PlayerLimit = 8,
	LimitToggleDelay = 30,
	StatusTextPosX = 0.05,
	StatusTextPosY = 0.45,
	StatusTextColour = { 0, 255, 255 },
	AllowOnosExo = true,
	AllowMines = true,
	AllowCommanding = true,
	AllowStructureDamage = true,
	PregameArmorLevel = 3,
	PregameWeaponLevel = 3,
	PregameBiomassLevel = 9,
	PregameAlienUpgradesLevel = 3,
	ExtraMessageLine = "",
	Strings = {
		Status = "Pregame \"Sandbox\" - Mode is %s. A match has not started.",
		Limit = "Turns %s when %s %s players.",
		NoLimit = "No player limit.",
		Countdown = "Pregame \"Sandbox\" - Mode turning %s in %s.",
	}
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

local Shine = Shine
local StringFormat = string.format

--Hooks
do
	local SetupClassHook = Shine.Hook.SetupClassHook
	local SetupGlobalHook = Shine.Hook.SetupGlobalHook

	SetupClassHook( "AlienTeam", "UpdateBioMassLevel", "AlTeamUpdateBioMassLevel", "ActivePre")
	SetupClassHook( "Crag", "GetMaxSpeed", "CragGetMaxSpeed", "ActivePre")
	SetupClassHook( "InfantryPortal", "FillQueueIfFree", "FillQueueIfFree", "Halt" )
	SetupClassHook( "MAC", "GetMoveSpeed", "MACGetMoveSpeed", "ActivePre" )
	SetupClassHook( "MAC", "OnUse", "MACOnUse", "PassivePost" )
	SetupClassHook( "Shift", "GetMaxSpeed", "ShiftGetMaxSpeed", "ActivePre" )
	SetupClassHook( "TeleportMixin", "GetCanTeleport", "ShiftGetCanTeleport", "ActivePre" )
	SetupClassHook( "NS2Gamerules", "GetWarmUpPlayerLimit", "GetWarmUpPlayerLimit", "ActivePre" )
	SetupGlobalHook( "CanEntityDoDamageTo", "CanEntDoDamageTo", "ActivePre" )

	PrecacheAssetIfExists("models/marine/mac/mac.model")
	PrecacheAssetIfExists("models/marine/mac/mac.animation_graph")
end

function Plugin:Initialise()
	local Gamemode = Shine.GetGamemode()
	local Build = Shared.GetBuildNumber()

	if Build < 302 then
		return false, "PregamePlus requieres ns2 build 302 or greater! Please update your server."
	end

    if Gamemode ~= "ns2" and Gamemode ~= "mvm" then        
        return false, StringFormat( "The pregameplus plugin does not work with %s.", Gamemode )
    end

	--Checks if all config strings are okay syntax wise
	self:CheckConfigStrings()

	self.Enabled = true

	self.dt.AllowOnosExo = self.Config.AllowOnosExo
	self.dt.AllowMines = self.Config.AllowMines
	self.dt.AllowCommanding = self.Config.AllowCommanding

	self.dt.BioLevel = math.Clamp( self.Config.PregameBiomassLevel, 1, 12 )
	self.dt.UpgradeLevel = math.Clamp( self.Config.PregameAlienUpgradesLevel, 0, 3 )
	self.dt.WeaponLevel = math.Clamp( self.Config.PregameWeaponLevel, 0, 3 )
	self.dt.ArmorLevel = math.Clamp( self.Config.PregameArmorLevel, 0, 3 )

	self.dt.StatusX = math.Clamp(self.Config.StatusTextPosX, 0 , 1)
	self.dt.StatusY = math.Clamp(self.Config.StatusTextPosY, 0 , 1)
	self.dt.StatusR = math.Clamp(self.Config.StatusTextColour[1], 0 , 255 )
	self.dt.StatusG = math.Clamp(self.Config.StatusTextColour[2], 0 , 255 )
	self.dt.StatusB = math.Clamp(self.Config.StatusTextColour[3], 0 , 255 )
	self.dt.StatusDelay = math.Clamp(self.Config.LimitToggleDelay, 0, 1023)

	self.Ents = {}
	self.ProtectedEnts = {}

	--if the plugin gets enabled at a later point then the first load
	self:OnResume()

	return true
end

function Plugin:CheckConfigStrings()
	local changed

	for i, value in pairs( self.DefaultConfig.Strings ) do
		if not self.Config.Strings[i] then
			self.Config.Strings[i] = value
			changed = true
		end
	end
	
	if changed then
		self:SaveConfig()
	end
end

local function MakeTechEnt( techPoint, mapName, rightOffset, forwardOffset, teamType )
	local origin = techPoint:GetOrigin()
	local right = techPoint:GetCoords().xAxis
	local forward = techPoint:GetCoords().zAxis
	local position = origin + right * rightOffset + forward * forwardOffset

	local newEnt = CreateEntity( mapName, position, teamType)
	if HasMixin( newEnt, "Construct" ) then
		SetRandomOrientation( newEnt )
		newEnt:SetConstructionComplete() 
	end

	if HasMixin( newEnt, "Live" ) then
		newEnt:SetIsAlive(true)
	end

	local ID = newEnt:GetId()
	table.insert( Plugin.Ents, ID )
	Plugin.ProtectedEnts[ ID ] = true
end

function Plugin:CanEntDoDamageTo( _, Target )
	if not GetGameInfoEntity():GetWarmUpActive() then return end

	if self.Config.AllowStructureDamage and HasMixin(Target, "Construct") and not self.ProtectedEnts[ Target:GetId() ] then
		return true
	end
end

function Plugin:AlTeamUpdateBioMassLevel( AlienTeam )
	if GetGameInfoEntity():GetWarmUpActive()  then
		AlienTeam.bioMassLevel = self.Config.PregameBiomassLevel
		AlienTeam.bioMassAlertLevel = 0
		AlienTeam.maxBioMassLevel = 12
		AlienTeam.bioMassFraction = self.Config.PregameBiomassLevel
		return true
	end
end

--Prevent comm from moving crag
function Plugin:CragGetMaxSpeed( Crag )
	if self.ProtectedEnts[ Crag:GetId() ] then return 0 end
end

--Prevent comm from moving shifts
function Plugin:ShiftGetMaxSpeed( Shift )
	if self.ProtectedEnts[ Shift:GetId() ] then return 0 end
end

--prevents start buildings from being teleported
function Plugin:ShiftGetCanTeleport( Shift )
	if self.ProtectedEnts[ Shift:GetId() ] then return false end
end

--immobile macs so they don't get lost on the map
function Plugin:MACGetMoveSpeed( Mac )
	if self.ProtectedEnts[ Mac:GetId() ] then return 0 end
end

-- lets players use macs to instant heal since the immobile mac
function Plugin:MACOnUse( _, Player )
	if GetGameInfoEntity():GetWarmUpActive() then Player:AddHealth( 999, nil, false, nil ) end
end

function Plugin:SendText()
	self.dt.StatusText = StringFormat("%s\n%s\n%s", StringFormat(self.Config.Strings.Status, GetGameInfoEntity():GetWarmUpActive() and "enabled" or "disabled"),
		self.Config.CheckLimit and StringFormat( self.Config.Strings.Limit, GetGameInfoEntity():GetWarmUpActive() and "off" or "on",
			GetGameInfoEntity():GetWarmUpActive() and "being at" or "being under", self.Config.PlayerLimit )
		or self.Config.Strings.NoLimit,	self.Config.ExtraMessageLine )
	self.dt.ShowStatus = true
end

function Plugin:DestroyEnts()
	for i = 1, #self.Ents do
		local entid = self.Ents[ i ]
		local ent = Shared.GetEntity(entid)
		if ent then 
			DestroyEntity( ent )
		end
	end

	self.Ents = {}
	self.ProtectedEnts = {}
end

local function SpawnBuildings( team )
	local teamNr = team:GetTeamNumber()
	local techPoint = team:GetInitialTechPoint()

	if team:GetTeamType() == kAlienTeamType then
		MakeTechEnt( techPoint, Crag.kMapName, 3.5, 2, teamNr )
		MakeTechEnt( techPoint, Crag.kMapName, 3.5, -2, teamNr )
		MakeTechEnt( techPoint, Shift.kMapName, -3.5, 2, teamNr )
	else

		MakeTechEnt(techPoint, MAC.kMapName, 3.5, 2, teamNr)
	end
end

function Plugin:SetGameState( Gamerules, State, OldState )
	if OldState == State then return end --just in case, you never know

	if OldState == kGameState.WarmUp then
		self:Disable()
	elseif State == kGameState.WarmUp then
		self:Enable()
	end
end

function Plugin:GetWarmUpPlayerLimit()
	if not self.Config.CheckLimit or self:GetTimer( "Countdown" ) then return 999 end

	return self.Config.PlayerLimit
end

function Plugin:Enable()
	self:SendText()

	if GetGameInfoEntity():GetWarmUpActive() then
		local Rules = GetGamerules()
		if not Rules then return end

		local Team1 = Rules:GetTeam1()
		local Team2 = Rules:GetTeam2()

		SpawnBuildings(Team1)
		SpawnBuildings(Team2)

		for _, ent in ipairs( GetEntitiesWithMixin( "Construct" ) ) do
			self.ProtectedEnts[ ent:GetId() ] = true
		end
	end
end

function Plugin:Disable()

	self.dt.ShowStatus = false

	--stop the ongoing countdown
	self:DestroyTimer( "Countdown" )
	self.dt.CountdownText = ""

	if not GetGameInfoEntity():GetWarmUpActive() then return end

	self:DestroyEnts()
end

function Plugin:CheckLimit( Gamerules )
	if not self.Config.CheckLimit or not self.dt.ShowStatus then return end

	local Team1Players, _, Team1Bots = Gamerules:GetTeam1():GetNumPlayers()
	local Team2Players, _, Team2Bots = Gamerules:GetTeam2():GetNumPlayers()

	local PlayerCount = Team1Players + Team2Players - Team1Bots - Team2Bots

	local toogle = GetGameInfoEntity():GetWarmUpActive()

	if PlayerCount < self.Config.PlayerLimit then
		toogle = not toogle
	end

	if toogle then
		if not self:GetTimer( "Countdown" ) then
			self.dt.CountdownText = StringFormat( "%s\n%s\n%s", StringFormat( self.Config.Strings.Status,
				not GetGameInfoEntity():GetWarmUpActive()  and "disabled" or "enabled" ), StringFormat( self.Config.Strings.Countdown,
				not GetGameInfoEntity():GetWarmUpActive() and "on" or "off", "%s"), self.Config.ExtraMessageLine )

			self:CreateTimer( "Countdown", self.dt.StatusDelay, 1, function()
				Gamerules:ResetGame()
			end)
		end
	elseif self:TimerExists( "Countdown" ) then
		self:DestroyTimer( "Countdown" )
		self.dt.CountdownText = ""
	end
end

function Plugin:PostJoinTeam( Gamerules )
	self:CheckLimit( Gamerules )
end

function Plugin:ClientDisconnect( Client )
	local Player = Client:GetControllingPlayer()
	if Player then
		self:CheckLimit(GetGamerules())
	end
end

function Plugin:OnSuspend()
	self:Disable()
end

function Plugin:OnResume()
	if GetGamerules and GetGamerules() and GetGamerules():GetGameState() ~= kGameState.NotStarted then
		self:Enable()
	end
end

function Plugin:Cleanup()
	self:Disable()

	self.BaseClass.Cleanup( self )

	self.Enabled = false
end
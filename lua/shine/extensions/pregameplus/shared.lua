local Shine = Shine

local Plugin = {}
Plugin.Version = "1.4"
Plugin.NS2Only = true

function Plugin:SetupDataTable()
	self:AddDTVar( "boolean", "ShowStatus", false )
	self:AddDTVar( "string (255)", "CountdownText", "" )
	self:AddDTVar( "string (255)", "StatusText", "" )
	self:AddDTVar( "float (0 to 1 by 0.05)", "StatusX", 0.05)
	self:AddDTVar( "float (0 to 1 by 0.05)", "StatusY", 0.45)
	self:AddDTVar( "integer (0 to 255)", "StatusR", 0 )
	self:AddDTVar( "integer (0 to 255)", "StatusG", 255 )
	self:AddDTVar( "integer (0 to 255)", "StatusB", 255 )
	self:AddDTVar( "integer (0 to 1023)", "StatusDelay", 30 ) --2^10
	self:AddDTVar( "boolean", "AllowOnosExo", true )
	self:AddDTVar( "boolean", "AllowMines", true )
	self:AddDTVar( "boolean", "AllowCommanding", true )
	self:AddDTVar( "integer (1 to 12)", "BioLevel", 9 )
	self:AddDTVar( "integer (0 to 3)", "UpgradeLevel", 3 )
	self:AddDTVar( "integer (0 to 3)", "WeaponLevel", 3 )
	self:AddDTVar( "integer (0 to 3)", "ArmorLevel", 3 )
end

function Plugin:NetworkUpdate( Key, _, NewValue )
	if Server then return end

	if Key == "ShowStatus" then
		self:ShowStatus( NewValue )
	elseif Key == "StatusText" then
		self:UpdateStatusText( NewValue )
	elseif Key == "CountdownText" then
		self:UpdateStatusCountdown( NewValue )
	end
end

--stuff for modular Exo mod ( guys really use the techtree )
local function ReplaceModularExo_GetIsConfigValid( OldFunc, ... )
	local Hook = Shine.Hook.Call( "ModularExo_GetIsConfigValid", ... )
	if not Hook then return OldFunc(...) end

	local a, b, resourceCost, powerSupply, powerCost, exoTexturePath = OldFunc(...)
	resourceCost = resourceCost and 0

	return a, b, resourceCost, powerSupply, powerCost, exoTexturePath
end

--Hooks
do
	local SetupClassHook = Shine.Hook.SetupClassHook
	local SetupGlobalHook = Shine.Hook.SetupGlobalHook

	SetupClassHook( "TechNode", "GetResearched", "GetResearched", "ActivePre" )
	SetupClassHook( "TechNode", "GetHasTech", "GetHasTech", "ActivePre" )
	SetupGlobalHook( "LookupTechData", "LookupTechData", "ActivePre" )

	Shine.Hook.Add( "Think", "LoadSharedPGPHooks", function()

		SetupClassHook( "Player", "GetGameStarted", "GetGameStarted", "ActivePre" )

		SetupClassHook( "AlienTeamInfo", "OnUpdate", "AlienTeamInfoUpdate", "PassivePost" )

		SetupGlobalHook( "ModularExo_GetIsConfigValid", "ModularExo_GetIsConfigValid", ReplaceModularExo_GetIsConfigValid )

		Shine.Hook.Remove( "Think", "LoadSharedPGPHooks")
	end)
end

function Plugin:LookupTechData( techId, fieldName )
	if GetGameInfoEntity() and GetGameInfoEntity():GetWarmUpActive() and ( fieldName == kTechDataUpgradeCost or fieldName == kTechDataCostKey ) then

		if not self.dt.AllowOnosExo and ( techId == kTechId.Onos or techId == kTechId.Exosuit or techId == kTechId.ClawRailgunExosuit ) then
			return 999
		end
		
		if not self.dt.AllowMines then
			local Gamemode = Shine.GetGamemode()
			if Gamemode == "ns2" and techId == kTechId.LayMines or Gamemode == "mvm" and ( techId == kTechId.DemoMines or techId == kTechId.Mine ) then
				return 999 
			end
		end	
		
		return 0
	end
end

--fixing issues with TechNode
function TechNode:GetCost()
	return LookupTechData(self.techId, kTechDataCostKey, 0)
end

function Plugin:GetHasTech( Tech )
	if GetGameInfoEntity():GetWarmUpActive()  then
		local TechId = Tech.techId
		if TechId == kTechId.Weapons3 and self.dt.WeaponLevel < 3 then return false end
		if TechId == kTechId.Weapons2 and self.dt.WeaponLevel < 2 then return false end
		if TechId == kTechId.Weapons1 and self.dt.WeaponLevel < 1 then return false end
		
		if TechId == kTechId.Armor3 and self.dt.ArmorLevel < 3 then return false end
		if TechId == kTechId.Armor2 and self.dt.ArmorLevel < 2 then return false end
		if TechId == kTechId.Armor1 and self.dt.ArmorLevel < 1 then return false end
		return true
	end
end

function Plugin:GetResearched( Tech )
	return self:GetHasTech( Tech )
end

function Plugin:GetGameStarted( Player )
	if GetGameInfoEntity():GetWarmUpActive()  then
		if Player:isa( "Commander" ) and not self.dt.AllowCommanding then return false end
		return true 
	end
end

function Plugin:AlienTeamInfoUpdate( AlienTeamInfo )
	if not GetGameInfoEntity():GetWarmUpActive()  then return end

	AlienTeamInfo.bioMassLevel = self.dt.BioLevel
	AlienTeamInfo.numHives = 3
	AlienTeamInfo.veilLevel = self.dt.UpgradeLevel
	AlienTeamInfo.spurLevel = self.dt.UpgradeLevel
	AlienTeamInfo.shellLevel = self.dt.UpgradeLevel
end

function Plugin:ModularExo_GetIsConfigValid()
	return GetGameInfoEntity():GetWarmUpActive()
end

Shine:RegisterExtension( "pregameplus", Plugin )
-- ======= Copyright (c) 2003-2011, Unknown Worlds Entertainment, Inc. All rights reserved. =======
--
-- lua\Weapons\Marine\LayMinesCrazy.lua
--
--    Created by:   Andreas Urwalek (a_urwa@sbox.tugraz.at)
--
-- ========= For more information, visit us at http://www.unknownworlds.com =====================

Script.Load("lua/Weapons/Weapon.lua")
Script.Load("lua/PickupableWeaponMixin.lua")

class 'LayMinesCrazy' (LayMines)

LayMinesCrazy.kMapName = "minecrazy"
kNumCrazyMines = 99

local kPlacementDistance = 4

local networkVars =
{
    minesLeft = string.format("integer (0 to %d)", kNumCrazyMines),
    droppingMine = "boolean"
}

AddMixinNetworkVars(PickupableWeaponMixin, networkVars)
AddMixinNetworkVars(LiveMixin, networkVars)
AddMixinNetworkVars(PointGiverMixin, networkVars)

function LayMinesCrazy:OnCreate()

    Weapon.OnCreate(self)
    
    InitMixin(self, PickupableWeaponMixin)
    InitMixin(self, LiveMixin)
    InitMixin(self, PointGiverMixin)
    InitMixin(self, AchievementGiverMixin)

    self.minesLeft = kNumCrazyMines
    self.droppingMine = false
    self.animationSpeed = 2
end


function LayMinesCrazy:GetCatalystSpeedBase()
    return 5
end

function LayMinesCrazy:OnUpdateAnimationInput(modelMixin)

    PROFILE("LayMinesCrazy:OnUpdateAnimationInput")
    
    modelMixin:SetAnimationInput("activity", ConditionalValue(self.droppingMine, "primary", "none"))
    
end

function LayMinesCrazy:OnPrimaryAttack(player)

    -- Ensure the current location is valid for placement.
    
    -- we comment this out so the player can just hold down fire
    --if not player:GetPrimaryAttackLastFrame() then
    
	local showGhost, coords, valid = self:GetPositionForStructure(player)
	if valid then
	
	    if self.minesLeft > 0 then
		self.droppingMine = true
	    else
	    
		self.droppingMine = false
		
		if Client then
		    player:TriggerInvalidSound()
		end
		
	    end
	    
	else
	
	    self.droppingMine = false
	    
	    if Client then
		player:TriggerInvalidSound()
	    end
	    
	end
	
   --end
    
end

local function DropStructure(self, player)

    if Server then
    
	local showGhost, coords, valid = self:GetPositionForStructure(player)
	if valid then
	
	    -- Create mine.
	    local mine = CreateEntity(self:GetDropMapName(), coords.origin, player:GetTeamNumber())
	    if mine then
	    
		mine:SetOwner(player)
		
		-- Check for space
		if mine:SpaceClearForEntity(coords.origin) then
		
		    local angles = Angles()
		    angles:BuildFromCoords(coords)
		    mine:SetAngles(angles)
		    
		    player:TriggerEffects("create_" .. self:GetSuffixName())
		    
		    -- Jackpot.
		    return true
		    
		else
		
		    player:TriggerInvalidSound()
		    DestroyEntity(mine)
		    
		end
		
	    else
		player:TriggerInvalidSound()
	    end
	    
	else
	
	    if not valid then
		player:TriggerInvalidSound()
	    end
	    
	end
	
    elseif Client then
	return true
    end
    
    return false
    
end
function LayMinesCrazy:PerformPrimaryAttack(player)

    local success = true
    
    if self.minesLeft > 0 then
    
	player:TriggerEffects("start_create_" .. self:GetSuffixName())
	
	local viewAngles = player:GetViewAngles()
	local viewCoords = viewAngles:GetCoords()
	
	success = DropStructure(self, player)
	
	if success and not player:GetDarwinMode() then
	    self.minesLeft = Clamp(self.minesLeft - 1, 0, kNumCrazyMines)
	end
	
    end
    
    return success
    
end

-- Given a gorge player's position and view angles, return a position and orientation
-- for structure. Used to preview placement via a ghost structure and then to create it.
-- Also returns bool if it's a valid position or not.
function LayMinesCrazy:GetPositionForStructure(player)

    local isPositionValid = false
    local foundPositionInRange = false
    local structPosition = nil
    
    local origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * kPlacementDistance
    
    -- Trace short distance in front
    local trace = Shared.TraceRay(player:GetEyePos(), origin, CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
    
    local displayOrigin = trace.endPoint
    
    -- If we hit nothing, trace down to place on ground
    if trace.fraction == 1 then
    
	origin = player:GetEyePos() + player:GetViewAngles():GetCoords().zAxis * kPlacementDistance
	trace = Shared.TraceRay(origin, origin - Vector(0, kPlacementDistance, 0), CollisionRep.Default, PhysicsMask.AllButPCsAndRagdolls, EntityFilterTwo(player, self))
	
    end

    
    -- If it hits something, position on this surface (must be the world or another structure) and not right in our face
    if trace.fraction < 1 and trace.fraction > 0.1 then
	
	foundPositionInRange = true
    
	if trace.entity == nil then
	    isPositionValid = true
	elseif not trace.entity:isa("Clog") and not trace.entity:isa("Web") then
	    isPositionValid = true
	end
	
	displayOrigin = trace.endPoint
	
	-- Can not be built on infestation
	if GetIsPointOnInfestation(displayOrigin) then
	    isPositionValid = false
	end
    
	-- Don't allow dropped structures to go too close to techpoints and resource nozzles
	if GetPointBlocksAttachEntities(displayOrigin) then
	    isPositionValid = false
	end
    
	if trace.surface == "nocling" then       
	    --isPositionValid = false
	end
	
	-- Don't allow placing above or below us and don't draw either
	local structureFacing = player:GetViewAngles():GetCoords().zAxis
    
	if math.abs(Math.DotProduct(trace.normal, structureFacing)) > 0.9 then
	    structureFacing = trace.normal:GetPerpendicular()
	end
    
	-- Coords.GetLookIn will prioritize the direction when constructing the coords,
	-- so make sure the facing direction is perpendicular to the normal so we get
	-- the correct y-axis.
	local perp = Math.CrossProduct(trace.normal, structureFacing)
	structureFacing = Math.CrossProduct(perp, trace.normal)
    
	structPosition = Coords.GetLookIn(displayOrigin, structureFacing, trace.normal)
	
    end
    
    return foundPositionInRange, structPosition, isPositionValid
    
end

if Client then

    function LayMinesCrazy:OnProcessIntermediate(input)
    
	local player = self:GetParent()
	
	if player then
	
	    self.showGhost, self.ghostCoords, self.placementValid = self:GetPositionForStructure(player)
	    self.showGhost = self.showGhost and self.minesLeft > 0
	    
	end
	
    end
    
    function LayMinesCrazy:GetUIDisplaySettings()
	return { xSize = 256, ySize = 417, script = "lua/GUIMineDisplay.lua", textureNameOverride = "mine"}
    end
    
end

Shared.LinkClassToMap("LayMinesCrazy", LayMinesCrazy.kMapName, networkVars)

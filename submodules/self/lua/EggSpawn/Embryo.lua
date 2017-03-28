
local kMinGestationTime = 1


function Embryo:SetGestationData(techIds, previousTechId, healthScalar, armorScalar)

    -- Save upgrades so they can be given when spawned
    self.evolvingUpgrades = {}
    table.copy(techIds, self.evolvingUpgrades)

    self.gestationClass = nil
    
    for i, techId in ipairs(techIds) do
        self.gestationClass = LookupTechData(techId, kTechDataGestateName)
        if self.gestationClass then 
            -- Remove gestation tech id from "upgrades"
            self.gestationTypeTechId = techId
            table.removevalue(self.evolvingUpgrades, self.gestationTypeTechId)
            break 
        end
    end
    
    -- Upgrades don't have a gestate name, we want to gestate back into the
    -- current alien type, previousTechId.
    if not self.gestationClass then
        self.gestationTypeTechId = previousTechId
        self.gestationClass = LookupTechData(previousTechId, kTechDataGestateName)
    end
    self.gestationStartTime = Shared.GetTime()
    
    local lifeformTime = ConditionalValue(self.gestationTypeTechId ~= previousTechId, self:GetGestationTime(self.gestationTypeTechId), 0)
    
    if self:GetTechId() == kTechId.Egg then
      lifeformTime = kEmbryoGestateTime
    end
    
    local newUpgradesAmount = 0    
    local currentUpgrades = self:GetUpgrades()
    
    for _, upgradeId in ipairs(self.evolvingUpgrades) do
    
        if not table.contains(currentUpgrades, upgradeId) then
            newUpgradesAmount = newUpgradesAmount + 1
        end
        
    end
    
    self.gestationTime = ConditionalValue(Shared.GetDevMode() or GetGameInfoEntity():GetWarmUpActive(), 1, lifeformTime + newUpgradesAmount * kUpgradeGestationTime)
    
    self.gestationTime = math.max(kMinGestationTime, self.gestationTime)

    if Embryo.gFastEvolveCheat then
        self.gestationTime = 5
    end
    
    self.evolveTime = 0
    
    local maxHealth = LookupTechData(self.gestationTypeTechId, kTechDataMaxHealth) * 0.3 + 100
    maxHealth = math.round(maxHealth * 0.1) * 10

    self:SetMaxHealth(maxHealth)
    self:SetHealth(maxHealth * healthScalar)
    self:SetMaxArmor(0)
    self:SetArmor(0)
    
    -- Use this amount of health when we're done evolving
    self.storedHealthScalar = healthScalar
    self.storedArmorScalar = armorScalar
    
    -- we reset the upgrades entirely and set them again, simplifies the code
    self:ClearUpgrades()
    
	-- First upgrade time for skulks is 2, after this it uses kMinGestationTime + upgrades as normal
    if self.gestationTypeTechId == kTechId.Skulk and #currentUpgrades == 0 then
        self.gestationTime = 2
    end
    
end
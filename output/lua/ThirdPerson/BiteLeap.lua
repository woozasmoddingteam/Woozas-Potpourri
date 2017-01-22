
-- kRange is the range from eye to edge of attack range, ie its independent of the size of
-- the melee box. previously this value had an offset, which caused targets to be behind the melee
-- attack (too close to the target and you missed)
-- NS1 was 20 inches, which is .5 meters. The eye point in NS1 was correct but in NS2 it's the model origin.
-- Melee attacks must originate from the player's eye instead of the world model's eye to make sure you
-- can't attack through walls.
local kRange = 1.42
local kEnzymedRange = 1.55
local kAttackDuration = Shared.GetAnimationLength("models/alien/skulk/skulk_view.model", "bite_attack")

local originalOnUpdateAnimationInput = BiteLeap.OnUpdateAnimationInput
function BiteLeap:OnUpdateAnimationInput(modelMixin)

  PROFILE("BiteLeap:OnUpdateAnimationInput")

  modelMixin:SetAnimationInput("ability", "bite")
  
  local activityString = (self.primaryAttacking and "primary") or "none"
  modelMixin:SetAnimationInput("activity", activityString)
  
end


local originalOnTag = BiteLeap.OnTag
function BiteLeap:OnTag(tagName)

    PROFILE("BiteLeap:OnTag")

    if tagName == "hit" then
    
        local player = self:GetParent()
        
        if player then
        
            local range = (player.GetIsEnzymed and player:GetIsEnzymed()) and kEnzymedRange or kRange
            
            local optionalCoords = nil
            if player:GetIsThirdPerson() and not player:GetIsWallWalking() then
                -- squash the vertical view vector in third person
                local verticalSquash = GetNormalizedVectorXZ(Vector(1,0.1, 1))
                optionalCoords = player:GetViewAngles():GetCoords()
                optionalCoords.xAxis.y = optionalCoords.xAxis.y * 0.3 + 0.1
                optionalCoords.yAxis.y = optionalCoords.yAxis.y * 0.3 + 0.1
                optionalCoords.zAxis.y = optionalCoords.zAxis.y * 0.3 + 0.1
            end
            
            local didHit, target, endPoint = AttackMeleeCapsule(self, player, kBiteDamage, range, optionalCoords, false, EntityFilterOneAndIsa(player, "Babbler"))
            
            if Client and didHit and not player:GetIsThirdPerson() then
                self:TriggerFirstPersonHitEffects(player, target)  
            end
            
            if target and HasMixin(target, "Live") and not target:GetIsAlive() then
                self:TriggerEffects("bite_kill")
            elseif Server and target and target.TriggerEffects and GetReceivesStructuralDamage(target) and (not HasMixin(target, "Live") or target:GetCanTakeDamage()) then
                target:TriggerEffects("bite_structure", {effecthostcoords = Coords.GetTranslation(endPoint), isalien = GetIsAlienUnit(target)})
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            self:TriggerEffects("bite_attack")
            
            self:DoAbilityFocusCooldown(player, kAttackDuration)
            
        end
        
    end
    
end



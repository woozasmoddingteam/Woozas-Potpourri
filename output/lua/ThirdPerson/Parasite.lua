
local kRange = 1000
local kParasiteSize = 0.15 -- size of parasite blob
local kParasiteSound = PrecacheAsset("sound/NS2.fev/alien/skulk/parasite")

local oldPerformPrimaryAttack = Parasite.PerformPrimaryAttack

function Parasite:PerformPrimaryAttack(player)

    self.activity = Parasite.kActivity.Primary
    self.primaryAttacking = true
    
    local success = false

    if not self.blocked then
    
        self.blocked = true
        
        success = true
        
        if player:GetIsThirdPerson() then
            -- only play the sound, there is no view model
            StartSoundEffectForPlayer(kParasiteSound, player)
        else
            self:TriggerEffects("parasite_attack")
        end
        -- Trace ahead to see if hit enemy player or structure

        local viewCoords = player:GetLookingCoords()
        local startPoint = player:GetEyePos()
    
        -- double trace; first as a ray to allow us to hit through narrow openings, then as a fat box if the first one misses
        local trace = Shared.TraceRay(startPoint, startPoint + viewCoords.zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(viewCoords.zAxis, kParasiteSize)
            trace = Shared.TraceBox(extents, startPoint, startPoint + viewCoords.zAxis * kRange, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
        end
        
        if trace.fraction < 1 then
        
            local hitObject = trace.entity
            local direction = GetNormalizedVector(trace.endPoint - startPoint)
            local impactPoint = trace.endPoint - direction * kHitEffectOffset
            
            self:DoDamage(kParasiteDamage, hitObject, impactPoint, direction)
            
        end
        
    end
    
    return success
    
end



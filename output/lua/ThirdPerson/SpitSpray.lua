
local kSpitSpeed = 35
local attackEffectMaterial = nil
local kSpitViewEffect = PrecacheAsset("cinematics/alien/gorge/spit_1p.cinematic")
local kViewSpitMaterial = PrecacheAsset("materials/effects/mesh_effects/view_spit.material")
local kAttackDuration = Shared.GetAnimationLength("models/alien/gorge/gorge_view.model", "spit_attack")
-- special case for gorge spit.  Let them fire faster, but do less damage.  Lowering gorge spit frequency as much
-- as other lifeforms is more punishing as gorge spit is harder to land anyways.
kAttackDuration = kAttackDuration * 0.75

if Client then

    attackEffectMaterial = Client.CreateRenderMaterial()
    attackEffectMaterial:SetMaterial(kViewSpitMaterial)
    
end


local function CreateSpitProjectile(self, player)   

    if not Predict then
        
        local eyePos = player:GetEyePos()        
        local viewCoords = player:GetLookingCoords()
        
        local startPointTrace = Shared.TraceCapsule(eyePos, eyePos + viewCoords.zAxis * 1.5, Spit.kRadius, 0, CollisionRep.Damage, PhysicsMask.PredictedProjectileGroup, EntityFilterOneAndIsa(player, "Babbler"))
        local startPoint = startPointTrace.endPoint
        
        local spit = player:CreatePredictedProjectile("Spit", startPoint, viewCoords.zAxis * kSpitSpeed, 0, 0, 0 )
    
    end

end



function SpitSpray:OnTag(tagName)

    PROFILE("SpitSpray:OnTag")

    if self.primaryAttacking and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
        
            if Server or (Client and Client.GetIsControllingPlayer()) then
                CreateSpitProjectile(self, player)
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())
            self:TriggerEffects("spitspray_attack")
            
            self:DoAbilityFocusCooldown(player, kAttackDuration)
            
            if Client then
            
                if not player:GetIsThirdPerson() then
                  local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                  cinematic:SetCinematic(kSpitViewEffect)
                end
                
                local model = player:GetViewModelEntity():GetRenderModel()

                model:RemoveMaterial(attackEffectMaterial)
                model:AddMaterial(attackEffectMaterial)
                attackEffectMaterial:SetParameter("attackTime", Shared.GetTime())
                
            end
            
        end
        
    end
    
end
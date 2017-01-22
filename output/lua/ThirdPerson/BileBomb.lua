

local kBombVelocity = 11
local kThirdPersonHelp = Vector(0,0.3,0)
local kBbombViewEffect = PrecacheAsset("cinematics/alien/gorge/bbomb_1p.cinematic")

local function NewCreateBombProjectile(self, player)

    if not Predict then
        
    
        local viewCoords = player:GetLookingCoords()
        local startPoint = player:GetEyePos() + viewCoords.zAxis * 1.5
        
        local startPointTrace = Shared.TraceRay(player:GetEyePos(), startPoint, CollisionRep.Damage, PhysicsMask.Bullets, EntityFilterOneAndIsa(player, "Babbler"))
        startPoint = startPointTrace.endPoint
        
        
        local startVelocity = viewCoords.zAxis * kBombVelocity
        
        -- small upwards boost for third person players
        if player:GetIsThirdPerson() then
            startVelocity = GetNormalizedVector(viewCoords.zAxis + kThirdPersonHelp) * kBombVelocity
        end
        
        local bomb = player:CreatePredictedProjectile( "Bomb", startPoint, startVelocity, 0, 0, nil )
        
    end
    
    
end

function BileBomb:OnTag(tagName)

    PROFILE("BileBomb:OnTag")

    if self.firingPrimary and tagName == "shoot" then
    
        local player = self:GetParent()
        
        if player then
        
            if Server or (Client and Client.GetIsControllingPlayer()) then
                NewCreateBombProjectile(self, player)
            end
            
            player:DeductAbilityEnergy(self:GetEnergyCost())            
            self.timeLastBileBomb = Shared.GetTime()
            
            
            self:TriggerEffects("bilebomb_attack")
              
            if Client and not player:GetIsThirdPerson() then
            
                local cinematic = Client.CreateCinematic(RenderScene.Zone_ViewModel)
                cinematic:SetCinematic(kBbombViewEffect)
                
            end
            
        end
    
    end
    
end


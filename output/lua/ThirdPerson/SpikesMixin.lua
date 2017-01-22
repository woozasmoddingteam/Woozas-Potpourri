

Script.Load("lua/ThirdPerson/ReplaceUpValue.lua")


local kSpikeSize = 0.03
local kSpread = Math.Radians(4)

local function NewFireSpikes(self)

    local player = self:GetParent()    
    
    -- Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterOneAndIsa(player, "Babbler")
    local range = kSpikesRange
    
    local numSpikes = kSpikesPerShot
    local startPoint = player:GetEyePos()
    
    local viewCoords = player:GetLookingCoords()
    
    self.spiked = true
    self.silenced = GetHasSilenceUpgrade(player) and GetVeilLevel(player:GetTeamNumber()) > 0
    
    for spike = 1, numSpikes do

        -- Calculate spread for each shot, in case they differ
        local spreadDirection = CalculateSpread(viewCoords, kSpread, NetworkRandom) 

        local endPoint = startPoint + spreadDirection * range
        startPoint = player:GetEyePos()
        
        local trace = Shared.TraceRay(startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        if not trace.entity then
            local extents = GetDirectedExtentsForDiameter(spreadDirection, kSpikeSize)
            trace = Shared.TraceBox(extents, startPoint, endPoint, CollisionRep.Damage, PhysicsMask.Bullets, filter)
        end
        
        local distToTarget = (trace.endPoint - startPoint):GetLength()
        
        if trace.fraction < 1 then

            -- Have damage increase to reward close combat
            local damageDistScalar = Clamp(1 - (distToTarget / kSpikeMinDamageRange), 0, 1)
            local damage = kSpikeMinDamage + damageDistScalar * (kSpikeMaxDamage - kSpikeMinDamage)
            local direction = (trace.endPoint - startPoint):GetUnit()
            self:DoDamage(damage, trace.entity, trace.endPoint - direction * kHitEffectOffset, direction, trace.surface, true, math.random() < 0.75)
                
        end
        
    end
    
end
ReplaceUpValue( SpikesMixin.OnTag, "FireSpikes", NewFireSpikes, { LocateRecurse = true; CopyUpValues = true; } )

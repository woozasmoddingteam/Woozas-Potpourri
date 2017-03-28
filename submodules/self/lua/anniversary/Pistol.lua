
-- Taken from ClipWeapon.lua
local function FireBullets(self, player)

    PROFILE("FireBullets")

    local viewAngles = player:GetViewAngles()
    local shootCoords = viewAngles:GetCoords()

    -- Filter ourself out of the trace so that we don't hit ourselves.
    local filter = EntityFilterTwo(player, self)
    local range = self:GetRange()

    if GetIsVortexed(player) then
        range = 5
    end

    local numberBullets = self:GetBulletsPerShot()
    local startPoint = player:GetEyePos()
    local bulletSize = self:GetBulletSize()

    for bullet = 1, numberBullets do

        local spreadDirection = self:CalculateSpreadDirection(shootCoords, player)

        local endPoint = startPoint + spreadDirection * range
        local targets, trace, hitPoints = GetBulletTargets(startPoint, endPoint, spreadDirection, bulletSize, filter)
        local damage = self:GetBulletDamage()

        HandleHitregAnalysis(player, startPoint, endPoint, trace)

        local direction = (trace.endPoint - startPoint):GetUnit()
        local hitOffset = direction * kHitEffectOffset
        local impactPoint = trace.endPoint - hitOffset
        local effectFrequency = self:GetTracerEffectFrequency()
        local showTracer = math.random() < effectFrequency

        local numTargets = #targets

        if numTargets == 0 then
            self:ApplyBulletGameplayEffects(player, nil, impactPoint, direction, 0, trace.surface, showTracer)
        end

        if Client and showTracer then
            TriggerFirstPersonTracer(self, impactPoint)
        end

        for i = 1, numTargets do

            local target = targets[i]

			if Client and target:isa("SecretGorge") then
				target:OnUse(player, self);
				goto continue;
			end

            local hitPoint = hitPoints[i]

            self:ApplyBulletGameplayEffects(player, target, hitPoint - hitOffset, direction, damage, "", showTracer and i == numTargets)

            local client = Server and player:GetClient() or Client
            if not Shared.GetIsRunningPrediction() and client.hitRegEnabled then
                RegisterHitEvent(player, bullet, startPoint, trace, damage)
            end

			::continue::
        end

    end

end

function Pistol:FirePrimary(player)

    self.fireTime = Shared.GetTime()
	FireBullets(self, player)

    self:TriggerEffects("pistol_attack")

end


local weaponOnInitialized = Weapon.OnInitialized
function Weapon:OnInitialized(deltatime)
   local ret = weaponOnInitialized(self, deltatime)
   self:SetUpdates(self:GetIsDroppable())
   return ret
end

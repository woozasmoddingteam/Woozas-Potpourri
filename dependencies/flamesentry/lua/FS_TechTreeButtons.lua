local old_GetMaterialXYOffset = GetMaterialXYOffset
function GetMaterialXYOffset(techId)
   if (techId == kTechId.FlameSentry) then
      techId = kTechId.Sentry
   end
   return old_GetMaterialXYOffset(techId)
end

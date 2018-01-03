local offsets = debug.getupvalue(GetMaterialXYOffset, "kTechIdToMaterialOffset")
offsets[kTechId.FlameSentry] = offsets[kTechId.Sentry]


-- Thanks compmod for the function
local function _AddFlameSentryModTechChanges(techData)


   table.insert(techData, { [kTechDataId] = kTechId.FlameSentry,
     [kTechDataSupply] = kSentrySupply,
     [kTechDataBuildMethodFailedMessage] = "COMMANDERERROR_TOO_MANY_SENTRIES",
     [kTechDataHint] = "SENTRY_HINT",
     [kTechDataGhostModelClass] = "MarineGhostModel",

     [kTechDataMapName] = FlameSentry.kMapName,
     [kTechDataDisplayName] = "FLAME_SENTRY_TURRET",
     [kTechDataCostKey] = kSentryCost,
     [kTechDataPointValue] = kSentryPointValue,
     [kTechDataModel] = FlameSentry.kModelName,

     [kTechDataBuildTime] = kSentryBuildTime,
     [kTechDataMaxHealth] = kSentryHealth,
     [kTechDataMaxArmor] = kSentryArmor,
     [kTechDataDamageType] = kFlameSentryAttackDamageType,
     [kTechDataSpecifyOrientation] = true,
     -- [kTechDataHotkey] = Move.S,
     [kTechDataInitialEnergy] = kSentryInitialEnergy,
     [kTechDataMaxEnergy] = kSentryMaxEnergy,
     [kTechDataNotOnInfestation] = kPreventMarineStructuresOnInfestation,
     [kTechDataEngagementDistance] = kFlameSentryEngagementDistance,
     [kTechDataTooltipInfo] = "SENTRY_TOOLTIP",

     [kStructureBuildNearClass] = "SentryBattery",
     [kStructureAttachRange] = SentryBattery.kRange,
     [kTechDataBuildRequiresMethod] = GetCheckSentryLimit,
     [kTechDataGhostGuidesMethod] = GetBatteryInRange,
     [kTechDataObstacleRadius] = 0.25 })



    -- for index, record in ipairs(techData) do
       -- if record[kTechDataId] == kTechId.FlameSentry then
       --    record[kTechDataBuildRequiresMethod] = GetCheckSentryLimit
       -- end
    -- end
end

local oldBuildTechData = BuildTechData
function BuildTechData()
   local techData = oldBuildTechData()
   _AddFlameSentryModTechChanges(techData)
   return techData
end


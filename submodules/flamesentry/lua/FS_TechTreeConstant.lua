-- flameSentry_kTechId = {
--    'FlameSentry',
-- }

-- for key, name in ipairs( kTechId ) do
--    if (#flameSentry_kTechId <= 511) then -- should not get above 511
--       table.insert(flameSentry_kTechId, kTechId[key])
--    end
-- end

-- -- Increase techNode network precision if more needed
-- kTechIdMax  = math.pow(2, math.ceil( math.log( #flameSentry_kTechId )/ math.log(2) ) ) - 1 -- use all the bits

-- -- To be compliant with ns2+
-- for i = #flameSentry_kTechId + 1, kTechIdMax do
--    flameSentry_kTechId[i] = 'unused'.. i
-- end

-- kTechId = enum(flameSentry_kTechId)

flameSentry_kTechId = {
}

for key, name in ipairs( kTechId ) do
   table.insert(flameSentry_kTechId, kTechId[key])
end

-- Remove kTechId.Max
table.remove(flameSentry_kTechId, #flameSentry_kTechId)
-- Insert our own entries
table.insert(flameSentry_kTechId, 'FlameSentry')
-- Add Max back
table.insert(flameSentry_kTechId, 'Max')

kTechId = enum(flameSentry_kTechId)
kTechIdMax  = kTechId.Max

local old = BuildTechData
function BuildTechData()
	local techdata = old()
	for i = #techdata, 1, -1 do
		local e = techdata[i]
		if e[kTechDataId] == kTechId.HadesDevice then
			e[kTechDataDisplayName] = "Super Hades Device"
			break
		end
	end
	return techdata
end

Script.Load("lua/Client.lua")
Script.Load("lua/Class.lua")

local kObservatoryTechButtons = { kTechId.Scan, kTechId.Detector, kTechId.None, kTechId.None,
								   kTechId.PhaseTech, kTechId.DistressBeacon, kTechId.None, kTechId.None }
								   
function Observatory:GetTechButtons(techId)

	if techId == kTechId.RootMenu then
		return kObservatoryTechButtons
	end
	
	return nil
	
end
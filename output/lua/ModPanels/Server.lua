Log("waaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaat")
local oldCreateLiveMapEntities = CreateLiveMapEntities
function CreateLiveMapEntities()
    oldCreateLiveMapEntities(self)
    Log("wat")
    OnModPanelsCommand()
    kModPanelsLoaded = true
end

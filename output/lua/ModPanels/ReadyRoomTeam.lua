
if Server then
Log("wat")
    local oldInitialize = ReadyRoomTeam.Initialize
    function ReadyRoomTeam:Initialize()
        oldInitialize(self)
        Log("Spawning mod panels")
        OnModPanelsCommand()
    end

end
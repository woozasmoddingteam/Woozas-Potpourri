
if Server then
    local old = Gamerules.OnMapPostLoad
    function Gamerules:OnMapPostLoad()
        old(self)
        InitializeModPanels()
    end
end

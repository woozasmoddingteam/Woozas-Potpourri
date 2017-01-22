if Client then
    
    local originalOnGetIsVisible = Babbler.OnGetIsVisible
    
    -- hide babblers which are clinged on the local player to not obscure their view
    function Babbler:OnGetIsVisible(visibleTable, viewerTeamNumber)
        
        local parent = self:GetParent()
        if parent and (parent == Client.GetLocalPlayer() or not parent:GetIsVisible()) and not parent:GetIsThirdPerson() then
            visibleTable.Visible = false
        end
    
    end

end

local kThirdPersonTextXOffset = 110
local kThirdPersonTextYOffset = 25
local kThirdPersonButtonXOffset = 92
local kThirdPersonButtonYOffset = -25
local kThirdPersonTextColor = Color(1, 121/255, 12/255, 1)
local kThirdPersonFontName = Fonts.kStamp_Medium

local oldInitialize = GUIAlienHUD.Initialize
function GUIAlienHUD:Initialize()

    oldInitialize(self)
    
    self.thirdPersonButton = GUICreateButtonIcon("Reload")
    self.thirdPersonButton:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.thirdPersonButton:SetPosition(GUIScale(Vector(kThirdPersonButtonXOffset, kThirdPersonButtonYOffset, 0)))
    
    self.thirdPersonText = GUIManager:CreateTextItem()
    self.thirdPersonText:SetFontName(kThirdPersonFontName)
    self.thirdPersonText:SetAnchor(GUIItem.Middle, GUIItem.Center)
    self.thirdPersonText:SetPosition(Vector(GUIScale(kThirdPersonTextXOffset), GUIScale(kThirdPersonTextYOffset), 0))
    self.thirdPersonText:SetTextAlignmentX(GUIItem.Align_Center)
    self.thirdPersonText:SetTextAlignmentY(GUIItem.Align_Center)
    self.thirdPersonText:SetColor(kThirdPersonTextColor)
    self.thirdPersonText:SetScale(GetScaledVector())
    self.thirdPersonText:SetText("Camera")
    self.thirdPersonText:SetInheritsParentAlpha(true)
    GUIMakeFontScale(self.thirdPersonText)
    
    self.healthBall:GetBackground():AddChild(self.thirdPersonText)
    self.healthBall:GetBackground():AddChild(self.thirdPersonButton)
    
end



local oldUninitialize = GUIAlienHUD.Uninitialize
function GUIAlienHUD:Uninitialize()
    oldUninitialize(self)
    
    if self.thirdPersonText then
        GUI.DestroyItem(self.thirdPersonText)
    end
    if self.thirdPersonButton then
        GUI.DestroyItem(self.thirdPersonButton)
    end

end
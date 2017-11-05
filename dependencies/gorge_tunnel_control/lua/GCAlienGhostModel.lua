local kMistCinematic =PrecacheAsset("cinematics/alien/build/build.cinematic")
local kFontColor = Color(1, 0.8, 0.2)

Script.Load("lua/Hud/Commander/GCGhostModelUI.lua")

function AlienGhostModel:Initialize()

    GhostModel.Initialize(self)
	
    if not self.trailCinematic then
    
        self.cinematic = Client.CreateCinematic(RenderScene.Zone_Default)
        self.cinematic:SetCinematic(kMistCinematic)
        self.cinematic:SetRepeatStyle(Cinematic.Repeat_Endless)
    
    end
	
	if not self.specialText then
    
        self.specialText = GUIManager:CreateTextItem()
        self.specialText:SetIsVisible(false)
		self.specialText:SetFontName(Fonts.kStamp_Medium)
		self.specialText:SetColor(kFontColor)
        self.specialText:SetLayer(kGUILayerCommanderHUD)
        
    end
    
end

function AlienGhostModel:Update()
    local modelCoords = GhostModel.Update(self)
    
    if modelCoords then        
        self.cinematic:SetCoords(modelCoords)
		
		if GhostModelUI_GetTunnelText then
			self.specialText:SetIsVisible(true)
			local text = string.format(GhostModelUI_GetTunnelText())
			self.specialText:SetPosition(Client.WorldToScreen(modelCoords.origin) - Vector( 2 + (text:len()/2) ,0,0) )
			self.specialText:SetText(text)
		else
			self.specialText:SetIsVisible(false)
		end
		
    end
    
end

function AlienGhostModel:Destroy() 

    GhostModel.Destroy(self)   
    
    if self.cinematic then
        Client.DestroyCinematic(self.cinematic)
        self.cinematic = nil
    end
	
    if self.specialText then
    
        GUI.DestroyItem(self.specialText)
        self.specialText = nil
        
    end
	
end
--[[
 	ShoulderPatchesExtra
	ZycaR (c) 2016
]]
Script.Load("lua/spe/ShoulderPatchesConfig.lua")
Script.Load("lua/spe/ShoulderPatchesMessage.lua")

local speMenuOptions = {
    name  = "ShoulderPatch",
    label = "Custom Patches",
    css   = "customize_input"
}

local function OnShoulderPatchChanged(formElement)
    local name = formElement:GetValue()
    local index = ShoulderPatchesConfig:SetClientShoulderPatch(name)
    MenuPoses_SetPose("idle", "decal", true)
    MenuPoses_Function():SetCoordsOffset("decal")
    SendShoulderPatchUpdate(index)
end

local menuRefreshed = false
local inputKey = newproxy()

local function OnMouseInFn(self)
	local input = self[inputKey]
	local showModelType = "decal"
	local currentModel = Client.GetOptionString("currentModel", "")
	Client.SetOptionString("currentModel", input:GetFormElementName())

	if input:GetFormElementName() ~= currentModel or menuRefreshed == true then
		if Client.GetOptionString("lastShownModel", "") ~= showModelType then
			MenuPoses_SetPose("idle", showModelType, true)
			MenuPoses_Function():SetCoordsOffset(showModelType)
		end

		Client.SetOptionString("lastShownModel", showModelType)
		Client.SetOptionString("lastModel", input:GetFormElementName())
		menuRefreshed = false
	end
end

local function OnHideFn(self)
	self.scriptHandle.spe:SetIsVisible(false)
end

local ns2_CreateCustomizeWindow = GUIMainMenu.CreateCustomizeWindow
function GUIMainMenu:CreateCustomizeWindow()
    ns2_CreateCustomizeWindow(self)
    self.customizeFrame:AddEventCallbacks( { OnShow = function(self) menuRefreshed = true end } )

    local player = Client and Client.GetLocalPlayer()
    local patchNames = ShoulderPatchesConfig:GetClientShoulderPatchNames(player)
    local patchName, index = ShoulderPatchesConfig:GetClientShoulderPatch(player)

    LoadCSSFile("lua/spe/css.css")

    // create container
    self.spe = CreateMenuElement(self.mainWindow, "ContentBox", true)
    self.spe:SetCSSClass("shoulder_patches_wrapper")

    self.customizeFrame:AddEventCallbacks {
        OnHide = OnHideFn
    }

    // create form
    local form = CreateMenuElement(self.spe, "Form", true)
    form:SetCSSClass("options")

    // label on top of input
    local label = CreateMenuElement(form, "Font", false)
    label:SetCSSClass("shoulder_patches_label")
    label:SetText(speMenuOptions.label)
    label:SetTopOffset(0)
    label:SetIgnoreEvents(false)

    // input for patches
    local input = form:CreateFormElement(Form.kElementType.DropDown, speMenuOptions.name, patchName)
    input:SetOptions(patchNames)
    input:SetCSSClass(speMenuOptions.css)
    input:AddSetValueCallback(OnShoulderPatchChanged)
    input:SetTopOffset(35)

    for index, child in ipairs(input:GetChildren()) do
		child[inputKey] = input
        child:AddEventCallbacks {OnMouseIn = OnMouseInFn}
    end

    self.customizeElements[speMenuOptions.name] = input
end

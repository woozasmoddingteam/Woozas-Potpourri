--[[
	[Shine] ModSelector by Keats & Yeats.
	A Shine plugin to enable and disable server mods in-game.
	Please see https://github.com/keatsandyeats/Shine-ModSelector for more information.
--]]
	
local Shine = Shine
local Plugin = Plugin
local SGUI = Shine.GUI

Plugin.HasConfig = false

function Plugin:Initialise()
	self:SetupAdminMenuCommands()
	
	self.Enabled = true
	
	return true
end

-- TODO: new tab doesn't populate the first time you select it, only after you select away and back.
function Plugin:SetupAdminMenuCommands()
	ModTabData = {
		OnInit = function(Panel, Data)
			local List = SGUI:Create("List", Panel)
			List:SetAnchor(GUIItem.Left, GUIItem.Top)
			List:SetPos(Vector(16, 28, 0))
			List:SetColumns("Mod", "State")
			List:SetSpacing(0.7, 0.3)
			List:SetSize(Vector(640, 512, 0))
			List.ScrollPos = Vector(0, 32, 0)
			List:SetSecondarySortColumn(2,1)
			
			self.ModList = List
			
			self:RequestModData()
			
			self:PopulateModList()
			
			--sort list by Enabled
			List:SortRows(2, nil, true)
			
			local ButtonSize = Vector(128, 32, 0)
			
			--returns the hexID and state of the selected mod
			local function GetSelectedMod()
				local Selected = List:GetSelectedRow()
				if not Selected then return end
				
				return Selected.HexID, Selected.ModEnabled
			end
			
			local DisableMod = SGUI:Create("Button", Panel)
			DisableMod:SetAnchor("BottomLeft")
			DisableMod:SetSize(ButtonSize)
			DisableMod:SetPos(Vector(16, -48, 0))
			DisableMod:SetText("Disable Mod")
			DisableMod:SetFont(Fonts.kAgencyFB_Small)
			
			function DisableMod.DoClick(Button)
				local Mod, State = GetSelectedMod()
				
				if not Mod then return false end --a nil mod means no selection, so do nothing
				if not State then return false end --if mod is already disabled then do nothing
				
				--change mod's status in the mod table
				self.ModData[Mod]["enabled"] = false
				
				--change mod's status in the list
				for i=1,#List.Rows do --for loop is inefficient but I don't know a better way
					if List.Rows[i]["HexID"] == Mod then
						List.Rows[i]["ModEnabled"] = false
						List.Rows[i]:SetColumnText(2, "Disabled")
						
						break
					end
				end
				
				Shine.AdminMenu:RunCommand("sh_disablemods", Mod)
			end
			
			local EnableMod = SGUI:Create("Button", Panel)
			EnableMod:SetAnchor("BottomRight")
			EnableMod:SetSize(ButtonSize)
			EnableMod:SetPos(Vector(-144, -48, 0))
			EnableMod:SetText("Enable Mod")
			EnableMod:SetFont(Fonts.kAgencyFB_Small)
			
			function EnableMod.DoClick(Button)
				local Mod, State = GetSelectedMod()
				
				if not Mod then return false end --a nil mod means no selection, so do nothing
				if State then return false end --if mod is already enabled then do nothing
				
				--change mod's status in the mod table
				self.ModData[Mod]["enabled"] = true
				
				--change mod's status in the list
				for i=1,#List.Rows do --for loop is inefficient but I don't know a better way
					if List.Rows[i]["HexID"] == Mod then
						List.Rows[i]["ModEnabled"] = true
						List.Rows[i]:SetColumnText(2, "Enabled")
						
						break
					end
				end
				
				Shine.AdminMenu:RunCommand("sh_enablemods", Mod)
			end
		end
	}
	
	self:AddAdminMenuTab("Mods", ModTabData)
end

--[[
	Ask the server for all the mod data.
--]]
function Plugin:RequestModData()
	self:SendNetworkMessage("RequestModData", {}, true)
end

--[[
	handle the network message from the server that contains mod data
--]]
function Plugin:ReceiveModData(Data)
	self.ModData = self.ModData or {}
	self.ModData[Data.HexID] = {displayname = Data.DisplayName, enabled = Data.Enabled}
end

--[[
	add a row for each mod to the mod list
--]]
function Plugin:PopulateModList()
	self.ModData = self.ModData or {}
	
	local List = self.ModList
	if not SGUI.IsValid(List) then return end
	
	for HexID, modData in pairs(self.ModData) do
		--add the row to the list display
		local Row = List:AddRow(modData.displayname, modData.enabled and "Enabled" or "Disabled")
		
		--add extra info for GetSelectedMod
		Row["HexID"] = HexID
		Row["ModEnabled"] = modData.enabled
	end
end

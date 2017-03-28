class 'ModPanel' (Entity)

ModPanel.kMapName = "modpanel"

local networkVars = {
	modPanelId = "integer (0 to 255)"
}

function ModPanel:OnCreate()
    Entity.OnCreate(self)
	InitMixin(self, UsableMixin)

	self.size = {0.66 / 2, 1.2 / 2}
	self.offset = Vector(0, 1, 0)

	self.indices = {
		0, 1, 2,
		0, 2, 3,
	}

	self.vertices = {
		-1,-1,0,
		1,-1,0,
		1,1,0,
		-1,1,0,
	}

	self.tex_coords = {
		0,1,
		1,1,
		1,0,
		0,0,
	}

	self.modPanelId = 0
end

function ModPanel:OnInitialized()
	self:ReInitialize()
end

function ModPanel:SetOrigin(origin)
	Entity.SetOrigin(self, origin)
	self:ReInitialize()
end

if Client then
	function ModPanel:ReInitialize()
		if type(self.offset) == "table" then
			self.offset = Vector(self.offset[1], self.offset[2], self.offset[3])
		end

		if self.panel then
			Client.DestroyRenderDynamicMesh(self.panel)
		end

		if self.modPanelId ~= 0 then
			for k, v in pairs(kModPanels[self.modPanelId]) do
				self[k] = v
			end
		end

		if self.OnReInitialize then
			self:OnReInitialize()
		end

		self.panel = Client.CreateRenderDynamicMesh(RenderScene.Zone_Default)
		self.panel:SetMaterial(self.material)

		local vertices

		if self.size then
			vertices = {}
			for i = 1, #self.vertices, 3 do
				vertices[i]   = self.vertices[i]   * self.size[1]
				vertices[i+1] = self.vertices[i+1] * self.size[2]
				vertices[i+2] = 0
			end
		else
			vertices = self.vertices
		end

		local coords = Coords()
		coords.origin = self:GetOrigin() + self.offset
		self.panel:SetIndices(self.indices, #self.indices)
		self.panel:SetVertices(vertices, #vertices)
		self.panel:SetTexCoords(self.tex_coords, #self.tex_coords)
		self.panel:SetCoords(coords)
		self.panel:SetIsVisible(true)

		if self.OnPostReInitialize then
			self:OnPostReInitialize()
		end

		self.lastUpdate = Shared.GetTime()
	end

	local up = Vector(0, 1, 0)
	local kRecreationInterval = 5
	function ModPanel:OnUpdateRender()
		if Shared.GetTime() - self.lastUpdate > kRecreationInterval then
			self:ReInitialize()
		end
		local player = Client.GetLocalPlayer()
		local coords = Coords.GetLookAt(self:GetOrigin() + self.offset, player:GetEyePos(), up)
		self.panel:SetCoords(coords)
	end
else
	function ModPanel:ReInitialize()
		if type(self.offset) == "table" then
			self.offset = Vector(self.offset[1], self.offset[2], self.offset[3])
		end
		if self.modPanelId ~= 0 then
			for k, v in pairs(kModPanels[self.modPanelId]) do
				self[k] = v
			end
		end
	end
end

function ModPanel:GetPanelOrigin()
	return self:GetOrigin() + self.offset
end

function ModPanel:SetModPanelId(id)
	self.modPanelId = id
	self:ReInitialize()
end

function ModPanel:GetUseAllowedBeforeGameStart()
	return true
end

function ModPanel:GetIsMapEntity()
	return true
end

function ModPanel:OnDestroy()
	if Client and self.panel then
		Client.DestroyRenderDynamicMesh(self.panel)
	end
end

function ModPanel:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self.url ~= nil
end

function ModPanel:GetUsablePoints()
	return {self:GetPanelOrigin()}
end

if Client then
    function ModPanel:OnUse()
		Client.ShowWebpage(self.url)
    end
end
Shared.LinkClassToMap("ModPanel", ModPanel.kMapName, networkVars, true)

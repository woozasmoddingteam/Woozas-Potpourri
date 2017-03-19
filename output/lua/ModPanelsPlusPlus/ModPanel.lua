class 'ModPanel' (Entity)

ModPanel.kMapName = "modpanel"

local networkVars = {
	modPanelId = "integer (0 to 255)"
}

function ModPanel:OnCreate()
    Entity.OnCreate(self)
	InitMixin(self, UsableMixin)

	self.size = Vector(1.2, 0.66, 0)
	self.color = Color(1, 1, 1, 1)
	self.offset = Vector(0, 1.7, 0)
	self.mass = 1

	self.modPanelId = 0
	self:SetRelevancyDistance(20)
end

function ModPanel:OnInitialized()
	self:ReInitialize()
end

function ModPanel:SetOrigin(origin)
	Entity.SetOrigin(self, origin)

	if Client and self.panel then
		self.panel:SetOrigin(origin + self.offset)
	end

	if self.physicsBody then
		local coords = self.physicsBody:GetCoords()
		coords.origin = origin + self.offset
		self.physicsBody:SetCoords(coords)
	end
end

function ModPanel:InitializePhysicsBody()
	if self.physicsBody then
		Shared.DestroyCollisionObject(self.physicsBody)
	end
	local coords = Coords()
	coords.origin = self:GetOrigin() + self.offset
	self.physicsBody = Shared.CreatePhysicsBoxBody(false, Vector(0.1, self.size.y, 0.1), self.mass, coords)
end

if Client then
	function ModPanel:ReInitialize()
		if self.panel then
			Client.DestroyRenderBillboard(self.panel)
		end

		if self.modPanelId ~= 0 then
			for k, v in pairs(kModPanels[self.modPanelId]) do
				self[k] = v
			end
		end

		if self.OnReInitialize then
			self:OnReInitialize()
		end

		self.panel = Client.CreateRenderBillboard()
        self.panel:SetMaterial(self.material)
		self.panel:SetOrigin(self:GetOrigin() + self.offset)
		self.panel:SetSize(self.size)
		self.panel:SetColor(self.color)

		self:InitializePhysicsBody()

		if self.OnPostReInitialize then
			self:OnPostReInitialize()
		end
	end
else
	function ModPanel:ReInitialize()
		self:InitializePhysicsBody()
	end
end

function ModPanel:SetModPanelId(id)
	self.modPanelId = id
end

function ModPanel:GetUseAllowedBeforeGameStart()
	return true
end

function ModPanel:GetIsMapEntity()
	return true
end

function ModPanel:OnDestroy()
	if Client and self.panel then
		Client.DestroyRenderBillboard(self.panel)
	end

	if self.physicsBody then
		Shared.DestroyCollisionObject(self.physicsBody)
	end
end

function ModPanel:GetCanBeUsed(player, useSuccessTable)
    useSuccessTable.useSuccess = self.url ~= nil
end

function ModPanel:GetUsablePoints()
	return {self:GetOrigin() + self.offset}
end

if Client then
    function ModPanel:OnUse()
		Client.ShowWebpage(self.url)
    end
end
Shared.LinkClassToMap("ModPanel", ModPanel.kMapName, networkVars, true)

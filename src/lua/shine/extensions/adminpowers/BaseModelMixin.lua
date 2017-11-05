if Server then
	local old = BaseModelMixin.__initmixin
	function BaseModelMixin:__initmixin()
		old(self)
		self.scale = Vector(1, 1, 1)
	end
end

function BaseModelMixin:UpdateModelCoords()
    local modelCoords = nil
    local physicsModel = self.physicsModel
    if physicsModel and physicsType == PhysicsType.Dynamic then
	modelCoords = physicsModel:GetCoords()
    else
	modelCoords = self:GetCoords()
    end

    local OnAdjustModelCoords = self.OnAdjustModelCoords
    if OnAdjustModelCoords then
	modelCoords = OnAdjustModelCoords(self, modelCoords)
    end

	self:ModifyModelCoords(modelCoords)

	self._modelCoords = modelCoords
end

function BaseModelMixin:ModifyModelCoords(c)
	c.xAxis = c.xAxis * self.scale.x
	c.yAxis = c.yAxis * self.scale.y
	c.zAxis = c.zAxis * self.scale.z
end


BaseModelMixin.networkVars.scale = "vector (0.1 to 10 by 0.1 [], 0.1 to 10 by 0.1 [], 0.1 to 10 by 0.1 [])"
BaseModelMixin.optionalCallbacks.UpdateModelCoords = "Modify the passed in coords and return nothing."

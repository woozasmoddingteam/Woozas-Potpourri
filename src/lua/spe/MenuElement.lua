
local function new(self, bottomPos, isPercentage, time, animateFunc, animName, callBack)

	local positionOffset = 0

	if self.verticalAlign == GUIItem.Bottom then

		positionOffset = 0

	elseif self.verticalAlign == GUIItem.Center then

		if self.parent then
			positionOffset = self.parent:GetAvailableSpace().y / 2
		else
			positionOffset = Client.GetScreenHeight() / 2
		end

	else

		if self.parent then
			positionOffset = self.parent:GetAvailableSpace().y / self:GetScaleDivider()
		else
			positionOffset = Client.GetScreenHeight() / self:GetScaleDivider()
		end

	end

	if isPercentage then

		if self.parent then
			bottomPos = bottomPos * self.parent:GetAvailableSpace().y / self:GetScaleDivider()
		else
			bottomPos = bottomPos* Client.GetScreenHeight() / self:GetScaleDivider()
		end

	end

	local pos = self.background:GetPosition()
	pos.y = positionOffset - bottomPos - self.background:GetSize().y


	self:SetBackgroundPosition(pos, true, time, animateFunc, animName, callBack)

end

debug.replacemethod("MenuElement", "SetBottomOffset", new)

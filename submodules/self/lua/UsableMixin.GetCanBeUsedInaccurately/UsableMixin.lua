UsableMixin.optionalCallbacks.GetCanBeUsedInaccurately = "Called when something uses this entity"

function UsableMixin:GetCanBeUsedInaccurately(player, t)
	t.b = true;
end

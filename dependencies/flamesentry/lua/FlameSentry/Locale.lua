if not Locale then return end

local old = Locale.ResolveString
function Locale.ResolveString(text)
	if text == "FLAME_SENTRY_TURRET" then
		return "Flame Sentry"
	else
		return old(text)
	end
end

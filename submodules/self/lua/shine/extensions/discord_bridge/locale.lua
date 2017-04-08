local language = ...
local format = string.format
local lower  = string.lower

local strings   = {
	core = assert(Shine.LoadJSONFile ("locale/shine/core/" .. language .. ".json"))
}

local function GetLocalisedString(source, key)
	source = source and lower(source) or "core"
	if strings[source] == nil then
		strings[source] = Shine.LoadJSONFile(format("locale/shine/extensions/%s/" .. language .. ".json", source))
	end
	return strings[source] and strings[source][key] or key
end

return {
	GetLocalisedString = GetLocalisedString
}

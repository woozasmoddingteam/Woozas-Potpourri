local function getLocal(f, n)
	local index = 1
	while assert(debug.getupvalue(f, index)) ~= n do
		index = index + 1
	end
	local n, v = debug.getupvalue(f, index) -- This n is the same as the previous n
	return v
end

local function setLocal(f, n, v)
	local index = 1
	while assert(debug.getupvalue(f, index)) ~= n do
		index = index + 1
	end
	debug.setupvalue(f, index, v)
end

local defaults = getLocal(GetDefaultInputValue, "defaults")
table.insert(defaults, {"LocalVoiceChat", "None"})
table.insert(defaults, {"LocalVoiceChatTeam", "None"})

local globalControlBindings = getLocal(BindingsUI_GetBindingsData, "globalControlBindings")
table.insert(globalControlBindings, "LocalVoiceChat")
table.insert(globalControlBindings, "input")
table.insert(globalControlBindings, "Proximity Communication (can be heard by enemy)")
table.insert(globalControlBindings, "None")

table.insert(globalControlBindings, "LocalVoiceChatTeam")
table.insert(globalControlBindings, "input")
table.insert(globalControlBindings, "Proximity Communication (can be heard by team only)")
table.insert(globalControlBindings, "None")

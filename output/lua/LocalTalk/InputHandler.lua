local function getLocal(f, n)
	local index = 1
	while assert(debug.getupvalue(f, index)) ~= n do
		index = index + 1
	end
	local n, v = debug.getupvalue(f, index) -- This n is the same as the previous n
	return v
end

local _keyBinding = getLocal(Input_SyncInputOptions, "_keyBinding")
_keyBinding.LocalVoiceChat = InputKey.None
_keyBinding.LocalVoiceChatTeam = InputKey.None

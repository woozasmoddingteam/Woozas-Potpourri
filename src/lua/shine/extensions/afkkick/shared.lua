local Plugin = {
	NotifyPrefixColour = {255, 50, 0},
	Version = "1.0",
	DefaultState = true,
	AFKTimeWarn = 150,
	AFKTimeKick = 300,
}

function Plugin:SetupDataTable()
	self:AddNetworkMessage("Kick", {}, "Server")
end

Shine:RegisterExtension("afkkick", Plugin)

if Client then
	Event.Hook("SendKeyEvent", function(key, down, amount, repeated)
		if not repeated then
			Plugin.last_activity = Shared.GetTime()
		end
	end)
end

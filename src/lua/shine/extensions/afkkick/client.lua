local Plugin = Plugin

function Plugin:Initialise()
	self.Enabled = true
	return true
end

local warning = string.format("You have been AFK for %i seconds, you will be kicked after %i!", Plugin.AFKTimeWarn, Plugin.AFKTimeKick)
function Plugin:Think()
	local now = Shared.GetTime()
	if Client.GetLocalPlayer():isa "Spectator" then
		self.last_activity = now
	elseif GetGameInfoEntity():GetNumPlayersTotal() == 50 then
		local last = self.last_activity
		if now - last > 150 then
			-- Warn
			Shared.ConsoleCommand "rr"
			local c = self.NotifyPrefixColour
			Shine.AddChatText(c[1], c[2], c[3], "[AFKKick]", 1, 1, 1, warning);
		elseif now - last > 300 then
			-- Kick
			self:SendNetworkMessage("Kick", {}, true)
		end
	end
end

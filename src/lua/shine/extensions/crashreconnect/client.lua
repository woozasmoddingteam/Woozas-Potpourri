local Shine = Shine

local Plugin = Plugin
Plugin.HasConfig = true
Plugin.ConfigName = "CrashReconnect.json"
Plugin.DefaultConfig = {
	Timeout = 10
}
Plugin.CheckConfig = true
Plugin.CheckConfigTypes = true

function Plugin:Initialise()
	self:CreateTimer("ConnectionProblems", 2, -1, function() self:ConnectionProblems() end)
	self:CreateTimer("ContinuousConnectionProblems", 0, -1, function() self:ContinuousConnectionProblems() end)

	self:PauseTimer  "ContinuousConnectionProblems" -- Disabled by default

	self.Enabled = true
	return true
end

function Plugin:ContinuousConnectionProblems()
	if not Client.GetConnectionProblems() then
		Shared.Message "No problems!"
		self:PauseTimer  "ContinuousConnectionProblems"
		self:ResumeTimer "ConnectionProblems"
	elseif Shared.GetTime() - self.problemStart >= self.Config.Timeout then
		-- TODO: Make this a callback for an HTTP request
		-- That way we will not reconnect, if we have lost internet connection.
		(function()
			Shared.Message "Reconnecting!"
			Shared.ConsoleCommand "retry"
		end)()
	end
end

function Plugin:ConnectionProblems()
	if Client.GetConnectionProblems() then
		Shared.Message "ConnectionProblems()"
		self.problemStart = Shared.GetTime()
		self:ResumeTimer "ContinuousConnectionProblems"
		self:PauseTimer "ConnectionProblems"
	end
end

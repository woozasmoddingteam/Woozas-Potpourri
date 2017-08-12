local Plugin = Plugin
local Shine = Shine

function Plugin:Initialise()
	self:CreateTimer("ConnectionProblems", 2, -1, function() self:ConnectionProblems() end)
	self:CreateTimer("ContinuousConnectionProblems", 0, -1, function() self:ContinuousConnectionProblems() end)

	self:PauseTimer  "ContinuousConnectionProblems" -- Disabled by default

	self.Enabled = false
	return false
end

function Plugin:ContinuousConnectionProblems()
	if not Client.GetConnectionProblems() then
		Shared.Message "No problems!)"
		self:PauseTimer  "ContinuousConnectionProblems"
		self:ResumeTimer "ConnectionProblems"
	elseif Shared.GetTime() - self.problemStart >= 5 then
		Shared.Message "Reconnecting!"
		Shared.ConsoleCommand "retry"
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

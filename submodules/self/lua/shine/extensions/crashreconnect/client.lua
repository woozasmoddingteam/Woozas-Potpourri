local Plugin = Plugin

function Plugin:Initialise()
	self:CreateTimer("ConnectionProblems", 2, -1, function() self:ConnectionProblems() end)
	self:CreateTimer("ContinuousConnectionProblems", 0, -1, function() self:ContinuousConnectionProblems() end)

	self:PauseTimer  "ContinuousConnectionProblems" -- Disabled by default

	self.Enabled = true
	return true
end

function Plugin:ContinuousConnectionProblems()
	if not (Client.GetConnectionProblems() and Client.GetConnectedServerPerformanceScore() == -99) then
		self:PauseTimer  "ContinuousConnectionProblems"
		self:ResumeTimer "ConnectionProblems"
	elseif Shared.GetTime() - self.problemStart >= 5 then
		Shared.ConsoleCommand "retry"
	end
end

function Plugin:ConnectionProblems()
	if Client.GetConnectionProblems() and Client.GetConnectedServerPerformanceScore() == -99 then
		self.problemStart = Shared.GetTime()
		self:ResumeTimer "ContinuousConnectionProblems"
		self:PauseTimer "ConnectionProblems"
	end
end

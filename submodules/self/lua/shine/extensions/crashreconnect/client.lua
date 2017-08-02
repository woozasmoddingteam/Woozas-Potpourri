local Plugin = Plugin

local usableConnectionAt = 0
local queriedServerStatusAt = 0

function Plugin:Initialise()
	self:CreateTimer("ConnectionProblems", 2, -1, function() self:ConnectionProblems() end)
	self:CreateTimer("ContinousConnectionProblems", 0, -1, function() self:ContinousConnectionProblems() end)

	self:PauseTimer  "ContinuousConnectionProblems" -- Disabled by default

	self.Enabled = true
	return true
end

function Plugin:ContinuousConnectionProblems()
	if not Client.GetConnectionProblems() then
		self:PauseTimer  "ContinuousConnectionProblems"
		self:ResumeTimer "ConnectionProblems"
	elseif Shared.GetTime() - self.problemStart >= 5 then
		Shared.ConsoleCommand "retry"
	end
end

function Plugin:ConnectionProblems()
	if Client.GetConnectionProblems() then
		self.problemStart = Shared.GetTime()
		self:ResumeTimer "ContinuousConnectionProblems"
		self:PauseTimer "ConnectionProblems"
	end
end

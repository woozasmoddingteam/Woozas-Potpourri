local Plugin = Plugin

function Plugin:Initialise()
  self.BaseClass.Initialise(self)

	self:CreateCommands()

	self.Enabled = true

	return true
end

function Plugin:CreateCommands()
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
end
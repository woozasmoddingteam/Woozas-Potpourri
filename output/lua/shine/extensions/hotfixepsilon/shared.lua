--[[
-- This is a hotfix plugin I'll use to realease hotfixes for ns2.
 ]]
local Plugin = {}

--Plugin Stub
function Plugin:Initialise()
	self.Enabled = true
	return true
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup( self )
	self.Enabled = false
end

Shine:RegisterExtension( "hotfixepsilon", Plugin )
--[[
    Shine No Rookies - Shared
]]
local Shine = Shine
local Plugin = {}

Shine:RegisterExtension( "norookies", Plugin, {
	Base = "hiveteamrestriction",
	BlacklistKeys = {
		BuildBlockMessage = true
	}
} )
local Plugin = {}

local Shine = Shine
local SetupClassHook = Shine.Hook.SetupClassHook
local SetupGlobalHook = Shine.Hook.SetupGlobalHook

function Plugin:Initialise()

end

function Plugin:SetupDataTable()
end

function Plugin:NetworkUpdate( Key, Old, New )
	if Server then return end
end

Shine:RegisterExtension("entitytick", Plugin)

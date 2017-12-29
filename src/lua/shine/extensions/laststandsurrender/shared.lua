
local Shine  = Shine
local Plugin = {
	Conflicts = {
		DisableThem = {
			"votesurrender"
		}
	}
}

Shine:RegisterExtension("laststandsurrender", Plugin, {
	Base = "votesurrender"
})

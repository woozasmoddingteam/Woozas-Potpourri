local old = BuildClassToGrid
function BuildClassToGrid()
	local grid = old()
	grid.FlameSentry = grid.Sentry
	return grid
end

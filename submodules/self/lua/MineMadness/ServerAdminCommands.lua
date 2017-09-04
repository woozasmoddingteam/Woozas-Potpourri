
--[[
 * Iterates over all players sorted in alphabetically calling the passed in function.
]]
local function GetPlayerList()

    local playerList = EntityListToTable(Shared.GetEntitiesWithClassname("Player"))
    table.sort(playerList, function(p1, p2) return p1:GetName() < p2:GetName() end)
    return playerList

end
local function AllPlayers(doThis)

    return function(client)

	local playerList = GetPlayerList()
	for p = 1, #playerList do

	    local player = playerList[p]
	    doThis(player, client, p)

	end

    end

end
local function GiveCrazyMines()

    local function GetMarines(player, client)
	if player:isa("Marine") then
	    local newItem = player:GiveItem('minecrazy', nil, true)
	    if newItem and newItem.UpdateWeaponSkins then
		newItem:UpdateWeaponSkins( client )
	    end
	end
    end
    AllPlayers(GetMarines)()
end
CreateServerAdminCommand("Console_crazymines", function() GiveCrazyMines() end, "Gives 99 crazy mines to all marines")

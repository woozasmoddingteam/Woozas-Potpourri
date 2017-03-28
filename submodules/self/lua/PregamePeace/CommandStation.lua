local function getLocal(f, n)
	local index = 1;
	while assert(debug.getupvalue(f, index)) ~= n do
		index = index + 1;
	end
	local n, v = debug.getupvalue(f, index); -- This n is the same as the previous n
	return v;
end

local kLoginAttachPoint = getLocal(CommandStation.GetUsablePoints, "kLoginAttachPoint");

function CommandStation:GetUsablePoints()

	local gameinfo = GetGameInfoEntity();

	if gameinfo:GetGameStarted() then

    	local loginPoint = self:GetAttachPointOrigin(kLoginAttachPoint)
    	return { loginPoint }

	end

end

if Server then
	function CommandStation:GetIsPlayerValidForCommander(player)
	    return player ~= nil and player:isa("Marine") and (not GetGameInfoEntity():GetGameStarted() or self:GetIsPlayerInside(player)) and CommandStructure.GetIsPlayerValidForCommander(self, player)
	end
end

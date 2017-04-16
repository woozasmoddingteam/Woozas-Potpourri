local Shine = Shine
local Plugin = Plugin

local saved
local eggindices = setmetatable({}, {
	__mode = "k"
})

local function invalid(v)
	return v.x == 0 and v.y == 0 and v.z == 0
end

local function encode(egg)
	local coords = egg:GetCoords()
	local xAxis  = coords.xAxis
	local yAxis  = coords.yAxis
	local zAxis  = coords.zAxis
	local origin = coords.origin
	return {
		room = egg:GetLocationName(),
		name = egg:GetName(),
		model = egg:GetModelName(),
		coords = {
			origin.x,
			origin.y,
			origin.z,
			xAxis.x,
			xAxis.y,
			xAxis.z,
			yAxis.x,
			yAxis.y,
			yAxis.z,
			zAxis.x,
			zAxis.y,
			zAxis.z
		}
	}
end

local function new(client, name)
	local player = client:GetControllingPlayer()

	local startPoint = player:GetEyePos()
	local viewCoords = player:GetViewCoords()

	local endPoint = startPoint + viewCoords.zAxis * 100

	local t = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()))
	endPoint = t.endPoint

	local normal = t.normal

	local ent = CreateEntity("easteregg")

	local coords = Coords()

	coords.yAxis = invalid(normal) and Vector(0, 1, 0) or normal
	local direction = viewCoords.zAxis
	local x = -normal:CrossProduct(direction)
	coords.xAxis = invalid(x) and Vector(-1, 0, 0) or x
	local z = normal:CrossProduct(coords.xAxis)
	coords.zAxis = invalid(z) and Vector(0, 0, 1) or z
	coords.origin = endPoint

	ent:SetCoords(coords)
	ent:SetName(name)

	table.insert(saved, encode(ent))
	eggindices[ent] = #saved
end

local function sanitise()
	--[=[
		Clear our unused entries
	]=]
	local i = 1
	while true do
		if i > #saved then
			break
		elseif saved[i] == false then
			table.remove(saved, i)
		else
			i = i + 1
		end
	end

	Plugin:SaveConfig()
end

local function hide()
	sanitise()

	local eggs = GetEntities "EasterEgg"
	for i = 1, #eggs do
		Server.DestroyEntity(eggs[i])
	end

	Plugin:SaveConfig()
end

local function show()
	hide()

	for i = 1, #saved do
		local data = saved[i]
		local dcoords = data.coords
		local egg = CreateEntity "easteregg"
		local coords = Coords()
		coords.origin = Vector(dcoords[1], dcoords[2], dcoords[3])
		coords.xAxis  = Vector(dcoords[4], dcoords[5], dcoords[6])
		coords.yAxis  = Vector(dcoords[7], dcoords[8], dcoords[9])
		coords.zAxis  = Vector(dcoords[10], dcoords[11], dcoords[12])
		egg:SetName(data.name)
		egg:SetCoords(coords)
		egg:SetModel(data.model)
		eggindices[egg] = i
	end
end

local function reload()
	Plugin:LoadConfig()
	saved = Plugin.Config.Saved[Shared.GetMapName()]
end

function Plugin.remove(egg)
	saved[eggindices[egg]] = false
end

local function void() end

local function endEvent()
	hide()
	GetGamerules():ResetGame()
end

local function startEvent(client, cls)
	if not _G[cls] or not _G[cls].kMapName then
		Shine:NotifyError(client, "Not a class!")
		return
	end
	local base = Script.GetBaseClass(cls)
	local spawnPoints = GetBeaconPointsForTechPoint(GetEntities("TechPoint")[1]:GetId())
	local commmandstructures = GetEntities "CommandStructure"
	for i = 1, #commmandstructures do
		commmandstructures[i].OnUse = void
	end
	if base == "ClipWeapon" or base == "Weapon" then
		local idx = 1
		while true do
			local client = Server.GetClientById(idx)
			if not client then break end

			local player = client:GetControllingPlayer()

			if player then
				Log("Replacing player %s...", player)

				player = player:Replace(Marine.kMapName, kMarineTeamType, false, spawnPoints[i])
		        local wep = CreateEntity(_G[cls].kMapName, player:GetEyePos(), player:GetTeamNumber())
				local hudslot = wep:GetHUDSlot()
				local current = player:GetWeaponInHUDSlot(hudslot)
				if current:GetMapName() == wep:GetMapName() then
					Server.DestroyEntity(wep)
					player:SetActiveWeapon(current:GetMapName())
				else
					player:AddWeapon(wep, true)
				end
				player.SetActiveWeapon = void
				player.ProcessBuyAction = void
			end

			idx = idx + 1
		end
	elseif cls == "Exo" or cls == "Marine" or base == "Marine" or base == "Alien" then
		local idx = 1
		while true do
			local client = Server.GetClientById(idx)
			if not client then break end

			local player = client:GetControllingPlayer()

			if player then
				Log("Replacing player %s...", player)

				player = player:Replace(_G[cls].kMapName, base == "Alien" and kAlienTeamType or kMarineTeamType, false, spawnPoints[i])
				player.ProcessBuyAction = void
			end

			idx = idx + 1
		end
	else
		Shine:NotifyError(client, "Not a valid class for this event!")
		endEvent()
		return
	end
	show()
end

function Plugin:MapPostLoad()
	saved = self.Config.Saved[Shared.GetMapName()] or {}
	self.Config.Saved[Shared.GetMapName()] = saved

	local command

	command = self:BindCommand("sh_new_easter_egg", "NewEasterEgg", new)
	command:Help "Plants a gorge on what you're looking at."
	command:AddParam {
		Type = "string",
		Optional = true,
		TakeRestOfLine = true,
		Help = "Name of gorge",
		Default = nil
	}

	command = self:BindCommand("sh_hide_easter_eggs", "HideEasterEggs", hide)
	command:Help "Hides all eggs and saves their placements. Done automatically before map change."

	command = self:BindCommand("sh_show_easter_eggs", "ShowEasterEggs", show)
	command:Help "Hide but recreates all eggs again."

	command = self:BindCommand("sh_reload_easter_eggs", "ReloadEasterEggs", reload)
	command:Help "Reloads the configuration file. Save before you reload, because eggs created after the last save will be ignored by the reload!"

	command = self:BindCommand("sh_begin_easter", "BeginEaster", startEvent)
	command:AddParam {
		Type = "string",
		Help = "Class to use, can be weapon or player type."
	}

	command = self:BindCommand("sh_end_easter", "EndEaster", endEvent)
end

function Plugin:Initialise()
	Script.AddShutdownFunction(function()
		sanitise()
		Plugin:SaveConfig()
	end)
	self.Enabled = true
	return true
end

Plugin.Cleanup = hide

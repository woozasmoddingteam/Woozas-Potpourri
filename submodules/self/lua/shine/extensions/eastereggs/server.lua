local Shine = Shine
local Plugin = Plugin

local saved

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
end

local function hide(self)
	Log("Hiding eggs!")

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
	end
end

local function save(self)
	Plugin:SaveConfig()
	saved = Plugin.Config.Saved[Shared.GetMapName()]
end

local function reload()
	Plugin:LoadConfig()
	saved = Plugin.Config.Saved
end

local function void() end

local function startEvent(client, cls)
	if not _G[cls] or not _G[cls].kMapName then
		Shine:NotifyError(client, "Not a class!")
		return
	end
	local base = Script.GetBaseClass(cls)
	if base == "ClipWeapon" or base == "Weapon" then
		local spawnPoints = GetBeaconPointsForTechPoint(GetEntities("TechPoint")[1]:GetId())
		GetGamerules():ResetGame()
		local commmandstructures = GetEntities "CommandStructure"
		for i = 1, #commmandstructures do
			Server.DestroyEntity(commmandstructures[i])
		end
		local idx = 1
		while true do
			local player = Server.GetClientById(idx):GetControllingPlayer()
			if not player then break end

			Log("Replacing player %s...", player)

			player = player:Replace(Marine.kMapName, kMarineTeamType, false, spawnPoints[i])
			player:GiveItem(_G[cls].kMapName)
			player.SetActiveWeapon = void
			player.ProcessBuyAction = void
			show()
			return
		end
	elseif cls == "Exo" or cls == "Marine" or base == "Marine" or base == "Alien" then
		local spawnPoints = GetBeaconPointsForTechPoint(GetEntities("TechPoint")[1]:GetId())
		GetGamerules():ResetGame()
		local commmandstructures = GetEntities "CommandStructure"
		for i = 1, #commmandstructures do
			Server.DestroyEntity(commmandstructures[i])
		end
		local idx = 1
		while true do
			local player = Server.GetClientById(idx):GetControllingPlayer()
			if not player then break end

			Log("Replacing player %s...", player)

			player = player:Replace(_G[cls].kMapName, kMarineTeamType, false, spawnPoints[i])
			player.ProcessBuyAction = void
			show()
			return
		end
	else
		Shine:NotifyError(client, "Not a valid class for this event!")
		return
	end
end

local function endEvent()
	hide()
	GetGamerules():ResetGame()
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

	command = self:BindCommand("sh_save_easter_eggs", "SaveEasterEggs", save)
	command:Help "Saves the eggs to the configuration file. Done automatically at map change."

	command = self:BindCommand("sh_show_easter_eggs", "ShowEasterEggs", show)

	command = self:BindCommand("sh_reload_easter_eggs", "ReloadEasterEggs", reload)
	command:Help "Save before you reload, because eggs created after the last save will be ignored by the reload!"

	command = self:BindCommand("sh_begin_easter", "BeginEaster", startEvent)
	command:AddParam {
		Type = "string",
		Help = "Class to use, can be weapon or player type."
	}

	command = self:BindCommand("sh_end_easter", "EndEaster", endEvent)
end

function Plugin:Initialise()
	Script.AddShutdownFunction(save)
	self.Enabled = true
	return true
end

Plugin.Cleanup = hide

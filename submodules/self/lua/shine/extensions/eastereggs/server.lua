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
	Log("Location ID for %s: %s", egg:GetName(), egg.locationId)
	local coords = egg:GetCoords()
	local xAxis  = coords.xAxis
	local yAxis  = coords.yAxis
	local zAxis  = coords.zAxis
	local origin = coords.origin
	return {
		room = GetLocationForPoint(origin).name,
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
	saved = Plugin.Config.Saved[Shared.GetMapName()] or {}
	Plugin.Config.Saved[Shared.GetMapName()] = saved
end

function Plugin.remove(egg)
	saved[eggindices[egg]] = false
end

local function void() end

local oldReplace
local oldSendTeamMessage
local oldOnClientConnect
local oldGetWarmUpPlayerLimit
local oldJoinTeam

local function endEvent()
	hide()
	if not oldReplace then
		return
	end
	local idx = 1
	while true do
		local client = Server.GetClientById(idx)
		if not client then break end

		local player = client:GetControllingPlayer()

		if player then
			if player.Replace == Player.Replace then
				player.Replace = oldReplace
			end
		end

		idx = idx + 1
	end
	Player.Replace = oldReplace
	GetGamerules().JoinTeam = oldJoinTeam
	GetGamerules().OnClientConnect = oldOnClientConnect
	GetGamerules().GetWarmUpPlayerLimit = oldGetWarmUpPlayerLimit
	SendTeamMessage = oldSendTeamMessage

	oldReplace, oldSendTeamMessage, oldJoinTeam, oldOnClientConnect = nil, nil, nil, nil

	GetGamerules():ResetGame(kGameState.NotStarted)
	Shared.ConsoleCommand("sh_csay Easter has ended!")
	Plugin:DestroyTimer("advert")
end

local function advert()
	Shine:NotifyDualColour(nil, 0xB5, 0xDA, 0xAC, "[Easter Eggs]", 0xF0, 0xF0, 0xF0, ("Kill the easter eggs! %i easter eggs remaining!"):format(EasterEgg.GetCount()))
end

local function jointeam(self, player)
	return false, player
end

local function startEvent(client, cls)
	if oldReplace then
		Shine:NotifyError(client, "Easter is already in progress!")
		return
	end

	if not _G[cls] or not _G[cls].kMapName then
		Shine:NotifyError(client, "Not a class!")
		return
	end

	local base = Script.GetBaseClass(cls)
	local spawnPoints = GetBeaconPointsForTechPoint(GetEntities("TechPoint")[1]:GetId())

	local map = _G[cls].kMapName

	oldReplace = Player.Replace

	local team = kMarineTeamType

	if base == "ClipWeapon" or base == "Weapon" then
		function Player:Replace()
			self = oldReplace(self, Marine.kMapName, kMarineTeamType, false)
			self.Replace = self.Replace == oldReplace and Player.Replace or self.Replace
			local wep = CreateEntity(map, self:GetEyePos(), self:GetTeamNumber())
			local hudslot = wep:GetHUDSlot()
			local current = self:GetWeaponInHUDSlot(hudslot)
			if current and current:GetMapName() == map then
				Server.DestroyEntity(wep)
				self:SetActiveWeapon(map)
			else
				self:AddWeapon(wep, true)
			end
			self.SetActiveWeapon = void
			self.ProcessBuyAction = void
			self:SetDarwinMode(true)
			return self
		end
	elseif cls == "Exo" or cls == "Marine" or base == "Marine" or base == "Alien" then
		function Player:Replace()
			team = base == "Alien" and kAlienTeamType or kMarineTeamType
			self = oldReplace(self, map, team, false)
			self.Replace = self.Replace == oldReplace and Player.Replace or self.Replace
			self.ProcessBuyAction = void
			self:SetDarwinMode(true)
			return self
		end
	else
		Shine:NotifyError(client, "Not a valid class for this event!")
		oldReplace = nil
		return
	end

	oldSendTeamMessage = SendTeamMessage
	oldOnClientConnect = GetGamerules().OnClientConnect
	oldGetWarmUpPlayerLimit = GetGamerules().GetWarmUpPlayerLimit
	oldJoinTeam = GetGamerules().JoinTeam

	GetGamerules().JoinTeam = function(self, player, new_team)
		if new_team ~= kTeamReadyRoom then
			if player.Replace == oldReplace then
				player.Replace = Player.Replace
			end
			local _
			_, player = oldJoinTeam(self, player, team, true)
			local idx = math.random(math.ceil(#spawnPoints/2))
			player:SetOrigin(spawnPoints[idx])
		else
			--[=[ Horrible hack ]=]
			local temp = Player.Replace
			Player.Replace = oldReplace
			if player.Replace == temp then
				player.Replace = oldReplace
			end
			local _
			_, player = oldJoinTeam(self, player, new_team, true)
			Player.Replace = temp
		end
	end
	GetGamerules().OnClientConnect = function(self, client)
		local player = oldOnClientConnect(self, client)
		if player.Replace == oldReplace then
			player.Replace = Player.Replace
		end
		local idx = math.random(math.ceil(#spawnPoints/2))
		player:SetOrigin(spawnPoints[idx])
		player:Replace()
	end
	GetGamerules().GetWarmUpPlayerLimit = function()
		return 2^50
	end
	SendTeamMessage = void

	GetGamerules():SetGameState(kGameState.NotStarted)

	local commandstructures = GetEntities "CommandStructure"
	for i = 1, #commandstructures do
		commandstructures[i].OnUse = void
	end

	local idx = 1
	while true do
		local client = Server.GetClientById(idx)
		if not client then break end

		local player = client:GetControllingPlayer()

		if player then
			player:SetOrigin(spawnPoints[idx])
			if player.Replace == oldReplace then
				player.Replace = Player.Replace
			end
			player:Replace()
		end

		idx = idx + 1
	end

	show()
	Shared.ConsoleCommand("sh_csay Easter has begun! Find all easter eggs and kill them!")
	advert()
	Plugin:CreateTimer("advert", 60, -1, advert)
end

function Plugin:Initialise()
	local map = Shared.GetMapName()
	if #map ~= 0 then
		saved = self.Config.Saved[map] or {}
		self.Config.Saved[map] = saved
	end

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

	Script.AddShutdownFunction(function()
		sanitise()
	end)

	self.Enabled = true
	return true
end

function Plugin:MapPostLoad()
	saved = self.Config.Saved[Shared.GetMapName()] or {}
	self.Config.Saved[Shared.GetMapName()] = saved
end

Plugin.Cleanup = endEvent

local Shine = Shine
local Plugin = Plugin
Plugin.HasConfig = true
Plugin.ConfigName = "EasterEggs.json"
Plugin.DefaultConfig = {
	Limit   = 2,
	Winners = {},
	Class   = false,
	Weapons = false,
	Saved   = {}
}

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
	local location = GetLocationForPoint(origin)
	return {
		room = location and location.name,
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

local function advert()
	Shine:NotifyDualColour(nil, 0xB5, 0xDA, 0xAC, "[Easter Eggs]", 0xF0, 0xF0, 0xF0, ("Kill the easter eggs! %i easter eggs remaining! Look at the mod panel in ready room for more information."):format(EasterEgg.GetCount()))
end

function Plugin:PostLoadScript(script)
	local class = self.Config.Class
	if not class then return end
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

	command = self:BindCommand("sh_save_easter_eggs", "ShowEasterEggs", show)
	command:Help "Hide but recreates all eggs again."

	command = self:BindCommand("sh_reload_easter_eggs", "ReloadEasterEggs", reload)
	command:Help "Reloads the configuration file. Save before you reload, because eggs created after the last save will be ignored by the reload!"

	Script.AddShutdownFunction(function()
		sanitise()
	end)

	Plugin:CreateTimer("advert", 60, -1, advert)
	self.Enabled = true
	return true
end

function Plugin:MapPostLoad()
	saved = self.Config.Saved[Shared.GetMapName()] or {}
	self.Config.Saved[Shared.GetMapName()] = saved
end

local function ReplaceMethodInDerivedClasses(cls, method, original)

	local classes = Script.GetDerivedClasses(cls)

	for _, subcls in ipairs(classes) do
		if _G[subcls][method] == original then
			_G[subcls][method] = _G[cls][method]
			ReplaceMethodInDerivedClasses(subcls, method, original)
		end
	end
end

function Plugin:MapPreLoad()
	local class = self.Config.Class
	local weapons = self.Config.Weapons

	if not class then return end
	local tbl = _G[class]

	--[=[I am a monster]=]
	if not tbl or not tbl.kMapName then return Log("ERROR: eastereggs: %s is not a valid class!", class) end

	local old = Player.OnCreate
	function Player:OnCreate()
		old(self)
		self.darwinMode = true
	end
	ReplaceMethodInDerivedClasses("Player", "OnCreate", old)
	local old = Player.UseTarget
	function Player:UseTarget(ent, time)
		if not ent:isa "CommandStructure" then
			return old(self, ent, time)
		else
			return false
		end
	end
	ReplaceMethodInDerivedClasses("Player", "UseTarget", old)
	local old = Player.SetDarwinMode
	Player.SetDarwinMode = void
	ReplaceMethodInDerivedClasses("Player", "SetDarwinMode", old)
	local old = Player.ProcessBuyAction
	Player.ProcessBuyAction = void
	ReplaceMethodInDerivedClasses("Player", "ProcessBuyAction", old)
	local old = Player.Buy
	Player.Buy = void
	ReplaceMethodInDerivedClasses("Player", "Buy", old)
	local old = Marine.Drop
	Marine.Drop = void
	ReplaceMethodInDerivedClasses("Marine", "Drop", old)
	local old = Alien.ProcessBuyAction
	Alien.ProcessBuyAction = void
	ReplaceMethodInDerivedClasses("Alien", "ProcessBuyAction", old)
	function NS2Gamerules:GetWarmUpPlayerLimit()
		return 2^52
	end
	local team = Script.GetBaseClass(class) == "Alien" and 2 or 1
	local old = NS2Gamerules.JoinTeam
	function NS2Gamerules:JoinTeam(player, new_team)
		if new_team == kTeamReadyRoom then
			return old(self, player, kTeamReadyRoom, true, true)
		else
			return old(self, player, team, true, true)
		end
	end
	local team_class = team == 2 and AlienTeam or MarineTeam
	local old = team_class.Initialize
	team_class.Initialize = function(self, name, number)
		old(self, name, number)
		self.respawnEntity = _G[class].kMapName
	end
	SendTeamMessage = void

	if not weapons then return end

	local old = tbl.InitWeapons
	tbl.InitWeapons = function(self)
		for i = 1, #weapons do
			self:GiveItem(_G[weapons[i]].kMapName)
		end
	end
end

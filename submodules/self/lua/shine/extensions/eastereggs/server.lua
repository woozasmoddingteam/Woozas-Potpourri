local Shine = Shine
local Plugin = Plugin

local function invalid(v)
	return v.x == 0 and v.y == 0 and v.z == 0
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
end

local function show()
	local eggs = Plugin.Config.Saved[Shared.GetMapName()]

	for i = 1, #eggs do
		local data = eggs[i]
		local dcoords = data.coords
		local egg = CreateEntity("easteregg")
		local coords = Coords()
		coords.origin = Vector(dcoords[1], dcoords[2], dcoords[3])
		coords.xAxis  = Vector(dcoords[4], dcoords[5], dcoords[6])
		coords.yAxis  = Vector(dcoords[7], dcoords[8], dcoords[9])
		coords.zAxis  = Vector(dcoords[10], dcoords[11], dcoords[12])
		egg:SetName(data.name)
		egg:SetCoords(coords)
		egg:SetModel(data.model)
	end

	Plugin.Config.Saved[Shared.GetMapName()] = {}
end

local function hide()
	local eggs = GetEntities "EasterEgg"

	local saved = {}
	for i = 1, #eggs do
		local egg = eggs[i]
		local coords = egg:GetCoords()
		local xAxis  = coords.xAxis
		local yAxis  = coords.yAxis
		local zAxis  = coords.zAxis
		local origin = coords.origin
		saved[i] = {
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
		Server.DestroyEntity(egg)
	end

	table.copy(saved, Plugin.Config.Saved[Shared.GetMapName()], true)

	Plugin:SaveConfig()
end

function Plugin:Initialise()
	config = self.Config

	local command

	command = self:BindCommand("sh_new_easter_egg", "NewEasterEgg", new)
	command:Help("Plants a gorge on what you're looking at.")
	command:AddParam {
		Type = "string",
		Optional = true,
		TakeRestOfLine = true,
		Help = "Name of gorge",
		Default = nil
	}

	command = self:BindCommand("sh_hide_easter_eggs", "HideEasterEggs", hide)

	command = self:BindCommand("sh_show_easter_eggs", {"ShowEasterEggs", "SaveEasterEggs"}, show)

	self.Enabled = true
	return true
end

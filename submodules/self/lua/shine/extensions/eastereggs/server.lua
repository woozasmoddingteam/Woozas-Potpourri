local Shine = Shine

local count = 0

local function new(client, name)
	local player = client:GetControllingPlayer()

	local startPoint = player:GetEyePos()
	local viewCoords = player:GetViewCoords()

	local endPoint = startPoint + viewCoords.zAxis * max

	local endPoint = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon())).endPoint

	local ent = CreateEntity("easteregg")

	local coords = Coords()
	coords.yAxis = t.normal
	local direction = player:GetViewCoords().zAxis
	coords.xAxis = -t.normal:CrossProduct(direction)
	coords.zAxis = coords.yAxis:CrossProduct(coords.xAxis)

	ent:SetCoords(coords)
	ent:SetName(name)

	count = count + 1
end

local function hide()
	local eggs = GetEntities "EasterEgg"

	local saved = {}
	for i = 1, #eggs do
		local egg = eggs[i]
		local coords = egg:GetCoords()
		local xAxis = coords.xAxis
		local yAxis = coords.yAxis
		local zAxis = coords.zAxis
		saved[i] = {
			name = egg:GetName(),
			model = egg:GetModelName(),
			coords = {
				origin,
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

	Plugin.Config.Saved[Shared.GetMapName()] = saved

	Plugin:SaveConfig()

	count = 0
end

local function show()
	hide()
	local eggs = Plugin.Config.Saved[Shared.GetMapName()]

	for i = 1, #eggs do
		local data = eggs[i]
		local dcoords = data.coords
		local egg = CreateEntity("EasterEgg")
		egg:SetName(data.name)
		local coords = Coords()
		coords.origin = dcoords[1]
		coords.xAxis = Vector(dcoords[2], dcoords[3], dcoords[4])
		coords.yAxis = Vector(dcoords[5], dcoords[6], dcoords[7])
		coords.zAxis = Vector(dcoords[8], dcoords[9], dcoords[10])
		egg:SetCoords(coords)
	end

	count = #eggs
end

local handler = Shine.BuildErrorHandler("TEST")
handler()

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

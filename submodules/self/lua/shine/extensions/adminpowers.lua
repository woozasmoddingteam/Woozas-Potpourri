local Shine = Shine
local Plugin = {
	Version = "1.0",
	NS2Only = false
}

local function trace(client, max)
	max = max or 100

	local player = client:GetControllingPlayer()

	local startPoint = player:GetEyePos()
	local viewCoords = player:GetViewCoords()

	local endPoint = startPoint + viewCoords.zAxis * max

	return Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()))
end

local function changeAngles(client, prop, amount)
	local ent = trace(client).entity

	if not ent then return end

	local angles = ent:GetAngles()

	angles[prop] = (angles[prop] + (amount * math.pi)) % (2*math.pi)

	ent:SetAngles(angles)
end

local function increaseYaw(client, amount)
	changeAngles(client, "yaw", amount)
end

local function increaseRoll(client, amount)
	changeAngles(client, "roll", amount)
end

local function increasePitch(client, amount)
	changeAngles(client, "pitch", amount)
end

local function pushRelative(client, amount)
	local t = trace(client)
	local endPoint = t.endPoint
	local ent = t.entity

	if not ent then return end

	local origin = ent:GetOrigin()
	ent:SetOrigin((endPoint - startPoint) * amount + startPoint + origin - endPoint)
end

local function pushAbsolute(client, amount)
	local t = trace(client)
	local endPoint = t.endPoint
	local ent = t.entity

	if not ent then return end

	local origin = ent:GetOrigin()
	local hoffset = origin - endPoint
	local offset = endPoint - startPoint
	local dir = Vector(offset)
	dir:Normalize()
	offset = offset + dir * amount
	ent:SetOrigin(offset + startPoint + hoffset)
end


local function flash(client, amount)
	local player = client:GetControllingPlayer()

	local viewCoords = player:GetViewCoords()

	player:PerformMovement(viewCoords.zAxis * amount, 3)
end

function Plugin:Initialise()
	local command
	command = self:BindCommand("sh_increase_yaw", "IncreaseYaw", increaseYaw, false, true)
	command:AddParam {
		Type = "number"
	}

	command = self:BindCommand("sh_increase_roll", "IncreaseRoll", increaseRoll, false, true)
	command:AddParam {
		Type = "number"
	}

	command = self:BindCommand("sh_increase_pitch", "IncreasePitch", increasePitch, false, true)
	command:AddParam {
		Type = "number"
	}

	command = self:BindCommand("sh_flash", "Flash", flash, false, true)
	command:AddParam {
		Type = "number",
		Default = 10
	}

	self.Enabled = true
	return true
end

Shine:RegisterExtension("adminpowers", Plugin)

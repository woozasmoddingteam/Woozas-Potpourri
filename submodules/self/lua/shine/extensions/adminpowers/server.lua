local Shine = Shine
local Plugin = Plugin

local function invalid(client, ent)
	if not ent then
		Shine:NotifyError(client, "Not a valid target!")
		return true
	end
end

local function trace(client, max)
	max = max or 100

	local player = client:GetControllingPlayer()

	local startPoint = player:GetEyePos()
	local viewCoords = player:GetViewCoords()

	local endPoint = startPoint + viewCoords.zAxis * max

	local t = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()))
	return t, player, startPoint
end

local function changeAngles(client, prop, amount)
	local ent = trace(client).entity

	if invalid(client, ent) then
		return
	end

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

local function scale(client, x, y, z)
	local ent = trace(client).entity

	if invalid(client, ent) then
		return
	end

	ent.scale.x = x
	ent.scale.y = y
	ent.scale.z = z
end

local function pushRelative(client, amount)
	local t, _, startPoint = trace(client)
	local endPoint = t.endPoint
	local ent = t.entity

	if invalid(client, ent) then
		return
	end

	local origin = ent:GetOrigin()
	ent:SetOrigin((endPoint - startPoint) * amount + startPoint + origin - endPoint)
end

local function pushAbsolute(client, amount)
	local t, _, startPoint = trace(client)
	local endPoint = t.endPoint
	local ent = t.entity

	if invalid(client, ent) then
		return
	end

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

	command = self:BindCommand("sh_push_rel", "PushRelative", pushRelative, false, true)
	command:AddParam {
		Type = "number"
	}

	command = self:BindCommand("sh_push_abs", "PushAbsolute", pushAbsolute, false, true)
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

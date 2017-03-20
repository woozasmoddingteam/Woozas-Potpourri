
Script.Load("lua/ModPanelsPlusPlus/ModPanel.lua")

if Server then

	local function hasDistance(origin, min, max, points, count)
		local nearbies = 0
		for i = 1, #points do
			local dist = points[i]:GetOrigin():GetDistanceTo(origin)
			if dist > min and dist < max then
				nearbies = nearbies + 1
				if nearbies >= count then
					return true
				end
			end
		end
		return false
	end

	local function makeBody(dynamicity, extents, coords, bodies)
		local body = Shared.CreatePhysicsBoxBody(dynamicity, extents, 1, coords)
		table.insert(bodies, body)
		body:SetGravityEnabled(false)
		body:SetLinearDamping(0)
		body:SetTriggerEnabled(false)
		body:SetCollisionEnabled(true)
		return body
	end

	local mod_panels_spawned = false
	function InitializeModPanels()
		assert(not mod_panels_spawned, "Mod Panels have already been spawned!")

		Log "Initializing mod panels..."

		local spawnPoints = Server.readyRoomSpawnList

		local bodies = {}

		local teamjoins = GetEntities("TeamJoin")
		for i = 1, #teamjoins do
			local body = makeBody(false, Vector(3, 2, 0.5), teamjoins[i]:GetCoords(), bodies)
		end

		local config = LoadConfigFile("ModPanels.json", {})
		local configChanged = false

		for index, values in ipairs(kModPanels) do

			local name = values.name

			if config[name] == nil then

				config[name] = true
				configChanged = true

			end

			if config[name] then

				local spawnPoint = spawnPoints[math.random(#spawnPoints)]:GetOrigin()

				local modPanel = CreateEntity(ModPanel.kMapName, spawnPoint)

				modPanel:SetModPanelId(index)

				local extents = modPanel.size and Vector(modPanel.size[1], modPanel.size[2], modPanel.size[1]) or Vector(0.5, 0.6, 0.5)
				local coords = modPanel:GetCoords()
				coords.origin = coords.origin + modPanel.offset
				local body = makeBody(true, extents, coords, bodies)

				-- Move it around until it has moved succesfully or tried too many times
				local count = 0
				local trace
				repeat
					trace = body:Move(Vector((math.random() - 0.5) * 5, 0, (math.random() - 0.5) * 5), CollisionRep.Default, CollisionRep.Default, PhysicsMask.Movement)
					count = count + 1
					if count > 50 then
						Log "WARNING: Over 50 tries for mod panel placement!"
						break
					end
				until not trace.entity and hasDistance(trace.endPoint, 0.5, 10, spawnPoints, math.ceil(#spawnPoints/10))

				modPanel:SetOrigin(trace.endPoint - modPanel.offset)

				Log("Mod Panel created at %s", modPanel:GetOrigin())

			end

		end

		for i = 1, #bodies do
			Shared.DestroyCollisionObject(bodies[i])
		end

		if configChanged then
			SaveConfigFile("ModPanels.json", config, true)
		end
	end

else
	function InitializeModPanels()
		error "Only callable from Server VM!"
	end
end

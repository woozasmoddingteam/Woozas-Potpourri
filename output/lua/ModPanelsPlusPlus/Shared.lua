
Script.Load("lua/ModPanelsPlusPlus/ModPanel.lua")

if Server then

	local function random()
		local v = (math.random() + 0.5) / (1+0.5)
		v = math.random(1, 2) == 1 and -v or v
		return v
	end

	local function randomXZvector()
		return Vector(random(), 0, random()) * 1.5
	end

	local function initBody(body)
		body:SetGravityEnabled(false)
		body:SetLinearDamping(0)
		body:SetCollisionEnabled(true)
		body:SetTriggerEnabled(false)
	end

	local mod_panels_spawned = false
	function InitializeModPanels()
		assert(not mod_panels_spawned, "Mod Panels have already been spawned!")

		Log "Initializing mod panels..."

		local spawnPoints = Server.readyRoomSpawnList

		local teamjoins = GetEntities("TeamJoin")
		local teamjoinbodies = {}
		for i = 1, #teamjoins do
			teamjoinbodies[i] = Shared.CreatePhysicsBoxBody(false, Vector(3, 2, 2), 1, teamjoins[i]:GetCoords())
			initBody(teamjoinbodies[i])
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

				local modPanel = CreateEntity(
					ModPanel.kMapName,
					spawnPoint
				)

				modPanel:SetModPanelId(index)
				modPanel:ReInitialize()

				local radius = modPanel.size and math.max(modPanel.size[1], modPanel.size[2]) or 1
				local coords = Coords()
				coords.origin = spawnPoint + modPanel.offset
				local body = Shared.CreatePhysicsSphereBody(false, radius, 1, coords)
				initBody(body)
				local offset = randomXZvector()
				body:Move(offset, CollisionRep.Default, CollisionRep.Default, PhysicsMask.All)
				body:Move(Vector(0, -100, 0), CollisionRep.Default, CollisionRep.Default, PhysicsMask.All)

				modPanel:SetOrigin(body:GetPosition() - Vector(0, radius, 0))

				Shared.DestroyCollisionObject(body)

				Log("Mod Panel '%s' created at %s", modPanel.name, modPanel:GetOrigin())

			end

		end

		for i = 1, #teamjoinbodies do
			Shared.DestroyCollisionObject(teamjoinbodies[i])
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

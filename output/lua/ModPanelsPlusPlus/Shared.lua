
Script.Load("lua/ModPanelsPlusPlus/ModPanel.lua")

if Server then

	local mod_panels_spawned = false
	function InitializeModPanels()
		assert(not mod_panels_spawned, "Mod Panels have alraedy been spawned!")

		Log "Initializing mod panels..."

		local spawnPoints = Server.readyRoomSpawnList

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

				Log("Mod Panel created at %s", modPanel:GetOrigin())

			end

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

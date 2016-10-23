Script.Load("lua/anniversary/WoozArmory.lua");

local Shine = Shine;
local Plugin = {
	Version = "1.0";
	NS2Only = false;
	HasConfig = true;
	ConfigName = "WoozArmory.json";
	DefaultConfig = {
		Winners = {};
		Maps = {}
	};
};

local armories = {}; -- Key: entityId, Value: ConfigId
local config;
local winners;

local function pointToTable(point)
	return {
		x = point.x,
		y = point.y,
		z = point.z
	};
end

local function tableToPoint(t)
	local v = Vector();
	v.x = t.x;
	v.y = t.y;
	v.z = t.z;
	return v;
end

local function coordsToTable(coords)
	return {
		xAxis = pointToTable(coords.xAxis);
		yAxis = pointToTable(coords.yAxis);
		zAxis = pointToTable(coords.zAxis);
		origin = pointToTable(coords.origin);
	};
end

local function tableToCoords(table)
	local coords = Coords();

	coords.xAxis = tableToPoint(table.xAxis);
	coords.yAxis = tableToPoint(table.yAxis);
	coords.zAxis = tableToPoint(table.zAxis);
	coords.origin = tableToPoint(table.origin);

	return coords;
end

local function armoryCallback(player, armory)
	local id = armory:GetId();
	local entry = config[armories[id]];
	entry.Used = true;
	local map = Shared.GetMapName();
	local room = GetLocationForPoint(armory:GetOrigin()):GetName();
	local name = entry.Name;
	local pname = player.name;
	local psteamid = GetSteamIdForClientIndex(player:GetClientIndex());
	Shine:NotifyColour(nil, 128, 218, 148, "[The Gorges of Apherioxia] Player " .. pname .. " has found a secret Apherioxian Gorge!");
	Shared.Message("[The Gorges of Apherioxia] Gorge '" .. name .. "' found; Player Name: " .. pname .. "; Room: " .. room);
	armories[id] = -1;
	table.insert(winners, {
		PlayerName = pname;
		SteamID = psteamid;
		GorgeName = name;
		Map = map;
		Room = room;
		Coords = entry.Coords;
		Time = os.date("!");
	});
end

local function iterateTable(t)
	for k, v in pairs(t) do
		Shared.Message(tostring(k) .. ":" .. type(v));
		if type(v) == "table" then
			iterateTable(v);
		end
	end
end

local function plantArmory(client, name)
	local player = client:GetControllingPlayer();
	local ent = CreateEntity("woozarmory", player:GetOrigin());
	local angles = player:GetViewAngles();
	ent:SetAngles(angles);
	ent:SetCallback(armoryCallback);
	table.insert(config, {
		Name = name;
		Coords = coordsToTable(ent:GetCoords());
		Used = false;
	});
	iterateTable(Plugin.Config);
	armories[ent:GetId()] = #config;
	Plugin:SaveConfig();
end

local function cleanUsedEntries()
	if #config > 0 then
		local newconfig = {};
		for i = 1, #config do
			local entry = config[i];
			if not entry.Used then
				table.insert(newconfig, entry);
			end
		end
		config = newconfig;
		Plugin.Config.Maps[Shared.GetMapName()] = config;
		Plugin:SaveConfig();
	end
end

function Plugin:Initialise()
	assert(debug.getregistry().WoozArmory);

	local mapName = Shared.GetMapName();
	local mapsConfig = Plugin.Config.Maps;
	mapsConfig[mapName] = mapsConfig[mapName] or {}
	config = mapsConfig[mapName];
	cleanUsedEntries(); -- If #config == 0 then config isn't saved.
	winners = Plugin.Config.Winners;

	local command = self:BindCommand("sh_plant_armory", "PlantArmory", plantArmory, true);
	command:Help("Plants an armory on what you're looking at.");
	command:AddParam {
		Type = "string";
		Optional = true;
		TakeRestOfLine = true;
		Help = "Name of armory";
		Default = "Unnamed";
	};

	self:BindCommand("sh_spawn_armories", "SpawnArmories", function()
			for i = 1, #config do
				local entry = config[i];
				local ent = CreateEntity("woozarmory");
				ent:SetCoords(tableToCoords(entry.Coords));
				ent:SetCallback(armoryCallback);
				armories[ent:GetId()] = i;
			end
	end, true);

	self.Enabled = true;
	return true;
end
Shine:RegisterExtension("woozarmory", Plugin);

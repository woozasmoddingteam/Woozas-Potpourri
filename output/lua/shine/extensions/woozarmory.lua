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
	local room = entry.Room;
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
		Room = room or "[No Room]";
		Origin = entry.Coords.origin;
		Time = os.date();
	});
	Plugin:SaveConfig();
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
		Room = GetLocationForPoint(ent:GetOrigin()):GetName();
	});
	armories[ent:GetId()] = #config;
	Plugin:SaveConfig();
end

local function cleanUsedEntries(cfg)
	local newcfg = {};
	for i = 1, #cfg do
		local entry = cfg[i];
		if not entry.Used then
			table.insert(newcfg, entry);
		end
	end
	cfg = newcfg;
	return #cfg ~= 0 and cfg or nil;
end

local function init()
	Shared.Message("Initialisation");

	local mapName = Shared.GetMapName();
	local mapsConfig = Plugin.Config.Maps;

	for k, v in pairs(mapsConfig) do
		mapsConfig[k] = cleanUsedEntries(v);
	end
	Plugin:SaveConfig();

	mapsConfig[mapName] = mapsConfig[mapName] or {}
	config = mapsConfig[mapName];
	winners = Plugin.Config.Winners;

	for i = 1, #config do
		Shared.Message("Spawning armories!");
		local entry = config[i];
		local ent = Server.CreateEntity("woozarmory", {origin = Vector(0, 0, 0)});
		ent:SetCoords(tableToCoords(entry.Coords));
		ent:SetCallback(armoryCallback);
		armories[ent:GetId()] = i;
	end
end

local function emptyFunction() end

local function waitForGameStart(self, gamerules, newstate, oldstate)
	if newstate == kGameState.Started then
		local ents = GetEntities("WoozArmory");
		for i = 1, #ents do
			DestroyEntity(ents[i]);
		end
	end
	setGameState = emptyFunction;
end

local function setGameState(self, gamerules, newstate, oldstate)
	if newstate ~= oldstate then
		init();
		setGameState = waitForGameStart;
	end
end

function Plugin:SetGameState(Gamerules, NewState, OldState)
	if NewState ~= OldState then
		init()
	end
end

function Plugin:Initialise()
	local command = self:BindCommand("sh_plant_armory", "PlantArmory", plantArmory, true);
	command:Help("Plants an armory on what you're looking at.");
	command:AddParam {
		Type = "string";
		Optional = true;
		TakeRestOfLine = true;
		Help = "Name of armory";
		Default = "Unnamed";
	};

	self.Enabled = true;
	return true;
end

Shine:RegisterExtension("woozarmory", Plugin);

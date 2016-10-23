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

local function updateGorges()
	local ents = GetEntities("WoozArmory");
	for i = 1, #ents do
		local ent = ents[i];
		local index = armories[ent:GetId()];
		local entry = config[index];
		entry.Coords = coordsToTable(ent:GetCoords());
	end
	Plugin:SaveConfig();
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

function Plugin:SetGameState(...)
	setGameState(self, ...);
end

local function increaseYaw(client, amount)
	local player = client:GetControllingPlayer()

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()));
	local ent = trace.entity;

	local angles = ent:GetAngles();

	angles.yaw = (angles.yaw + amount) % math.pi*2;

	ent:SetAngles(angles);
end

local function increaseRoll(client, amount)
	local player = client:GetControllingPlayer()

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()));
	local ent = trace.entity;

	local angles = ent:GetAngles();

	angles.roll = (angles.roll + amount) % math.pi*2;

	ent:SetAngles(angles);
end

local function increasePitch(client, amount)
	local player = client:GetControllingPlayer()

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()));
	local ent = trace.entity;

	local angles = ent:GetAngles();

	angles.pitch = (angles.pitch + amount) % math.pi*2;

	ent:SetAngles(angles);
end

local function push(client, amount)
	local player = client:GetControllingPlayer()

    local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()));
	local ent = trace.entity;

	endPoint = trace.endPoint;

	local origin = ent:GetOrigin();
	local offset = origin - endPoint;
	local new = endPoint - startPoint;
	new = new + amount;
	ent:SetOrigin(new + startPoint);
end

local function plantGorge(client, name)
	local player = client:GetControllingPlayer();

	local startPoint = player:GetEyePos()
    local endPoint = startPoint + player:GetViewCoords().zAxis * 100
    local trace = Shared.TraceRay(startPoint, endPoint,  CollisionRep.Default, PhysicsMask.Bullets, EntityFilterTwo(player, player:GetActiveWeapon()));

	local ent = CreateEntity("woozarmory", trace.endPoint);
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

function Plugin:Initialise()
	local command = self:BindCommand("sh_plant_gorge", "PlantGorge", plantGorge, true);
	command:Help("Plants an armory on what you're looking at.");
	command:AddParam {
		Type = "string";
		Optional = true;
		TakeRestOfLine = true;
		Help = "Name of armory";
		Default = "Unnamed";
	};

	command = self:BindCommand("sh_increase_yaw", "IncreaseYaw", increaseYaw, true);
	command:AddParam {
		Type = "number";
	};

	command = self:BindCommand("sh_increase_roll", "IncreaseRoll", increaseRoll, true);
	command:AddParam {
		Type = "number";
	};

	command = self:BindCommand("sh_increase_pitch", "IncreasePitch", increasePitch, true);
	command:AddParam {
		Type = "number";
	};

	command = self:BindCommand("sh_pushent", "PushEnt", push, true);
	command:AddParam {
		Type = "number";
	};

	command = self:BindCommand("sh_update_gorges", "UpdateGorges", updateGorges, true);

	self.Enabled = true;
	return true;
end

Shine:RegisterExtension("woozarmory", Plugin);

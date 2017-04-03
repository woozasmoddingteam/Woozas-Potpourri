local Shine = Shine
local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	outbound = "localhost:64999/to",
	inbound  = "localhost:64999/from"
}

local marker = string.byte '!'
local byte = string.byte
local sub  = string.sub

local inbound
local outbound

local function say(msg)
	Shared.SendHTTPRequest(outbound, "POST", {str = msg})
end

local function fromDiscord(msg)
	local admin = byte(msg, 1) == marker
	local num = 0
	local idx = admin and 2 or 1
	while byte(msg, idx) ~= marker do
		num = num * 10 + byte(msg, idx) - byte '0'
		idx = idx + 1
	end
	Log("Raw: %s", msg)
	Log("Index: %s", idx)
	Log("Num: %s", num)
	local name = sub(msg, idx+1, idx+num)
	local message = sub(msg, idx+num+1)
	-- Command
	if byte(message, 1) == '!' then
		local exploded = string.Explode(message, " ")
		local cmd = Shine.ChatCommands[table.remove(exploded, 1)]
		if cmd.Disabled then
			say "Error: This command is disabled!"
		else
			Shine:RunCommand(admin and "0" or nil, cmd.ConCmd, false, unpack(exploded))
		end
	else
		Log("Name: %s", name)
		Log("Message: %s", message)
		Shine:NotifyDualColour(nil, 40, 20, 80, "(Discord) " .. name .. ":", 170, 170, 170, message)
	end
	Shared.SendHTTPRequest(inbound, "POST", fromDiscord)
end

function Plugin:Initialise()
	inbound = self.Config.inbound
	outbound = self.Config.outbound
	self.Enabled = true
	Shared.SendHTTPRequest(inbound, "POST", fromDiscord)

	return true
end

local team_names = {
	[0] = kSpectatorTeamName,
	kTeam1Name,
	kTeam2Name,
	"Spectator"
}

function Plugin:PlayerSay(client, message)
	if not message.teamOnly then
		local player = client:GetControllingPlayer()
		local name = player:GetName()
		local team = team_names[player:GetTeamNumber()] or "N/A"
		say("__<" .. team .. ">__ **" .. name .. "**: " .. message.message)
	end
end

Shine:RegisterExtension("discord_bridge", Plugin)

local Shine = Shine
local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	outbound = "localhost:64999/to",
	inbound  = "localhost:64999/from"
}

local discord = newproxy()

local byte = string.byte
local sub  = string.sub

local inbound
local outbound

local function say(msg)
	if outbound then
		Log("Sending message to discord: %s", msg)
		Shared.SendHTTPRequest(outbound, "POST", msg)
	end
end

local space = byte ' '
local function explode(str)
	local ret = {}
	local last = 1
	for i = 1, #str do
		if byte(str, i) == space then
			if i ~= last then
				table.insert(ret, sub(str, last, i-1))
			end
			last = i
		end
	end
	if last ~= #str then
		table.insert(sub(str, last))
	end
	return ret
end

local fromDiscord
local function request()
	Shared.SendHTTPRequest(inbound, "POST", fromDiscord)
end

function fromDiscord(msg)
	if byte(msg, 1) == 2 then
		Shine:NotifyColour(nil, 40, 10, 10, "Discord bot is restarting! Connection disrupted for 10 seconds.")
		Shine.Timer.Simple(10, request)
		return
	end
	local admin = byte(msg, 1) == 1
	local name_len = byte(msg, 2)
	local name = sub(msg, 3, 2+name_len)
	local message = sub(msg, 3+name_len)
	--[=[
	Log("Admin: %s", admin)
	Log("Name length: %s", name_len)
	Log("Name: %s", name)
	Log("Message: %s", message)
	--]=]
	-- Command
	if false and byte(message, 1) == byte '!' then
		local exploded = explode(message)
		Log("Command %s received with arguments %s!", cmd.ConCmd, exploded)
		local cmd = Shine.ChatCommands[table.remove(exploded, 1)]
		if cmd.Disabled then
			say {
				author  = "Shine",
				steamid = 0,
				color   = 0xFF0000,
				message = "Error: This command is disabled!"
			}
		else
			Shine:RunCommand(admin and "0" or nil, cmd.ConCmd, false, unpack(exploded))
		end
	else
		Shine:NotifyDualColour(nil, 40, 20, 80, "(Discord) " .. name .. ":", 170, 170, 170, message)
	end
	request()
end

do
	local StringFormat = string.format
	local Ceil = math.ceil
	function Shine:Notify( Player, Prefix, Name, String, Format, ... )
		local Message = Format and StringFormat( String, ... ) or String

		if Prefix == "" and Name == "" then
			return self:NotifyColour( Player, 255, 255, 255, String, Format, ... )
		end

		if Player == "Console" then
			Shared.Message( Message )

			return
		end

		local MessageLength = Message:UTF8Length()
		if MessageLength > kMaxChatLength then
			local Iterations = Ceil( MessageLength / kMaxChatLength )

			for i = 1, Iterations do
				self:Notify( Player, Prefix, Name, Message:UTF8Sub( 1 + kMaxChatLength * ( i - 1 ),
					kMaxChatLength * i ) )
			end

			return
		end

		local MessageTable = self.BuildChatMessage( Prefix, Name, kTeamReadyRoom,
			kNeutralTeamType, Message )

		Server.AddChatToHistory( Message, Name, 0, kTeamReadyRoom, false )

		if Player == discord then
			goto to_discord
		end

		self:ApplyNetworkMessage( Player, "Shine_Chat", MessageTable, true )

		if Player == nil then
			goto to_discord
		end

		do return end

		::to_discord::

		say {
			steamid = 0,
			author  = Prefix .. ": " .. Name,
			message = Message,
			color   = 0xFFFFFF
		}
	end
end

do
	local old = Shine.NotifyDualColour
	local StringFormat = string.format
	function Shine:NotifyDualColour(player, rp, gp, bp, prefix, c, g, b, string, format, ...)
		local message = format and StringFormat(string, ...) or string

		if player == discord then
			goto to_discord
		end

		old(player, rp, gp, bp, prefix, c, g, b, message)

		if player == nil then
			goto to_discord
		end

		do return end

		::to_discord::

		say {
			steamid = 0,
			author = prefix,
			message = message,
			color = bit.bor(bit.lshift(rp, 16), bit.lshift(gp, 8), bp)
		}
	end
end

do
	local old = Shine.TranslatedNotifyDualColour
	local StringFormat = string.format
	function Shine:TranslatedNotifyDualColour(player, rp, gp, bp, prefix, c, g, b, string, source)
		if player == discord then
			goto to_discord
		end

		old(player, rp, gp, bp, prefix, c, g, b, string, source)

		if player == nil then
			goto to_discord
		end

		do return end

		::to_discord::

		source = source or "Core"

		prefix = Shine.Locale:GetLocalisedString(source, "enUS", prefix)
		string = Shine.Locale:GetLocalisedString(source, "enUS", string)

		say {
			steamid = 0,
			author = prefix,
			message = message,
			color = bit.bor(bit.lshift(rp, 16), bit.lshift(gp, 8), bp)
		}
	end
end

local team_colors = {
	[0] = 0x4B4E52,
	0x327FB4,
	0xF65C00,
	0xD3D7CF
}

function Plugin:PlayerSay(client, message)
	if not message.teamOnly then
		local player = client:GetControllingPlayer()
		local name = player:GetName()
		local team = player:GetTeamNumber()
		say {
			steamid = player:GetSteamId(),
			author  = name,
			message = message.message,
			color   = team_colors[team] or 0x00FF00
		}
	end
end

function Plugin:Initialise()
	inbound = self.Config.inbound
	outbound = self.Config.outbound
	self.Enabled = true
	request()

	return true
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup(self)
	inbound, outbound = nil, nil
end

Shine:RegisterExtension("discord_bridge", Plugin)

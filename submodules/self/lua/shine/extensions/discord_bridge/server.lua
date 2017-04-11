local Shine = Shine
local Plugin = Plugin

local discord_user = {}
function discord_user.GetControllingPlayer() end
function discord_user.GetUserId() return 1 end

local discord_admin = {}
function discord_admin.GetControllingPlayer() end
function discord_admin.GetUserId() return 0 end

local byte = string.byte
local sub  = string.sub

local inbound
local outbound
local language

local original_notify

local function say(msg)
	if outbound then
		Shared.SendHTTPRequest(outbound, "POST", msg)
	end
end

local function explode(str)
	local ret = {}
	local last = 1
	for i = 1, #str do
		if byte(str, i) == byte ' ' then
			if i ~= last then
				table.insert(ret, sub(str, last, i-1))
			end
			last = i+1
		end
	end
	if last <= #str then
		table.insert(ret, sub(str, last))
	end
	return ret
end

local fromDiscord
local function request()
	Shared.SendHTTPRequest(inbound, "POST", fromDiscord)
end

function fromDiscord(msg)
	if #msg == 0 then return end
	local admin = byte(msg, 1) == 1
	local name_len = byte(msg, 2)
	local name = sub(msg, 3, 2+name_len)
	local message = sub(msg, 3+name_len)
	-- Command
	if byte(message, 1) == byte '!' or byte(message, 1) == byte '?' then
		local exploded = explode(sub(message, 2))
		local cmd = table.remove(exploded, 1)
		if byte(message, 1) == byte '!' then
			cmd = Shine.ChatCommands[cmd]
			if not cmd then
				say {
					color = 0xFF0000,
					steamid = 0,
					author = "DiscordBot",
					message = "Not a valid command!"
				}
				request()
				return
			end
			cmd = cmd.ConCmd
		end
		local client = admin and discord_admin or discord_user
		Shine:RunCommand(client, cmd, false, unpack(exploded))
	else
		(original_notify or Shine.NotifyDualColour)(Shine, nil, 40, 20, 80, "(Discord) " .. name .. ":", 170, 170, 170, message)
	end
	request()
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

function Plugin:MapChange(map)
	say {
		steamid = 0,
		author  = "[Map Vote]",
		message = "Changing map to " .. map,
		color   = 0x808F24
	}
end

function Plugin:Initialise()
	inbound  = self.Config.inbound
	outbound = self.Config.outbound
	language = self.Config.language

	Shine.Hook.Add("OnFirstThink", "OverrideShineLogging", function()
		local Locale = loadfile("lua/shine/extensions/discord_bridge/locale.lua")(language)

		assert(Shine.Notify)
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

			if Player == discord_user or Player == discord_admin then
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

		local old = assert(Shine.NotifyDualColour)
		original_notify = old
		function Shine:NotifyDualColour(player, rp, gp, bp, prefix, c, g, b, string, format, ...)
			local message = format and StringFormat(string, ...) or string

			if player == discord_admin or player == discord_user then
				goto to_discord
			end

			old(self, player, rp, gp, bp, prefix, c, g, b, message)

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

		local old = assert(Shine.TranslatedNotifyDualColour)
		function Shine:TranslatedNotifyDualColour(player, rp, gp, bp, prefix, c, g, b, string, source)
			if player == discord_user or player == discord_admin then
				goto to_discord
			end

			old(self, player, rp, gp, bp, prefix, c, g, b, string, source)

			if player == nil then
				goto to_discord
			end

			do return end

			::to_discord::

			prefix = Locale.GetLocalisedString(source, prefix)
			string = Locale.GetLocalisedString(source, string)

			say {
				steamid = 0,
				author = prefix,
				message = string,
				color = bit.bor(bit.lshift(rp, 16), bit.lshift(gp, 8), bp)
			}
		end

		local old = ServerAdminPrint
		function ServerAdminPrint(client, msg, wrap)
			if not client then return end

			if client == discord_admin or client == discord_user then
				goto to_discord
			end

			old(client, msg, wrap)

			if client == nil then
				goto to_discord
			end

			do return end

			::to_discord::

			say {
				steamid = 0,
				author  = "",
				message = msg,
				color   = 0x808F24
			}
		end

		local old = Shine.SendTranslatedCommandError
		local interpolate = string.Interpolate
		function Shine:SendTranslatedCommandError(client, name, data, source)
			if client == discord_user or client == discord_admin then
				local localised_string = Locale.GetLocalisedString(source, name)
				local interpolated = interpolate(localised_string, data)
				say {
					color   = 0xFF0000,
					steamid = 0,
					message = interpolated,
					author  = "Shine"
				}
			else
				old(self, client, name, data, source)
			end
		end
	end)

	self:BindCommand("sh_relinkdiscord", "RelinkDiscord", request)

	self.Enabled = true
	request()

	return true
end

function Plugin:Cleanup()
	self.BaseClass.Cleanup(self)
	inbound, outbound = nil, nil
end

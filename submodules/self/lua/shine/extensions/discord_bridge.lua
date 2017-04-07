local Shine = Shine
local Plugin = {}
Plugin.NS2Only = false
Plugin.HasConfig = true
Plugin.ConfigName = "DiscordBridge.json"
Plugin.DefaultConfig = {
	outbound = "localhost:64999/to",
	inbound  = "localhost:64999/from"
}

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
local original_notify

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
	if byte(message, 1) == byte '!' or byte(message, 1) == byte '?' then
		local exploded = explode(sub(message, 2))
		local cmd = table.remove(exploded, 1)
		cmd = byte(message, 1) == byte '!' and Shine.ChatCommands[cmd].ConCmd or cmd
		Log("Command %s received with arguments %s!", cmd, exploded)
		local client = admin and discord_admin or discord_user
		Shine:RunCommand(client, cmd, false, unpack(exploded))
	else
		(original_notify or Shine.NotifyDualColour)(Shine, nil, 40, 20, 80, "(Discord) " .. name .. ":", 170, 170, 170, message)
	end
	request()
end

Shine.Hook.Add("OnFirstThink", "OverrideShineLogging", function()
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

	--[=[ Server-side Locale lib ]=]

	local LangFiles = {}
	local Sources   = {
		core = "locale/shine/core"
	}
	local Strings   = {
		core = {}
	}
	Shared.GetMatchingFileNames( "locale/*.json", true, LangFiles )
	local extensions = {}
	Shared.GetMatchingFileNames("locale/shine/extensions/*", false, extensions)

	local function baseName(path)
		for i = #path-1, 1, -1 do
			if path:byte(i) == byte '/' then
				return path:sub(i+1)
			end
		end
		return path
	end
	for i = 1, #extensions do
		local path = extensions[i]
		path = path:sub(1, #path-1)
		local name = baseName(path)
		Log("Registered locale %s in path %s!", name, path)
		Sources[name] = path
		Strings[name] = {}
	end

	local LangLookup = {}
	for i = 1, #LangFiles do
		LangLookup[ LangFiles[ i ] ] = true
	end

	local loadstring = loadstring
	local DefaultDef = {
		GetPluralForm = function( Value )
			return Value == 1 and 1 or 2
		end
	}

	local pcall = pcall
	local setfenv = setfenv
	local StringGSub = string.gsub

	local PermittedKeywords = {
		[ "and" ] = true,
		[ "or" ] = true,
		[ "not" ] = true,
		[ "n" ] = true
	}

	local function SanitiseCode( Source )
		return StringGSub( StringGSub( Source, "[\"'%[%]%.:]", "" ), "%a+", function( Keyword )
			if not PermittedKeywords[ Keyword ] then return "" end
		end )
	end

	local ExpectedDefKeys = {
		GetPluralForm = function( Lang, Source )
			if not Source then return DefaultDef.GetPluralForm end

			local Code = StringFormat( "return ( function( n ) return ( %s ) end )( ... )",
				SanitiseCode( Source ) )

			local PluralFormFunc, Err = loadstring( Code )
			local function Reject( Error )
				Print( "[Shine Locale] Error in plural form for %s: %s", Lang, Error )
				PluralFormFunc = DefaultDef.GetPluralForm
			end

			if PluralFormFunc then
				setfenv( PluralFormFunc, {} )
				local Valid, Err = pcall( PluralFormFunc, 1 )
				if not Valid then
					Reject( Err )
				end
			else
				Reject( Err )
			end

			return PluralFormFunc
		end
	}

	local function ResolveFilePath( Folder, Lang )
		return StringFormat( "%s/%s.json", Folder, Lang )
	end

	local LanguageDefinitions = {}

	local function GetLanguageDefinition( Lang )
		Lang = Lang or "enGB"

		if LanguageDefinitions[ Lang ] then
			return LanguageDefinitions[ Lang ]
		end

		local Path = ResolveFilePath( "locale/shine", StringFormat( "def-%s", Lang ) )
		local Def = DefaultDef

		if LangLookup[ Path ] then
			local LangDefs = Shine.LoadJSONFile( Path )
			if LangDefs then
				Def = {}

				for ExpectedKey, Loader in pairs( ExpectedDefKeys ) do
					Def[ ExpectedKey ] = Loader( Lang, LangDefs[ ExpectedKey ] )
				end
			else
				Def = DefaultDef
			end
		end

		LanguageDefinitions[ Lang ] = Def

		return Def
	end


	local function LoadStrings( Source, Lang )
		local Folder = Sources[ Source ]
		if not Folder then return nil end

		local Path = ResolveFilePath( Folder, Lang )
		if not LangLookup[ Path ] then
			return nil
		end

		local LanguageStrings = Shine.LoadJSONFile( Path )
		if LanguageStrings then
			Strings[ Source ][ Lang ] = LanguageStrings
		end

		return LanguageStrings
	end

	local function GetLanguageStrings( Source, Lang )
		local LoadedStrings = Strings[ Source ]
		if not LoadedStrings then return nil end

		local LanguageStrings = LoadedStrings[ Lang ]
		if not LanguageStrings then
			LanguageStrings = LoadStrings( Source, Lang )
		end

		return LanguageStrings
	end

	local function GetLocalisedString( Source, Lang, Key )
		local LanguageStrings = GetLanguageStrings( Source, Lang )
		if not LanguageStrings or not LanguageStrings[ Key ] then
			LanguageStrings = GetLanguageStrings( Source, DefaultLanguage )
		end

		return LanguageStrings and LanguageStrings[ Key ] or Key
	end

	local old = assert(Shine.TranslatedNotifyDualColour)
	function Shine:TranslatedNotifyDualColour(player, rp, gp, bp, prefix, c, g, b, string, source)
		Log("Message to %s from %s: %s", player, prefix or "[N/A]", string)
		if player == discord_user or player == discord_admin then
			goto to_discord
		end

		old(self, player, rp, gp, bp, prefix, c, g, b, string, source)

		if player == nil then
			goto to_discord
		end

		do return end

		::to_discord::

		source = source and string.UTF8Lower(source) or "core"

		prefix = GetLocalisedString(source, "enGB", prefix)
		string = GetLocalisedString(source, "enGB", string)

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
end)

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

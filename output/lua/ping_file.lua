local fileName = "server_modding_ping.txt"

local refresh = 0
local function updatePingFile(timePassed)

   refresh = refresh + timePassed
   if (refresh > 1) then
      refresh = 0
      local configFile = io.open("config://" .. fileName, "w")
      if configFile then
	 configFile:write(tostring(os.date()))
	 io.close(configFile)
      end
   end
end

Event.Hook("UpdateServer", updatePingFile)

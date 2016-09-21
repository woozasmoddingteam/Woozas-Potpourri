--[[
    Shine ReadyRoomRave Plugin
]]

local Plugin = {}


function Plugin:SetupDataTable()
    self:AddNetworkMessage( "RaveCinematic", { origin = "vector", stop = "boolean" }, "Client" )
    self:AddNetworkMessage( "CreateSpray", {
        originX = "float",
        originY = "float",
        originZ = "float",
        yaw = "float",
        roll = "float",
        pitch = "float",
        path = "string (20)"
    }, "Client" )
end


Shine:RegisterExtension( "readyroomrave", Plugin )

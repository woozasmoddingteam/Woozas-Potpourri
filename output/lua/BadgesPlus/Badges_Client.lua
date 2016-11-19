Script.Load("lua/Badges_Shared.lua")

local ClientId2Badges = {}

--cache owned badges
local ownedBadges = {}

--Assign badges to client based on the hive response
function Badges_FetchBadges(_, response)
    local badges = response or {}

    for _, badgeid in ipairs(gDLCBadges) do
        local data = Badges_GetBadgeData(badgeid)
        if GetHasDLC(data.productId) then
            badges[#badges + 1] = gBadges[badgeid]
        end
    end

    for _, badge in ipairs(badges) do
        local badgeid = rawget(gBadges, badge)
        local data = Badges_GetBadgeData(badgeid)
        ownedBadges[badgeid] = data.columns
    end

    Badges_ApplyHive1Badges(response)
end

--Returns lookup table of by the client owned badges
function Badges_GetOwnedBadges()
    return ownedBadges
end

local textures = {}
local badgeNames = {}

Client.HookNetworkMessage("DisplayBadge",
    function(msg)
        if not ClientId2Badges[msg.clientId] then
            ClientId2Badges[ msg.clientId ] = {}
            for i = 1, 10 do
                ClientId2Badges[msg.clientId][i] = 1
            end
        end

        ClientId2Badges[msg.clientId][msg.column] = msg.badge

        --reset textures
        textures[msg.clientId] = nil
        badgeNames[msg.clientId] = nil
    end)

Client.HookNetworkMessage("BadgeRows",
    function(msg)
        if msg.columns == 0 then
            ownedBadges[msg.badge] = nil
        else
            ownedBadges[msg.badge] = msg.columns
        end
    end)

Client.HookNetworkMessage("BadgeName",
    function(msg)
        Badges_SetName(msg.badge, msg.name)
    end)

function Badges_GetBadgeTextures( clientId, usecase )
    
    local badges = ClientId2Badges[clientId]
    if badges then
        if not textures[clientId] then
            textures[clientId] = {}
            badgeNames[clientId] = {}

            for _, badge in ipairs(badges) do
                local data = Badges_GetBadgeData(badge)
                local textureTyp = usecase == "scoreboard" and "scoreboardTexture" or "unitStatusTexture"

                if data then
                    textures[clientId][#textures[clientId] + 1] = data[textureTyp]
                    badgeNames[clientId][#badgeNames[clientId] + 1] = data.name
                end
            end
        end

        return textures[clientId], badgeNames[clientId]
    else
        return {}, {}
    end

end

-- temp cache of often used function
local StringFormat = string.format

function SelectBadge(badgeId, column)
    Client.SetOptionString( StringFormat( "Badge%s", column ), gBadges[badgeId] )
    if Client.GetIsConnected() then
        Client.SendNetworkMessage( "SelectBadge", BuildSelectBadgeMessage(badgeId, column), true)
    end
end

local function OnConsoleBadge( badgename, column)
    column = tonumber( column )

    local badgeid = table.contains(gBadges, badgename) and gBadges[badgename]
    if not column or column < 0 or column > 10 then column = 5 end

    local sSavedBadge = Client.GetOptionString( StringFormat( "Badge%s", column ), "" )

    if StringTrim( badgename ) == "" then
        Print( StringFormat( "Saved Badge: %s", sSavedBadge or "none" ))
    elseif badgename == "-" or badgeid and badgeid == 1 then
        SelectBadge( gBadges.none, column )
    elseif badgename == sSavedBadge then
        Print( "You already have selected the requested badge" )
    elseif badgeid and ownedBadges[badgeid] then
        SelectBadge( badgeid, column )
    else
        Print( "Either you don't own the requested badge at this server or it doesn't exist." )
    end
end
Event.Hook( "Console_badge", OnConsoleBadge)

function Badges_ApplyHive1Badges(badges)
    local hiveOneApplied = Client.GetOptionBoolean( "Hive1BadgesConverted", false )
    if hiveOneApplied then return end

    Client.SetOptionBoolean( "Hive1BadgesConverted", true )

    for i = 1, 3 do
        if rawget(gBadges, badges[i]) then
            SelectBadge(gBadges[badges[i]], 6 + i)
        end
    end

    if badges[#badges] == "pax2012" then
        SelectBadge(gBadges.pax2012, 10)
    end
end

local function OnLoadComplete()
    for i = 1, 10 do
        local sSavedBadge = Client.GetOptionString( StringFormat("Badge%s", i), "" )
        if sSavedBadge and sSavedBadge ~= "" and Client.GetIsConnected() then
            local badgeid = table.contains(gBadges, sSavedBadge) and gBadges[sSavedBadge]
            if badgeid then
                Client.SendNetworkMessage( "SelectBadge", BuildSelectBadgeMessage(badgeid, i), true)
            end
        end
    end
end
Event.Hook( "LoadComplete", OnLoadComplete )
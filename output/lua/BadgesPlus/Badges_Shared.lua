------------------------------------------
--  Create basic badge tables
------------------------------------------

-- Max number of available badge columns
kMaxBadgeColumns = 10

--List of all avaible badges
gBadges = {
    "none",
    "dev",
    "dev_retired",
    "maptester",
    "playtester",
    "ns1_playtester",
    "constellation",
    "hughnicorn",
    "squad5_blue",
    "squad5_silver",
    "squad5_gold",
    "commander",
    "community_dev",
    "reinforced1",
    "reinforced2",
    "reinforced3",
    "reinforced4",
    "reinforced5",
    "reinforced6",
    "reinforced7",
    "reinforced8",
    "wc2013_supporter",
    "wc2013_silver",
    "wc2013_gold",
    "wc2013_shadow",
    "pax2012"
}

--Stores information about textures and names of the Badges
local badgeData = {}

--scope this properly so the GC can clean up directly afterwards
do
    local function MakeBadgeData2(name, ddsPrefix)
        return {
            name = string.upper(string.format("BADGE_%s", name)),
            unitStatusTexture = string.format("ui/badges/%s.dds", ddsPrefix),
            scoreboardTexture = string.format("ui/badges/%s_20.dds", ddsPrefix),
            columns = 960, --column 7,8,9,10
            isOfficial = true,
        }
    end

    local function MakeBadgeData(name)
        return MakeBadgeData2(name, name)
    end

    local function MakeDLCBadgeInfo(name, ddsPrefix, productId)
        local info = MakeBadgeData2(name, ddsPrefix)

        info.productId = productId

        return info
    end
    
    --vanilla badges data
    badgeData["dev"] = MakeBadgeData("dev")
    badgeData["dev_retired"] = MakeBadgeData("dev_retired")
    badgeData["maptester"] = MakeBadgeData("maptester")
    badgeData["playtester"] = MakeBadgeData("playtester")
    badgeData["ns1_playtester"] = MakeBadgeData("ns1_playtester")
    badgeData["constellation"] = MakeBadgeData2("constellation", "constelation")
    badgeData["hughnicorn"] = MakeBadgeData("hughnicorn")
    badgeData["squad5_blue"] = MakeBadgeData("squad5_blue")
    badgeData["squad5_silver"] = MakeBadgeData("squad5_silver")
    badgeData["squad5_gold"] = MakeBadgeData("squad5_gold")
    badgeData["commander"] = MakeBadgeData("commander")
    badgeData["community_dev"] = MakeBadgeData("community_dev")
    badgeData["reinforced1"] = MakeBadgeData2("reinforced1", "game_tier1_blue")
    badgeData["reinforced2"] = MakeBadgeData2("reinforced2", "game_tier2_silver")
    badgeData["reinforced3"] = MakeBadgeData2("reinforced3", "game_tier3_gold")
    badgeData["reinforced4"] = MakeBadgeData2("reinforced4", "game_tier4_diamond")
    badgeData["reinforced5"] = MakeBadgeData2("reinforced5", "game_tier5_shadow")
    badgeData["reinforced6"] = MakeBadgeData2("reinforced6", "game_tier6_onos")
    badgeData["reinforced7"] = MakeBadgeData2("reinforced7", "game_tier7_Insider")
    badgeData["reinforced8"] = MakeBadgeData2("reinforced8", "game_tier8_GameDirector")
    badgeData["wc2013_supporter"] = MakeBadgeData("wc2013_supporter")
    badgeData["wc2013_silver"] = MakeBadgeData("wc2013_silver")
    badgeData["wc2013_gold"] = MakeBadgeData("wc2013_gold")
    badgeData["wc2013_shadow"] = MakeBadgeData("wc2013_shadow")
    badgeData["pax2012"] = MakeDLCBadgeInfo("pax2012", "badge_pax2012", 4931)

    --custom badges
    local badgeFiles = {}
    local officialFiles = {}

    Shared.GetMatchingFileNames( "ui/badges/*.dds", false, badgeFiles )

    for _, badge in ipairs(gBadges) do
        local data = badgeData[badge]
        if data then
            officialFiles[data.unitStatusTexture] = true
            officialFiles[data.scoreboardTexture] = true
            officialFiles[badge] = true
        end
    end

    for _, badgeFile in ipairs(badgeFiles) do
        if not officialFiles[badgeFile] then
            local _, _, badgeName = string.find( badgeFile, "ui/badges/(.*).dds" )

            if not officialFiles[badgeName] then --avoid custom badges named like official badges
                local badgeId = #gBadges + 1

                gBadges[badgeId] = badgeName

                badgeData[badgeName] = {
                    name = badgeName,
                    unitStatusTexture = badgeFile,
                    scoreboardTexture = badgeFile,
                    columns = 16, --column 5
                }
            end
        end
    end

    gBadges = enum(gBadges)
end

function Badges_GetBadgeData(badgeId)

    return badgeData[gBadges[badgeId]]
end

function Badges_SetName(badgeId, name)
    if not badgeData[gBadges[badgeId]] or not name then return false end

    badgeData[gBadges[badgeId]].name = tostring(name)

    return true
end

--Returns maximum amount of different badges avaible
function Badges_GetMaxBadges()
    return #gBadges
end

function GetBadgeFormalName(badgename)
    local fullString = badgename and Locale.ResolveString(badgename)

    return fullString or "Custom Badge"
end

--List of all Badges which are assigned to a DLC
gDLCBadges = {
    gBadges.pax2012
}

------------------------------------------
--  Create network message spec
------------------------------------------

--Used to network displayed Badges from Server to Client
function BuildDisplayBadgeMessage(clientId, badge, column)
    return {
        clientId = clientId,
        badge = badge,
        column = column
    }
end

local kBadgesMessage = 
{
    clientId = "entityid",
    badge = "enum gBadges",
    column = string.format("integer (0 to %s)", kMaxBadgeColumns)
}
Shared.RegisterNetworkMessage("DisplayBadge", kBadgesMessage)

--Used to network the badge selection of the client to the server
function BuildSelectBadgeMessage(badge, column)
    return {
        badge = badge,
        column = column
    }
end

local kBadgesMessage =
{
    badge = "enum gBadges",
    column = string.format("integer (0 to %s)", kMaxBadgeColumns)
}
Shared.RegisterNetworkMessage("SelectBadge", kBadgesMessage)

--Used to network the allowed columns of a badge from the server to the client
--columns are represented as bitsmask from right to left: 1 = first column, 2(bin: 10) = second column
function BuildBadgeRowsMessage(badge, columns)
    return {
        badge = badge,
        columns = columns
    }
end

local kBadgeRowsMessage =
{
    badge = "enum gBadges",
    columns = string.format("integer (0 to %s)", 2^(kMaxBadgeColumns+1)-1)
}

Shared.RegisterNetworkMessage("BadgeRows", kBadgeRowsMessage)

--Used to send the badge names to the client
local kBadgeBroadcastMessage =
{
    badge = "enum gBadges",
    name = "string (128)"
}

Shared.RegisterNetworkMessage("BadgeName", kBadgeBroadcastMessage)

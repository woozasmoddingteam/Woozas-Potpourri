-- temp cache of often used function
local TableInsert = table.insertunique
local TableContains = table.contains

local StringFind = string.find

-- Load all badge images. Custom badges will be loaded through here
do

    local function isOfficial( badgeFile )
        for i, info in ipairs( gBadgesData ) do
            if info.unitStatusTexture == badgeFile then
                return true
            end
        end
        return false
    end
    
    local sBadges = { 'None' }
    local badgeFiles = { }
    Shared.GetMatchingFileNames( "ui/badges/*.dds", false, badgeFiles )

    -- Texture for all badges is "ui/${name}.dds"
    for _, badgeFile in pairs( badgeFiles ) do
        
        -- exclude official and _20.dds small versions of badges
        if not isOfficial( badgeFile ) and not StringEndsWith( badgeFile, "_20.dds" ) then
            local _, _, sBadgeName = StringFind( badgeFile, "ui/badges/(.*).dds" )
            TableInsert( sBadges, sBadgeName )
        end
        
    end
    
    kBadges = enum( sBadges )
end

local kBadgeNameMessage =
{
    badge = "enum kBadges",
    badgename = "string (255)"
}

function BuildBadgeNameMessage( badge, badgename )
    local t = {}
    t.badge = kBadges[badge]
    t.badgename	= badgename
    return t
end

Shared.RegisterNetworkMessage( "BadgeName", kBadgeNameMessage )

local kBadgeMessage = 
{
    clientIndex = "entityid",
    badge = "enum kBadges",
    badgerow = "integer (1 to 10)"
}

function BuildBadgeMessage(clientIndex, badge, badgerow )
    local t = {}
    t.clientIndex = clientIndex
    t.badge = badge
    t.badgerow	= badgerow
    return t
end

Shared.RegisterNetworkMessage( "Badge", kBadgeMessage )

function sBadgeExists( sBadge )
    return TableContains( kBadges, sBadge )
end
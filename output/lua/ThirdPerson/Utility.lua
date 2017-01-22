
--not sure doing this has any performance impact
local dot

-- slerping between two vectors is moving one to the other along the shortest path along a sphere by rate <rate>
-- You can't slerp between two vectors by a third vector. This function is performing a Lerp on the components of
-- all three arguments if you 
function SlerpVector(current, target, rate)

    local result

    if type(rate) == "number" then
    
        dot = current:DotProduct(target)
        
        -- close enough
        if dot > 0.99999 or dot < -0.99999 then
          result = rate <= 0.5 and current or target
        else
          result = math.acos(dot)
          result = (current*math.sin((1 - rate)*result) + target*math.sin(rate*result)) / math.sin(result)
        end
        
    elseif rate:isa("Vector") then
        result = Vector()
        result.x = Slerp(current.x, target.x, rate.x)
        result.y = Slerp(current.y, target.y, rate.y)
        result.z = Slerp(current.z, target.z, rate.z)
    
    end
    
    return result

end


function SlerpRadians(current, target, rate)
    -- normalize the current and target angles to between -pi to pi
    current = math.atan2(math.sin(current), math.cos(current))
    target = math.atan2(math.sin(target), math.cos(target))
    
    -- Interpoloate the short way around
    if(target - current > math.pi) then
        target = target - 2*math.pi
    elseif(current - target > math.pi) then
        target = target + 2*math.pi
    end
   
    return Slerp(current, target, rate)

end


-- Returns radians in [-pi,pi)
function RadiansTo2PiRange(rads)

    return math.atan2(math.sin(rads), math.cos(rads))

end

-- this is actually a lerp
function SlerpAngles(current, target, rate)

    -- local result = Angles()
    
    -- result.pitch = SlerpRadians(current.pitch, target.pitch, rate)
    -- result.yaw = SlerpRadians(current.yaw, target.yaw, rate)
    -- result.roll = SlerpRadians(current.roll, target.roll, rate)
    
    return Angles.Lerp(current, target, rate)

end


function GetInstalledMapList()

    local matchingFiles = { }
    Shared.GetMatchingFileNames("maps/*.level", false, matchingFiles)
    
    local mapNames = { }
    local mapFiles = { }
    
    for _, mapFile in pairs(matchingFiles) do
    
        local _, _, filename = string.find(mapFile, "maps/(.*).level")
        local mapname = string.gsub(filename, 'ns2_', '', 1):gsub("^%l", string.upper)
        local tagged,_ = string.match(filename, "ns2_", 1)
        if tagged ~= nil then
        
            table.insert(mapNames, mapname)
            table.insert(mapFiles, {["name"] = mapname, ["fileName"] = filename})
            
        end
        
    end
    
    return mapNames, mapFiles
    
end

function GetCachedMapList()

    local matchingFiles = { }
    Shared.GetMatchingFileNames("Workshop/*/maps/*.level", false, matchingFiles)
    
    local mapNames = { }
    local mapFiles = { }
    
    for _, mapFile in pairs(matchingFiles) do
    
        local _, _, filename = string.find(mapFile, "maps/(.*).level")
        local mapname = string.gsub(filename, 'ns2_', '', 1):gsub("^%l", string.upper)
        local tagged,_ = string.match(filename, "ns2_", 1)
        if tagged ~= nil then
        
            table.insert(mapNames, mapname)
            table.insert(mapFiles, {["name"] = mapname, ["fileName"] = filename})
            
        end
        
    end
    
    return mapNames, mapFiles
    
end
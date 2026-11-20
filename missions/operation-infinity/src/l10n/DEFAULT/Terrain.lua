-- =============================================================================
-- TERRAIN VALIDATION
-- Terrain validation utilities for ground unit placement
-- =============================================================================

-- Guard against multiple script loads
if _G.TerrainLoaded then
    env.info("[Terrain] Script already loaded, skipping")
    return
end
_G.TerrainLoaded = true

Terrain = {}

Terrain.config = {
    defaultMaxSlope = 15, -- Degrees
    defaultMaxRoughness = 5, -- Meters standard deviation
    maxSearchAttempts = 20, -- Attempts to find valid position; land cover rejects most bad points cheaply
    sampleRadius = 50, -- Meters for slope sampling
    sceneryClearance = 100, -- Meters around a position that must be free of buildings and other scenery
    roadProbeDistance = 60, -- Meters from a road point to probe for the road's direction
    roadProbeDirections = 8, -- Evenly spaced probes when looking for the road's direction
}

local log = Logging:create("Terrain")

-- Loaded by TerrainData.lua, which is too large for the Lua language server to index
local TerrainData = _G.TerrainData

-- Decoded land cover mask rows, keyed by row index. Each row is a list of
-- cumulative run ends; odd runs are open ground, even runs are blocked.
local landCoverRows = {}

local function getLandCoverRow(rowIndex)
    local row = landCoverRows[rowIndex]
    if row then
        return row
    end

    row = {}
    local columnEnd = 0
    for runLength in TerrainData.rows[rowIndex]:gmatch("%d+") do
        columnEnd = columnEnd + tonumber(runLength)
        row[#row + 1] = columnEnd
    end
    landCoverRows[rowIndex] = row
    return row
end

-- Check the generated land cover mask (TerrainData.lua) for forest, water, or
-- ground off the terrain mesh. DCS scripting cannot detect forest, so this is
-- the only forest check. Positions outside the mask are not blocked.
function Terrain:isBlockedLandCover(pos)
    if not TerrainData then
        return false
    end

    local rowIndex = math.floor((TerrainData.northX - pos.x) / TerrainData.cellSize) + 1
    local column = math.floor((pos.y - TerrainData.westZ) / TerrainData.cellSize) + 1
    if rowIndex < 1 or rowIndex > #TerrainData.rows or column < 1 or column > TerrainData.columns then
        return false
    end

    -- Binary search for the first run that ends at or after this column
    local row = getLandCoverRow(rowIndex)
    local low, high = 1, #row
    while low < high do
        local middle = math.floor((low + high) / 2)
        if row[middle] >= column then
            high = middle
        else
            low = middle + 1
        end
    end
    return low % 2 == 0
end

-- Check for buildings, bridges, power line towers and other scenery objects
-- near a position. The land cover "town" class only says buildings are likely,
-- so buildings are checked here at runtime instead.
function Terrain:hasSceneryNearby(pos, radius)
    radius = radius or self.config.sceneryClearance

    local found = false
    local volume = {
        id = world.VolumeType.SPHERE,
        params = {
            point = { x = pos.x, y = land.getHeight({ x = pos.x, y = pos.y }), z = pos.y },
            radius = radius,
        },
    }
    world.searchObjects(Object.Category.SCENERY, volume, function()
        found = true
        return false
    end)
    return found
end

-- Calculate maximum slope around a position by sampling 8 points
function Terrain:calculateMaxSlope(center, sampleRadius)
    sampleRadius = sampleRadius or self.config.sampleRadius

    local centerHeight = land.getHeight({ x = center.x, y = center.y })
    local maxSlope = 0

    -- Sample 8 points around center
    for i = 0, 7 do
        local angle = i * (math.pi / 4)
        local samplePos = {
            x = center.x + sampleRadius * math.cos(angle),
            y = center.y + sampleRadius * math.sin(angle),
        }

        local ok, sampleHeight = pcall(land.getHeight, samplePos)
        if ok then
            local heightDiff = math.abs(sampleHeight - centerHeight)
            local slope = math.deg(math.atan(heightDiff / sampleRadius))
            if slope > maxSlope then
                maxSlope = slope
            end
        end
    end

    return maxSlope
end

-- Check if surface type is valid for ground units
function Terrain:isValidSurfaceType(pos)
    local ok, surfaceType = pcall(land.getSurfaceType, { x = pos.x, y = pos.y })
    if not ok then
        return false
    end

    -- Accept LAND and ROAD, reject WATER, SHALLOW_WATER
    return surfaceType == land.SurfaceType.LAND or surfaceType == land.SurfaceType.ROAD
end

-- Calculate terrain roughness using height variance
function Terrain:calculateTerrainRoughness(center, checkRadius)
    checkRadius = checkRadius or self.config.sampleRadius

    local heights = {}
    local sum = 0

    -- Sample a 5x5 grid
    for dx = -2, 2 do
        for dy = -2, 2 do
            local samplePos = {
                x = center.x + dx * (checkRadius / 2),
                y = center.y + dy * (checkRadius / 2),
            }
            local ok, h = pcall(land.getHeight, samplePos)
            if ok then
                heights[#heights + 1] = h
                sum = sum + h
            end
        end
    end

    if #heights < 5 then
        return 999 -- Return high roughness if sampling failed
    end

    -- Calculate standard deviation
    local mean = sum / #heights
    local variance = 0
    for _, h in ipairs(heights) do
        variance = variance + (h - mean) ^ 2
    end
    variance = variance / #heights

    return math.sqrt(variance)
end

-- Get distance to nearest road
function Terrain:getDistanceToNearestRoad(pos)
    local ok, roadX, roadY = pcall(land.getClosestPointOnRoads, "roads", pos.x, pos.y)
    if not ok or not roadX then
        return 999999
    end

    local dx = roadX - pos.x
    local dy = roadY - pos.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Combined terrain validation
function Terrain:isValidTerrainForUnits(center, options)
    options = options or {}
    local maxSlope = options.maxSlope or self.config.defaultMaxSlope
    local maxRoughness = options.maxRoughness or self.config.defaultMaxRoughness
    local maxRoadDistance = options.maxRoadDistance -- nil means no road requirement
    local ignoreScenery = options.ignoreScenery -- true for units placed on a road

    -- Check land cover first; it is a table lookup and rejects about half the map
    if self:isBlockedLandCover(center) then
        return false, "forest or water"
    end

    -- Check surface type
    if not self:isValidSurfaceType(center) then
        return false, "invalid surface type"
    end

    -- Check slope
    local slope = self:calculateMaxSlope(center)
    if slope > maxSlope then
        return false, "slope too steep: " .. string.format("%.1f", slope) .. " degrees"
    end

    -- Check roughness
    local roughness = self:calculateTerrainRoughness(center)
    if roughness > maxRoughness then
        return false, "terrain too rough: " .. string.format("%.1f", roughness) .. "m variance"
    end

    -- Check road proximity if required
    if maxRoadDistance then
        local roadDist = self:getDistanceToNearestRoad(center)
        if roadDist > maxRoadDistance then
            return false, "too far from road: " .. string.format("%.0f", roadDist) .. "m"
        end
    end

    -- Check buildings last; it searches the world
    if not ignoreScenery and self:hasSceneryNearby(center) then
        return false, "buildings or other scenery nearby"
    end

    return true, nil
end

-- Check a single unit's position for forest, water, and off-mesh ground.
-- Slope, roughness, and scenery are checked once at the group center.
function Terrain:isValidUnitPosition(pos)
    return not self:isBlockedLandCover(pos) and self:isValidSurfaceType(pos)
end

-- Check every unit in a list of units with x and y
function Terrain:areValidUnitPositions(units)
    for _, unit in ipairs(units) do
        if not self:isValidUnitPosition(unit) then
            return false
        end
    end
    return true
end

-- Snap a position to the nearest road, returns nil if there is no road
function Terrain:snapToRoad(pos)
    local ok, roadX, roadY = pcall(land.getClosestPointOnRoads, "roads", pos.x, pos.y)
    if not ok or not roadX then
        return nil
    end
    return { x = roadX, y = roadY }
end

-- Find a valid point on a road within radius and lay out a group there with
-- buildUnits(roadPos), which returns a list of units with x and y. Returns the
-- road point and units, or nil if no road point fits every unit. Road points
-- skip the scenery check: roads are clear of buildings, and bridges over rivers
-- are rejected by the land cover mask.
function Terrain:findRoadLayout(center, radius, buildUnits, maxAttempts)
    maxAttempts = maxAttempts or self.config.maxSearchAttempts
    local options = { ignoreScenery = true }

    for attempt = 0, maxAttempts do
        local testPos = attempt == 0 and center or Spatial:randomPointInRadius(center, radius)
        local roadPos = self:snapToRoad(testPos)
        if roadPos and self:isValidTerrainForUnits(roadPos, options) then
            local units = buildUnits(roadPos)
            if #units > 0 and self:areValidUnitPositions(units) then
                return roadPos, units
            end
        end
    end

    log(
        "WARNING: Could not find a valid road near ("
            .. math.floor(center.x)
            .. ", "
            .. math.floor(center.y)
            .. ") - skipping spawn"
    )
    return nil
end

-- Unit vector along the road at a road point, or nil if the road is too short
function Terrain:getRoadDirection(roadPos)
    local probe = self.config.roadProbeDistance
    local best, bestLength = nil, 0

    local directions = self.config.roadProbeDirections
    local startAngle = math.random() * 2 * math.pi
    for i = 1, directions do
        local angle = startAngle + i * 2 * math.pi / directions
        local snapped = self:snapToRoad({
            x = roadPos.x + probe * math.cos(angle),
            y = roadPos.y + probe * math.sin(angle),
        })
        if snapped then
            local dx, dy = snapped.x - roadPos.x, snapped.y - roadPos.y
            local length = math.sqrt(dx * dx + dy * dy)
            if length > bestLength then
                best, bestLength = { x = dx / length, y = dy / length }, length
            end
        end
    end

    -- A probe that snaps back near the start crossed the road instead of following it
    if bestLength < probe / 2 then
        return nil
    end
    return best
end

-- Positions and headings for a column of vehicles following a road from a
-- road point. Each step snaps to the road, so the column follows curves.
-- Returns fewer than count positions if the road ends.
function Terrain:getRoadColumn(start, count, spacing)
    local direction = self:getRoadDirection(start)
    if not direction then
        return {}
    end

    local column = {}
    local current = start
    for i = 1, count do
        column[i] = { x = current.x, y = current.y, heading = math.atan2(direction.y, direction.x) }
        if i == count then
            break
        end

        local nextPos = self:snapToRoad({
            x = current.x + direction.x * spacing,
            y = current.y + direction.y * spacing,
        })
        if not nextPos then
            break
        end
        local dx, dy = nextPos.x - current.x, nextPos.y - current.y
        local length = math.sqrt(dx * dx + dy * dy)
        if length < spacing / 2 then
            break -- Road ended or turned back
        end
        direction = { x = dx / length, y = dy / length }
        current = nextPos
    end
    return column
end

-- Search center, then random points within radius, for a position that
-- passes isValidTerrainForUnits and accept(pos). accept returns a value to
-- keep, or nil to reject the position.
local function searchPositions(center, radius, options, maxAttempts, accept)
    for attempt = 0, maxAttempts do
        local testPos = attempt == 0 and center or Spatial:randomPointInRadius(center, radius)
        if Terrain:isValidTerrainForUnits(testPos, options) then
            local accepted = accept(testPos)
            if accepted then
                return testPos, accepted
            end
        end
    end

    log(
        "WARNING: Could not find valid terrain near ("
            .. math.floor(center.x)
            .. ", "
            .. math.floor(center.y)
            .. ") - skipping spawn"
    )
    return nil
end

-- Find a valid position within radius, returns nil if none found
function Terrain:findValidPosition(center, radius, options, maxAttempts)
    local pos = searchPositions(center, radius, options or {}, maxAttempts or self.config.maxSearchAttempts, function()
        return true
    end)
    return pos, pos ~= nil
end

-- Find a valid position within radius and lay out a group there with
-- buildUnits(pos), which returns a list of units with x and y. The group
-- center gets the full isValidTerrainForUnits check and every unit gets
-- isValidUnitPosition, so spread-out groups such as SAM sites do not put
-- units in forest or water. Returns the position and units, or nil.
function Terrain:findValidLayout(center, radius, buildUnits, options, maxAttempts)
    return searchPositions(center, radius, options or {}, maxAttempts or self.config.maxSearchAttempts, function(pos)
        local units = buildUnits(pos)
        if self:areValidUnitPositions(units) then
            return units
        end
        return nil
    end)
end

if TerrainData then
    log("Land cover mask: " .. TerrainData.theatre .. ", " .. #TerrainData.rows .. " rows")
else
    log("WARNING: TerrainData not loaded, land cover checks disabled")
end

env.info("[Terrain] Loaded successfully")

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
    defaultMaxSlope = 15,       -- Degrees
    defaultMaxRoughness = 5,    -- Meters standard deviation
    maxSearchAttempts = 10,     -- Attempts to find valid position
    sampleRadius = 50,          -- Meters for slope sampling
}

function Terrain:log(message)
    env.info("[Terrain] " .. message)
end

-- Generate a random point within a given radius of a center point
function Terrain:randomPointInRadius(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    return {
        x = center.x + distance * math.cos(angle),
        y = center.y + distance * math.sin(angle),
    }
end

-- Calculate maximum slope around a position by sampling 8 points
function Terrain:calculateMaxSlope(center, sampleRadius)
    sampleRadius = sampleRadius or self.config.sampleRadius

    local centerHeight = land.getHeight({x = center.x, y = center.y})
    local maxSlope = 0

    -- Sample 8 points around center
    for i = 0, 7 do
        local angle = i * (math.pi / 4)
        local samplePos = {
            x = center.x + sampleRadius * math.cos(angle),
            y = center.y + sampleRadius * math.sin(angle)
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
    local ok, surfaceType = pcall(land.getSurfaceType, {x = pos.x, y = pos.y})
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
                y = center.y + dy * (checkRadius / 2)
            }
            local ok, h = pcall(land.getHeight, samplePos)
            if ok then
                table.insert(heights, h)
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

    return true, nil
end

-- Find a valid position within radius, returns nil if none found
function Terrain:findValidPosition(center, radius, options, maxAttempts)
    maxAttempts = maxAttempts or self.config.maxSearchAttempts
    options = options or {}

    -- First, check if center itself is valid
    local valid, reason = self:isValidTerrainForUnits(center, options)
    if valid then
        return center, true
    end

    -- Try random positions
    for attempt = 1, maxAttempts do
        local testPos = self:randomPointInRadius(center, radius)
        valid, reason = self:isValidTerrainForUnits(testPos, options)
        if valid then
            return testPos, true
        end
    end

    -- Try with relaxed thresholds (50% higher limits)
    local relaxedOptions = {
        maxSlope = (options.maxSlope or self.config.defaultMaxSlope) * 1.5,
        maxRoughness = (options.maxRoughness or self.config.defaultMaxRoughness) * 1.5,
        maxRoadDistance = options.maxRoadDistance and (options.maxRoadDistance * 1.5) or nil,
    }

    for attempt = 1, math.floor(maxAttempts / 2) do
        local testPos = self:randomPointInRadius(center, radius)
        valid, reason = self:isValidTerrainForUnits(testPos, relaxedOptions)
        if valid then
            self:log("Used relaxed terrain thresholds for position near (" ..
                math.floor(center.x) .. ", " .. math.floor(center.y) .. ")")
            return testPos, true
        end
    end

    -- Failed to find valid position
    self:log("WARNING: Could not find valid terrain near (" ..
        math.floor(center.x) .. ", " .. math.floor(center.y) .. ") - skipping spawn")
    return nil, false
end

env.info("[Terrain] Loaded successfully")

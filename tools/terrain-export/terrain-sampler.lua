-- =============================================================================
-- TERRAIN SAMPLER
-- Exports terrain and airport data from DCS World to JSON for external processing
-- Requires desanitized MissionScripting.lua for io/lfs access
-- =============================================================================

TerrainSampler = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

TerrainSampler.config = {
    -- Grid resolution in meters (5km default)
    gridResolution = 5000,

    -- Road sampling resolution (coarser than terrain grid)
    roadGridResolution = 10000,

    -- Maximum road path search distance (meters)
    maxRoadSearchDistance = 50000,

    -- Maximum road path samples to collect (performance limit)
    maxRoadSegments = 500,

    -- Output file path (relative to lfs.writedir())
    outputPath = "TerrainExport/",

    -- Debug logging
    debug = true,

    -- Theatre-specific bounds (approximate, in game coordinates)
    -- x = East-West, z = North-South
    theatreBounds = {
        ["Caucasus"] = {
            minX = -400000, maxX = 100000,
            minZ = 200000, maxZ = 900000,
        },
        ["Syria"] = {
            minX = -400000, maxX = 200000,
            minZ = -400000, maxZ = 400000,
        },
        ["Nevada"] = {
            minX = -450000, maxX = 150000,
            minZ = -450000, maxZ = 150000,
        },
        ["PersianGulf"] = {
            minX = -200000, maxX = 300000,
            minZ = -400000, maxZ = 200000,
        },
        ["MarianaIslands"] = {
            minX = -300000, maxX = 300000,
            minZ = -300000, maxZ = 300000,
        },
        ["Falklands"] = {
            minX = -400000, maxX = 200000,
            minZ = -400000, maxZ = 200000,
        },
        ["Sinai"] = {
            minX = -300000, maxX = 300000,
            minZ = -300000, maxZ = 300000,
        },
        ["Kola"] = {
            minX = -400000, maxX = 200000,
            minZ = -200000, maxZ = 600000,
        },
        ["Afghanistan"] = {
            minX = -300000, maxX = 300000,
            minZ = -300000, maxZ = 300000,
        },
    },
}

-- =============================================================================
-- STATE
-- =============================================================================

TerrainSampler.state = {
    sampleCount = 0,
    roadPointCount = 0,
    airbaseCount = 0,
}

-- =============================================================================
-- UTILITIES
-- =============================================================================

function TerrainSampler:log(message)
    if self.config.debug then
        env.info("[TerrainSampler] " .. message)
    end
end

function TerrainSampler:getBounds()
    local theatre = env.mission.theatre
    local bounds = self.config.theatreBounds[theatre]

    if bounds then
        return bounds
    end

    -- Fallback for unknown theatres
    self:log("WARNING: Unknown theatre '" .. tostring(theatre) .. "', using default bounds")
    return {
        minX = -500000, maxX = 500000,
        minZ = -500000, maxZ = 500000,
    }
end

-- Simple JSON encoder for Lua tables
-- Handles: tables (arrays/objects), strings, numbers, booleans, nil
function TerrainSampler:encodeJSON(data)
    local function encode(val)
        local t = type(val)

        if t == "nil" then
            return "null"
        elseif t == "boolean" then
            return val and "true" or "false"
        elseif t == "number" then
            if val ~= val then return "null" end  -- NaN
            if val == math.huge then return "1e308" end
            if val == -math.huge then return "-1e308" end
            -- Use integer format for whole numbers, float otherwise
            if val == math.floor(val) and math.abs(val) < 1e15 then
                return string.format("%.0f", val)
            else
                return string.format("%.6f", val)
            end
        elseif t == "string" then
            local escaped = val:gsub('\\', '\\\\')
                              :gsub('"', '\\"')
                              :gsub('\n', '\\n')
                              :gsub('\r', '\\r')
                              :gsub('\t', '\\t')
            return '"' .. escaped .. '"'
        elseif t == "table" then
            -- Check if array (sequential integer keys starting at 1)
            local isArray = true
            local maxIndex = 0
            for k, _ in pairs(val) do
                if type(k) ~= "number" or k ~= math.floor(k) or k < 1 then
                    isArray = false
                    break
                end
                maxIndex = math.max(maxIndex, k)
            end
            if isArray and maxIndex > 0 then
                for i = 1, maxIndex do
                    if val[i] == nil then
                        isArray = false
                        break
                    end
                end
            end

            local parts = {}
            if isArray and maxIndex > 0 then
                for i = 1, maxIndex do
                    table.insert(parts, encode(val[i]))
                end
                return "[" .. table.concat(parts, ",") .. "]"
            else
                for k, v in pairs(val) do
                    local key = type(k) == "string" and k or tostring(k)
                    table.insert(parts, '"' .. key .. '":' .. encode(v))
                end
                return "{" .. table.concat(parts, ",") .. "}"
            end
        else
            return "null"
        end
    end

    return encode(data)
end

-- =============================================================================
-- TERRAIN SAMPLING
-- =============================================================================

function TerrainSampler:sampleGrid()
    self:log("Starting grid sampling...")

    local bounds = self:getBounds()
    local resolution = self.config.gridResolution
    local samples = {}

    local totalX = math.floor((bounds.maxX - bounds.minX) / resolution) + 1
    local totalZ = math.floor((bounds.maxZ - bounds.minZ) / resolution) + 1
    local totalSamples = totalX * totalZ
    self:log("Expected samples: " .. totalSamples .. " (" .. totalX .. " x " .. totalZ .. ")")

    local count = 0
    for xCoord = bounds.minX, bounds.maxX, resolution do
        for zCoord = bounds.minZ, bounds.maxZ, resolution do
            local point = {x = xCoord, y = zCoord}
            local height = land.getHeight(point)
            local surfaceType = land.getSurfaceType(point)

            -- Convert to lat/lon for human reference (x, y, z where y is altitude)
            local lat, lon, alt = coord.LOtoLL(xCoord, height, zCoord)

            table.insert(samples, {
                x = xCoord,
                z = zCoord,
                height = height,
                surface = surfaceType,
                lat = lat,
                lon = lon,
            })

            count = count + 1

            if count % 5000 == 0 then
                self:log("Sampled " .. count .. "/" .. totalSamples .. " points...")
            end
        end
    end

    self.state.sampleCount = count
    self:log("Grid sampling complete: " .. count .. " samples")
    return samples
end

-- =============================================================================
-- ROAD SAMPLING
-- =============================================================================

function TerrainSampler:sampleRoads()
    self:log("Starting road network sampling...")

    local bounds = self:getBounds()
    local resolution = self.config.roadGridResolution
    local roadPoints = {}
    local roadSegments = {}

    -- Sample road points from grid
    for x = bounds.minX, bounds.maxX, resolution do
        for z = bounds.minZ, bounds.maxZ, resolution do
            local roadX, roadZ = land.getClosestPointOnRoads("roads", x, z)

            if roadX and roadZ then
                local dist = math.sqrt((roadX - x)^2 + (roadZ - z)^2)

                -- Only include if reasonably close to our sample point
                if dist < resolution * 0.75 then
                    local height = land.getHeight({x = roadX, y = roadZ})
                    local lat, lon = coord.LOtoLL(roadX, height, roadZ)

                    table.insert(roadPoints, {
                        x = roadX,
                        z = roadZ,
                        height = height,
                        lat = lat,
                        lon = lon,
                    })
                end
            end
        end
    end

    self:log("Found " .. #roadPoints .. " road sample points")
    self.state.roadPointCount = #roadPoints

    -- Sample paths between nearby road points to build connectivity
    local segmentCount = 0

    for i = 1, math.min(#roadPoints, self.config.maxRoadSegments) do
        local p1 = roadPoints[i]

        -- Check connectivity to nearby points
        for j = i + 1, math.min(i + 8, #roadPoints) do
            local p2 = roadPoints[j]
            local directDist = math.sqrt((p1.x - p2.x)^2 + (p1.z - p2.z)^2)

            if directDist < self.config.maxRoadSearchDistance then
                local path = land.findPathOnRoads("roads", p1.x, p1.z, p2.x, p2.z)

                if path and #path > 0 then
                    table.insert(roadSegments, {
                        from = {x = p1.x, z = p1.z},
                        to = {x = p2.x, z = p2.z},
                        pathLength = #path,
                        directDistance = directDist,
                    })
                    segmentCount = segmentCount + 1

                    if segmentCount >= self.config.maxRoadSegments then
                        break
                    end
                end
            end
        end

        if segmentCount >= self.config.maxRoadSegments then
            break
        end
    end

    self:log("Road sampling complete: " .. segmentCount .. " segments")

    return {
        points = roadPoints,
        segments = roadSegments,
    }
end

-- =============================================================================
-- AIRBASE COLLECTION
-- =============================================================================

function TerrainSampler:collectAirbases()
    self:log("Collecting airbase data...")

    local airbases = {}

    -- Get all airbases from world
    local allAirbases = world.getAirbases()

    for _, airbase in ipairs(allAirbases or {}) do
        if airbase and airbase:isExist() then
            local name = airbase:getName()
            local callsign = airbase:getCallsign()
            local pos = airbase:getPoint()
            local lat, lon, alt = coord.LOtoLL(pos.x, pos.y, pos.z)

            -- Get category from description
            local desc = airbase:getDesc()
            local category = desc and desc.category or -1

            -- Get parking spots
            local parkingSpots = {}
            local parkingData = airbase:getParking()
            if parkingData then
                for _, spot in ipairs(parkingData) do
                    local spotLat, spotLon
                    if spot.vTerminalPos then
                        spotLat, spotLon = coord.LOtoLL(
                            spot.vTerminalPos.x,
                            spot.vTerminalPos.y or 0,
                            spot.vTerminalPos.z
                        )
                    end

                    table.insert(parkingSpots, {
                        Term_Index = spot.Term_Index,
                        Term_Type = spot.Term_Type,
                        fDistToRW = spot.fDistToRW,
                        x = spot.vTerminalPos and spot.vTerminalPos.x or nil,
                        y = spot.vTerminalPos and spot.vTerminalPos.y or nil,
                        z = spot.vTerminalPos and spot.vTerminalPos.z or nil,
                        lat = spotLat,
                        lon = spotLon,
                    })
                end
            end

            -- Get runways
            local runways = {}
            local runwayData = airbase:getRunways()
            if runwayData then
                for _, rwy in ipairs(runwayData) do
                    table.insert(runways, {
                        heading = rwy.course,
                        length = rwy.length,
                        width = rwy.width,
                        x = rwy.position and rwy.position.x or nil,
                        z = rwy.position and rwy.position.z or nil,
                    })
                end
            end

            table.insert(airbases, {
                name = name,
                callsign = callsign,
                x = pos.x,
                z = pos.z,
                height = pos.y,
                lat = lat,
                lon = lon,
                category = category,
                parking = parkingSpots,
                runways = runways,
            })
        end
    end

    self.state.airbaseCount = #airbases
    self:log("Found " .. #airbases .. " airbases")
    return airbases
end

-- =============================================================================
-- EXPORT
-- =============================================================================

function TerrainSampler:export()
    self:log("Beginning terrain export...")

    local theatre = env.mission.theatre or "Unknown"
    self:log("Theatre: " .. theatre)

    local bounds = self:getBounds()
    self:log("Bounds: x=" .. bounds.minX .. " to " .. bounds.maxX ..
             ", z=" .. bounds.minZ .. " to " .. bounds.maxZ)

    -- Collect all data
    local gridSamples = self:sampleGrid()
    local roadData = self:sampleRoads()
    local airbases = self:collectAirbases()

    -- Build export structure
    local exportData = {
        metadata = {
            theatre = theatre,
            exportTime = os.date("!%Y-%m-%dT%H:%M:%SZ"),
            gridResolution = self.config.gridResolution,
            bounds = bounds,
            stats = {
                terrainSamples = self.state.sampleCount,
                roadPoints = self.state.roadPointCount,
                airbases = self.state.airbaseCount,
            },
        },
        terrain = gridSamples,
        roads = roadData,
        airbases = airbases,
    }

    -- Write to file
    local outputDir = lfs.writedir() .. self.config.outputPath
    local success, err = lfs.mkdir(outputDir)
    if not success and err ~= "File exists" then
        self:log("Note: mkdir result - " .. tostring(err))
    end

    local filename = outputDir .. theatre:lower():gsub(" ", "-") .. "-terrain.json"
    local file = io.open(filename, "w")

    if file then
        self:log("Writing JSON to: " .. filename)
        local json = self:encodeJSON(exportData)
        file:write(json)
        file:close()
        self:log("Export complete: " .. filename)
        self:log("Stats: " .. self.state.sampleCount .. " terrain samples, " ..
                 self.state.roadPointCount .. " road points, " ..
                 self.state.airbaseCount .. " airbases")
        trigger.action.outText("Terrain export complete!\n" .. filename, 30)
    else
        self:log("ERROR: Could not open file for writing: " .. filename)
        trigger.action.outText("ERROR: Terrain export failed - check logs", 30)
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Run export immediately (mission trigger handles timing)
local status, err = pcall(function()
    TerrainSampler:export()
end)
if not status then
    env.error("[TerrainSampler] Export failed: " .. tostring(err))
    trigger.action.outText("ERROR: Terrain export failed - " .. tostring(err), 30)
end

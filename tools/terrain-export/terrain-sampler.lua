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

    -- Progress update intervals
    gridProgressInterval = 2500,    -- Show progress every N terrain samples
    roadProgressInterval = 100,     -- Show progress every N road points

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
    startTime = nil,
    phaseStartTime = nil,
}

-- =============================================================================
-- UTILITIES
-- =============================================================================

function TerrainSampler:log(message)
    if self.config.debug then
        env.info("[TerrainSampler] " .. message)
    end
end

function TerrainSampler:logError(message)
    env.error("[TerrainSampler] " .. message)
end

function TerrainSampler:logWarning(message)
    env.warning("[TerrainSampler] " .. message)
end

function TerrainSampler:showMessage(message, duration)
    duration = duration or 10
    trigger.action.outText("[Terrain Export] " .. message, duration)
    self:log(message)
end

function TerrainSampler:showProgress(message)
    -- Short duration for progress updates so they don't stack up
    trigger.action.outText("[Terrain Export] " .. message, 5)
    self:log(message)
end

function TerrainSampler:getElapsedTime()
    if self.state.startTime then
        return os.time() - self.state.startTime
    end
    return 0
end

function TerrainSampler:getPhaseElapsedTime()
    if self.state.phaseStartTime then
        return os.time() - self.state.phaseStartTime
    end
    return 0
end

function TerrainSampler:formatTime(seconds)
    if seconds < 60 then
        return string.format("%ds", seconds)
    elseif seconds < 3600 then
        return string.format("%dm %ds", math.floor(seconds / 60), seconds % 60)
    else
        return string.format("%dh %dm", math.floor(seconds / 3600), math.floor((seconds % 3600) / 60))
    end
end

function TerrainSampler:startPhase(phaseName)
    self.state.phaseStartTime = os.time()
    self:showMessage("Starting phase: " .. phaseName, 8)
end

function TerrainSampler:endPhase(phaseName, details)
    local elapsed = self:getPhaseElapsedTime()
    local msg = "Completed: " .. phaseName .. " (" .. self:formatTime(elapsed) .. ")"
    if details then
        msg = msg .. " - " .. details
    end
    self:showMessage(msg, 10)
end

function TerrainSampler:getBounds()
    local theatre = env.mission.theatre
    local bounds = self.config.theatreBounds[theatre]

    if bounds then
        self:log("Using predefined bounds for theatre: " .. theatre)
        return bounds
    end

    -- Fallback for unknown theatres
    self:logWarning("Unknown theatre '" .. tostring(theatre) .. "', using default bounds")
    self:showMessage("WARNING: Unknown theatre, using default bounds", 15)
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
    self:startPhase("Terrain Grid Sampling")

    local bounds = self:getBounds()
    local resolution = self.config.gridResolution
    local samples = {}

    local totalX = math.floor((bounds.maxX - bounds.minX) / resolution) + 1
    local totalZ = math.floor((bounds.maxZ - bounds.minZ) / resolution) + 1
    local totalSamples = totalX * totalZ

    self:log("Grid dimensions: " .. totalX .. " x " .. totalZ .. " = " .. totalSamples .. " samples")
    self:log("Resolution: " .. resolution .. " meters")
    self:showMessage("Sampling " .. totalSamples .. " terrain points at " .. (resolution/1000) .. "km resolution...", 15)

    local count = 0
    local lastProgressUpdate = 0

    for xCoord = bounds.minX, bounds.maxX, resolution do
        for zCoord = bounds.minZ, bounds.maxZ, resolution do
            local point = {x = xCoord, z = zCoord}
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

            -- Progress updates
            if count - lastProgressUpdate >= self.config.gridProgressInterval then
                local percent = math.floor((count / totalSamples) * 100)
                self:showProgress("Terrain: " .. count .. "/" .. totalSamples .. " (" .. percent .. "%)")
                lastProgressUpdate = count
            end
        end
    end

    self.state.sampleCount = count
    self:endPhase("Terrain Grid Sampling", count .. " samples collected")
    return samples
end

-- =============================================================================
-- ROAD SAMPLING
-- =============================================================================

function TerrainSampler:sampleRoads()
    self:startPhase("Road Network Sampling")

    local bounds = self:getBounds()
    local resolution = self.config.roadGridResolution
    local roadPoints = {}
    local roadSegments = {}

    local totalX = math.floor((bounds.maxX - bounds.minX) / resolution) + 1
    local totalZ = math.floor((bounds.maxZ - bounds.minZ) / resolution) + 1
    local totalGridPoints = totalX * totalZ

    self:showMessage("Scanning " .. totalGridPoints .. " grid points for roads...", 10)
    self:log("Road grid resolution: " .. resolution .. " meters")

    local gridPointsChecked = 0
    local lastProgressUpdate = 0

    -- Sample road points from grid
    for x = bounds.minX, bounds.maxX, resolution do
        for z = bounds.minZ, bounds.maxZ, resolution do
            gridPointsChecked = gridPointsChecked + 1

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

            -- Progress updates
            if gridPointsChecked - lastProgressUpdate >= self.config.roadProgressInterval then
                local percent = math.floor((gridPointsChecked / totalGridPoints) * 100)
                self:showProgress("Road scan: " .. gridPointsChecked .. "/" .. totalGridPoints .. " (" .. percent .. "%) - " .. #roadPoints .. " points found")
                lastProgressUpdate = gridPointsChecked
            end
        end
    end

    self:log("Found " .. #roadPoints .. " road sample points")
    self:showMessage("Found " .. #roadPoints .. " road points. Building connectivity...", 10)

    -- Sample paths between nearby road points to build connectivity
    local segmentCount = 0
    local segmentChecks = 0
    local maxSegments = self.config.maxRoadSegments

    for i = 1, math.min(#roadPoints, maxSegments) do
        local p1 = roadPoints[i]

        -- Check connectivity to nearby points
        for j = i + 1, math.min(i + 8, #roadPoints) do
            local p2 = roadPoints[j]
            local directDist = math.sqrt((p1.x - p2.x)^2 + (p1.z - p2.z)^2)

            if directDist < self.config.maxRoadSearchDistance then
                segmentChecks = segmentChecks + 1
                local path = land.findPathOnRoads("roads", p1.x, p1.z, p2.x, p2.z)

                if path and #path > 0 then
                    table.insert(roadSegments, {
                        from = {x = p1.x, z = p1.z},
                        to = {x = p2.x, z = p2.z},
                        pathLength = #path,
                        directDistance = directDist,
                    })
                    segmentCount = segmentCount + 1

                    if segmentCount >= maxSegments then
                        self:log("Reached max road segments limit: " .. maxSegments)
                        break
                    end
                end
            end
        end

        if segmentCount >= maxSegments then
            break
        end

        -- Periodic progress for segment building
        if i % 50 == 0 then
            self:showProgress("Road connectivity: " .. segmentCount .. " segments from " .. i .. " points checked")
        end
    end

    self.state.roadPointCount = #roadPoints
    self:endPhase("Road Network Sampling", #roadPoints .. " points, " .. segmentCount .. " segments")

    return {
        points = roadPoints,
        segments = roadSegments,
    }
end

-- =============================================================================
-- AIRBASE COLLECTION
-- =============================================================================

function TerrainSampler:collectAirbases()
    self:startPhase("Airbase Collection")

    local airbases = {}

    -- Get all airbases from world
    local allAirbases = world.getAirbases()
    local totalAirbases = allAirbases and #allAirbases or 0

    self:showMessage("Processing " .. totalAirbases .. " airbases...", 10)

    for idx, airbase in ipairs(allAirbases or {}) do
        if airbase and airbase:isExist() then
            local name = airbase:getName()
            local callsign = airbase:getCallsign()
            local pos = airbase:getPoint()
            local lat, lon, alt = coord.LOtoLL(pos.x, pos.y, pos.z)

            -- Get category from description
            local desc = airbase:getDesc()
            local category = desc and desc.category or -1

            self:log("Processing airbase " .. idx .. "/" .. totalAirbases .. ": " .. tostring(name))

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

            self:log("  - " .. #parkingSpots .. " parking spots, " .. #runways .. " runways")
        end
    end

    self.state.airbaseCount = #airbases
    self:endPhase("Airbase Collection", #airbases .. " airbases with parking/runway data")
    return airbases
end

-- =============================================================================
-- EXPORT
-- =============================================================================

function TerrainSampler:export()
    self.state.startTime = os.time()

    self:showMessage("=== TERRAIN EXPORT STARTING ===", 15)
    self:log("========================================")
    self:log("TERRAIN EXPORT STARTING")
    self:log("========================================")

    local theatre = env.mission.theatre or "Unknown"
    self:showMessage("Theatre: " .. theatre, 10)
    self:log("Theatre: " .. theatre)

    -- Verify required APIs are available
    self:log("Verifying API availability...")
    if not io then
        self:logError("io library not available - MissionScripting.lua needs to be desanitized")
        self:showMessage("ERROR: io library not available!\nPlease desanitize MissionScripting.lua", 30)
        return
    end
    if not lfs then
        self:logError("lfs library not available - MissionScripting.lua needs to be desanitized")
        self:showMessage("ERROR: lfs library not available!\nPlease desanitize MissionScripting.lua", 30)
        return
    end
    self:log("API check passed: io and lfs available")
    self:showMessage("API check passed", 5)

    local bounds = self:getBounds()
    self:log("Bounds: x=" .. bounds.minX .. " to " .. bounds.maxX ..
             ", z=" .. bounds.minZ .. " to " .. bounds.maxZ)

    local boundsWidth = (bounds.maxX - bounds.minX) / 1000
    local boundsHeight = (bounds.maxZ - bounds.minZ) / 1000
    self:showMessage("Export area: " .. boundsWidth .. "km x " .. boundsHeight .. "km", 10)

    -- Collect all data
    self:showMessage("Phase 1/3: Terrain sampling...", 10)
    local gridSamples = self:sampleGrid()

    self:showMessage("Phase 2/3: Road network sampling...", 10)
    local roadData = self:sampleRoads()

    self:showMessage("Phase 3/3: Airbase collection...", 10)
    local airbases = self:collectAirbases()

    -- Build export structure
    self:showMessage("Building export data structure...", 10)
    self:log("Building export data structure...")

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
    self:showMessage("Writing JSON output file...", 10)
    local outputDir = lfs.writedir() .. self.config.outputPath
    self:log("Output directory: " .. outputDir)

    local success, err = lfs.mkdir(outputDir)
    if not success and err ~= "File exists" then
        self:log("mkdir result: " .. tostring(err))
    else
        self:log("Output directory ready")
    end

    local filename = outputDir .. theatre:lower():gsub(" ", "-") .. "-terrain.json"
    self:log("Output filename: " .. filename)

    local file = io.open(filename, "w")

    if file then
        self:showMessage("Encoding JSON (this may take a moment)...", 15)
        self:log("Encoding JSON...")

        local jsonStartTime = os.time()
        local json = self:encodeJSON(exportData)
        local jsonTime = os.time() - jsonStartTime

        self:log("JSON encoding completed in " .. self:formatTime(jsonTime))
        self:log("JSON size: " .. #json .. " bytes (" .. math.floor(#json / 1024) .. " KB)")

        self:showMessage("Writing " .. math.floor(#json / 1024) .. " KB to disk...", 10)
        file:write(json)
        file:close()

        local totalTime = self:getElapsedTime()

        self:log("========================================")
        self:log("EXPORT COMPLETE")
        self:log("========================================")
        self:log("File: " .. filename)
        self:log("Size: " .. #json .. " bytes")
        self:log("Total time: " .. self:formatTime(totalTime))
        self:log("Stats:")
        self:log("  - Terrain samples: " .. self.state.sampleCount)
        self:log("  - Road points: " .. self.state.roadPointCount)
        self:log("  - Airbases: " .. self.state.airbaseCount)

        local summaryMsg = string.format(
            "=== EXPORT COMPLETE ===\n" ..
            "Theatre: %s\n" ..
            "File: %s\n" ..
            "Size: %d KB\n" ..
            "Time: %s\n" ..
            "---\n" ..
            "Terrain samples: %d\n" ..
            "Road points: %d\n" ..
            "Airbases: %d",
            theatre,
            filename,
            math.floor(#json / 1024),
            self:formatTime(totalTime),
            self.state.sampleCount,
            self.state.roadPointCount,
            self.state.airbaseCount
        )
        trigger.action.outText(summaryMsg, 60)
    else
        self:logError("Could not open file for writing: " .. filename)
        self:showMessage("ERROR: Could not write to file!\n" .. filename .. "\nCheck permissions and disk space.", 30)
    end
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

-- Show startup message
trigger.action.outText("[Terrain Export] Script loaded. Export will begin shortly...", 10)
env.info("[TerrainSampler] Script loaded, preparing to export...")

-- Run export immediately (mission trigger handles timing)
local status, err = pcall(function()
    TerrainSampler:export()
end)

if not status then
    env.error("[TerrainSampler] Export failed with error: " .. tostring(err))
    trigger.action.outText(
        "=== TERRAIN EXPORT FAILED ===\n" ..
        "Error: " .. tostring(err) .. "\n\n" ..
        "Check DCS.log for details.\n" ..
        "Common issues:\n" ..
        "- MissionScripting.lua not desanitized\n" ..
        "- Invalid theatre bounds\n" ..
        "- Disk full or permission denied",
        60
    )
end

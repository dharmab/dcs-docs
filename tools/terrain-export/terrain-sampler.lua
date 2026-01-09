-- =============================================================================
-- TERRAIN SAMPLER
-- Exports terrain and airport data from DCS World to JSON for external processing
-- Requires desanitized MissionScripting.lua for io/lfs access
-- =============================================================================

TerrainSampler = {}
TerrainSampler.VERSION = "1.2.0-debug"


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
    maxRoadSegments = 2000,

    -- Output file path (relative to lfs.writedir())
    outputPath = "TerrainExport/",

    -- === QUICK TEST CONFIGURATION ===
    -- To run a fast, small-area test, uncomment and adjust the following:
    -- theatreBounds = {
    --     ["Caucasus"] = {
    --         minX = -10000, maxX = 10000,
    --         minZ = 200000, maxZ = 220000,
    --     },
    -- },
    -- detectBounds = false, -- Use the above bounds instead of dynamic detection
    -- Debug logging
    debug = true,

    -- Enable dynamic bounds detection (recommended for unknown terrains)
    detectBounds = true,
    detectStepSize = 10000,      -- meters per step when searching for bounds
    detectMaxDistance = 1000000, -- max distance from origin to search (meters)
    detectFlatThreshold = 3,     -- how many consecutive flat heights to consider as "flat" (out of bounds)
    detectMinArea = 200000,      -- minimum area (meters) to always include (e.g. 200km)

    -- Progress update intervals
    gridProgressInterval = 2500,          -- Show progress every N terrain samples
    roadProgressInterval = 100,           -- Show progress every N road points
    connectivityProgressInterval = 50,    -- Show progress every N road points checked for connectivity

    -- Road sampling thresholds
    roadProximityFactor = 0.75,           -- Maximum distance to road as fraction of grid resolution
    roadNeighborCount = 8,                -- Number of neighboring road points to check for connectivity

    -- Chunked sampling/throttling for DCS scripting safety
    maxSamplesPerChunk = 250, -- Maximum samples per scheduled chunk
    maxChunkTime = 0.05,      -- Maximum wall clock time (seconds) per chunk

    -- Theatre-specific bounds (approximate, in game coordinates)
    -- x = East-West, z = North-South
    theatreBounds = {
        ["Caucasus"] = {
            minX = -400000,
            maxX = 100000,
            minZ = 200000,
            maxZ = 900000,
        },
        ["Syria"] = {
            minX = -400000,
            maxX = 200000,
            minZ = -400000,
            maxZ = 400000,
        },
        ["Nevada"] = {
            minX = -450000,
            maxX = 150000,
            minZ = -450000,
            maxZ = 150000,
        },
        ["PersianGulf"] = {
            minX = -200000,
            maxX = 300000,
            minZ = -400000,
            maxZ = 200000,
        },
        ["MarianaIslands"] = {
            minX = -300000,
            maxX = 300000,
            minZ = -300000,
            maxZ = 300000,
        },
        ["Falklands"] = {
            minX = -400000,
            maxX = 200000,
            minZ = -400000,
            maxZ = 200000,
        },
        ["Sinai"] = {
            minX = -300000,
            maxX = 300000,
            minZ = -300000,
            maxZ = 300000,
        },
        ["Kola"] = {
            minX = -400000,
            maxX = 200000,
            minZ = -200000,
            maxZ = 600000,
        },
        ["Afghanistan"] = {
            minX = -300000,
            maxX = 300000,
            minZ = -300000,
            maxZ = 300000,
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

function TerrainSampler:log(msg)
    if self.config.debug then
        env.info("[TerrainSampler] " .. tostring(msg))
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

    self:logWarning("Unknown theatre '" .. tostring(theatre) .. "', using default bounds")
    self:showMessage("WARNING: Unknown theatre, using default bounds", 15)
    return {
        minX = -500000,
        maxX = 500000,
        minZ = -500000,
        maxZ = 500000,
    }
end

-- =============================================================================
-- DYNAMIC BOUNDS DETECTION METHOD (moved out of getBounds)
-- =============================================================================

function TerrainSampler:detectBoundsFromOrigin(stepSize, maxDistance, flatThreshold, minArea)
    -- Returns {minX, maxX, minZ, maxZ} for valid terrain area
    stepSize = stepSize or 10000
    maxDistance = maxDistance or 1000000
    flatThreshold = flatThreshold or 3
    minArea = minArea or 200000

    local origin = { x = 0, y = 0 }
    local directions = {
        { name = "East",  dx = 1,  dz = 0 },
        { name = "West",  dx = -1, dz = 0 },
        { name = "North", dx = 0,  dz = 1 },
        { name = "South", dx = 0,  dz = -1 },
    }
    local bounds = { minX = 0, maxX = 0, minZ = 0, maxZ = 0 }
    local minSteps = math.floor((minArea / 2) / stepSize)

    local function getHeightSafe(x, z)
        if not land or type(land.getHeight) ~= "function" then return nil end
        local ok, h = pcall(function() return land.getHeight({ x = x, y = z }) end)
        if ok and type(h) == "number" then return h end
        return nil
    end

    for _, dir in ipairs(directions) do
        local lastValid = 0
        local flatCount = 0
        local reason = "maxDistance"
        for step = 1, math.floor(maxDistance / stepSize) do
            local x = origin.x + dir.dx * step * stepSize
            local z = origin.y + dir.dz * step * stepSize
            local h = getHeightSafe(x, z)
            if h == nil then
                flatCount = flatCount + 1
                if flatCount >= flatThreshold and step > minSteps then
                    reason = "flat"
                    break
                end
            else
                flatCount = 0
                lastValid = step
            end
        end
        local dist = lastValid * stepSize
        if dir.name == "East" then
            bounds.maxX = origin.x + dist
            self:log(string.format("Detected East bound at x=%.0f (%s after %d steps)", bounds.maxX, reason,
                lastValid))
        elseif dir.name == "West" then
            bounds.minX = origin.x - dist
            self:log(string.format("Detected West bound at x=%.0f (%s after %d steps)", bounds.minX, reason,
                lastValid))
        elseif dir.name == "North" then
            bounds.maxZ = origin.y + dist
            self:log(string.format("Detected North bound at z=%.0f (%s after %d steps)", bounds.maxZ, reason,
                lastValid))
        elseif dir.name == "South" then
            bounds.minZ = origin.y - dist
            self:log(string.format("Detected South bound at z=%.0f (%s after %d steps)", bounds.minZ, reason,
                lastValid))
        end
    end
    self:log(string.format("Dynamic bounds: x=%.0f to %.0f, z=%.0f to %.0f", bounds.minX, bounds.maxX, bounds.minZ,
        bounds.maxZ))
    return bounds
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
            if val ~= val then return "null" end -- NaN
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

-- Samples a single terrain point and returns the sample data, or nil if sampling fails.
-- Handles all validation and error logging internally.
function TerrainSampler:sampleTerrainPoint(xCoord, zCoord)
    -- Validate land API
    if not land or type(land) ~= "table" then
        self:logError("land API is not available at sampleGrid, skipping sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
        return nil
    end
    if type(land.getHeight) ~= "function" then
        self:logError("land.getHeight is not available at sampleGrid, skipping sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
        return nil
    end
    if type(land.getSurfaceType) ~= "function" then
        self:logError("land.getSurfaceType is not available at sampleGrid, skipping sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
        return nil
    end

    -- Validate coordinates
    if type(xCoord) ~= "number" or type(zCoord) ~= "number" then
        self:logWarning("Invalid coordinates at sampleGrid: x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord) .. ". Skipping sample.")
        return nil
    end

    -- Get terrain data
    local height, surfaceType
    local ok, err = pcall(function()
        height = land.getHeight({ x = xCoord, y = zCoord })
        surfaceType = land.getSurfaceType({ x = xCoord, y = zCoord })
    end)
    if not ok or type(height) ~= "number" then
        self:logError("Error calling land.getHeight or land.getSurfaceType at queryPoint: {x=" ..
            tostring(xCoord) ..
            ", y=" .. tostring(zCoord) .. "} | Error: " .. tostring(err) .. ". Skipping sample.")
        return nil
    end

    -- Convert to lat/lon
    local lat, lon, alt = nil, nil, nil
    if coord and type(coord.LOtoLL) == "function" then
        local okLL, errLL = pcall(function()
            lat, lon, alt = coord.LOtoLL(xCoord, height, zCoord)
        end)
        if not okLL then
            self:logWarning("coord.LOtoLL failed at x=" ..
                tostring(xCoord) ..
                ", y=" ..
                tostring(height) .. ", z=" .. tostring(zCoord) .. " | Error: " .. tostring(errLL) ..
                " | Args: x=" ..
                tostring(xCoord) .. ", y=" .. tostring(height) .. ", z=" .. tostring(zCoord) ..
                " | Types: x=" ..
                type(xCoord) ..
                ", y=" .. type(height) .. ", z=" .. type(zCoord) .. ". Skipping lat/lon for this sample.")
            lat, lon, alt = nil, nil, nil
        end
    else
        self:logWarning(
            "coord or coord.LOtoLL not available at sampleGrid, skipping lat/lon for sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
    end

    return {
        x = xCoord,
        z = zCoord,
        height = height,
        surface = surfaceType,
        lat = lat,
        lon = lon,
    }
end

function TerrainSampler:sampleGrid(callback)
    self:startPhase("Terrain Grid Sampling")

    -- Use dynamic bounds detection if enabled
    local bounds = nil
    if self.config.detectBounds then
        self:log("Detecting map bounds dynamically from origin...")
        if not self.detectBoundsFromOrigin then
            self:logWarning("detectBoundsFromOrigin is nil on TerrainSampler! Check initialization and method binding.")
        else
            bounds = self:detectBoundsFromOrigin(
                self.config.detectStepSize,
                self.config.detectMaxDistance,
                self.config.detectFlatThreshold,
                self.config.detectMinArea
            )
            if not bounds then
                self:logWarning("detectBoundsFromOrigin returned nil! Dynamic bounds detection failed.")
            end
        end
    else
        bounds = self:getBounds()
    end
    -- Cache bounds for reuse by other phases (e.g., road sampling)
    self.state.detectedBounds = bounds
    local resolution = self.config.gridResolution

    local totalX = math.floor((bounds.maxX - bounds.minX) / resolution) + 1
    local totalZ = math.floor((bounds.maxZ - bounds.minZ) / resolution) + 1
    local totalSamples = totalX * totalZ

    self:log("Grid dimensions: " ..
        tostring(totalX) .. " x " .. tostring(totalZ) .. " = " .. tostring(totalSamples) .. " samples")
    self:log("Resolution: " .. tostring(resolution) .. " meters")
    self:showMessage(
        "Sampling " ..
        tostring(totalSamples) .. " terrain points at " .. tostring(resolution / 1000) .. "km resolution...",
        15)

    -- Chunked stateful sampling
    self.state.gridSamples = {}
    self.state.gridCount = 0
    self.state.gridLastProgressUpdate = 0
    self.state.gridXIndex = 0
    self.state.gridZIndex = 0
    self.state.gridBounds = bounds
    self.state.gridTotalX = totalX
    self.state.gridTotalZ = totalZ
    self.state.gridResolution = resolution
    self.state.gridTotalSamples = totalSamples

    local function gridChunkSampler()
        local startTime = os.clock()
        local samplesThisChunk = 0
        local maxSamples = self.config.maxSamplesPerChunk or 250
        local maxTime = self.config.maxChunkTime or 0.05

        local xIndex = self.state.gridXIndex
        local zIndex = self.state.gridZIndex
        local bounds = self.state.gridBounds
        local resolution = self.state.gridResolution
        local totalX = self.state.gridTotalX
        local totalZ = self.state.gridTotalZ
        local totalSamples = self.state.gridTotalSamples
        local count = self.state.gridCount
        local lastProgressUpdate = self.state.gridLastProgressUpdate
        local samples = self.state.gridSamples

        while xIndex < totalX do
            local xCoord = bounds.minX + xIndex * resolution
            while zIndex < totalZ do
                local zCoord = bounds.minZ + zIndex * resolution

                local sample = self:sampleTerrainPoint(xCoord, zCoord)
                if sample then
                    table.insert(samples, sample)
                    count = count + 1

                    -- Progress updates
                    if count - lastProgressUpdate >= self.config.gridProgressInterval then
                        local percent = math.floor((count / totalSamples) * 100)
                        self:showProgress("Terrain: " ..
                            tostring(count) .. "/" .. tostring(totalSamples) .. " (" .. tostring(percent) .. "%)")
                        lastProgressUpdate = count
                    end
                end

                samplesThisChunk = samplesThisChunk + 1
                zIndex = zIndex + 1

                if samplesThisChunk >= maxSamples or (os.clock() - startTime) > maxTime then
                    self.state.gridXIndex = xIndex
                    self.state.gridZIndex = zIndex
                    self.state.gridCount = count
                    self.state.gridLastProgressUpdate = lastProgressUpdate
                    self.state.gridSamples = samples
                    return timer.getTime() + 0.1, gridChunkSampler
                end
            end
            zIndex = 0
            xIndex = xIndex + 1
        end

        -- Done
        self.state.gridXIndex = xIndex
        self.state.gridZIndex = zIndex
        self.state.gridCount = count
        self.state.gridLastProgressUpdate = lastProgressUpdate
        self.state.gridSamples = samples
        self.state.sampleCount = count
        self:endPhase("Terrain Grid Sampling", tostring(count) .. " samples collected")
        self.state.gridSamplingDone = true
        if callback then
            callback(self.state.gridSamples)
        end
        return nil
    end

    self.state.gridSamplingDone = false
    timer.scheduleFunction(gridChunkSampler, {}, timer.getTime() + 0.1)
end

-- =============================================================================
-- ROAD SAMPLING
-- =============================================================================

-- Samples a road point near the given coordinates and returns the point data, or nil if no road is found.
-- Handles all validation and error logging internally.
function TerrainSampler:sampleRoadPoint(xCoord, zCoord, resolution)
    -- Validate land API
    if not land or type(land) ~= "table" then
        self:logError("land API is not available at sampleRoads, skipping sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
        return nil
    end
    if type(land.getClosestPointOnRoads) ~= "function" then
        self:logError(
            "land.getClosestPointOnRoads is not available at sampleRoads, skipping sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
        return nil
    end
    if type(land.getHeight) ~= "function" then
        self:logError("land.getHeight is not available at sampleRoads, skipping sample at x=" ..
            tostring(xCoord) .. ", z=" .. tostring(zCoord))
        return nil
    end

    -- Find closest road point
    local roadX, roadZ = nil, nil
    local okRoad, errRoad = pcall(function()
        roadX, roadZ = land.getClosestPointOnRoads("roads", xCoord, zCoord)
    end)
    if not okRoad then
        self:logWarning("land.getClosestPointOnRoads failed at x=" ..
            tostring(xCoord) ..
            ", z=" .. tostring(zCoord) .. " | Error: " .. tostring(errRoad) .. ". Skipping sample.")
        return nil
    end

    if not roadX or not roadZ then
        return nil
    end

    local dist = math.sqrt((roadX - xCoord) ^ 2 + (roadZ - zCoord) ^ 2)

    -- Only include if reasonably close to our sample point
    if dist >= resolution * self.config.roadProximityFactor then
        return nil
    end

    -- Get height at road point
    local height = nil
    local okHeight, errHeight = pcall(function()
        height = land.getHeight({ x = roadX, y = roadZ })
    end)
    if not okHeight or type(height) ~= "number" then
        self:logWarning("land.getHeight failed for road point at x=" ..
            tostring(roadX) ..
            ", z=" ..
            tostring(roadZ) .. " | Error: " .. tostring(errHeight) .. ". Skipping sample.")
        return nil
    end

    -- Convert to lat/lon
    local lat, lon = nil, nil
    if coord and type(coord.LOtoLL) == "function" then
        local okLL, errLL = pcall(function()
            lat, lon = coord.LOtoLL(roadX, height, roadZ)
        end)
        if not okLL then
            self:logWarning("coord.LOtoLL failed for road point at x=" ..
                tostring(roadX) ..
                ", y=" ..
                tostring(height) ..
                ", z=" .. tostring(roadZ) .. " | Error: " .. tostring(errLL) ..
                " | Args: x=" ..
                tostring(roadX) .. ", y=" .. tostring(height) .. ", z=" .. tostring(roadZ) ..
                " | Types: x=" ..
                type(roadX) ..
                ", y=" ..
                type(height) .. ", z=" .. type(roadZ) .. ". Skipping lat/lon for this sample.")
            lat, lon = nil, nil
        end
    else
        self:logWarning(
            "coord or coord.LOtoLL not available at sampleRoads, skipping lat/lon for sample at x=" ..
            tostring(roadX) .. ", z=" .. tostring(roadZ))
    end

    return {
        x = roadX,
        z = roadZ,
        height = height,
        lat = lat,
        lon = lon,
    }
end

function TerrainSampler:sampleRoads(callback)
    self:startPhase("Road Network Sampling")

    -- Use cached bounds from terrain sampling phase, or detect/fetch if not available
    local bounds = self.state.detectedBounds
    if not bounds then
        if self.config.detectBounds then
            self:log("No cached bounds available, detecting bounds for road sampling...")
            bounds = self:detectBoundsFromOrigin(
                self.config.detectStepSize,
                self.config.detectMaxDistance,
                self.config.detectFlatThreshold,
                self.config.detectMinArea
            )
        end
        if not bounds then
            bounds = self:getBounds()
        end
    end
    local resolution = self.config.roadGridResolution
    local roadPoints = {}
    local roadSegments = {}

    local totalX = math.floor((bounds.maxX - bounds.minX) / resolution) + 1
    local totalZ = math.floor((bounds.maxZ - bounds.minZ) / resolution) + 1
    local totalGridPoints = totalX * totalZ

    self:showMessage("Scanning " .. tostring(totalGridPoints) .. " grid points for roads...", 10)
    self:log("Road grid resolution: " .. tostring(resolution) .. " meters")

    local gridPointsChecked = 0
    local lastProgressUpdate = 0

    -- Defensive: Check land and its methods
    local landOK = land and type(land) == "table" and type(land.getClosestPointOnRoads) == "function" and
        type(land.getHeight) == "function"
    if not landOK then
        self:logError("land or required land methods not available at sampleRoads")
        if callback then callback({ points = {}, segments = {} }) end
        return
    end

    -- Chunked road point sampling
    self.state.roadPoints = {}
    self.state.roadPointCount = 0
    self.state.roadSamplingDone = false
    self.state.roadXIndex = 0
    self.state.roadZIndex = 0
    self.state.roadTotalX = totalX
    self.state.roadTotalZ = totalZ
    self.state.roadResolution = resolution
    self.state.roadBounds = bounds
    self.state.roadTotalGridPoints = totalGridPoints

    local function roadChunkSampler()
        local startTime = os.clock()
        local maxSamples = self.config.maxSamplesPerChunk or 250
        local maxTime = self.config.maxChunkTime or 0.05

        local xIndex = self.state.roadXIndex
        local zIndex = self.state.roadZIndex
        local bounds = self.state.roadBounds
        local resolution = self.state.roadResolution
        local totalX = self.state.roadTotalX
        local totalZ = self.state.roadTotalZ
        local totalGridPoints = self.state.roadTotalGridPoints
        local roadPoints = self.state.roadPoints
        local gridPointsChecked = self.state.roadPointCount
        local lastProgressUpdate = self.state.roadLastProgressUpdate or 0

        local samplesThisChunk = 0

        while xIndex < totalX do
            local xCoord = bounds.minX + xIndex * resolution
            while zIndex < totalZ do
                local zCoord = bounds.minZ + zIndex * resolution
                gridPointsChecked = gridPointsChecked + 1

                local roadPoint = self:sampleRoadPoint(xCoord, zCoord, resolution)
                if roadPoint then
                    table.insert(roadPoints, roadPoint)
                end

                -- Progress updates
                if gridPointsChecked - lastProgressUpdate >= self.config.roadProgressInterval then
                    local percent = math.floor((gridPointsChecked / totalGridPoints) * 100)
                    self:showProgress("Road scan: " ..
                        tostring(gridPointsChecked) ..
                        "/" ..
                        tostring(totalGridPoints) ..
                        " (" .. tostring(percent) .. "%) - " .. tostring(#roadPoints) .. " points found")
                    lastProgressUpdate = gridPointsChecked
                end

                samplesThisChunk = samplesThisChunk + 1
                zIndex = zIndex + 1

                if samplesThisChunk >= maxSamples or (os.clock() - startTime) > maxTime then
                    self.state.roadXIndex = xIndex
                    self.state.roadZIndex = zIndex
                    self.state.roadPointCount = gridPointsChecked
                    self.state.roadLastProgressUpdate = lastProgressUpdate
                    self.state.roadPoints = roadPoints
                    timer.scheduleFunction(roadChunkSampler, {}, timer.getTime() + 0.1)
                    return
                end
            end
            zIndex = 0
            xIndex = xIndex + 1
        end

        -- Done with road point sampling
        self.state.roadXIndex = xIndex
        self.state.roadZIndex = zIndex
        self.state.roadPointCount = gridPointsChecked
        self.state.roadLastProgressUpdate = lastProgressUpdate
        self.state.roadPoints = roadPoints
        self.state.roadSamplingDone = true

        -- Start connectivity phase (chunked)
        self:log("Found " .. tostring(#roadPoints) .. " road sample points")
        self:showMessage("Found " .. tostring(#roadPoints) .. " road points. Building connectivity...", 10)

        local findPathOK = land and type(land.findPathOnRoads) == "function"
        if not findPathOK then
            self:logWarning("land.findPathOnRoads not available at sampleRoads, skipping connectivity")
            self.state.roadPointCount = #roadPoints
            self:endPhase("Road Network Sampling", tostring(#roadPoints) .. " points, 0 segments")
            if callback then callback({ points = roadPoints, segments = {} }) end
            return
        end

        -- Initialize connectivity phase state
        self.state.connectivityIIndex = 1
        self.state.connectivityJIndex = 2
        self.state.connectivitySegments = {}
        self.state.connectivitySegmentCount = 0
        self.state.connectivityMaxSegments = self.config.maxRoadSegments or 10000

        local function connectivityChunkProcessor()
            local startTime = os.clock()
            local maxChecks = self.config.maxSamplesPerChunk or 250
            local maxTime = self.config.maxChunkTime or 0.05

            local iIndex = self.state.connectivityIIndex
            local jIndex = self.state.connectivityJIndex
            local segments = self.state.connectivitySegments
            local segmentCount = self.state.connectivitySegmentCount
            local maxSegments = self.state.connectivityMaxSegments
            local roadPoints = self.state.roadPoints
            local checksThisChunk = 0

            while iIndex <= #roadPoints do
                local p1 = roadPoints[iIndex]
                local jEnd = math.min(iIndex + self.config.roadNeighborCount, #roadPoints)

                while jIndex <= jEnd do
                    local p2 = roadPoints[jIndex]
                    local directDist = math.sqrt((p1.x - p2.x) ^ 2 + (p1.z - p2.z) ^ 2)

                    if directDist < self.config.maxRoadSearchDistance then
                        checksThisChunk = checksThisChunk + 1
                        local path = nil
                        local okPath, errPath = pcall(function()
                            path = land.findPathOnRoads("roads", p1.x, p1.z, p2.x, p2.z)
                        end)
                        if okPath and path and #path > 0 then
                            table.insert(segments, {
                                from = { x = p1.x, z = p1.z },
                                to = { x = p2.x, z = p2.z },
                                pathLength = #path,
                                directDistance = directDist,
                            })
                            segmentCount = segmentCount + 1
                        elseif not okPath then
                            self:logWarning("land.findPathOnRoads failed for segment from (" ..
                                tostring(p1.x) ..
                                "," ..
                                tostring(p1.z) ..
                                ") to (" .. tostring(p2.x) .. "," .. tostring(p2.z) .. ") | Error: " .. tostring(errPath))
                        end
                    end

                    jIndex = jIndex + 1

                    -- Check if we should yield
                    if checksThisChunk >= maxChecks or (os.clock() - startTime) > maxTime then
                        self.state.connectivityIIndex = iIndex
                        self.state.connectivityJIndex = jIndex
                        self.state.connectivitySegments = segments
                        self.state.connectivitySegmentCount = segmentCount
                        timer.scheduleFunction(connectivityChunkProcessor, {}, timer.getTime() + 0.1)
                        return
                    end

                    -- Check segment limit
                    if segmentCount >= maxSegments then
                        break
                    end
                end

                -- Check segment limit for outer loop
                if segmentCount >= maxSegments then
                    break
                end

                -- Progress update
                if iIndex % self.config.connectivityProgressInterval == 0 then
                    self:showProgress("Road connectivity: " ..
                        tostring(segmentCount) .. " segments from " .. tostring(iIndex) .. " points checked")
                end

                iIndex = iIndex + 1
                jIndex = iIndex + 1
            end

            -- Done with connectivity
            self.state.connectivitySegmentCount = segmentCount
            self.state.roadPointCount = #roadPoints
            self:endPhase("Road Network Sampling",
                tostring(#roadPoints) .. " points, " .. tostring(segmentCount) .. " segments")

            if callback then callback({ points = roadPoints, segments = segments }) end
        end

        timer.scheduleFunction(connectivityChunkProcessor, {}, timer.getTime() + 0.1)
    end

    timer.scheduleFunction(roadChunkSampler, {}, timer.getTime() + 0.1)
end

-- =============================================================================
-- AIRBASE COLLECTION
-- =============================================================================

function TerrainSampler:collectAirbases(callback)
    self:startPhase("Airbase Collection")

    local airbases = {}

    -- Defensive: Check world and world.getAirbases
    if not world or type(world.getAirbases) ~= "function" then
        self:logError("world.getAirbases not available at collectAirbases")
        self:endPhase("Airbase Collection", "0 airbases (API unavailable)")
        self.state.airbaseCount = 0
        return airbases
    end

    local allAirbases = world.getAirbases()
    local totalAirbases = allAirbases and #allAirbases or 0

    self:showMessage("Processing " .. tostring(totalAirbases) .. " airbases...", 10)

    for idx, airbase in ipairs(allAirbases or {}) do
        local okAirbase, errAirbase = pcall(function()
            if airbase and type(airbase.isExist) == "function" and airbase:isExist() then
                local name = type(airbase.getName) == "function" and airbase:getName() or "Unknown"
                local callsign = type(airbase.getCallsign) == "function" and airbase:getCallsign() or ""
                local pos = type(airbase.getPoint) == "function" and airbase:getPoint() or { x = 0, y = 0, z = 0 }
                local lat, lon, alt = nil, nil, nil
                if coord and type(coord.LOtoLL) == "function" then
                    local okLL, errLL = pcall(function()
                        lat, lon, alt = coord.LOtoLL(pos.x, pos.y, pos.z)
                    end)
                    if not okLL then
                        self:logWarning("coord.LOtoLL failed for airbase at x=" ..
                            tostring(pos.x) ..
                            ", y=" .. tostring(pos.y) .. ", z=" .. tostring(pos.z) .. " | Error: " .. tostring(errLL) ..
                            " | Args: x=" .. tostring(pos.x) .. ", y=" .. tostring(pos.y) .. ", z=" .. tostring(pos.z) ..
                            " | Types: x=" .. type(pos.x) .. ", y=" .. type(pos.y) .. ", z=" .. type(pos.z))
                        lat, lon, alt = nil, nil, nil
                    end
                else
                    self:logWarning("coord or coord.LOtoLL not available at collectAirbases")
                end

                -- Get category from description
                local desc = type(airbase.getDesc) == "function" and airbase:getDesc() or nil
                local category = desc and desc.category or -1

                self:log("Processing airbase " ..
                    tostring(idx) .. "/" .. tostring(totalAirbases) .. ": " .. tostring(name))

                -- Get parking spots
                local parkingSpots = {}
                local parkingData = type(airbase.getParking) == "function" and airbase:getParking() or nil
                if parkingData then
                    for _, spot in ipairs(parkingData) do
                        local spotLat, spotLon
                        if spot.vTerminalPos and coord and type(coord.LOtoLL) == "function" then
                            local okSpotLL, errSpotLL = pcall(function()
                                spotLat, spotLon = coord.LOtoLL(
                                    spot.vTerminalPos.x,
                                    spot.vTerminalPos.y or 0,
                                    spot.vTerminalPos.z
                                )
                            end)
                            if not okSpotLL then
                                self:logWarning("coord.LOtoLL failed for parking spot at airbase " .. tostring(name) ..
                                    " | Error: " .. tostring(errSpotLL) ..
                                    " | Args: x=" ..
                                    tostring(spot.vTerminalPos.x) ..
                                    ", y=" ..
                                    tostring(spot.vTerminalPos.y or 0) .. ", z=" .. tostring(spot.vTerminalPos.z) ..
                                    " | Types: x=" ..
                                    type(spot.vTerminalPos.x) ..
                                    ", y=" .. type(spot.vTerminalPos.y) .. ", z=" .. type(spot.vTerminalPos.z))
                                spotLat, spotLon = nil, nil
                            end
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
                local runwayData = type(airbase.getRunways) == "function" and airbase:getRunways() or nil
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

                self:log("  - " .. tostring(#parkingSpots) .. " parking spots, " .. tostring(#runways) .. " runways")
            end
        end)
        if not okAirbase then
            self:logWarning("Error processing airbase index " .. tostring(idx) .. ": " .. tostring(errAirbase))
        end
    end

    self.state.airbaseCount = #airbases
    self:endPhase("Airbase Collection", tostring(#airbases) .. " airbases with parking/runway data")
    if callback then callback(airbases) end
end

-- =============================================================================
-- EXPORT
-- =============================================================================

function TerrainSampler:export()
    local sampler = self
    sampler.state.startTime = os.time()

    sampler:showMessage("=== TERRAIN EXPORT STARTING ===", 15)
    sampler:log("========================================")
    sampler:log("TERRAIN EXPORT STARTING")
    sampler:log("========================================")
    sampler:log("Script version: " .. tostring(sampler.VERSION))

    -- Defensive: Check env and env.mission
    local theatre = "Unknown"
    if env and env.mission and env.mission.theatre then
        theatre = env.mission.theatre
    end
    sampler:showMessage("Theatre: " .. theatre, 10)
    sampler:log("Theatre: " .. theatre)

    -- Verify required APIs are available
    sampler:log("Verifying API availability...")
    if not io or type(io.open) ~= "function" then
        sampler:logError("io library not available - MissionScripting.lua needs to be desanitized")
        sampler:showMessage("ERROR: io library not available!\nPlease desanitize MissionScripting.lua", 30)
        return
    end
    if not lfs or type(lfs.mkdir) ~= "function" or type(lfs.writedir) ~= "function" then
        sampler:logError("lfs library not available - MissionScripting.lua needs to be desanitized")
        sampler:showMessage("ERROR: lfs library not available!\nPlease desanitize MissionScripting.lua", 30)
        return
    end
    sampler:log("API check passed: io and lfs available")
    sampler:showMessage("API check passed", 5)

    local bounds = sampler:getBounds()
    sampler:log("Bounds: x=" .. tostring(bounds.minX) .. " to " .. tostring(bounds.maxX) ..
        ", z=" .. tostring(bounds.minZ) .. " to " .. tostring(bounds.maxZ))

    local boundsWidth = (bounds.maxX - bounds.minX) / 1000
    local boundsHeight = (bounds.maxZ - bounds.minZ) / 1000
    sampler:showMessage("Export area: " .. tostring(boundsWidth) .. "km x " .. tostring(boundsHeight) .. "km", 10)

    -- Callback-driven sequencing
    local function finalizeExport(gridSamples, roadData, airbases)
        sampler:showMessage("Building export data structure...", 10)
        sampler:log("Building export data structure...")

        local exportData = {
            metadata = {
                theatre = theatre,
                exportTime = os.date("!%Y-%m-%dT%H:%M:%SZ"),
                gridResolution = sampler.config.gridResolution,
                bounds = bounds,
                stats = {
                    terrainSamples = sampler.state.sampleCount or 0,
                    roadPoints = sampler.state.roadPointCount or 0,
                    airbases = sampler.state.airbaseCount or 0,
                },
            },
            terrain = gridSamples,
            roads = roadData,
            airbases = airbases,
        }

        -- Write to file
        sampler:showMessage("Writing JSON output file...", 10)
        local outputDir = lfs.writedir() .. sampler.config.outputPath
        sampler:log("Output directory: " .. outputDir)

        local success, err = pcall(function()
            local okDir, errDir = lfs.mkdir(outputDir)
            if not okDir and errDir ~= "File exists" then
                sampler:log("mkdir result: " .. tostring(errDir))
            else
                sampler:log("Output directory ready")
            end
        end)
        if not success then
            sampler:logError("Failed to create output directory: " .. tostring(err))
            sampler:showMessage("ERROR: Could not create output directory!\n" .. outputDir, 30)
            return
        end

        -- Clean output directory before export to remove old files
        local cleanSuccess, cleanErr = pcall(function()
            for file in lfs.dir(outputDir) do
                if file ~= "." and file ~= ".." then
                    local filePath = outputDir .. file
                    local attr = lfs.attributes(filePath)
                    if attr and attr.mode == "file" then
                        local ok, removeErr = os.remove(filePath)
                        if ok then
                            sampler:log("Removed old export file: " .. filePath)
                        else
                            sampler:logWarning("Could not remove file: " ..
                                filePath .. " | Error: " .. tostring(removeErr))
                        end
                    end
                end
            end
        end)
        if not cleanSuccess then
            sampler:logWarning("Failed to clean output directory: " .. tostring(cleanErr))
        end

        local filename = outputDir .. theatre:lower():gsub(" ", "-") .. "-terrain.json"
        sampler:log("Output filename: " .. filename)

        local file, fileErr = io.open(filename, "w")
        if not file then
            sampler:logError("Could not open file for writing: " ..
                tostring(filename) .. " | Error: " .. tostring(fileErr))
            sampler:showMessage(
                "ERROR: Could not write to file!\n" .. tostring(filename) .. "\nCheck permissions and disk space.", 30)
            return
        end

        local okWrite, errWrite = pcall(function()
            sampler:showMessage("Encoding JSON (this may take a moment)...", 15)
            sampler:log("Encoding JSON...")

            local jsonStartTime = os.time()
            local json = sampler:encodeJSON(exportData)
            local jsonTime = os.time() - jsonStartTime

            sampler:log("JSON encoding completed in " .. sampler:formatTime(jsonTime))
            sampler:log("JSON size: " .. #json .. " bytes (" .. math.floor(#json / 1024) .. " KB)")

            sampler:showMessage("Writing " .. math.floor(#json / 1024) .. " KB to disk...", 10)
            file:write(json)
            file:close()

            local totalTime = sampler:getElapsedTime()

            sampler:log("========================================")
            sampler:log("EXPORT COMPLETE")
            sampler:log("========================================")
            sampler:log("File: " .. filename)
            sampler:log("Size: " .. #json .. " bytes")
            sampler:log("Total time: " .. sampler:formatTime(totalTime))
            sampler:log("Stats:")
            sampler:log("  - Terrain samples: " .. tostring(sampler.state.sampleCount or 0))
            sampler:log("  - Road points: " .. tostring(sampler.state.roadPointCount or 0))
            sampler:log("  - Airbases: " .. tostring(sampler.state.airbaseCount or 0))

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
                sampler:formatTime(totalTime),
                sampler.state.sampleCount or 0,
                sampler.state.roadPointCount or 0,
                sampler.state.airbaseCount or 0
            )
            if trigger and trigger.action and type(trigger.action.outText) == "function" then
                trigger.action.outText(summaryMsg, 60)
            end
        end)
        if not okWrite then
            sampler:logError("Failed to write JSON output: " .. tostring(errWrite))
            sampler:showMessage("ERROR: Could not write JSON output!\n" .. tostring(filename), 30)
        end
    end

    -- Callback chain for chunked sampling
    sampler:showMessage("Phase 1/3: Terrain sampling...", 10)
    sampler:sampleGrid(function(gridSamples)
        sampler:showMessage("Phase 2/3: Road network sampling...", 10)
        sampler:sampleRoads(function(roadData)
            sampler:showMessage("Phase 3/3: Airbase collection...", 10)
            sampler:collectAirbases(function(airbases)
                finalizeExport(gridSamples, roadData, airbases)
            end)
        end)
    end)
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

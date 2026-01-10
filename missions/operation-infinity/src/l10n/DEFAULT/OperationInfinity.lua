-- =============================================================================
-- OPERATION INFINITY - MAIN MISSION SCRIPT
-- F10 menu, battlefield generation, and coordination display
-- =============================================================================

-- =============================================================================
-- BATCH SCHEDULER
-- Time-budgeted work processing to avoid triggering DCS Antifreeze
-- =============================================================================

BatchScheduler = {}

BatchScheduler.config = {
    frameBudgetMs = 1,  -- Max milliseconds per frame
    minItems = 1,       -- Always process at least 1 item
}

function BatchScheduler:log(message)
    env.info("[BatchScheduler] " .. message)
end

-- Process array items within time budget, yielding between frames
-- params.array: Array of items to process
-- params.callback: Function(item, index, context) called for each item
-- params.onComplete: Function(context) called when all items processed
-- params.context: Optional context object passed to callbacks
function BatchScheduler:processArray(params)
    local array = params.array
    local callback = params.callback
    local onComplete = params.onComplete
    local context = params.context or {}
    local index = 1
    local total = #array

    if total == 0 then
        if onComplete then onComplete(context) end
        return
    end

    local function processBatch()
        local startTime = os.clock() * 1000  -- Current time in ms
        local budgetMs = BatchScheduler.config.frameBudgetMs
        local itemsProcessed = 0

        while index <= total do
            callback(array[index], index, context)
            index = index + 1
            itemsProcessed = itemsProcessed + 1

            -- Check time budget (but always process at least minItems)
            local elapsed = (os.clock() * 1000) - startTime
            if itemsProcessed >= BatchScheduler.config.minItems and elapsed >= budgetMs then
                break
            end
        end

        if index <= total then
            return timer.getTime() + 0.001  -- Next frame
        else
            if onComplete then onComplete(context) end
            return nil
        end
    end

    timer.scheduleFunction(processBatch, nil, timer.getTime() + 0.001)
end

-- Execute sequential async steps with callbacks
-- params.steps: Array of {name = "step name", fn = function(context, done)}
-- params.onComplete: Function(context) called when all steps complete
-- params.onError: Function(err, stepName, context) called on error
-- params.context: Optional context object passed to all steps
function BatchScheduler:runSequence(params)
    local steps = params.steps
    local onComplete = params.onComplete
    local onError = params.onError
    local context = params.context or {}

    local stepIndex = 1

    local function runNextStep()
        if stepIndex > #steps then
            if onComplete then onComplete(context) end
            return nil
        end

        local step = steps[stepIndex]
        stepIndex = stepIndex + 1

        local function done(err)
            if err then
                if onError then
                    onError(err, step.name, context)
                else
                    BatchScheduler:log("Error in step " .. step.name .. ": " .. tostring(err))
                end
                return
            end
            timer.scheduleFunction(runNextStep, nil, timer.getTime() + 0.001)
        end

        step.fn(context, done)
    end

    timer.scheduleFunction(runNextStep, nil, timer.getTime() + 0.001)
end

-- =============================================================================
-- OPERATION INFINITY
-- =============================================================================

OperationInfinity = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

OperationInfinity.config = {
    maxSpawnedUnits = 800,
    debug = true,

    -- Terrain validation settings
    terrain = {
        defaultMaxSlope = 15,       -- Degrees
        defaultMaxRoughness = 5,    -- Meters standard deviation
        maxSearchAttempts = 10,     -- Attempts to find valid position
        sampleRadius = 50,          -- Meters for slope sampling
    },

    -- Unit randomization settings
    unitRandomization = {
        countVariance = 0.3,        -- ±30% unit count variation
        missingUnitChance = 0.1,    -- 10% chance each unit is "missing"
        substitutionChance = 0.3,   -- 30% chance for unit type substitution
    },

    -- RED aerodrome positions (from Caucasus terrain data)
    aerodromes = {
        maykop = { name = "Maykop-Khanskaya", x = -27626, y = 457048 },
        gudauta = { name = "Gudauta", x = -195651, y = 515899 },
        sukhumi = { name = "Sukhumi-Babushara", x = -221382, y = 565909 },
        senaki = { name = "Senaki-Kolkhi", x = -281903, y = 648379 },
        kobuleti = { name = "Kobuleti", x = -317605, y = 636704 },
        kutaisi = { name = "Kutaisi", x = -284583, y = 685030 },
        mozdok = { name = "Mozdok", x = -83330, y = 835635 },
        tbilisi = { name = "Tbilisi-Lochini", x = -314926, y = 895724 },
        vaziani = { name = "Vaziani", x = -318192, y = 902332 },
    },

    -- Aerodrome regions - geographic clusters for each playtime
    aerodromeRegions = {
        northwest = {
            name = "Maykop Area",
            aerodromes = { "maykop" },
            playtimes = { "45" },
        },
        central_coast = {
            name = "Gudauta/Sukhumi Area",
            aerodromes = { "gudauta", "sukhumi" },
            playtimes = { "45", "90" },
        },
        southwest_coast = {
            name = "Kobuleti/Senaki/Kutaisi Area",
            aerodromes = { "kobuleti", "senaki", "kutaisi" },
            playtimes = { "90" },
        },
        northeast = {
            name = "Mozdok Area",
            aerodromes = { "mozdok" },
            playtimes = { "180" },
        },
        southeast = {
            name = "Tbilisi/Vaziani Area",
            aerodromes = { "tbilisi", "vaziani" },
            playtimes = { "180" },
        },
    },

    -- Battlefield spawning distances from aerodromes
    battlefieldDistance = {
        min = 16000,  -- 10 miles in meters
        max = 64000,  -- 40 miles in meters
    },

    -- Frontline generation parameters
    frontline = {
        sectorsMin = 3,
        sectorsMax = 5,
        platoonPairsMin = 2,
        platoonPairsMax = 3,
        engagementDistanceMin = 300, -- Minimum meters between opposing platoons
        engagementDistanceMax = 1000, -- Maximum meters between opposing platoons
        fireOffset = 50,              -- Meters offset for FireAtPoint
    },

    -- Behind-lines targets
    behindLines = {
        convoyCount = { 2, 4 },  -- Min/max convoys
        artilleryCount = { 1, 3 }, -- Min/max artillery batteries
        patrolCount = { 3, 6 },  -- Min/max patrol groups
    },

    -- SAM site counts by difficulty
    samCounts = {
        Normal = {
            SA2 = { 0, 1 },
            SA3 = { 1, 2 },
            SA6 = { 1, 2 },
            SA8 = { 2, 3 },
            EWR = { 2, 3 },
        },
        Hard = {
            SA10 = { 1, 1 },
            SA11 = { 1, 2 },
            SA6 = { 1, 2 },
            SA15 = { 2, 3 },
            EWR = { 2, 4 },
        },
    },
}

-- =============================================================================
-- STATE
-- =============================================================================

OperationInfinity.state = {
    initialized = false,
    missionGenerated = false,

    -- Settings (locked when first player selects both)
    difficulty = nil,
    playtime = nil,
    settingsLockedBy = nil,

    -- Generated battlefield
    battlefield = {
        region = nil,           -- Selected aerodrome region
        targetAerodromes = {},  -- Aerodromes in the selected region
        sectors = {},           -- Generated frontline sectors
    },

    -- Menu tracking
    settingsMenu = nil,
    difficultyMenu = nil,
    playtimeMenu = nil,

    -- Player tracking
    knownPlayers = {},

    -- Unit counters
    groupCounter = 3000,
    unitCounter = 3000,

    -- Marker counter
    markerCounter = 1000,
}

-- =============================================================================
-- UTILITY FUNCTIONS
-- =============================================================================

function OperationInfinity:log(message)
    if self.config.debug then
        env.info("[OperationInfinity] " .. message)
    end
end

function OperationInfinity:getNextGroupId()
    self.state.groupCounter = self.state.groupCounter + 1
    return self.state.groupCounter
end

function OperationInfinity:getNextUnitId()
    self.state.unitCounter = self.state.unitCounter + 1
    return self.state.unitCounter
end

function OperationInfinity:randomInRange(min, max)
    return math.random(min, max)
end

function OperationInfinity:randomPointInRadius(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.random() * radius
    return {
        x = center.x + distance * math.cos(angle),
        y = center.y + distance * math.sin(angle),
    }
end

function OperationInfinity:addMarker(text, pos)
    self.state.markerCounter = self.state.markerCounter + 1
    local vec3 = {x = pos.x, y = land.getHeight(pos), z = pos.y}
    trigger.action.markToCoalition(
        self.state.markerCounter,
        text,
        vec3,
        coalition.side.BLUE,
        true,  -- readOnly (players cannot delete)
        ""     -- no announcement message
    )
end

-- Select a random region that matches the given playtime
function OperationInfinity:selectRegionForPlaytime(playtime)
    local matchingRegions = {}
    for key, region in pairs(self.config.aerodromeRegions) do
        for _, pt in ipairs(region.playtimes) do
            if pt == playtime then
                table.insert(matchingRegions, { key = key, region = region })
                break
            end
        end
    end
    if #matchingRegions == 0 then
        self:log("WARNING: No regions match playtime " .. playtime)
        return nil
    end
    return matchingRegions[math.random(#matchingRegions)]
end

-- Generate a random position within 10-40 miles of a given aerodrome
function OperationInfinity:randomPointNearAerodrome(aerodrome)
    local minDist = self.config.battlefieldDistance.min
    local maxDist = self.config.battlefieldDistance.max
    local angle = math.random() * 2 * math.pi
    local distance = minDist + math.random() * (maxDist - minDist)
    return {
        x = aerodrome.x + distance * math.cos(angle),
        y = aerodrome.y + distance * math.sin(angle),
    }
end

-- =============================================================================
-- TERRAIN VALIDATION
-- =============================================================================

-- Calculate maximum slope around a position by sampling 8 points
function OperationInfinity:calculateMaxSlope(center, sampleRadius)
    sampleRadius = sampleRadius or self.config.terrain.sampleRadius

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
function OperationInfinity:isValidSurfaceType(pos)
    local ok, surfaceType = pcall(land.getSurfaceType, {x = pos.x, y = pos.y})
    if not ok then
        return false
    end

    -- Accept LAND and ROAD, reject WATER, SHALLOW_WATER
    return surfaceType == land.SurfaceType.LAND or surfaceType == land.SurfaceType.ROAD
end

-- Calculate terrain roughness using height variance
function OperationInfinity:calculateTerrainRoughness(center, checkRadius)
    checkRadius = checkRadius or self.config.terrain.sampleRadius

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
function OperationInfinity:getDistanceToNearestRoad(pos)
    local ok, roadX, roadY = pcall(land.getClosestPointOnRoads, "roads", pos.x, pos.y)
    if not ok or not roadX then
        return 999999
    end

    local dx = roadX - pos.x
    local dy = roadY - pos.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Combined terrain validation
function OperationInfinity:isValidTerrainForUnits(center, options)
    options = options or {}
    local maxSlope = options.maxSlope or self.config.terrain.defaultMaxSlope
    local maxRoughness = options.maxRoughness or self.config.terrain.defaultMaxRoughness
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
function OperationInfinity:findValidPosition(center, radius, options, maxAttempts)
    maxAttempts = maxAttempts or self.config.terrain.maxSearchAttempts
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
        maxSlope = (options.maxSlope or self.config.terrain.defaultMaxSlope) * 1.5,
        maxRoughness = (options.maxRoughness or self.config.terrain.defaultMaxRoughness) * 1.5,
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

-- =============================================================================
-- FORMATION GENERATORS
-- =============================================================================

-- Formation types
OperationInfinity.FormationType = {
    LINE = "LINE",
    WEDGE = "WEDGE",
    ECHELON_LEFT = "ECHELON_LEFT",
    ECHELON_RIGHT = "ECHELON_RIGHT",
}

-- Get relative positions for a formation
function OperationInfinity:getFormationPositions(unitCount, formationType, spacing)
    spacing = spacing or 30
    local positions = {}

    if formationType == self.FormationType.LINE then
        -- Units spread perpendicular to facing direction
        local startOffset = -((unitCount - 1) * spacing) / 2
        for i = 1, unitCount do
            table.insert(positions, {
                x = startOffset + (i - 1) * spacing,
                y = 0,
            })
        end

    elseif formationType == self.FormationType.WEDGE then
        -- Arrow/vee shape with lead unit at front
        table.insert(positions, {x = 0, y = 0}) -- Lead unit
        for i = 2, unitCount do
            local row = math.ceil((i - 1) / 2)
            local side = ((i - 1) % 2 == 0) and 1 or -1
            table.insert(positions, {
                x = side * row * spacing,
                y = -row * spacing,
            })
        end

    elseif formationType == self.FormationType.ECHELON_LEFT then
        for i = 1, unitCount do
            table.insert(positions, {
                x = -(i - 1) * spacing,
                y = -(i - 1) * spacing * 0.7,
            })
        end

    elseif formationType == self.FormationType.ECHELON_RIGHT then
        for i = 1, unitCount do
            table.insert(positions, {
                x = (i - 1) * spacing,
                y = -(i - 1) * spacing * 0.7,
            })
        end

    else
        -- Default to line if unknown
        return self:getFormationPositions(unitCount, self.FormationType.LINE, spacing)
    end

    return positions
end

-- Rotate a relative position by heading
function OperationInfinity:rotatePosition(relPos, heading)
    local cos_h = math.cos(heading)
    local sin_h = math.sin(heading)
    return {
        x = relPos.x * cos_h - relPos.y * sin_h,
        y = relPos.x * sin_h + relPos.y * cos_h,
    }
end

-- Get a random formation type
function OperationInfinity:getRandomFormationType()
    local types = {
        self.FormationType.LINE,
        self.FormationType.WEDGE,
        self.FormationType.ECHELON_LEFT,
        self.FormationType.ECHELON_RIGHT,
    }
    return types[math.random(#types)]
end

-- =============================================================================
-- UNIT RANDOMIZATION
-- =============================================================================

-- Randomize a template by varying counts and potentially removing units
-- Options:
--   skipSubstitutions: boolean - if true, do not substitute unit types (keeps homogenous compositions)
function OperationInfinity:randomizeTemplate(template, options)
    options = options or {}
    local variance = self.config.unitRandomization.countVariance
    local missingChance = self.config.unitRandomization.missingUnitChance
    local result = {}

    for _, def in ipairs(template) do
        -- Chance each unit definition is "missing" (casualties/detachments)
        if math.random() > missingChance then
            -- Vary count within ±variance of base
            local baseCount = def.count
            local minCount = math.max(1, math.floor(baseCount * (1 - variance)))
            local maxCount = math.ceil(baseCount * (1 + variance))
            local newCount = self:randomInRange(minCount, maxCount)

            -- Apply unit type substitution (unless skipped for homogenous units like artillery)
            local unitType = def.type
            if not options.skipSubstitutions then
                unitType = UnitTemplates:getSubstitute(def.type, self.config.unitRandomization.substitutionChance)
            end

            table.insert(result, {
                type = unitType,
                count = newCount,
            })
        end
    end

    -- Ensure at least one unit remains
    if #result == 0 and #template > 0 then
        local def = template[1]
        table.insert(result, {
            type = def.type,
            count = 1,
        })
    end

    return result
end

-- =============================================================================
-- F10 MENU SYSTEM
-- =============================================================================

function OperationInfinity:setupMenu()
    -- Create root menu
    self.state.settingsMenu = missionCommands.addSubMenuForCoalition(
        coalition.side.BLUE, "Mission Settings", nil
    )

    -- Difficulty submenu
    self.state.difficultyMenu = missionCommands.addSubMenuForCoalition(
        coalition.side.BLUE, "Difficulty", self.state.settingsMenu
    )

    local difficulties = {
        { key = "VeryEasy", label = "Very Easy (Training - no enemies shoot back)" },
        { key = "Easy",     label = "Easy (Light defenses, IR missiles only)" },
        { key = "Normal",   label = "Normal (IADS, semi-active radar missiles)" },
        { key = "Hard",     label = "Hard (Layered IADS, active radar missiles)" },
    }

    for _, diff in ipairs(difficulties) do
        missionCommands.addCommandForCoalition(
            coalition.side.BLUE,
            diff.label,
            self.state.difficultyMenu,
            function() OperationInfinity:selectDifficulty(diff.key) end
        )
    end

    -- Playtime submenu
    self.state.playtimeMenu = missionCommands.addSubMenuForCoalition(
        coalition.side.BLUE, "Target Playtime", self.state.settingsMenu
    )

    local playtimes = {
        { key = "45",  label = "45 Minutes (CAS - targets near Krymsk)" },
        { key = "90",  label = "90 Minutes (Interdiction - central Caucasus)" },
        { key = "180", label = "180 Minutes (Deep Strike - eastern Caucasus)" },
    }

    for _, pt in ipairs(playtimes) do
        missionCommands.addCommandForCoalition(
            coalition.side.BLUE,
            pt.label,
            self.state.playtimeMenu,
            function() OperationInfinity:selectPlaytime(pt.key) end
        )
    end
end

function OperationInfinity:selectDifficulty(difficulty)
    if self.state.missionGenerated then
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "Mission already generated!", 10)
        return
    end

    self.state.difficulty = difficulty
    trigger.action.outTextForCoalition(coalition.side.BLUE,
        "Difficulty set to: " .. difficulty, 10)

    self:checkAndGenerate()
end

function OperationInfinity:selectPlaytime(playtime)
    if self.state.missionGenerated then
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "Mission already generated!", 10)
        return
    end

    self.state.playtime = playtime
    trigger.action.outTextForCoalition(coalition.side.BLUE,
        "Playtime set to: " .. playtime .. " minutes", 10)

    self:checkAndGenerate()
end

function OperationInfinity:checkAndGenerate()
    if self.state.difficulty and self.state.playtime and not self.state.missionGenerated then
        self:lockSettings()
        self:generateBattlefield()
    end
end

function OperationInfinity:lockSettings()
    -- Remove menu items
    if self.state.settingsMenu then
        missionCommands.removeItemForCoalition(coalition.side.BLUE, self.state.settingsMenu)
        self.state.settingsMenu = nil
        self.state.difficultyMenu = nil
        self.state.playtimeMenu = nil
    end
end

-- =============================================================================
-- BATTLEFIELD GENERATION
-- =============================================================================

function OperationInfinity:generateBattlefield()
    self.state.missionGenerated = true

    -- Select a region for this playtime
    local selected = self:selectRegionForPlaytime(self.state.playtime)
    if not selected then
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "ERROR: No region available for playtime " .. self.state.playtime, 15)
        return
    end

    self.state.battlefield.region = selected.region
    self.state.battlefield.targetAerodromes = {}

    -- Populate target aerodromes from the selected region
    for _, key in ipairs(selected.region.aerodromes) do
        local aerodrome = self.config.aerodromes[key]
        if aerodrome then
            table.insert(self.state.battlefield.targetAerodromes, aerodrome)
        end
    end

    -- Build virtualization notice for longer missions
    local virtNote = ""
    if self.state.playtime == "90" or self.state.playtime == "180" then
        virtNote = "\n\nNote: For performance, ground units are virtualized\n" ..
            "and spawn when a player is within 100 nm."
    end

    self:log("Generating battlefield - Difficulty: " .. self.state.difficulty ..
        ", Playtime: " .. self.state.playtime .. ", Region: " .. selected.region.name)

    -- Store context for async generation
    local genContext = {
        selected = selected,
        virtNote = virtNote,
    }

    -- Helper for progress messages
    local function progress(msg)
        trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 5)
    end

    -- Run generation as async sequence
    BatchScheduler:runSequence({
        context = genContext,
        steps = {
            {
                name = "frontline",
                fn = function(ctx, done)
                    progress("Generating frontline...")
                    OperationInfinity:generateFrontlineSectorsBatched(done)
                end,
            },
            {
                name = "behind_lines",
                fn = function(ctx, done)
                    progress("Deploying enemy forces...")
                    OperationInfinity:generateBehindLinesTargetsBatched(done)
                end,
            },
            {
                name = "air_defenses",
                fn = function(ctx, done)
                    if OperationInfinity.state.difficulty == "Normal" or
                       OperationInfinity.state.difficulty == "Hard" then
                        progress("Deploying air defenses...")
                        OperationInfinity:generateAirDefensesBatched(done)
                    else
                        done()
                    end
                end,
            },
            {
                name = "ewrs",
                fn = function(ctx, done)
                    if OperationInfinity.state.difficulty ~= "VeryEasy" then
                        progress("Deploying radar networks...")
                        OperationInfinity:generateEWRsBatched(done)
                    else
                        done()
                    end
                end,
            },
            {
                name = "init_systems",
                fn = function(ctx, done)
                    progress("Initializing combat systems...")
                    Virtualization:init()
                    Virtualization:spawnPermanentGroupsBatched(function()
                        AirIntercept:init()
                        AirIntercept:enable(OperationInfinity.state.difficulty)
                        IADS:init()
                        IADS:enable(OperationInfinity.state.difficulty)
                        done()
                    end)
                end,
            },
            {
                name = "markers",
                fn = function(ctx, done)
                    progress("Generating map markers...")
                    OperationInfinity:generateMapMarkersBatched(done)
                end,
            },
        },
        onComplete = function(ctx)
            -- Display completion message
            local completionMsg = "=== OPERATION INFINITY ===\n" ..
                "Difficulty: " .. OperationInfinity.state.difficulty .. "\n" ..
                "Playtime: " .. OperationInfinity.state.playtime .. " minutes\n" ..
                "Target Area: " .. ctx.selected.region.name .. "\n\n" ..
                "BATTLEFIELD READY\n\n" ..
                "Good hunting, pilots!" .. ctx.virtNote
            trigger.action.outTextForCoalition(coalition.side.BLUE, completionMsg, 15)

            -- Display coordinates after a short delay
            timer.scheduleFunction(function()
                OperationInfinity:displayCoordinates()
            end, nil, timer.getTime() + 3)

            -- Add Mission Info menu for on-demand target info
            OperationInfinity:setupMissionInfoMenu()

            OperationInfinity:log("Battlefield generation complete")
        end,
    })
end

-- =============================================================================
-- FRONTLINE GENERATION
-- =============================================================================

function OperationInfinity:generateFrontlineSectors()
    local numSectors = self:randomInRange(
        self.config.frontline.sectorsMin,
        self.config.frontline.sectorsMax
    )

    self:log("Generating " .. numSectors .. " frontline sectors")

    for i = 1, numSectors do
        local sector = self:generateSector(i)
        table.insert(self.state.battlefield.sectors, sector)
    end
end

function OperationInfinity:generateSector(index)
    -- Pick a random target aerodrome from the selected region
    local aerodromes = self.state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]

    -- Generate position 10-40 miles from the aerodrome
    local sectorCenter = self:randomPointNearAerodrome(aerodrome)

    local numPairs = self:randomInRange(
        self.config.frontline.platoonPairsMin,
        self.config.frontline.platoonPairsMax
    )

    self:log("Sector " .. index .. ": " .. numPairs .. " platoon pairs near " ..
        aerodrome.name .. " at (" .. math.floor(sectorCenter.x) .. ", " ..
        math.floor(sectorCenter.y) .. ")")

    -- Generate platoon pairs
    for j = 1, numPairs do
        self:generatePlatoonPair(sectorCenter, index, j)
    end

    -- Generate SHORAD for this sector
    self:generateSectorSHORAD(sectorCenter, index)

    return { center = sectorCenter, platoonPairs = numPairs }
end

function OperationInfinity:generatePlatoonPair(sectorCenter, sectorIndex, pairIndex)
    local offset = (pairIndex - 1) * 300 -- Spread pairs along front

    -- Randomized engagement distance (300-1000m)
    local engageDist = self:randomInRange(
        self.config.frontline.engagementDistanceMin,
        self.config.frontline.engagementDistanceMax
    )

    -- Randomize the front line orientation slightly
    local frontAngle = math.random() * 0.3 - 0.15 -- Small angle variation

    -- Initial positions
    local isafPosInitial = {
        x = sectorCenter.x + offset * math.cos(frontAngle),
        y = sectorCenter.y - engageDist / 2,
    }

    local eruseaPosInitial = {
        x = sectorCenter.x + offset * math.cos(frontAngle),
        y = sectorCenter.y + engageDist / 2,
    }

    -- Find valid terrain for ISAF platoon (100m search radius)
    local isafPos, isafValid = self:findValidPosition(isafPosInitial, 100)
    if not isafValid then
        self:log("Skipping ISAF platoon S" .. sectorIndex .. "-P" .. pairIndex .. " - no valid terrain")
        return
    end

    -- Find valid terrain for Erusea platoon
    local eruseaPos, eruseaValid = self:findValidPosition(eruseaPosInitial, 100)
    if not eruseaValid then
        self:log("Skipping Erusea platoon S" .. sectorIndex .. "-P" .. pairIndex .. " - no valid terrain")
        return
    end

    -- Calculate facing directions (toward each other)
    local isafFacing = math.atan2(eruseaPos.y - isafPos.y, eruseaPos.x - isafPos.x)
    local eruseaFacing = math.atan2(isafPos.y - eruseaPos.y, isafPos.x - eruseaPos.x)

    -- Select random formation for this pair
    local formation = self:getRandomFormationType()

    -- Build ISAF units with formation and facing
    local isafTemplate = self:randomizeTemplate(UnitTemplates.ISAFPlatoon)
    local isafUnits = self:buildPlatoonUnits(isafTemplate, isafPos, {
        formation = formation,
        facing = isafFacing,
    })
    Virtualization:registerGroup({
        name = "ISAF-S" .. sectorIndex .. "-P" .. pairIndex,
        center = isafPos,
        units = isafUnits,
        countryId = country.id.CJTF_BLUE,
        category = Group.Category.GROUND,
    }, {
        immortal = true,
        invisible = true,
        fireAtPoint = {
            x = eruseaPos.x,
            y = eruseaPos.y - self.config.frontline.fireOffset,
            radius = 50,
            expendQty = 200,
        },
    })

    -- Build Erusea units with formation and facing
    local diff = self.state.difficulty
    local baseEruseaTemplate = UnitTemplates.EruseaPlatoon[diff] or UnitTemplates.EruseaPlatoon.Normal
    local eruseaTemplate = self:randomizeTemplate(baseEruseaTemplate)
    local eruseaUnits = self:buildPlatoonUnits(eruseaTemplate, eruseaPos, {
        formation = formation,
        facing = eruseaFacing,
    })
    Virtualization:registerGroup({
        name = "Erusea-S" .. sectorIndex .. "-P" .. pairIndex,
        center = eruseaPos,
        units = eruseaUnits,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        fireAtPoint = {
            x = isafPos.x,
            y = isafPos.y + self.config.frontline.fireOffset,
            radius = 50,
            expendQty = 200,
        },
    })
end

function OperationInfinity:buildPlatoonUnits(template, center, options)
    options = options or {}
    local formation = options.formation or self:getRandomFormationType()
    local facing = options.facing or (math.random() * 2 * math.pi)
    local spacing = options.spacing or 30
    local jitterMin = options.jitterMin or 10
    local jitterMax = options.jitterMax or 15

    -- Count total units
    local totalUnits = 0
    for _, def in ipairs(template) do
        totalUnits = totalUnits + def.count
    end

    -- Get formation positions
    local formationPositions = self:getFormationPositions(totalUnits, formation, spacing)

    local units = {}
    local unitIndex = 1

    for _, def in ipairs(template) do
        for c = 1, def.count do
            local formPos = formationPositions[unitIndex] or {x = 0, y = 0}

            -- Rotate position to face the correct direction
            local rotatedPos = self:rotatePosition(formPos, facing)

            -- Add random jitter (10-15m, visible from aircraft altitude)
            local jitterAmount = jitterMin + math.random() * (jitterMax - jitterMin)
            local jitterAngle = math.random() * 2 * math.pi
            local jitterX = jitterAmount * math.cos(jitterAngle)
            local jitterY = jitterAmount * math.sin(jitterAngle)

            -- Add heading variance (±10 degrees from facing)
            local headingVariance = (math.random() - 0.5) * math.rad(20)
            local unitHeading = facing + headingVariance

            units[#units + 1] = {
                type = def.type,
                x = center.x + rotatedPos.x + jitterX,
                y = center.y + rotatedPos.y + jitterY,
                heading = unitHeading,
                skill = "High",
            }
            unitIndex = unitIndex + 1
        end
    end

    return units
end

function OperationInfinity:generateSectorSHORAD(sectorCenter, sectorIndex)
    local diff = self.state.difficulty
    local shoradTemplate = UnitTemplates.SHORAD[diff]

    if not shoradTemplate or #shoradTemplate == 0 then
        return
    end

    -- Position SHORAD slightly behind Erusean lines
    local initialPos = {
        x = sectorCenter.x + (math.random() - 0.5) * 500,
        y = sectorCenter.y + 1000 + math.random() * 500,
    }

    -- Find valid terrain for SHORAD
    local shoradPos, valid = self:findValidPosition(initialPos, 200)
    if not valid then
        self:log("Skipping SHORAD-S" .. sectorIndex .. " - no valid terrain")
        return
    end

    -- Apply template randomization and random formation
    local template = self:randomizeTemplate(shoradTemplate)
    local units = self:buildPlatoonUnits(template, shoradPos, {
        formation = self:getRandomFormationType(),
    })

    Virtualization:registerGroup({
        name = "SHORAD-S" .. sectorIndex,
        center = shoradPos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

-- Batched version of generateFrontlineSectors
function OperationInfinity:generateFrontlineSectorsBatched(onComplete)
    local numSectors = self:randomInRange(
        self.config.frontline.sectorsMin,
        self.config.frontline.sectorsMax
    )

    self:log("Generating " .. numSectors .. " frontline sectors (batched)")

    -- Build array of sector indices to process
    local sectorIndices = {}
    for i = 1, numSectors do
        table.insert(sectorIndices, i)
    end

    BatchScheduler:processArray({
        array = sectorIndices,
        callback = function(sectorIndex)
            local sector = OperationInfinity:generateSector(sectorIndex)
            table.insert(OperationInfinity.state.battlefield.sectors, sector)
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- BEHIND-LINES TARGETS
-- =============================================================================

function OperationInfinity:generateBehindLinesTargets()
    -- Generate convoys
    local numConvoys = self:randomInRange(
        self.config.behindLines.convoyCount[1],
        self.config.behindLines.convoyCount[2]
    )
    for i = 1, numConvoys do
        self:generateConvoy(i)
    end

    -- Generate artillery batteries
    local numArtillery = self:randomInRange(
        self.config.behindLines.artilleryCount[1],
        self.config.behindLines.artilleryCount[2]
    )
    for i = 1, numArtillery do
        self:generateArtilleryBattery(i)
    end

    -- Generate patrol groups
    local numPatrols = self:randomInRange(
        self.config.behindLines.patrolCount[1],
        self.config.behindLines.patrolCount[2]
    )
    for i = 1, numPatrols do
        self:generatePatrolGroup(i)
    end

    self:log("Generated behind-lines targets: " .. numConvoys .. " convoys, " ..
        numArtillery .. " artillery, " .. numPatrols .. " patrols")
end

function OperationInfinity:generateConvoy(index)
    -- Pick a random target aerodrome and position convoy near it
    local aerodromes = self.state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local initialPos = self:randomPointNearAerodrome(aerodrome)

    -- Convoys should be near roads (within 100m)
    local pos, valid = self:findValidPosition(initialPos, 200, {
        maxRoadDistance = 100,
    })
    if not valid then
        self:log("Skipping Convoy-" .. index .. " near " .. aerodrome.name .. " - no valid terrain near roads")
        return
    end

    -- Apply template randomization and use LINE formation for convoy
    local template = self:randomizeTemplate(UnitTemplates.LogisticsConvoy)
    local units = self:buildPlatoonUnits(template, pos, {
        formation = self.FormationType.LINE,
        spacing = 20, -- Tighter spacing for convoy
    })

    Virtualization:registerGroup({
        name = "Convoy-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

function OperationInfinity:generateArtilleryBattery(index)
    -- Pick a random target aerodrome and position artillery near it
    local aerodromes = self.state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local initialPos = self:randomPointNearAerodrome(aerodrome)

    -- Artillery needs flatter terrain (8 degree max slope)
    local pos, valid = self:findValidPosition(initialPos, 300, {
        maxSlope = 8,
    })
    if not valid then
        self:log("Skipping Artillery-" .. index .. " near " .. aerodrome.name .. " - no valid flat terrain")
        return
    end

    -- Find a frontline position to fire at
    local targetSector = self.state.battlefield.sectors[math.random(#self.state.battlefield.sectors)]
    local fireTarget = nil
    local facingDirection = math.random() * 2 * math.pi

    if targetSector then
        fireTarget = {
            x = targetSector.center.x + (math.random() - 0.5) * 500,
            y = targetSector.center.y - 400, -- Aim at ISAF side
            radius = 100,
            expendQty = 500,
        }
        -- Face toward the target
        facingDirection = math.atan2(fireTarget.y - pos.y, fireTarget.x - pos.x)
    end

    -- Artillery batteries are homogenous - no unit type substitution
    local template = self:randomizeTemplate(UnitTemplates.ArtilleryBattery, {
        skipSubstitutions = true,
    })
    local units = self:buildPlatoonUnits(template, pos, {
        formation = self.FormationType.LINE,
        facing = facingDirection,
        spacing = 40, -- Wider spacing for artillery
    })

    Virtualization:registerGroup({
        name = "Artillery-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
        fireAtPoint = fireTarget,
    })
end

function OperationInfinity:generatePatrolGroup(index)
    -- Pick a random target aerodrome and position patrol near it
    local aerodromes = self.state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]
    local initialPos = self:randomPointNearAerodrome(aerodrome)

    -- Find valid terrain for patrol
    local pos, valid = self:findValidPosition(initialPos, 150)
    if not valid then
        self:log("Skipping Patrol-" .. index .. " near " .. aerodrome.name .. " - no valid terrain")
        return
    end

    -- Use simple 2-vehicle patrol with random heading
    local patrolHeading = math.random() * 2 * math.pi
    local template = {
        { type = "BRDM-2", count = 2 },
    }
    local units = self:buildPlatoonUnits(template, pos, {
        formation = self.FormationType.LINE,
        facing = patrolHeading,
        spacing = 25,
    })

    Virtualization:registerGroup({
        name = "Patrol-" .. index,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    }, {
        immortal = false,
        invisible = false,
    })
end

-- Batched version of generateBehindLinesTargets
function OperationInfinity:generateBehindLinesTargetsBatched(onComplete)
    -- Calculate all counts upfront
    local numConvoys = self:randomInRange(
        self.config.behindLines.convoyCount[1],
        self.config.behindLines.convoyCount[2]
    )
    local numArtillery = self:randomInRange(
        self.config.behindLines.artilleryCount[1],
        self.config.behindLines.artilleryCount[2]
    )
    local numPatrols = self:randomInRange(
        self.config.behindLines.patrolCount[1],
        self.config.behindLines.patrolCount[2]
    )

    -- Build work items array
    local workItems = {}
    for i = 1, numConvoys do
        table.insert(workItems, { type = "convoy", index = i })
    end
    for i = 1, numArtillery do
        table.insert(workItems, { type = "artillery", index = i })
    end
    for i = 1, numPatrols do
        table.insert(workItems, { type = "patrol", index = i })
    end

    self:log("Generating behind-lines targets (batched): " .. numConvoys .. " convoys, " ..
        numArtillery .. " artillery, " .. numPatrols .. " patrols")

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            if item.type == "convoy" then
                OperationInfinity:generateConvoy(item.index)
            elseif item.type == "artillery" then
                OperationInfinity:generateArtilleryBattery(item.index)
            elseif item.type == "patrol" then
                OperationInfinity:generatePatrolGroup(item.index)
            end
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- AIR DEFENSE GENERATION
-- =============================================================================

function OperationInfinity:generateAirDefenses()
    local samCounts = self.config.samCounts[self.state.difficulty]
    if not samCounts then
        return
    end

    local samTemplates = UnitTemplates.SAMSites[self.state.difficulty]
    if not samTemplates then
        return
    end

    self:log("Generating air defenses for difficulty: " .. self.state.difficulty)

    for samType, countRange in pairs(samCounts) do
        if samType ~= "EWR" then
            local template = samTemplates[samType]
            if template then
                local count = self:randomInRange(countRange[1], countRange[2])
                for i = 1, count do
                    self:generateSAMSite(samType, template, i)
                end
            end
        end
    end
end

function OperationInfinity:generateSAMSite(samType, template, index)
    -- Pick a random target aerodrome and position SAM site near it
    local aerodromes = self.state.battlefield.targetAerodromes
    local aerodrome = aerodromes[math.random(#aerodromes)]

    -- Position SAM sites closer to aerodrome than frontline units
    -- Heavier SAMs positioned closer to protect the aerodrome
    local minDist = 5000  -- 5 km minimum from aerodrome
    local maxDist = 30000 -- 30 km max
    if samType == "SA10" or samType == "SA11" then
        maxDist = 15000 -- Longer range SAMs closer to protect the aerodrome
    end

    local angle = math.random() * 2 * math.pi
    local distance = minDist + math.random() * (maxDist - minDist)

    local pos = {
        x = aerodrome.x + distance * math.cos(angle),
        y = aerodrome.y + distance * math.sin(angle),
    }

    local units = self:buildSAMUnits(template, pos)
    local groupName = samType .. "-" .. index

    -- Register as permanent group (always spawned - SAM radars need to be active)
    Virtualization:registerPermanentGroup({
        name = groupName,
        center = pos,
        units = units,
        countryId = country.id.CJTF_RED,
        category = Group.Category.GROUND,
    })

    -- Register with IADS for emission control
    IADS:registerSAMSite(groupName, samType, pos)

    self:log("Generated " .. samType .. " at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
end

function OperationInfinity:buildSAMUnits(template, center)
    local units = {}
    local unitIndex = 1

    for _, def in ipairs(template) do
        for c = 1, def.count do
            -- Arrange in a circular pattern
            local angle = (unitIndex - 1) * (2 * math.pi / 8)
            local radius = 50 + (unitIndex - 1) * 30

            units[#units + 1] = {
                type = def.type,
                x = center.x + radius * math.cos(angle),
                y = center.y + radius * math.sin(angle),
                heading = angle + math.pi, -- Face outward
                skill = "Excellent",
            }
            unitIndex = unitIndex + 1
        end
    end

    return units
end

-- Batched version of generateAirDefenses
function OperationInfinity:generateAirDefensesBatched(onComplete)
    local samCounts = self.config.samCounts[self.state.difficulty]
    if not samCounts then
        if onComplete then onComplete() end
        return
    end

    local samTemplates = UnitTemplates.SAMSites[self.state.difficulty]
    if not samTemplates then
        if onComplete then onComplete() end
        return
    end

    self:log("Generating air defenses for difficulty: " .. self.state.difficulty .. " (batched)")

    -- Build work items for all SAM sites
    local workItems = {}
    for samType, countRange in pairs(samCounts) do
        if samType ~= "EWR" then
            local template = samTemplates[samType]
            if template then
                local count = self:randomInRange(countRange[1], countRange[2])
                for i = 1, count do
                    table.insert(workItems, {
                        samType = samType,
                        template = template,
                        index = i,
                    })
                end
            end
        end
    end

    BatchScheduler:processArray({
        array = workItems,
        callback = function(item)
            OperationInfinity:generateSAMSite(item.samType, item.template, item.index)
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

function OperationInfinity:generateEWRs()
    local samCounts = self.config.samCounts[self.state.difficulty]
    local ewrCountRange = nil

    if samCounts and samCounts.EWR then
        ewrCountRange = samCounts.EWR
    else
        -- Default for Easy difficulty
        ewrCountRange = { 1, 2 }
    end

    local samTemplates = UnitTemplates.SAMSites[self.state.difficulty]
    local ewrTemplate = nil

    if samTemplates and samTemplates.EWR then
        ewrTemplate = samTemplates.EWR
    else
        -- Default EWR
        ewrTemplate = { { type = "1L13 EWR", count = 1 } }
    end

    local count = self:randomInRange(ewrCountRange[1], ewrCountRange[2])

    for i = 1, count do
        -- Pick a random target aerodrome and position EWR near it
        local aerodromes = self.state.battlefield.targetAerodromes
        local aerodrome = aerodromes[math.random(#aerodromes)]

        -- Position EWRs at moderate distance from aerodrome
        local minDist = 10000  -- 10 km minimum
        local maxDist = 40000  -- 40 km max
        local angle = math.random() * 2 * math.pi
        local distance = minDist + math.random() * (maxDist - minDist)

        local pos = {
            x = aerodrome.x + distance * math.cos(angle),
            y = aerodrome.y + distance * math.sin(angle),
        }

        local units = {}
        for _, def in ipairs(ewrTemplate) do
            for c = 1, def.count do
                units[#units + 1] = {
                    type = def.type,
                    x = pos.x + (c - 1) * 50,
                    y = pos.y,
                    heading = 0,
                    skill = "Excellent",
                }
            end
        end

        local groupName = "EWR-" .. i

        -- EWRs are permanent groups
        Virtualization:registerPermanentGroup({
            name = groupName,
            center = pos,
            units = units,
            countryId = country.id.CJTF_RED,
            category = Group.Category.GROUND,
        })

        IADS:registerEWR(groupName)

        self:log("Generated EWR at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
    end
end

-- Batched version of generateEWRs
function OperationInfinity:generateEWRsBatched(onComplete)
    local samCounts = self.config.samCounts[self.state.difficulty]
    local ewrCountRange = nil

    if samCounts and samCounts.EWR then
        ewrCountRange = samCounts.EWR
    else
        ewrCountRange = { 1, 2 }
    end

    local samTemplates = UnitTemplates.SAMSites[self.state.difficulty]
    local ewrTemplate = nil

    if samTemplates and samTemplates.EWR then
        ewrTemplate = samTemplates.EWR
    else
        ewrTemplate = { { type = "1L13 EWR", count = 1 } }
    end

    local count = self:randomInRange(ewrCountRange[1], ewrCountRange[2])

    -- Build array of EWR indices
    local ewrIndices = {}
    for i = 1, count do
        table.insert(ewrIndices, i)
    end

    self:log("Generating " .. count .. " EWRs (batched)")

    BatchScheduler:processArray({
        array = ewrIndices,
        context = { template = ewrTemplate },
        callback = function(i, _, ctx)
            local aerodromes = OperationInfinity.state.battlefield.targetAerodromes
            local aerodrome = aerodromes[math.random(#aerodromes)]

            local minDist = 10000
            local maxDist = 40000
            local angle = math.random() * 2 * math.pi
            local distance = minDist + math.random() * (maxDist - minDist)

            local pos = {
                x = aerodrome.x + distance * math.cos(angle),
                y = aerodrome.y + distance * math.sin(angle),
            }

            local units = {}
            for _, def in ipairs(ctx.template) do
                for c = 1, def.count do
                    units[#units + 1] = {
                        type = def.type,
                        x = pos.x + (c - 1) * 50,
                        y = pos.y,
                        heading = 0,
                        skill = "Excellent",
                    }
                end
            end

            local groupName = "EWR-" .. i

            Virtualization:registerPermanentGroup({
                name = groupName,
                center = pos,
                units = units,
                countryId = country.id.CJTF_RED,
                category = Group.Category.GROUND,
            })

            IADS:registerEWR(groupName)

            OperationInfinity:log("Generated EWR at (" .. math.floor(pos.x) .. ", " .. math.floor(pos.y) .. ")")
        end,
        onComplete = function()
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- COORDINATE DISPLAY
-- =============================================================================

function OperationInfinity:formatCoordinates(pos)
    -- Convert to Lat/Lon
    local lat, lon, alt = coord.LOtoLL({x = pos.x, y = 0, z = pos.y})

    -- Convert to MGRS
    local mgrs = coord.LLtoMGRS(lat, lon)
    local mgrsStr = mgrs.UTMZone .. mgrs.MGRSDigraph .. " " ..
        string.format("%05d", math.floor(mgrs.Easting)) .. " " ..
        string.format("%05d", math.floor(mgrs.Northing))

    -- Format Lat/Lon
    local latDir = lat >= 0 and "N" or "S"
    local lonDir = lon >= 0 and "E" or "W"
    local latDeg = math.floor(math.abs(lat))
    local latMin = (math.abs(lat) - latDeg) * 60
    local lonDeg = math.floor(math.abs(lon))
    local lonMin = (math.abs(lon) - lonDeg) * 60

    local llStr = string.format("%02d*%06.3f'%s %03d*%06.3f'%s",
        latDeg, latMin, latDir, lonDeg, lonMin, lonDir)

    return llStr, mgrsStr
end

function OperationInfinity:displayCoordinates()
    if not self.state.missionGenerated then
        return
    end

    local region = self.state.battlefield.region
    local aerodromes = self.state.battlefield.targetAerodromes

    -- Build list of aerodrome coordinates
    local coordLines = {}
    for _, aerodrome in ipairs(aerodromes) do
        local llStr, mgrsStr = self:formatCoordinates(aerodrome)
        table.insert(coordLines, string.format("  %s:\n    MGRS: %s\n    LL: %s",
            aerodrome.name, mgrsStr, llStr))
    end

    local msg = string.format(
        "=== TARGET AREA ===\n" ..
        "%s\n\n" ..
        "Target Aerodromes:\n%s\n\n" ..
        "Difficulty: %s\n" ..
        "Good hunting!",
        region.name,
        table.concat(coordLines, "\n"),
        self.state.difficulty
    )

    trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 30)
end

function OperationInfinity:setupMissionInfoMenu()
    missionCommands.addCommandForCoalition(
        coalition.side.BLUE,
        "Mission Info",
        nil,
        function() OperationInfinity:displayCoordinates() end
    )
end

-- =============================================================================
-- MAP MARKERS
-- =============================================================================

function OperationInfinity:generateMapMarkers()
    self:log("Generating map markers...")

    -- Mark each frontline sector accurately (friendly intel)
    for i, sector in ipairs(self.state.battlefield.sectors) do
        -- Offset slightly toward ISAF (south) side for clarity
        local markerPos = {
            x = sector.center.x,
            y = sector.center.y - 200, -- 200m south of sector center
        }
        self:addMarker("FEBA SECTOR " .. i, markerPos)
        self:log("Added FEBA marker for sector " .. i)
    end

    -- Mark target aerodromes with inaccuracy (1-3 km offset)
    for _, aerodrome in ipairs(self.state.battlefield.targetAerodromes) do
        -- Random offset between 1-3 km
        local offsetDistance = 1000 + math.random() * 2000
        local offsetAngle = math.random() * 2 * math.pi
        local markerPos = {
            x = aerodrome.x + offsetDistance * math.cos(offsetAngle),
            y = aerodrome.y + offsetDistance * math.sin(offsetAngle),
        }
        self:addMarker("OBJ " .. string.upper(aerodrome.name), markerPos)
        self:log("Added OBJ marker for " .. aerodrome.name .. " (offset: " ..
            math.floor(offsetDistance) .. "m)")
    end

    self:log("Map markers generated")
end

-- Batched version of generateMapMarkers
function OperationInfinity:generateMapMarkersBatched(onComplete)
    self:log("Generating map markers (batched)...")

    -- Build array of all markers to create
    local markerItems = {}

    -- FEBA sector markers
    for i, sector in ipairs(self.state.battlefield.sectors) do
        table.insert(markerItems, {
            type = "sector",
            label = "FEBA SECTOR " .. i,
            pos = {
                x = sector.center.x,
                y = sector.center.y - 200,
            },
        })
    end

    -- Aerodrome objective markers
    for _, aerodrome in ipairs(self.state.battlefield.targetAerodromes) do
        local offsetDistance = 1000 + math.random() * 2000
        local offsetAngle = math.random() * 2 * math.pi
        table.insert(markerItems, {
            type = "aerodrome",
            label = "OBJ " .. string.upper(aerodrome.name),
            pos = {
                x = aerodrome.x + offsetDistance * math.cos(offsetAngle),
                y = aerodrome.y + offsetDistance * math.sin(offsetAngle),
            },
        })
    end

    BatchScheduler:processArray({
        array = markerItems,
        callback = function(item)
            OperationInfinity:addMarker(item.label, item.pos)
            OperationInfinity:log("Added " .. item.type .. " marker: " .. item.label)
        end,
        onComplete = function()
            OperationInfinity:log("Map markers generated")
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- LATE JOINER SUPPORT
-- =============================================================================

function OperationInfinity:checkForNewPlayers()
    local players = coalition.getPlayers(coalition.side.BLUE)

    for _, player in ipairs(players) do
        if player and player:isExist() then
            local name = player:getName()
            if not self.state.knownPlayers[name] then
                self.state.knownPlayers[name] = true

                if self.state.missionGenerated then
                    -- Send coordinates to new player after a short delay
                    timer.scheduleFunction(function()
                        OperationInfinity:displayCoordinates()
                    end, nil, timer.getTime() + 5)

                    self:log("New player joined: " .. name)
                end
            end
        end
    end
end

-- =============================================================================
-- STATS
-- =============================================================================

function OperationInfinity:getStats()
    local virtStats = Virtualization:getStats()
    local airStats = AirIntercept:getStats()
    local iadsStats = IADS:getStats()

    return {
        missionGenerated = self.state.missionGenerated,
        difficulty = self.state.difficulty,
        playtime = self.state.playtime,
        sectors = #self.state.battlefield.sectors,
        virtualization = virtStats,
        airIntercept = airStats,
        iads = iadsStats,
    }
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function OperationInfinity:init()
    if self.state.initialized then
        self:log("Already initialized!")
        return
    end

    self:log("Initializing Operation Infinity...")

    -- Random number generator seeding is not required in this environment

    -- Display initial hint
    timer.scheduleFunction(function()
        trigger.action.outTextForCoalition(coalition.side.BLUE,
            "=== OPERATION INFINITY ===\n\n" ..
            "Welcome to Operation Infinity!\n\n" ..
            "Use the F10 menu to select:\n" ..
            "  1. Difficulty\n" ..
            "  2. Target Playtime\n\n" ..
            "The first player to make both selections\n" ..
            "locks the settings for all players.\n\n" ..
            "Support assets available:\n" ..
            "  AWACS Overlord: 255.5 MHz\n" ..
            "  Texaco (boom): 270.5 MHz, TACAN 100X\n" ..
            "  Arco (drogue): 270.1 MHz, TACAN 101X", 30)
    end, nil, timer.getTime() + 5)

    -- Setup F10 menu
    self:setupMenu()

    -- Start late joiner check loop
    timer.scheduleFunction(function(_, time)
        OperationInfinity:checkForNewPlayers()
        return time + 10 -- Check every 10 seconds
    end, nil, timer.getTime() + 10)

    self.state.initialized = true
    self:log("Initialization complete")
end

-- =============================================================================
-- START
-- =============================================================================

OperationInfinity:init()

env.info("[OperationInfinity] Loaded successfully")

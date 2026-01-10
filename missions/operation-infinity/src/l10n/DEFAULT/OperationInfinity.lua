-- =============================================================================
-- OPERATION INFINITY - MAIN MISSION SCRIPT
-- F10 menu, battlefield generation, and coordination display
-- =============================================================================

OperationInfinity = {}

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

OperationInfinity.config = {
    coordinateDisplayInterval = 60, -- Seconds between coordinate broadcasts
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

    -- Terrain exclusion zones (mountain regions from terrain data)
    -- These are areas with steep slopes where ground vehicles cannot operate
    terrainExclusions = {
        -- SouthWest Mountain 2 (center: -180030, 513939, avg elevation 1005m)
        {
            vertices = {
                {x = -181000, y = 510000}, {x = -180000, y = 507000},
                {x = -179000, y = 510000}, {x = -179000, y = 518000},
                {x = -180000, y = 520000}, {x = -181000, y = 519000},
            }
        },
        -- NorthWest Mountain 1 (center: -206556, 606667, avg elevation 1213m)
        {
            vertices = {
                {x = -206000, y = 604000}, {x = -205000, y = 604000},
                {x = -205000, y = 607000}, {x = -207000, y = 609000},
                {x = -209000, y = 609000}, {x = -207000, y = 605000},
            }
        },
        -- NorthWest Hill 70 - major Caucasus ridge (7577 km2, avg 2220m, steep slopes)
        {
            vertices = {
                {x = -153000, y = 535000}, {x = -135000, y = 733000},
                {x = -135000, y = 735000}, {x = -138000, y = 741000},
                {x = -179000, y = 822000}, {x = -187000, y = 824000},
                {x = -190000, y = 824000}, {x = -233000, y = 810000},
                {x = -237000, y = 808000}, {x = -242000, y = 803000},
                {x = -242000, y = 800000}, {x = -238000, y = 734000},
            }
        },
        -- NorthWest Hill 75 (1780 km2, avg 2383m)
        {
            vertices = {
                {x = -217000, y = 844000}, {x = -212000, y = 804000},
                {x = -209000, y = 801000}, {x = -201000, y = 801000},
                {x = -198000, y = 802000}, {x = -197000, y = 803000},
                {x = -175000, y = 833000}, {x = -175000, y = 836000},
                {x = -179000, y = 871000}, {x = -190000, y = 896000},
                {x = -194000, y = 898000}, {x = -199000, y = 900000},
            }
        },
    },

    -- Battlefield zones by playtime
    battlefieldZones = {
        ["45"] = {
            center = { x = -40000, y = 320000 },
            radius = 30000, -- 30 km
            name = "Anapa/Novorossiysk Area",
            description = "Close Air Support",
        },
        ["90"] = {
            center = { x = -220000, y = 560000 },
            radius = 50000, -- 50 km
            name = "Sukhumi/Zugdidi Area",
            description = "Interdiction",
        },
        ["180"] = {
            center = { x = -290000, y = 700000 },
            radius = 60000, -- 60 km
            name = "Kutaisi/Tbilisi Area",
            description = "Deep Strike",
        },
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
        center = nil,
        radius = nil,
        sectors = {},
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

-- =============================================================================
-- TERRAIN VALIDATION
-- =============================================================================

-- Point-in-polygon test using ray casting algorithm
function OperationInfinity:pointInPolygon(point, polygon)
    local x, y = point.x, point.y
    local inside = false
    local n = #polygon

    local j = n
    for i = 1, n do
        local xi, yi = polygon[i].x, polygon[i].y
        local xj, yj = polygon[j].x, polygon[j].y

        if ((yi > y) ~= (yj > y)) and (x < (xj - xi) * (y - yi) / (yj - yi) + xi) then
            inside = not inside
        end
        j = i
    end

    return inside
end

-- Check if position falls within any terrain exclusion zone
function OperationInfinity:isInExclusionZone(pos)
    for _, zone in ipairs(self.config.terrainExclusions) do
        if self:pointInPolygon(pos, zone.vertices) then
            return true
        end
    end
    return false
end

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

    -- Check exclusion zones first (fastest check)
    if self:isInExclusionZone(center) then
        return false, "in exclusion zone"
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

    local zone = self.config.battlefieldZones[self.state.playtime]
    self.state.battlefield.center = zone.center
    self.state.battlefield.radius = zone.radius

    trigger.action.outTextForCoalition(coalition.side.BLUE,
        "=== OPERATION INFINITY ===\n" ..
        "Difficulty: " .. self.state.difficulty .. "\n" ..
        "Playtime: " .. self.state.playtime .. " minutes\n" ..
        "Area: " .. zone.name .. "\n\n" ..
        "Generating battlefield...", 15)

    self:log("Generating battlefield - Difficulty: " .. self.state.difficulty ..
        ", Playtime: " .. self.state.playtime)

    -- Generate frontline sectors
    self:generateFrontlineSectors()

    -- Generate behind-lines targets
    self:generateBehindLinesTargets()

    -- Generate SAM sites (Normal/Hard)
    if self.state.difficulty == "Normal" or self.state.difficulty == "Hard" then
        self:generateAirDefenses()
    end

    -- Generate EWRs (Easy+)
    if self.state.difficulty ~= "VeryEasy" then
        self:generateEWRs()
    end

    -- Initialize other systems
    Virtualization:init()
    Virtualization:spawnPermanentGroups()

    AirIntercept:init()
    AirIntercept:enable(self.state.difficulty)

    IADS:init()
    IADS:enable(self.state.difficulty)

    -- Display coordinates after a short delay
    timer.scheduleFunction(function()
        OperationInfinity:displayCoordinates()
    end, nil, timer.getTime() + 3)

    -- Start coordinate display loop
    self:startCoordinateLoop()

    self:log("Battlefield generation complete")
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
    -- Position sectors in a spread pattern
    local angle = ((index - 1) / 5) * 2 * math.pi + (math.random() - 0.5) * 0.5
    local distance = self.state.battlefield.radius * (0.3 + math.random() * 0.5)

    local sectorCenter = {
        x = self.state.battlefield.center.x + distance * math.cos(angle),
        y = self.state.battlefield.center.y + distance * math.sin(angle),
    }

    local numPairs = self:randomInRange(
        self.config.frontline.platoonPairsMin,
        self.config.frontline.platoonPairsMax
    )

    self:log("Sector " .. index .. ": " .. numPairs .. " platoon pairs at (" ..
        math.floor(sectorCenter.x) .. ", " .. math.floor(sectorCenter.y) .. ")")

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
    -- Position convoys behind Erusean lines (north of battlefield center)
    local initialPos = {
        x = self.state.battlefield.center.x + (math.random() - 0.5) * self.state.battlefield.radius,
        y = self.state.battlefield.center.y + self.state.battlefield.radius * 0.3 +
            math.random() * self.state.battlefield.radius * 0.5,
    }

    -- Convoys should be near roads (within 100m)
    local pos, valid = self:findValidPosition(initialPos, 200, {
        maxRoadDistance = 100,
    })
    if not valid then
        self:log("Skipping Convoy-" .. index .. " - no valid terrain near roads")
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
    -- Position artillery further behind lines
    local initialPos = {
        x = self.state.battlefield.center.x + (math.random() - 0.5) * self.state.battlefield.radius * 0.8,
        y = self.state.battlefield.center.y + self.state.battlefield.radius * 0.5 +
            math.random() * self.state.battlefield.radius * 0.3,
    }

    -- Artillery needs flatter terrain (8 degree max slope)
    local pos, valid = self:findValidPosition(initialPos, 300, {
        maxSlope = 8,
    })
    if not valid then
        self:log("Skipping Artillery-" .. index .. " - no valid flat terrain")
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
    -- Scatter patrol groups throughout the battlefield
    local initialPos = self:randomPointInRadius(
        self.state.battlefield.center,
        self.state.battlefield.radius * 0.9
    )

    -- Find valid terrain for patrol
    local pos, valid = self:findValidPosition(initialPos, 150)
    if not valid then
        self:log("Skipping Patrol-" .. index .. " - no valid terrain")
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
    -- Position SAM sites within battlefield, with heavier ones further back
    local distanceMultiplier = 0.5
    if samType == "SA10" or samType == "SA11" then
        distanceMultiplier = 0.7 -- Longer range SAMs further back
    end

    local angle = math.random() * 2 * math.pi
    local distance = self.state.battlefield.radius * distanceMultiplier +
        math.random() * self.state.battlefield.radius * 0.3

    local pos = {
        x = self.state.battlefield.center.x + distance * math.cos(angle),
        y = self.state.battlefield.center.y + distance * math.sin(angle),
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
        -- Position EWRs on high ground throughout the area
        local angle = (i - 1) * (2 * math.pi / count) + math.random() * 0.5
        local distance = self.state.battlefield.radius * 0.6 + math.random() * self.state.battlefield.radius * 0.3

        local pos = {
            x = self.state.battlefield.center.x + distance * math.cos(angle),
            y = self.state.battlefield.center.y + distance * math.sin(angle),
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

-- =============================================================================
-- COORDINATE DISPLAY
-- =============================================================================

function OperationInfinity:formatCoordinates(pos)
    -- Convert to Lat/Lon
    local lat, lon, alt = coord.LOtoLL(pos.x, 0, pos.y)

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

    local center = self.state.battlefield.center
    local zone = self.config.battlefieldZones[self.state.playtime]

    local llStr, mgrsStr = self:formatCoordinates(center)

    local msg = string.format(
        "=== TARGET AREA ===\n" ..
        "%s\n\n" ..
        "Center:\n" ..
        "  MGRS: %s\n" ..
        "  LL: %s\n\n" ..
        "Radius: %d km\n\n" ..
        "Difficulty: %s\n" ..
        "Good hunting!",
        zone.name, mgrsStr, llStr,
        zone.radius / 1000,
        self.state.difficulty
    )

    trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 30)
end

function OperationInfinity:startCoordinateLoop()
    timer.scheduleFunction(function(_, time)
        if OperationInfinity.state.missionGenerated then
            OperationInfinity:displayCoordinates()
        end
        return time + OperationInfinity.config.coordinateDisplayInterval
    end, nil, timer.getTime() + self.config.coordinateDisplayInterval)
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

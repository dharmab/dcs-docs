-- =============================================================================
-- OPERATION INFINITY - MAIN MISSION SCRIPT
-- F10 menu, battlefield orchestration, and coordination display
-- =============================================================================

-- Guard against multiple script loads (belt-and-suspenders with trigger flag)
if _G.OperationInfinityLoaded then
    env.info("[OperationInfinity] Script already loaded, skipping re-initialization")
    return
end
_G.OperationInfinityLoaded = true

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
    -- spawnConstraints: optional overrides for ISAF spawn positioning
    --   angleMin/angleMax: radians, 0=East, pi/2=North, pi=West, 3pi/2=South
    --   minDistance/maxDistance: meters from aerodrome
    --   noFrontline: if true, skip frontline generation (logistics/defense only)
    aerodromeRegions = {
        northwest = {
            name = "Maykop Area",
            aerodromes = { "maykop" },
            playtimes = { "45" },
            -- Default spawn constraints work well for Maykop
        },
        central_coast = {
            name = "Gudauta/Sukhumi Area",
            aerodromes = { "gudauta", "sukhumi" },
            playtimes = { "45", "90" },
            -- Mountainous terrain unsuitable for frontline - use deep strike targets
            spawnConstraints = {
                noFrontline = true,
            },
        },
        southwest_coast = {
            name = "Kobuleti/Senaki/Kutaisi Area",
            aerodromes = { "kobuleti", "senaki", "kutaisi" },
            playtimes = { "90" },
            -- North or northwest of Senaki, looking for flat areas
            spawnConstraints = {
                angleMin = math.pi * 0.5,   -- North
                angleMax = math.pi,          -- West (NW quadrant)
                minDistance = 8000,          -- ~5 miles
                maxDistance = 24000,         -- ~15 miles
            },
        },
        northeast = {
            name = "Mozdok Area",
            aerodromes = { "mozdok" },
            playtimes = { "180" },
            -- Default spawn constraints work well for Mozdok
        },
        southeast = {
            name = "Tbilisi/Vaziani Area",
            aerodromes = { "tbilisi", "vaziani" },
            playtimes = { "180" },
            -- Deep strike area - no good frontline positions, focus on defense and logistics
            spawnConstraints = {
                noFrontline = true,
            },
        },
    },

    -- Battlefield spawning distances from aerodromes
    battlefieldDistance = {
        min = 16000,  -- 10 miles in meters
        max = 64000,  -- 40 miles in meters
    },

    -- Frontline generation parameters
    frontline = {
        platoonSpacingMin = 4800,     -- 3 miles in meters (minimum between platoons)
        platoonSpacingMax = 11300,    -- 7 miles in meters (maximum between platoons)
        platoonCountMin = 4,          -- Minimum platoons along frontline
        platoonCountMax = 8,          -- Maximum platoons along frontline
        wobbleMax = 500,              -- Max perpendicular offset for natural variation
        terrainSearchRadius = 1000,   -- Search radius for flat terrain
        engagementDistanceMin = 300,  -- Minimum meters between opposing platoons
        engagementDistanceMax = 1000, -- Maximum meters between opposing platoons
        fireOffset = 300,             -- Meters offset for FireAtPoint (fire past enemies, not at them)
        fireTargetWanderInterval = 15,    -- Seconds between target position updates
        fireTargetWanderRadius = 150,     -- Meters to randomly wander fire targets
        enemyPlatoonsMin = 2,         -- Min enemy platoons per friendly platoon
        enemyPlatoonsMax = 3,         -- Max enemy platoons per friendly platoon
        enemySpreadRadius = 150,      -- Meters to spread enemy platoons around engagement area
    },

    -- Behind-lines targets (normal frontline operations)
    behindLines = {
        convoyCount = { 2, 4 },  -- Min/max convoys
        artilleryCount = { 1, 3 }, -- Min/max artillery batteries
        patrolCount = { 8, 12 },  -- Min/max patrol groups (scattered single targets)
    },

    -- Deep strike targets (noFrontline regions like Tbilisi)
    -- More logistics and defense targets to compensate for no frontline
    deepStrike = {
        convoyCount = { 5, 8 },       -- More logistics convoys
        artilleryCount = { 2, 4 },    -- More artillery
        patrolCount = { 12, 18 },     -- More scattered patrols (single targets)
        depotCount = { 2, 4 },        -- Supply depots
        fuelTankCount = { 3, 6 },     -- Fuel storage
    },

    -- Krymsk airfield position (player and support aircraft base)
    krymsk = { x = -7000, y = 295000 },

    -- Support aircraft racetrack positions by region
    -- Distances in meters (1 nautical mile = 1852 meters)
    supportRacetracks = {
        -- Maykop: 15 miles south of Krymsk
        northwest = {
            x = -7000 - (15 * 1852),  -- 15nm south
            y = 295000,
            trackLength = 50000,      -- 50km racetrack
            heading = 0,              -- East-West track
        },
        -- Gudauta/Sukhumi: 50 miles SE of Krymsk (toward the target area)
        central_coast = {
            x = -7000 - (50 * 1852 * 0.64),   -- 50nm at ~130 degrees heading (SE)
            y = 295000 + (50 * 1852 * 0.77),
            trackLength = 60000,
            heading = math.pi * 0.75,  -- NW-SE track aligned with route
        },
        -- Kobuleti/Senaki/Kutaisi: 50 miles SE of Krymsk
        southwest_coast = {
            x = -7000 - (50 * 1852 * 0.64),
            y = 295000 + (50 * 1852 * 0.77),
            trackLength = 60000,
            heading = math.pi * 0.75,
        },
        -- Mozdok: 100 miles east of Krymsk along Krymsk-Mozdok axis
        northeast = {
            x = -7000 - (100 * 1852 * 0.14),  -- 100nm at ~98 degrees heading (mostly E)
            y = 295000 + (100 * 1852 * 0.99),
            trackLength = 80000,
            heading = 0,  -- E-W track
        },
        -- Tbilisi: 180 miles SE of Krymsk
        southeast = {
            x = -7000 - (180 * 1852 * 0.45),  -- 180nm at ~117 degrees heading
            y = 295000 + (180 * 1852 * 0.89),
            trackLength = 80000,
            heading = math.pi * 0.65,  -- NW-SE track
        },
    },

    -- Support aircraft group names and orbit altitudes
    supportAircraft = {
        { name = "Magic", altitude = 7925, speed = 180 },  -- AWACS at 26,000 ft
        { name = "Texaco", altitude = 5486, speed = 180, radio = 270.5, tacan = "100X", tankerType = "boom" },
        { name = "Arco", altitude = 4877, speed = 180, radio = 270.1, tacan = "101X", tankerType = "drogue" },
        { name = "Shell", altitude = 4572, speed = 105, radio = 270.0, tacan = "102X", tankerType = "slow boom" },
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
        regionKey = nil,        -- Key of the selected region (for racetrack lookup)
        targetAerodromes = {},  -- Aerodromes in the selected region
        frontline = {
            center = nil,       -- Center point of the frontline
            axis = nil,         -- Direction vector along the frontline
            approachDir = nil,  -- Direction vector from Krymsk toward enemy
            isafPositions = {}, -- ISAF platoon positions for FEBA visualization
        },
        spawnConstraints = nil, -- Region-specific spawn constraints
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

function OperationInfinity:addFEBAShape()
    local lineColor = {0.2, 0.4, 0.9, 1.0}
    local arrowFill = {0.2, 0.4, 0.9, 0.5}
    local frontline = self.state.battlefield.frontline
    local positions = frontline.isafPositions

    if #positions < 1 then
        self:log("No ISAF positions for frontline, skipping FEBA shape")
        return
    end

    -- Sort positions along the frontline axis for consistent line drawing
    local axis = frontline.axis
    if axis then
        -- Project each position onto the frontline axis and sort by that value
        table.sort(positions, function(a, b)
            local projA = a.x * axis.x + a.y * axis.y
            local projB = b.x * axis.x + b.y * axis.y
            return projA < projB
        end)
    else
        -- Fall back to sorting by x coordinate
        table.sort(positions, function(a, b) return a.x < b.x end)
    end

    -- Draw line segments connecting friendly positions along the front
    for i = 1, #positions - 1 do
        self.state.markerCounter = self.state.markerCounter + 1
        local p1 = positions[i]
        local p2 = positions[i + 1]
        trigger.action.lineToAll(
            coalition.side.BLUE,
            self.state.markerCounter,
            {x = p1.x, y = land.getHeight(p1), z = p1.y},
            {x = p2.x, y = land.getHeight(p2), z = p2.y},
            lineColor,
            1,      -- dashed line
            true,   -- readOnly
            ""
        )
    end

    -- Draw arrows from each ISAF position pointing toward enemy (along approach direction)
    local arrowLength = 400  -- meters
    local approachDir = frontline.approachDir or {x = 0, y = 1}  -- Default to north if not set
    for _, pos in ipairs(positions) do
        self.state.markerCounter = self.state.markerCounter + 1
        local arrowEnd = {
            x = pos.x + approachDir.x * arrowLength,
            y = pos.y + approachDir.y * arrowLength,
        }
        trigger.action.arrowToAll(
            coalition.side.BLUE,
            self.state.markerCounter,
            {x = arrowEnd.x, y = land.getHeight(arrowEnd), z = arrowEnd.y},
            {x = pos.x, y = land.getHeight(pos), z = pos.y},
            lineColor,
            arrowFill,
            1,      -- dashed
            true,   -- readOnly
            ""
        )
    end

    -- Add FEBA label at center of the frontline (behind friendly lines)
    local centerPos = positions[math.ceil(#positions / 2)]
    self.state.markerCounter = self.state.markerCounter + 1
    local labelOffset = 200
    trigger.action.textToAll(
        coalition.side.BLUE,
        self.state.markerCounter,
        {
            x = centerPos.x - approachDir.x * labelOffset,
            y = land.getHeight(centerPos),
            z = centerPos.y - approachDir.y * labelOffset,
        },
        lineColor,
        {0, 0, 0, 0},  -- transparent background
        12,
        true,
        "FEBA"
    )

    self:log("Added FEBA shape with " .. #positions .. " positions")
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

-- Generate a random position near a given aerodrome
-- Optional constraints table can override default angle and distance ranges
function OperationInfinity:randomPointNearAerodrome(aerodrome, constraints)
    constraints = constraints or {}

    -- Use constraints if provided, otherwise use defaults
    local minDist = constraints.minDistance or self.config.battlefieldDistance.min
    local maxDist = constraints.maxDistance or self.config.battlefieldDistance.max

    local angle
    if constraints.angleMin and constraints.angleMax then
        -- Random angle within the constrained range
        local angleRange = constraints.angleMax - constraints.angleMin
        angle = constraints.angleMin + math.random() * angleRange
    else
        -- Full 360 degree range
        angle = math.random() * 2 * math.pi
    end

    local distance = minDist + math.random() * (maxDist - minDist)
    return {
        x = aerodrome.x + distance * math.cos(angle),
        y = aerodrome.y + distance * math.sin(angle),
    }
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
        { key = "45",  label = "45 Minutes (Western Caucasus)" },
        { key = "90",  label = "90 Minutes (Central Caucasus)" },
        { key = "180", label = "180 Minutes (Eastern Caucasus)" },
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
-- BATTLEFIELD GENERATION (ORCHESTRATION)
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
    self.state.battlefield.regionKey = selected.key
    self.state.battlefield.targetAerodromes = {}
    self.state.battlefield.spawnConstraints = selected.region.spawnConstraints or {}

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
                    BattlefieldGeneration:generateFrontlineBatched(done)
                end,
            },
            {
                name = "behind_lines",
                fn = function(ctx, done)
                    progress("Deploying enemy forces...")
                    BattlefieldGeneration:generateBehindLinesTargetsBatched(done)
                end,
            },
            {
                name = "air_defenses",
                fn = function(ctx, done)
                    if OperationInfinity.state.difficulty == "Normal" or
                       OperationInfinity.state.difficulty == "Hard" then
                        progress("Deploying air defenses...")
                        BattlefieldGeneration:generateAirDefensesBatched(done)
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
                        BattlefieldGeneration:generateEWRsBatched(done)
                    else
                        done()
                    end
                end,
            },
            {
                name = "airbase_shorad",
                fn = function(ctx, done)
                    if OperationInfinity.state.difficulty ~= "VeryEasy" then
                        progress("Deploying airbase defenses...")
                        BattlefieldGeneration:generateAirbaseSHORADBatched(done)
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
                        -- Start fire target wandering for visual interest
                        timer.scheduleFunction(function(_, time)
                            BattlefieldGeneration:updateFireTargets()
                            return time + OperationInfinity.config.frontline.fireTargetWanderInterval
                        end, nil, timer.getTime() + 15)
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
            {
                name = "support_aircraft",
                fn = function(ctx, done)
                    progress("Launching support aircraft...")
                    OperationInfinity:activateSupportAircraft(OperationInfinity.state.battlefield.regionKey)
                    done()
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

    -- Build tanker information
    local tankerLines = {}
    for _, aircraft in ipairs(self.config.supportAircraft) do
        if aircraft.tankerType then
            table.insert(tankerLines, string.format("  %s (%s): %.1f MHz, TACAN %s",
                aircraft.name, aircraft.tankerType, aircraft.radio, aircraft.tacan))
        end
    end

    local msg = string.format(
        "=== TARGET AREA ===\n" ..
        "%s\n\n" ..
        "Target Aerodromes:\n%s\n\n" ..
        "Tankers:\n%s\n\n" ..
        "Difficulty: %s\n" ..
        "Good hunting!",
        region.name,
        table.concat(coordLines, "\n"),
        table.concat(tankerLines, "\n"),
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
-- COMMS PLAN DISPLAY
-- =============================================================================

function OperationInfinity:displayCommsPlan()
    local msg = [[=== COMMUNICATIONS PLAN ===

KRYMSK AIRFIELD
  Tower: 254.1 MHz AM
  Ground: 254.3 MHz AM
  Radar: 254.5 MHz AM

MISSION FREQUENCIES
  Strike: 255.1 MHz AM
  GCI UHF: 255.3 MHz AM
  GCI VHF: 124.1 MHz VHF
  GCI FM: 32.1 MHz FM
  In-Game AWACS: 255.5 MHz AM

FLIGHT TACTICAL (AM)
  Red 1-5: 260.1, 260.3, 260.5, 260.7, 260.9
  Blue 1-5: 261.1, 261.3, 261.5, 261.7, 261.9
  Green 1-5: 262.1, 262.3, 262.5, 262.7, 262.9

FLIGHT TACTICAL (FM)
  Yellow 1-5: 30.1, 30.3, 30.5, 30.7, 30.9
  Orange 1-5: 31.1, 31.3, 31.5, 31.7, 31.9

TANKERS
  Basket (Arco): 270.1 MHz AM
  Boom (Texaco): 270.5 MHz AM

GUARD
  Military: 243.0 MHz AM
  Civil: 121.5 MHz VHF]]

    trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 45)
end

function OperationInfinity:setupCommsPlanMenu()
    missionCommands.addCommandForCoalition(
        coalition.side.BLUE,
        "Comms Plan",
        nil,
        function() OperationInfinity:displayCommsPlan() end
    )
end

-- =============================================================================
-- MAP MARKERS
-- =============================================================================

-- Batched version of generateMapMarkers
function OperationInfinity:generateMapMarkersBatched(onComplete)
    self:log("Generating map markers (batched)...")

    -- Build array of all markers to create
    local markerItems = {}

    -- FEBA shape (single frontline)
    table.insert(markerItems, {
        type = "feba_shape",
    })

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
            if item.type == "feba_shape" then
                OperationInfinity:addFEBAShape()
            else
                OperationInfinity:addMarker(item.label, item.pos)
                OperationInfinity:log("Added " .. item.type .. " marker: " .. item.label)
            end
        end,
        onComplete = function()
            OperationInfinity:log("Map markers generated")
            if onComplete then onComplete() end
        end,
    })
end

-- =============================================================================
-- SUPPORT AIRCRAFT ACTIVATION
-- =============================================================================

-- Get the racetrack position for the selected region
function OperationInfinity:getRacetrackPosition(regionKey)
    local racetrack = self.config.supportRacetracks[regionKey]
    if not racetrack then
        -- Default to northwest if region not found
        self:log("WARNING: No racetrack config for region '" .. tostring(regionKey) .. "', using default")
        racetrack = self.config.supportRacetracks.northwest
    end
    return racetrack
end

-- Activate support aircraft and set their orbit positions based on selected region
function OperationInfinity:activateSupportAircraft(regionKey)
    local racetrack = self:getRacetrackPosition(regionKey)

    self:log("Activating support aircraft for region: " .. tostring(regionKey))
    self:log("Racetrack center: (" .. math.floor(racetrack.x) .. ", " .. math.floor(racetrack.y) .. ")")

    -- Calculate racetrack endpoints based on heading and track length
    local halfTrack = racetrack.trackLength / 2
    local heading = racetrack.heading or 0

    for i, aircraft in ipairs(self.config.supportAircraft) do
        -- Activate late activation group (spawns the aircraft)
        local group = Group.getByName(aircraft.name)
        if group then
            group:activate()
            self:log("Activated group: " .. aircraft.name)
        else
            self:log("WARNING: Could not find group to activate: " .. aircraft.name)
        end

        -- Offset each aircraft's racetrack slightly to avoid collisions
        -- AWACS highest and furthest back, tankers spread out
        local altOffset = (i - 1) * 500  -- 500m altitude separation
        local lateralOffset = (i - 1) * 5000  -- 5km lateral separation

        -- Calculate this aircraft's racetrack center (offset perpendicular to track)
        local perpHeading = heading + math.pi / 2
        local centerX = racetrack.x + lateralOffset * math.cos(perpHeading)
        local centerY = racetrack.y + lateralOffset * math.sin(perpHeading)

        -- Calculate racetrack endpoints
        local point1 = {
            x = centerX - halfTrack * math.cos(heading),
            y = centerY - halfTrack * math.sin(heading),
        }
        local point2 = {
            x = centerX + halfTrack * math.cos(heading),
            y = centerY + halfTrack * math.sin(heading),
        }

        local orbitAltitude = aircraft.altitude + altOffset

        -- Schedule orbit task to be pushed once aircraft is airborne
        local orbitTask = {
            id = "Orbit",
            params = {
                pattern = "Race-Track",
                point = point1,
                point2 = point2,
                altitude = orbitAltitude,
                speed = aircraft.speed,
            },
        }
        local groupName = aircraft.name
        local logCenterX = math.floor(centerX)
        local logCenterY = math.floor(centerY)

        -- Poll until aircraft is airborne, then push orbit task
        local function checkAndPushOrbit()
            local grp = Group.getByName(groupName)
            if not grp or not grp:isExist() then
                return timer.getTime() + 30  -- Group not ready yet, retry
            end

            local unit = grp:getUnit(1)
            if not unit or not unit:isExist() then
                return timer.getTime() + 30  -- Unit not ready yet, retry
            end

            -- Check if airborne (inAir returns true when not on ground)
            if unit:inAir() then
                local ctrl = grp:getController()
                if ctrl then
                    ctrl:pushTask(orbitTask)
                    OperationInfinity:log("Pushed orbit task to " .. groupName ..
                        " at (" .. logCenterX .. ", " .. logCenterY .. ")")
                end
                return nil  -- Done, stop polling
            else
                return timer.getTime() + 30  -- Not airborne yet, check again in 30 seconds
            end
        end

        -- Start polling after initial delay (60 sec for engine start)
        timer.scheduleFunction(checkAndPushOrbit, nil, timer.getTime() + 60)

        self:log("Will push orbit task to " .. aircraft.name .. " once airborne, alt " ..
            orbitAltitude .. "m, center (" .. logCenterX .. ", " .. logCenterY .. ")")
    end
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
                self:log("New player joined: " .. name)

                -- Schedule welcome/status message after a short delay
                timer.scheduleFunction(function()
                    if OperationInfinity.state.missionGenerated then
                        -- Mission already generated - show coordinates
                        OperationInfinity:displayCoordinates()
                    else
                        -- Mission not yet generated - show welcome message with instructions
                        trigger.action.outTextForCoalition(coalition.side.BLUE,
                            "=== OPERATION INFINITY ===\n\n" ..
                            "Welcome to Operation Infinity!\n\n" ..
                            "Use the F10 menu to select:\n" ..
                            "  1. Difficulty\n" ..
                            "  2. Target Playtime\n\n" ..
                            "The first player to make both selections\n" ..
                            "locks the settings for all players.\n\n" ..
                            "Support assets will launch after settings are selected:\n" ..
                            "  Texaco (boom): 270.5 MHz, TACAN 100X\n" ..
                            "  Arco (drogue): 270.1 MHz, TACAN 101X\n" ..
                            "  Shell (slow boom): 270.0 MHz, TACAN 102X\n\n" ..
                            "GCI: Use SkyEye on 255.3 MHz, 124.1 VHF, or 32.1 FM", 30)
                    end
                end, nil, timer.getTime() + 3)
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
        frontlinePlatoons = #self.state.battlefield.frontline.isafPositions,
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

    -- Setup F10 menus
    self:setupMenu()
    self:setupCommsPlanMenu()

    -- Start player check loop - runs early to catch singleplayer and first multiplayer joiners
    -- The welcome message is displayed by checkForNewPlayers when players are detected
    timer.scheduleFunction(function(_, time)
        OperationInfinity:checkForNewPlayers()
        return time + 5 -- Check every 5 seconds
    end, nil, timer.getTime() + 2)

    self.state.initialized = true
    self:log("Initialization complete")
end

-- =============================================================================
-- START
-- =============================================================================

OperationInfinity:init()

env.info("[OperationInfinity] Loaded successfully")

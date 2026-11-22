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

local METERS_PER_NM = 1852

OperationInfinity.config = {
    -- Ground unit budget. The scripting engine becomes unreliable above about
    -- 1000 units (docs/wisdom.md), and aircraft, ships, and weapons also count.
    maxSpawnedUnits = 600,
    -- Part of maxSpawnedUnits held back for permanent air defense groups,
    -- which are generated after the virtualized target groups
    airDefenseUnitReserve = 100,
    debug = true,

    -- Mission time limit (8 hours)
    missionDuration = 28800,
    missionWarnings = {
        { remaining = 3600, text = "1 hour" },
        { remaining = 1800, text = "30 minutes" },
        { remaining = 900, text = "15 minutes" },
        { remaining = 600, text = "10 minutes" },
        { remaining = 300, text = "5 minutes" },
    },
    missionEndFlag = "MISSION_TIME_EXPIRED",

    -- Aerodrome regions - geographic clusters for each playtime
    -- aerodromes: RED airbase names; positions are read into state.aerodromes at init
    -- spawnConstraints: optional overrides for ISAF spawn positioning
    --   angleMin/angleMax: radians, 0=East, pi/2=North, pi=West, 3pi/2=South
    --   minDistance/maxDistance: meters from aerodrome
    --   noFrontline: if true, skip frontline generation (logistics/defense only)
    aerodromeRegions = {
        northwest = {
            name = "Maykop Area",
            aerodromes = { "Maykop-Khanskaya" },
            playtimes = { "45" },
            -- Default spawn constraints work well for Maykop
        },
        central_coast = {
            name = "Gudauta/Sukhumi Area",
            aerodromes = { "Gudauta", "Sukhumi-Babushara" },
            playtimes = { "45", "90" },
            -- Mountainous terrain unsuitable for frontline - use deep strike targets
            spawnConstraints = {
                noFrontline = true,
                -- Overrides for config.approachRoute. This is a 45-minute region,
                -- so targets start ~60 nm from Krymsk instead of ~140 nm and are
                -- denser, giving players regular contact along the coast.
                approachRoute = {
                    safeZoneRadius = 50 * METERS_PER_NM,
                    waypointFractions = { 0.35, 0.45, 0.55, 0.65, 0.75, 0.85, 0.94 },
                    targetsPerWaypoint = {
                        patrolCount = { 4, 6 },
                        armorCount = { 1, 3 },
                        convoyCount = { 0, 1 },
                        checkpointCount = { 1, 2 },
                    },
                    -- Positive offsets are southwest of this route, toward the
                    -- coastal lowlands. Inland of the route is mountains.
                    corridorOffsetMin = -5000,
                    corridorOffsetMax = 8000,
                },
            },
        },
        southwest_coast = {
            name = "Kobuleti/Senaki/Kutaisi Area",
            aerodromes = { "Kobuleti", "Senaki-Kolkhi", "Kutaisi" },
            playtimes = { "90" },
            -- North or northwest of Senaki, looking for flat areas
            spawnConstraints = {
                angleMin = math.pi * 0.5, -- North
                angleMax = math.pi, -- West (NW quadrant)
                minDistance = 5 * METERS_PER_NM, -- ~5 nm
                maxDistance = 15 * METERS_PER_NM, -- ~15 nm
            },
        },
        northeast = {
            name = "Mozdok Area",
            aerodromes = { "Mozdok" },
            playtimes = { "180" },
            -- Default spawn constraints work well for Mozdok
        },
        southeast = {
            name = "Tbilisi/Vaziani Area",
            aerodromes = { "Tbilisi-Lochini", "Vaziani" },
            playtimes = { "180" },
            -- Deep strike area - no good frontline positions, focus on defense and logistics
            spawnConstraints = {
                noFrontline = true,
            },
        },
    },

    -- Battlefield spawning distances from aerodromes
    battlefieldDistance = {
        min = 10 * METERS_PER_NM, -- 10 nm
        max = 40 * METERS_PER_NM, -- 40 nm
    },

    -- Frontline generation parameters
    frontline = {
        platoonSpacingMin = 3 * METERS_PER_NM, -- 3 nm (minimum between platoons)
        platoonSpacingMax = 7 * METERS_PER_NM, -- 7 nm (maximum between platoons)
        platoonCountMin = 4, -- Minimum platoons along frontline
        platoonCountMax = 8, -- Maximum platoons along frontline
        wobbleMax = 500, -- Max perpendicular offset for natural variation
        terrainSearchRadius = 1000, -- Search radius for flat terrain
        engagementDistanceMin = 300, -- Minimum meters between opposing platoons
        engagementDistanceMax = 1000, -- Maximum meters between opposing platoons
        fireOffset = 300, -- Meters offset for FireAtPoint (fire past enemies, not at them)
        fireTargetWanderInterval = 15, -- Seconds between target position updates
        fireTargetWanderRadius = 150, -- Meters to randomly wander fire targets
        enemyPlatoonsMin = 2, -- Min enemy platoons per friendly platoon
        enemyPlatoonsMax = 3, -- Max enemy platoons per friendly platoon
        enemySpreadRadius = 150, -- Meters to spread enemy platoons around engagement area
    },

    -- Behind-lines targets (normal frontline operations)
    behindLines = {
        convoyCount = { 3, 5 }, -- Min/max convoys
        artilleryCount = { 3, 5 }, -- Min/max artillery batteries
        patrolCount = { 16, 22 }, -- Min/max patrol groups (scattered small groups)
        depotCount = { 3, 5 }, -- Supply depots in the rear area
        -- Depots are placed between a target aerodrome and this far behind
        -- the frontline (min/max meters)
        depotRearOffset = { 2 * METERS_PER_NM, 5 * METERS_PER_NM },
    },

    -- Deep strike targets (noFrontline regions like Tbilisi)
    -- More logistics and defense targets to compensate for no frontline
    deepStrike = {
        convoyCount = { 6, 10 }, -- More logistics convoys
        artilleryCount = { 4, 6 }, -- More artillery
        patrolCount = { 24, 32 }, -- More scattered patrols
        depotCount = { 3, 5 }, -- Supply depots
        fuelTankCount = { 4, 8 }, -- Fuel storage
    },

    -- F10 map hints for groups registered with a hint label (artillery, depots,
    -- fuel storage). Each hint is a circle of this radius placed so the target
    -- is inside it but off center. Removed when the group is destroyed.
    targetHints = {
        radius = 1500,
        -- The target is at most this fraction of the radius from the circle
        -- center, leaving room for the group's own spread inside the circle
        maxOffsetFraction = 0.8,
    },

    -- Approach route targets - enemies along flight path to deep strike zones
    -- Only applies to regions with noFrontline = true
    approachRoute = {
        -- Minimum distance from Krymsk - safe zone (no approach route targets)
        safeZoneRadius = 120 * METERS_PER_NM, -- 120 nm
        -- Waypoints as fraction of distance from Krymsk to target centroid
        -- Start at 0.82 to respect 120 nm safe zone
        waypointFractions = { 0.82, 0.88, 0.94 },
        -- Radius around each waypoint for target placement
        waypointRadius = 12000,
        -- Target counts per waypoint
        targetsPerWaypoint = {
            patrolCount = { 3, 5 },
            armorCount = { 1, 2 },
            convoyCount = { 0, 1 },
            checkpointCount = { 1, 2 },
        },
        -- Lateral offset from the approach corridor in meters. Positive is to
        -- the right of the route as seen from Krymsk.
        corridorOffsetMin = -8000,
        corridorOffsetMax = 8000,
    },

    -- Player and support aircraft airbase name. Position is read into state.homeAirbase at init.
    homeAirbase = "Krymsk",

    -- Support aircraft racetrack centers by region, as offsets from Krymsk
    supportRacetracks = {
        -- Maykop: 15 nm south of Krymsk
        northwest = {
            offset = { x = -(15 * METERS_PER_NM), y = 0 },
            trackLength = 50000, -- 50km racetrack
            heading = 0, -- North-South track
        },
        -- Gudauta/Sukhumi: 50 nm SE of Krymsk (~130 degrees, toward the target area)
        central_coast = {
            offset = { x = -(50 * METERS_PER_NM * 0.64), y = 50 * METERS_PER_NM * 0.77 },
            trackLength = 60000,
            heading = math.pi * 0.75, -- NW-SE track aligned with route
        },
        -- Kobuleti/Senaki/Kutaisi: 50 nm SE of Krymsk
        southwest_coast = {
            offset = { x = -(50 * METERS_PER_NM * 0.64), y = 50 * METERS_PER_NM * 0.77 },
            trackLength = 60000,
            heading = math.pi * 0.75,
        },
        -- Mozdok: 100 nm east of Krymsk along the Krymsk-Mozdok axis (~98 degrees)
        northeast = {
            offset = { x = -(100 * METERS_PER_NM * 0.14), y = 100 * METERS_PER_NM * 0.99 },
            trackLength = 80000,
            heading = 0, -- E-W track
        },
        -- Tbilisi: 180 nm SE of Krymsk (~117 degrees)
        southeast = {
            offset = { x = -(180 * METERS_PER_NM * 0.45), y = 180 * METERS_PER_NM * 0.89 },
            trackLength = 80000,
            heading = math.pi * 0.65, -- NW-SE track
        },
    },

    -- Support aircraft group names, orbit altitudes (feet MSL) and target
    -- indicated airspeeds (knots). The Orbit task takes TAS in m/s, which is
    -- derived at runtime from IAS and altitude (see indicatedToTrueAirspeed).
    -- Each aircraft gets its own altitude block; no per-index offset is added.
    supportAircraft = {
        {
            name = "Magic",
            role = "in-game E-3A AWACS, datalink only, no voice",
            altitudeFt = 30000,
            iasKnots = 280,
        },
        { name = "Texaco", altitudeFt = 20000, iasKnots = 280, radio = 270.5, tacan = "100X", tankerType = "boom" },
        { name = "Arco", altitudeFt = 18000, iasKnots = 250, radio = 270.1, tacan = "101X", tankerType = "drogue" },
        { name = "Shell", altitudeFt = 15000, iasKnots = 200, radio = 270.7, tacan = "102X", tankerType = "slow boom" },
    },

    -- SAM site counts by difficulty
    samCounts = {
        Easy = {
            SA2Incomplete = { 1, 2 },
            SA9 = { 1, 2 },
            SA13 = { 1, 2 },
        },
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

    -- Airbase positions read at init: { name, x, y }
    ---@type { name: string, x: number, y: number }?
    homeAirbase = nil,
    aerodromes = {}, -- Keyed by airbase name

    -- Settings (locked when first player selects both)
    difficulty = nil,
    playtime = nil,
    settingsLockedBy = nil,

    -- Generated battlefield
    battlefield = {
        ---@type { name: string }?
        region = nil, -- Selected aerodrome region
        regionKey = nil, -- Key of the selected region (for racetrack lookup)
        targetAerodromes = {}, -- Aerodromes in the selected region
        frontline = {
            ---@type Vec2?
            center = nil, -- Center point of the frontline
            axis = nil, -- Direction vector along the frontline
            ---@type Vec2?
            approachDir = nil, -- Direction vector from Krymsk toward enemy
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

    -- Group IDs with per-group F10 items, keyed by group name
    menuGroups = {},

    -- Marker counter
    markerCounter = 1000,

    -- Mission timer state
    missionTimer = {
        warningsIssued = {},
        expired = false,
    },
}

-- Named constants
local FEBA_ARROW_LENGTH_METERS = 400
local FEBA_LABEL_OFFSET_METERS = 200
local HINT_LINE_COLOR = { 0.9, 0.2, 0.2, 1.0 }
local HINT_FILL_COLOR = { 0.9, 0.2, 0.2, 0.15 }
local LINE_TYPE_DASHED = 2

local log = Logging:create("OperationInfinity")

function OperationInfinity:addMarker(text, pos)
    self.state.markerCounter = self.state.markerCounter + 1
    local vec3 = { x = pos.x, y = land.getHeight(pos), z = pos.y }
    trigger.action.markToCoalition(
        self.state.markerCounter,
        text,
        vec3,
        coalition.side.BLUE,
        true, -- readOnly (players cannot delete)
        "" -- no announcement message
    )
end

-- Draw a hint circle that contains the group somewhere inside it, plus a
-- labelled mark at the circle center. Both are removed when the group dies.
function OperationInfinity:addTargetHint(vGroup)
    local cfg = self.config.targetHints
    -- sqrt spreads the offset evenly over the disc instead of bunching it at the center
    local offset = cfg.radius * cfg.maxOffsetFraction * math.sqrt(math.random())
    local angle = math.random() * 2 * math.pi
    local center = {
        x = vGroup.center.x + offset * math.cos(angle),
        y = vGroup.center.y + offset * math.sin(angle),
    }

    self.state.markerCounter = self.state.markerCounter + 1
    local circleId = self.state.markerCounter
    trigger.action.circleToAll(
        coalition.side.BLUE,
        circleId,
        { x = center.x, y = land.getHeight(center), z = center.y },
        cfg.radius,
        HINT_LINE_COLOR,
        HINT_FILL_COLOR,
        LINE_TYPE_DASHED,
        true, -- readOnly
        ""
    )
    self:addMarker(vGroup.hint, center)
    local markId = self.state.markerCounter

    vGroup.hintCenter = center
    vGroup.onDestroyed = function()
        trigger.action.removeMark(circleId)
        trigger.action.removeMark(markId)
        log("Removed hint for destroyed group " .. vGroup.name)
    end
end

function OperationInfinity:addFEBAShape()
    local lineColor = { 0.2, 0.4, 0.9, 1.0 }
    local arrowFill = { 0.2, 0.4, 0.9, 0.5 }
    local frontline = self.state.battlefield.frontline
    local positions = frontline.isafPositions

    if #positions < 1 then
        log("No ISAF positions for frontline, skipping FEBA shape")
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
        table.sort(positions, function(a, b)
            return a.x < b.x
        end)
    end

    -- Draw line segments connecting friendly positions along the front
    for i = 1, #positions - 1 do
        self.state.markerCounter = self.state.markerCounter + 1
        local p1 = positions[i]
        local p2 = positions[i + 1]
        trigger.action.lineToAll(
            coalition.side.BLUE,
            self.state.markerCounter,
            { x = p1.x, y = land.getHeight(p1), z = p1.y },
            { x = p2.x, y = land.getHeight(p2), z = p2.y },
            lineColor,
            1, -- dashed line
            true, -- readOnly
            ""
        )
    end

    -- Draw arrows from each ISAF position pointing toward enemy (along approach direction)
    local approachDir = frontline.approachDir or { x = 0, y = 1 } -- Default to east if not set
    for _, pos in ipairs(positions) do
        self.state.markerCounter = self.state.markerCounter + 1
        local arrowEnd = {
            x = pos.x + approachDir.x * FEBA_ARROW_LENGTH_METERS,
            y = pos.y + approachDir.y * FEBA_ARROW_LENGTH_METERS,
        }
        trigger.action.arrowToAll(
            coalition.side.BLUE,
            self.state.markerCounter,
            { x = arrowEnd.x, y = land.getHeight(arrowEnd), z = arrowEnd.y },
            { x = pos.x, y = land.getHeight(pos), z = pos.y },
            lineColor,
            arrowFill,
            1, -- dashed
            true, -- readOnly
            ""
        )
    end

    -- Add FEBA label at center of the frontline (behind friendly lines)
    local centerPos = positions[math.ceil(#positions / 2)]
    self.state.markerCounter = self.state.markerCounter + 1
    trigger.action.textToAll(
        coalition.side.BLUE,
        self.state.markerCounter,
        {
            x = centerPos.x - approachDir.x * FEBA_LABEL_OFFSET_METERS,
            y = land.getHeight(centerPos),
            z = centerPos.y - approachDir.y * FEBA_LABEL_OFFSET_METERS,
        },
        lineColor,
        { 0, 0, 0, 0 }, -- transparent background
        12,
        true,
        "FEBA"
    )

    log("Added FEBA shape with " .. #positions .. " positions")
end

-- Select a random region that matches the given playtime
function OperationInfinity:selectRegionForPlaytime(playtime)
    local matchingRegions = {}
    for key, region in pairs(self.config.aerodromeRegions) do
        for _, pt in ipairs(region.playtimes) do
            if pt == playtime then
                matchingRegions[#matchingRegions + 1] = { key = key, region = region }
                break
            end
        end
    end
    if #matchingRegions == 0 then
        log("WARNING: No regions match playtime " .. playtime)
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
    self.state.settingsMenu = missionCommands.addSubMenuForCoalition(coalition.side.BLUE, "Mission Settings", nil)

    -- Difficulty submenu
    self.state.difficultyMenu =
        missionCommands.addSubMenuForCoalition(coalition.side.BLUE, "Difficulty", self.state.settingsMenu)

    local difficulties = {
        { key = "VeryEasy", label = "Very Easy (Training - no enemies shoot back)" },
        { key = "Easy", label = "Easy (Light defenses, IR missiles only)" },
        { key = "Normal", label = "Normal (IADS, semi-active radar missiles)" },
        { key = "Hard", label = "Hard (Layered IADS, active radar missiles)" },
    }

    for _, diff in ipairs(difficulties) do
        missionCommands.addCommandForCoalition(coalition.side.BLUE, diff.label, self.state.difficultyMenu, function()
            OperationInfinity:selectDifficulty(diff.key)
        end)
    end

    -- Playtime submenu
    self.state.playtimeMenu =
        missionCommands.addSubMenuForCoalition(coalition.side.BLUE, "Target Playtime", self.state.settingsMenu)

    local playtimes = {
        { key = "45", label = "45 Minutes (Western Caucasus)" },
        { key = "90", label = "90 Minutes (Central Caucasus)" },
        { key = "180", label = "180 Minutes (Eastern Caucasus)" },
    }

    for _, pt in ipairs(playtimes) do
        missionCommands.addCommandForCoalition(coalition.side.BLUE, pt.label, self.state.playtimeMenu, function()
            OperationInfinity:selectPlaytime(pt.key)
        end)
    end
end

function OperationInfinity:selectDifficulty(difficulty)
    if self.state.missionGenerated then
        trigger.action.outTextForCoalition(coalition.side.BLUE, "Mission already generated!", 10)
        return
    end

    self.state.difficulty = difficulty
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Difficulty set to: " .. difficulty, 10)

    self:checkAndGenerate()
end

function OperationInfinity:selectPlaytime(playtime)
    if self.state.missionGenerated then
        trigger.action.outTextForCoalition(coalition.side.BLUE, "Mission already generated!", 10)
        return
    end

    self.state.playtime = playtime
    trigger.action.outTextForCoalition(coalition.side.BLUE, "Playtime set to: " .. playtime .. " minutes", 10)

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
        trigger.action.outTextForCoalition(
            coalition.side.BLUE,
            "ERROR: No region available for playtime " .. self.state.playtime,
            15
        )
        return
    end

    self.state.battlefield.region = selected.region
    self.state.battlefield.regionKey = selected.key
    self.state.battlefield.targetAerodromes = {}
    self.state.battlefield.spawnConstraints = selected.region.spawnConstraints or {}

    -- Populate target aerodromes from the selected region
    for _, name in ipairs(selected.region.aerodromes) do
        self.state.battlefield.targetAerodromes[#self.state.battlefield.targetAerodromes + 1] =
            self.state.aerodromes[name]
    end

    -- Build virtualization notice for longer missions
    local virtNote = ""
    if self.state.playtime == "90" or self.state.playtime == "180" then
        virtNote = "\n\nNote: For performance, ground units are virtualized "
            .. "and spawn when a player is within 100 nm."
    end

    log(
        "Generating battlefield - Difficulty: "
            .. self.state.difficulty
            .. ", Playtime: "
            .. self.state.playtime
            .. ", Region: "
            .. selected.region.name
    )

    Virtualization.config.maxVirtualUnits = self.config.maxSpawnedUnits - self.config.airDefenseUnitReserve

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
                name = "approach_route",
                fn = function(ctx, done)
                    progress("Deploying approach route targets...")
                    BattlefieldGeneration:generateApproachRouteTargetsBatched(done)
                end,
            },
            {
                name = "air_defenses",
                fn = function(ctx, done)
                    if OperationInfinity.state.difficulty ~= "VeryEasy" then
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
            local completionMsg = "=== OPERATION INFINITY ===\n"
                .. "Difficulty: "
                .. OperationInfinity.state.difficulty
                .. "\n"
                .. "Playtime: "
                .. OperationInfinity.state.playtime
                .. " minutes\n"
                .. "Target Area: "
                .. ctx.selected.region.name
                .. "\n\n"
                .. "BATTLEFIELD READY\n\n"
                .. "Good hunting, pilots!"
                .. ctx.virtNote
            trigger.action.outTextForCoalition(coalition.side.BLUE, completionMsg, 15)

            -- Display coordinates after a short delay
            timer.scheduleFunction(function()
                OperationInfinity:displayCoordinates()
            end, nil, timer.getTime() + 3)

            -- Add Mission Info menu for on-demand target info
            OperationInfinity:setupMissionInfoMenu()

            log("Battlefield generation complete")
        end,
    })
end

-- =============================================================================
-- COORDINATE DISPLAY
-- =============================================================================

function OperationInfinity:formatCoordinates(pos)
    -- Convert to Lat/Lon
    local lat, lon, alt = coord.LOtoLL({ x = pos.x, y = 0, z = pos.y })

    -- Convert to MGRS
    local mgrs = coord.LLtoMGRS(lat, lon)
    local mgrsStr = mgrs.UTMZone
        .. mgrs.MGRSDigraph
        .. " "
        .. string.format("%05d", math.floor(mgrs.Easting))
        .. " "
        .. string.format("%05d", math.floor(mgrs.Northing))

    -- Format Lat/Lon
    local latDir = lat >= 0 and "N" or "S"
    local lonDir = lon >= 0 and "E" or "W"
    local latDeg = math.floor(math.abs(lat))
    local latMin = (math.abs(lat) - latDeg) * 60
    local lonDeg = math.floor(math.abs(lon))
    local lonMin = (math.abs(lon) - lonDeg) * 60

    local llStr = string.format("%02d*%06.3f'%s %03d*%06.3f'%s", latDeg, latMin, latDir, lonDeg, lonMin, lonDir)

    return llStr, mgrsStr
end

function OperationInfinity:displayCoordinates(groupId)
    if not self.state.missionGenerated then
        return
    end

    local region = self.state.battlefield.region
    local aerodromes = self.state.battlefield.targetAerodromes

    -- Build list of aerodrome coordinates
    local coordLines = {}
    for _, aerodrome in ipairs(aerodromes) do
        local llStr, mgrsStr = self:formatCoordinates(aerodrome)
        coordLines[#coordLines + 1] = string.format("  %s:\n    MGRS: %s\n    LL: %s", aerodrome.name, mgrsStr, llStr)
    end

    local msg = string.format(
        "=== TARGET AREA ===\n"
            .. "%s\n\n"
            .. "Target Aerodromes:\n%s\n\n"
            .. "Support Assets:\n%s\n\n"
            .. "Difficulty: %s\n"
            .. "Good hunting!",
        region.name,
        table.concat(coordLines, "\n"),
        self:getSupportAssetText(),
        self.state.difficulty
    )

    -- No group means the generation-complete announcement, which goes to everyone
    if groupId then
        trigger.action.outTextForGroup(groupId, msg, 30)
    else
        trigger.action.outTextForCoalition(coalition.side.BLUE, msg, 30)
    end
end

-- Callsigns and frequencies of all support assets, one per line
function OperationInfinity:getSupportAssetText()
    local lines = {
        "  Magic (SkyEye GCI): 255.3 MHz AM, 124.1 MHz VHF, 32.1 MHz FM",
    }
    for _, aircraft in ipairs(self.config.supportAircraft) do
        if aircraft.tankerType then
            lines[#lines + 1] = string.format(
                "  %s (%s): %.1f MHz AM, TACAN %s, %d ft, %d KIAS",
                aircraft.name,
                aircraft.tankerType,
                aircraft.radio,
                aircraft.tacan,
                aircraft.altitudeFt,
                aircraft.iasKnots
            )
        else
            lines[#lines + 1] = string.format("  %s (%s)", aircraft.name, aircraft.role)
        end
    end
    lines[#lines + 1] = "  CVN-74 Stennis: 254.7 MHz AM, TACAN 74X STN, ICLS 4, Link 4 336.0"
    -- Arco 2-1 is a mission-file group over the carrier area, not on the regional racetrack
    lines[#lines + 1] = "  Arco 2-1 (S-3B basket): 270.3 MHz AM, TACAN 103X, 8000 ft, 250 KIAS over the carrier area"
    return table.concat(lines, "\n")
end

function OperationInfinity:addMissionInfoMenu(groupId)
    missionCommands.removeItemForGroup(groupId, { "Mission Info" })
    missionCommands.addCommandForGroup(groupId, "Mission Info", nil, function()
        OperationInfinity:displayCoordinates(groupId)
    end)
end

function OperationInfinity:setupMissionInfoMenu()
    for _, groupId in pairs(self.state.menuGroups) do
        self:addMissionInfoMenu(groupId)
    end
end

-- =============================================================================
-- COMMS PLAN DISPLAY
-- =============================================================================

function OperationInfinity:displayCommsPlan(groupId)
    local msg = [[=== COMMUNICATIONS PLAN ===

PRIMARY PRESETS
NAME          FREQ          SHORE CH   CVN-74 CH
Strike        255.1         1          1
Magic         255.3         2          2
Krymsk TWR    254.1         3          4
Krymsk GND    254.3         4          6
Krymsk RDR    254.5         5          5
Stennis       254.7         6          3
Texaco 1-1    270.5         7          -
Shell 1-1     270.7         8          -
Arco 1-1      270.1         7          7
Arco 2-1      270.3         8          8
Red 1-5       260.1-260.9   9-13       9-13
Blue 1-5      261.1-261.9   14-18      14-18
Guard         243.0         19         19
Green 1       262.1         20         20
F-4E has presets 1-18 only.
MiG-29A (full fidelity) R-862 numbers presets 0-19.

AUX PRESETS
  V/UHF radios: 1 Magic 124.1 VHF, 2-20 = PRIMARY 1-19
    F-14, F-15E, A-10 ARC-210: 21-25 Green 1-5
    F-14: 26 Magic 32.1 FM, 27-30 Yellow 1-4
    F-15E: 26 Magic 32.1 FM, 27-31 Yellow 1-5,
      32-36 Orange 1-5, 37 Civil Guard 121.5
  F-16 COMM2: 1 Magic 124.1, 2 Magic 32.1 FM,
    3 Civil Guard 121.5, 4-8 Yellow 1-5, 9-13 Orange 1-5
  A-10 FM: 1 Magic 32.1, 2-6 Yellow 1-5, 7-11 Orange 1-5
  F-4E AUX: 1 Texaco, 2 Shell
  F-15C, MiG-29A/S/G (FC), Su-25, Su-25T: tune manually in SRS

MAGIC (SkyEye GCI): voice on 255.3 AM, 124.1 AM, 32.1 FM
OVERFLOW INTERFLIGHT: Green 1-5 262.1-262.9
FM INTERFLIGHT: Yellow 1-5 30.1-30.9, Orange 1-5 31.1-31.9

CVN-74 STENNIS (~50 nm SW of Krymsk)
  TACAN 74X STN, ICLS 4, Link 4 336.0, ACLS

TANKERS
CALLSIGN   TYPE        NOTE        TACAN
Texaco 1-1 KC-135      Fast boom   100X
Shell 1-1  KC-135      Slow boom   102X
Arco 1-1   KC-135MPRS  Basket      101X
Arco 2-1   S-3B        Recovery    103X
Note: DCS bug shows Arco 1-1 and Arco 2-1 both as Arco 1 in the radio menu.

MAGIC (in-game E-3A AWACS): datalink only, no voice

GUARD
  Military: 243.0 MHz AM
  Civil: 121.5 MHz VHF]]

    trigger.action.outTextForGroup(groupId, msg, 45)
end

-- Comms Plan and Mission Info are per-group so replies go only to the
-- requesting group. Called for every player group by checkForNewPlayers.
function OperationInfinity:setupGroupMenus(group)
    local groupName = group:getName()
    if self.state.menuGroups[groupName] then
        return
    end
    local groupId = group:getID()
    self.state.menuGroups[groupName] = groupId

    -- Dynamic spawn can reuse a group ID, so clear any items left from an earlier group
    missionCommands.removeItemForGroup(groupId, { "Comms Plan" })
    missionCommands.addCommandForGroup(groupId, "Comms Plan", nil, function()
        OperationInfinity:displayCommsPlan(groupId)
    end)
    if self.state.missionGenerated then
        self:addMissionInfoMenu(groupId)
    end
end

-- =============================================================================
-- MAP MARKERS
-- =============================================================================

-- Batched version of generateMapMarkers
function OperationInfinity:generateMapMarkersBatched(onComplete)
    log("Generating map markers (batched)...")

    -- Build array of all markers to create
    local markerItems = {}

    -- FEBA shape (single frontline)
    markerItems[#markerItems + 1] = {
        type = "feba_shape",
    }

    -- Aerodrome objective markers
    for _, aerodrome in ipairs(self.state.battlefield.targetAerodromes) do
        local offsetDistance = 1000 + math.random() * 2000
        local offsetAngle = math.random() * 2 * math.pi
        markerItems[#markerItems + 1] = {
            type = "aerodrome",
            label = "OBJ " .. string.upper(aerodrome.name),
            pos = {
                x = aerodrome.x + offsetDistance * math.cos(offsetAngle),
                y = aerodrome.y + offsetDistance * math.sin(offsetAngle),
            },
        }
    end

    -- Fuzzed hints for groups registered with a hint label
    for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
        if vGroup.hint and not vGroup.destroyed then
            markerItems[#markerItems + 1] = {
                type = "target_hint",
                vGroup = vGroup,
            }
        end
    end

    BatchScheduler:processArray({
        array = markerItems,
        callback = function(item)
            if item.type == "feba_shape" then
                OperationInfinity:addFEBAShape()
            elseif item.type == "target_hint" then
                OperationInfinity:addTargetHint(item.vGroup)
                log("Added target hint: " .. item.vGroup.hint .. " for " .. item.vGroup.name)
            else
                OperationInfinity:addMarker(item.label, item.pos)
                log("Added " .. item.type .. " marker: " .. item.label)
            end
        end,
        onComplete = function()
            log("Map markers generated")
            if onComplete then
                onComplete()
            end
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
        log("WARNING: No racetrack config for region '" .. tostring(regionKey) .. "', using default")
        racetrack = self.config.supportRacetracks.northwest
    end
    local homeAirbase = self.state.homeAirbase
    return {
        x = homeAirbase.x + racetrack.offset.x,
        y = homeAirbase.y + racetrack.offset.y,
        trackLength = racetrack.trackLength,
        heading = racetrack.heading,
    }
end

local METERS_PER_FOOT = 0.3048
local MPS_PER_KNOT = 0.514444
local ISA_SEA_LEVEL_DENSITY = 1.225 -- kg/m^3
local ISA_LAPSE_FACTOR = 2.25577e-5 -- per meter, troposphere
local ISA_DENSITY_EXPONENT = 4.25588

-- Convert indicated airspeed to true airspeed (both m/s) using the ISA
-- troposphere density model (valid below 11 km). Treats IAS as EAS.
local function indicatedToTrueAirspeed(iasMps, altitudeMeters)
    local density = ISA_SEA_LEVEL_DENSITY * (1 - ISA_LAPSE_FACTOR * altitudeMeters) ^ ISA_DENSITY_EXPONENT
    return iasMps * math.sqrt(ISA_SEA_LEVEL_DENSITY / density)
end

-- Activate support aircraft and set their orbit positions based on selected region
function OperationInfinity:activateSupportAircraft(regionKey)
    local racetrack = self:getRacetrackPosition(regionKey)

    log("Activating support aircraft for region: " .. tostring(regionKey))
    log("Racetrack center: (" .. math.floor(racetrack.x) .. ", " .. math.floor(racetrack.y) .. ")")

    -- Calculate racetrack endpoints based on heading and track length
    local halfTrack = racetrack.trackLength / 2
    local heading = racetrack.heading or 0

    for i, aircraft in ipairs(self.config.supportAircraft) do
        -- Activate late activation group (spawns the aircraft)
        local group = Group.getByName(aircraft.name)
        if group then
            group:activate()
            -- The mission can run 8 hours; without this the aircraft go
            -- bingo, RTB and are never replaced
            group:getController():setCommand({ id = "SetUnlimitedFuel", params = { value = true } })
            log("Activated group with unlimited fuel: " .. aircraft.name)
        else
            log("WARNING: Could not find group to activate: " .. aircraft.name)
        end

        -- Offset each aircraft's racetrack laterally; altitude separation comes
        -- from each aircraft's own altitudeFt block
        local lateralOffset = (i - 1) * 5000 -- 5km lateral separation

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

        local orbitAltitude = aircraft.altitudeFt * METERS_PER_FOOT
        local orbitSpeed = indicatedToTrueAirspeed(aircraft.iasKnots * MPS_PER_KNOT, orbitAltitude)

        -- Schedule orbit task to be pushed once aircraft is airborne
        local orbitTask = {
            id = "Orbit",
            params = {
                pattern = "Race-Track",
                point = point1,
                point2 = point2,
                altitude = orbitAltitude,
                speed = orbitSpeed,
            },
        }
        local groupName = aircraft.name
        local logCenterX = math.floor(centerX)
        local logCenterY = math.floor(centerY)

        -- Poll until aircraft is airborne, then push orbit task
        local function checkAndPushOrbit()
            local grp = Group.getByName(groupName)
            if not grp or not grp:isExist() then
                return timer.getTime() + 30 -- Group not ready yet, retry
            end

            local unit = grp:getUnit(1)
            if not unit or not unit:isExist() then
                return timer.getTime() + 30 -- Unit not ready yet, retry
            end

            -- Check if airborne (inAir returns true when not on ground)
            if unit:inAir() then
                local ctrl = grp:getController()
                if ctrl then
                    ctrl:pushTask(orbitTask)
                    log("Pushed orbit task to " .. groupName .. " at (" .. logCenterX .. ", " .. logCenterY .. ")")
                end
                return nil -- Done, stop polling
            else
                return timer.getTime() + 30 -- Not airborne yet, check again in 30 seconds
            end
        end

        -- Start polling after initial delay (60 sec for engine start)
        timer.scheduleFunction(checkAndPushOrbit, nil, timer.getTime() + 60)

        log(
            "Will push orbit task to "
                .. aircraft.name
                .. " once airborne, alt "
                .. aircraft.altitudeFt
                .. " ft, "
                .. aircraft.iasKnots
                .. " KIAS ("
                .. math.floor(orbitSpeed)
                .. " m/s TAS), center ("
                .. logCenterX
                .. ", "
                .. logCenterY
                .. ")"
        )
    end
end

-- =============================================================================
-- LATE JOINER SUPPORT
-- =============================================================================

function OperationInfinity:checkForNewPlayers()
    local players = coalition.getPlayers(coalition.side.BLUE)

    for _, player in ipairs(players) do
        if player and player:isExist() then
            local group = player:getGroup()
            if group then
                self:setupGroupMenus(group)
            end

            local name = player:getName()
            if group and not self.state.knownPlayers[name] then
                local groupId = group:getID()
                self.state.knownPlayers[name] = true
                log("New player joined: " .. name)

                -- Schedule welcome/status message after a short delay
                timer.scheduleFunction(function()
                    if OperationInfinity.state.missionGenerated then
                        -- Mission already generated - show coordinates
                        OperationInfinity:displayCoordinates(groupId)
                    else
                        -- Mission not yet generated - show welcome message with instructions
                        trigger.action.outTextForGroup(
                            groupId,
                            "=== OPERATION INFINITY ===\n\n"
                                .. "Welcome to Operation Infinity!\n\n"
                                .. "Use the F10 menu to select:\n"
                                .. "  1. Difficulty\n"
                                .. "  2. Target Playtime\n\n"
                                .. "The first player to make both selections locks the settings for all players.\n\n"
                                .. "Support assets will launch after settings are selected:\n"
                                .. OperationInfinity:getSupportAssetText()
                                .. "\n\n"
                                .. "Full comms plan: F10 > Comms Plan",
                            30
                        )
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
-- MISSION TIME LIMIT
-- =============================================================================

function OperationInfinity:startMissionTimer()
    log("Starting mission timer - " .. self.config.missionDuration .. " seconds")

    local function checkMissionTime(_, currentTime)
        local missionTime = timer.getTime()
        local timeRemaining = OperationInfinity.config.missionDuration - missionTime

        for _, warning in ipairs(OperationInfinity.config.missionWarnings) do
            if
                timeRemaining <= warning.remaining
                and not OperationInfinity.state.missionTimer.warningsIssued[warning.remaining]
            then
                OperationInfinity.state.missionTimer.warningsIssued[warning.remaining] = true
                trigger.action.outTextForCoalition(
                    coalition.side.BLUE,
                    "=== MISSION TIME WARNING ===\n\n"
                        .. warning.text
                        .. " remaining until mission end.\n\n"
                        .. "RTB and land before time expires!",
                    30
                )
                log("Mission time warning: " .. warning.text .. " remaining")
            end
        end

        if timeRemaining <= 0 and not OperationInfinity.state.missionTimer.expired then
            OperationInfinity.state.missionTimer.expired = true
            trigger.action.outTextForCoalition(
                coalition.side.BLUE,
                "=== MISSION COMPLETE ===\n\n"
                    .. "The 8-hour operation window has ended.\n\n"
                    .. "Mission will restart shortly.\n\n"
                    .. "Thank you for flying!",
                60
            )
            log("Mission time expired - setting end flag")
            trigger.action.setUserFlag(OperationInfinity.config.missionEndFlag, 1)
            return nil
        end

        return currentTime + 10
    end

    timer.scheduleFunction(checkMissionTime, nil, timer.getTime() + 10)
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

local function getAirbasePosition(name)
    local airbase = Airbase.getByName(name)
    if not airbase then
        error("Airbase not found: " .. name)
    end
    local p = airbase:getPoint()
    return { name = name, x = p.x, y = p.z }
end

-- Read airfield positions from the airbases
function OperationInfinity:resolveAirbasePositions()
    self.state.homeAirbase = getAirbasePosition(self.config.homeAirbase)
    for _, region in pairs(self.config.aerodromeRegions) do
        for _, name in ipairs(region.aerodromes) do
            self.state.aerodromes[name] = getAirbasePosition(name)
        end
    end
end

function OperationInfinity:init()
    if self.state.initialized then
        log("Already initialized!")
        return
    end

    log("Initializing Operation Infinity...")

    self:resolveAirbasePositions()

    -- Random number generator seeding is not required in this environment

    -- Setup F10 menus
    self:setupMenu()

    -- Start mission time limit countdown
    self:startMissionTimer()

    -- Start player check loop - runs early to catch singleplayer and first multiplayer joiners
    -- The welcome message is displayed by checkForNewPlayers when players are detected
    timer.scheduleFunction(function(_, time)
        OperationInfinity:checkForNewPlayers()
        return time + 5 -- Check every 5 seconds
    end, nil, timer.getTime() + 2)

    self.state.initialized = true
    log("Initialization complete")
end

-- =============================================================================
-- START
-- =============================================================================

OperationInfinity:init()

env.info("[OperationInfinity] Loaded successfully")

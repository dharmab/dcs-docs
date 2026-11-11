-- =============================================================================
-- CARRIER OPERATIONS
-- Keeps the CVN-74 carrier strike group steaming into the wind, holds the
-- escorts on station, and flies a plane guard helicopter on the carrier's
-- starboard side.
-- =============================================================================

-- Guard against multiple script loads
if _G.CarrierOpsLoaded then
    env.info("[CarrierOps] Script already loaded, skipping")
    return
end
_G.CarrierOpsLoaded = true

CarrierOps = {}

local log = Logging:create("CarrierOps")

local KNOTS_TO_MPS = 0.514444
local METERS_PER_NM = 1852
local FEET_TO_METERS = 0.3048
local TWO_PI = 2 * math.pi

-- Height at which wind over the deck is sampled (roughly flight deck height)
local DECK_HEIGHT = 20

-- TACAN frequency constants (X mode, channels 64-126)
local TACAN_X_HIGH_BASE_MHZ = 1151
local TACAN_X_LOW_BASE_MHZ = 962
local TACAN_HIGH_CHANNEL_START = 64
local HZ_PER_MHZ = 1000000

-- DCS beacon enums: BEACON_TYPE_TACAN and SystemName.TACAN
local BEACON_TYPE_TACAN = 4
local BEACON_SYSTEM_TACAN = 3
local BEACON_TYPE_ICLS_GLIDESLOPE = 131584

-- =============================================================================
-- CONFIGURATION
-- =============================================================================

CarrierOps.config = {
    -- Operating area: a circle of open water SW of Anapa (~50 nm from Krymsk)
    opArea = {
        x = -70000,
        y = 225000,
        radius = 30000,
        -- Turn back this far inside the circle edge
        margin = 2000,
    },

    carrier = {
        groupName = "CVN-74 Stennis",
        unitName = "CVN-74 John C. Stennis",
        -- Target wind over deck for launch and recovery
        windOverDeck = 25 * KNOTS_TO_MPS,
        -- Speed limits while steaming into the wind
        minSpeed = 5 * KNOTS_TO_MPS,
        maxSpeed = 25 * KNOTS_TO_MPS,
        -- Speed while repositioning downwind (escorts must be able to keep up)
        repositionSpeed = 25 * KNOTS_TO_MPS,
        -- The angled deck points ~9 degrees to port of the bow. Steering this far
        -- right of the wind puts the wind straight down the landing area.
        angledDeckOffset = math.rad(9),
        -- Course to use when the wind is calm (no preferred direction)
        calmWindSpeed = 1.0,
        calmCourse = math.rad(270),
        -- Replan the into-wind leg if the wind shifts this much
        replanWindShift = math.rad(10),
        replanWindSpeedChange = 1.5,
        -- Leg is complete within this distance of its end point
        arrivalDistance = 1500,
        checkInterval = 30,
    },

    -- Systems activated on the carrier (re-applied after every route change,
    -- because beacons can drop when a ship is given a new route)
    systems = {
        tacanChannel = 74,
        tacanMode = "X",
        tacanCallsign = "STN",
        iclsChannel = 4,
        link4Frequency = 336.0,
        radioFrequency = 254.7,  -- Carrier (Marshal/Approach/LSO) per comm plan
        radioModulation = 0,     -- AM
        radioPower = 10,
    },

    -- Escort stations, fixed relative to the into-wind axis so ships run
    -- parallel tracks and never cross during the downwind repositioning leg.
    -- along: meters toward the upwind end of the track (negative = downwind)
    -- across: meters to the right of the into-wind course (negative = left)
    escorts = {
        { groupName = "CSG Cruiser", along = 3 * METERS_PER_NM, across = 1 * METERS_PER_NM, maxSpeed = 30 * KNOTS_TO_MPS },
        { groupName = "CSG Destroyer 1", along = 1 * METERS_PER_NM, across = -3 * METERS_PER_NM, maxSpeed = 30 * KNOTS_TO_MPS },
        { groupName = "CSG Destroyer 2", along = 0, across = 3 * METERS_PER_NM, maxSpeed = 30 * KNOTS_TO_MPS },
        { groupName = "CSG Frigate", along = -4 * METERS_PER_NM, across = 0, maxSpeed = 28 * KNOTS_TO_MPS },
    },
    escortCheckInterval = 60,
    -- Extra speed (m/s) per meter of along-track position error
    escortSpeedGain = 0.002,
    escortMinSpeedFactor = 0.5,

    -- Plane guard helicopter: starboard side, clear of the Case I pattern
    -- (break, downwind, and approach are all on the port side)
    planeGuard = {
        groupName = "Angel",
        type = "SH-60B",
        countryId = country.id.CJTF_BLUE,
        altitude = 300 * FEET_TO_METERS,
        -- Station relative to the carrier's bow (meters)
        ahead = 300,
        starboard = 900,
        -- Aim this far ahead of the station so the helo never slows to a stop
        leadDistance = 2000,
        -- Beyond this distance, fly straight to station at cruise speed
        joinDistance = 3000,
        cruiseSpeed = 120 * KNOTS_TO_MPS,
        minSpeed = 3 * KNOTS_TO_MPS,
        -- Extra speed (m/s) per meter of along-track position error
        speedGain = 0.05,
        updateInterval = 3,
        respawnDelay = 120,
    },
}

-- =============================================================================
-- STATE
-- =============================================================================

CarrierOps.state = {
    phase = nil,           -- "INTO_WIND" or "REPOSITION"
    legEnd = nil,          -- {x, y} end of the current leg
    legCourse = nil,       -- radians, course of the current leg
    legSpeed = nil,        -- m/s, carrier speed on the current leg
    windAxis = nil,        -- radians, into-wind course used for escort stations
    plannedWindFrom = nil,
    plannedWindSpeed = nil,
    planeGuardRespawnAt = nil,
}

-- =============================================================================
-- GEOMETRY HELPERS
-- DCS map: x = north, y (Vec3 z) = east. Headings are clockwise from north.
-- =============================================================================

local function normalizeAngle(angle)
    angle = angle % TWO_PI
    if angle < 0 then
        angle = angle + TWO_PI
    end
    return angle
end

local function angleDifference(a, b)
    local diff = math.abs(normalizeAngle(a) - normalizeAngle(b))
    if diff > math.pi then
        diff = TWO_PI - diff
    end
    return diff
end

local function unitVector(course)
    return { x = math.cos(course), y = math.sin(course) }
end

-- Offset a point by `forward` meters along `course` and `right` meters to its right
local function offsetPoint(origin, course, forward, right)
    return {
        x = origin.x + forward * math.cos(course) - right * math.sin(course),
        y = origin.y + forward * math.sin(course) + right * math.cos(course),
    }
end

local function toDegrees(angle)
    return math.floor(math.deg(normalizeAngle(angle)) + 0.5)
end

local function toKnots(speed)
    return math.floor(speed / KNOTS_TO_MPS + 0.5)
end

-- Distance from `pos` along `course` until leaving the circle
local function distanceToCircleEdge(pos, course, center, radius)
    local dir = unitVector(course)
    local fx = pos.x - center.x
    local fy = pos.y - center.y
    local b = fx * dir.x + fy * dir.y
    local c = fx * fx + fy * fy - radius * radius
    local discriminant = b * b - c
    if discriminant < 0 then
        return 0
    end
    return math.max(0, -b + math.sqrt(discriminant))
end

local function isDeepWater(pos)
    local ok, surfaceType = pcall(land.getSurfaceType, { x = pos.x, y = pos.y })
    return ok and surfaceType == land.SurfaceType.WATER
end

local function getUnitPosition2D(unit)
    local p = unit:getPoint()
    return { x = p.x, y = p.z }
end

local function getUnitHeading(unit)
    local orientation = unit:getPosition()
    return normalizeAngle(math.atan2(orientation.x.z, orientation.x.x))
end

local function getUnitSpeed(unit)
    local v = unit:getVelocity()
    return math.sqrt(v.x * v.x + v.z * v.z)
end

-- =============================================================================
-- WIND
-- =============================================================================

-- Returns the direction the wind blows FROM (radians) and its speed (m/s).
-- atmosphere.getWind returns the vector the air moves TOWARD, which avoids the
-- mission file's ambiguous wind direction convention.
function CarrierOps:getWindAt(pos)
    local wind = atmosphere.getWind({ x = pos.x, y = DECK_HEIGHT, z = pos.y })
    local speed = math.sqrt(wind.x * wind.x + wind.z * wind.z)
    local from = normalizeAngle(math.atan2(-wind.z, -wind.x))
    return from, speed
end

-- =============================================================================
-- CARRIER SYSTEMS
-- =============================================================================

local function tacanFrequency(channel, mode)
    -- Only X mode is used here; Y mode would need different bases
    if mode ~= "X" then
        log("WARNING: TACAN mode " .. tostring(mode) .. " not supported, using X")
    end
    if channel < TACAN_HIGH_CHANNEL_START then
        return (TACAN_X_LOW_BASE_MHZ + channel - 1) * HZ_PER_MHZ
    end
    return (TACAN_X_HIGH_BASE_MHZ + channel - TACAN_HIGH_CHANNEL_START) * HZ_PER_MHZ
end

function CarrierOps:activateCarrierSystems(carrierUnit)
    local controller = carrierUnit:getGroup():getController()
    local unitId = carrierUnit:getID()
    local sys = self.config.systems

    controller:setCommand({
        id = "ActivateBeacon",
        params = {
            type = BEACON_TYPE_TACAN,
            system = BEACON_SYSTEM_TACAN,
            name = "Stennis",
            callsign = sys.tacanCallsign,
            frequency = tacanFrequency(sys.tacanChannel, sys.tacanMode),
            channel = sys.tacanChannel,
            modeChannel = sys.tacanMode,
            AA = false,
            bearing = true,
            unitId = unitId,
        },
    })
    controller:setCommand({
        id = "ActivateICLS",
        params = {
            type = BEACON_TYPE_ICLS_GLIDESLOPE,
            channel = sys.iclsChannel,
            unitId = unitId,
            name = "Stennis",
        },
    })
    controller:setCommand({
        id = "ActivateLink4",
        params = {
            unitId = unitId,
            frequency = sys.link4Frequency * HZ_PER_MHZ,
            name = "Stennis",
        },
    })
    controller:setCommand({
        id = "ActivateACLS",
        params = {
            unitId = unitId,
            name = "Stennis",
        },
    })
    controller:setCommand({
        id = "SetFrequency",
        params = {
            frequency = sys.radioFrequency * HZ_PER_MHZ,
            modulation = sys.radioModulation,
            power = sys.radioPower,
        },
    })

    log("Carrier systems active: TACAN " .. sys.tacanChannel .. sys.tacanMode .. " " .. sys.tacanCallsign ..
        ", ICLS " .. sys.iclsChannel .. ", Link 4 " .. sys.link4Frequency ..
        ", ACLS on, radio " .. sys.radioFrequency .. " AM")
end

-- =============================================================================
-- SHIP ROUTING
-- =============================================================================

local function shipRoute(fromPos, toPos, speed)
    local function point(pos)
        return {
            x = pos.x,
            y = pos.y,
            alt = 0,
            type = "Turning Point",
            action = "Turning Point",
            speed = speed,
            speed_locked = true,
            ETA_locked = false,
            task = { id = "ComboTask", params = { tasks = {} } },
        }
    end
    return {
        id = "Mission",
        params = {
            route = {
                points = { point(fromPos), point(toPos) },
            },
        },
    }
end

function CarrierOps:getCarrierUnit()
    local unit = Unit.getByName(self.config.carrier.unitName)
    if unit and unit:isExist() then
        return unit
    end
    return nil
end

-- Into-wind course and speed for the current wind
function CarrierOps:computeIntoWindLeg(windFrom, windSpeed)
    local cfg = self.config.carrier
    local course
    if windSpeed < cfg.calmWindSpeed then
        course = self.state.windAxis or cfg.calmCourse
    else
        course = normalizeAngle(windFrom + cfg.angledDeckOffset)
    end

    -- Headwind component along the deck after the angled deck offset
    local headwind = windSpeed * math.cos(angleDifference(course, windFrom))
    local speed = cfg.windOverDeck - headwind
    speed = math.max(cfg.minSpeed, math.min(cfg.maxSpeed, speed))
    return course, speed
end

function CarrierOps:startIntoWindLeg(carrierUnit)
    local cfg = self.config.carrier
    local area = self.config.opArea
    local pos = getUnitPosition2D(carrierUnit)
    local windFrom, windSpeed = self:getWindAt(pos)
    local course, speed = self:computeIntoWindLeg(windFrom, windSpeed)

    local legLength = distanceToCircleEdge(pos, course, area, area.radius - area.margin)
    if legLength < cfg.arrivalDistance * 2 then
        log("Into-wind leg too short (" .. math.floor(legLength) .. " m), repositioning first")
        self.state.windAxis = course
        self:startRepositionLeg(carrierUnit)
        return
    end

    local legEnd = offsetPoint(pos, course, legLength, 0)
    if not isDeepWater(legEnd) then
        log("WARNING: Into-wind leg end is not deep water at (" ..
            math.floor(legEnd.x) .. ", " .. math.floor(legEnd.y) .. ")")
    end

    self.state.phase = "INTO_WIND"
    self.state.legEnd = legEnd
    self.state.legCourse = course
    self.state.legSpeed = speed
    self.state.windAxis = course
    self.state.plannedWindFrom = windFrom
    self.state.plannedWindSpeed = windSpeed

    carrierUnit:getGroup():getController():setTask(shipRoute(pos, legEnd, speed))
    self:activateCarrierSystems(carrierUnit)

    log(string.format("INTO_WIND: wind from %03d at %d kt, course %03d at %d kt (WOD ~%d kt), leg %.1f nm",
        toDegrees(windFrom), toKnots(windSpeed), toDegrees(course), toKnots(speed),
        toKnots(speed + windSpeed * math.cos(angleDifference(course, windFrom))),
        legLength / METERS_PER_NM))

    self:updateEscorts()
end

function CarrierOps:startRepositionLeg(carrierUnit)
    local cfg = self.config.carrier
    local area = self.config.opArea
    local pos = getUnitPosition2D(carrierUnit)
    local axis = self.state.windAxis or cfg.calmCourse

    -- Run back to the downwind side of the area, ready for the next into-wind leg
    local target = offsetPoint(area, axis, -(area.radius - area.margin), 0)
    local dx = target.x - pos.x
    local dy = target.y - pos.y
    local course = normalizeAngle(math.atan2(dy, dx))

    self.state.phase = "REPOSITION"
    self.state.legEnd = target
    self.state.legCourse = course
    self.state.legSpeed = cfg.repositionSpeed

    carrierUnit:getGroup():getController():setTask(shipRoute(pos, target, cfg.repositionSpeed))
    self:activateCarrierSystems(carrierUnit)

    log(string.format("REPOSITION: course %03d at %d kt, %.1f nm to downwind start point",
        toDegrees(course), toKnots(cfg.repositionSpeed),
        math.sqrt(dx * dx + dy * dy) / METERS_PER_NM))

    self:updateEscorts()
end

-- Has the carrier reached (or passed) the end of its current leg?
function CarrierOps:isLegComplete(pos)
    local legEnd = self.state.legEnd
    local dx = legEnd.x - pos.x
    local dy = legEnd.y - pos.y
    if math.sqrt(dx * dx + dy * dy) < self.config.carrier.arrivalDistance then
        return true
    end
    local dir = unitVector(self.state.legCourse)
    return (dx * dir.x + dy * dir.y) < 0
end

function CarrierOps:checkCarrier()
    local carrierUnit = self:getCarrierUnit()
    if not carrierUnit then
        log("Carrier not found or destroyed; stopping carrier control")
        return false
    end

    local pos = getUnitPosition2D(carrierUnit)

    if not self.state.phase then
        self:startIntoWindLeg(carrierUnit)
        return true
    end

    if self:isLegComplete(pos) then
        if self.state.phase == "INTO_WIND" then
            self:startRepositionLeg(carrierUnit)
        else
            self:startIntoWindLeg(carrierUnit)
        end
        return true
    end

    -- Replan the into-wind leg if the wind has changed significantly
    if self.state.phase == "INTO_WIND" then
        local cfg = self.config.carrier
        local windFrom, windSpeed = self:getWindAt(pos)
        local shifted = windSpeed >= cfg.calmWindSpeed and
            angleDifference(windFrom, self.state.plannedWindFrom) > cfg.replanWindShift
        local changed = math.abs(windSpeed - self.state.plannedWindSpeed) > cfg.replanWindSpeedChange
        if shifted or changed then
            log("Wind changed, replanning into-wind leg")
            self:startIntoWindLeg(carrierUnit)
        end
    end

    return true
end

-- =============================================================================
-- ESCORTS
-- =============================================================================

function CarrierOps:updateEscorts()
    local carrierUnit = self:getCarrierUnit()
    if not carrierUnit or not self.state.phase then
        return
    end

    local carrierPos = getUnitPosition2D(carrierUnit)
    local axis = self.state.windAxis
    local legDir = unitVector(self.state.legCourse)

    for _, escort in ipairs(self.config.escorts) do
        local group = Group.getByName(escort.groupName)
        local unit = group and group:getUnit(1)
        if unit and unit:isExist() then
            local escortPos = getUnitPosition2D(unit)
            local station = offsetPoint(carrierPos, axis, escort.along, escort.across)
            local stationEnd = offsetPoint(self.state.legEnd, axis, escort.along, escort.across)

            -- Speed up or slow down to close the along-track gap to station
            local alongError = (station.x - escortPos.x) * legDir.x + (station.y - escortPos.y) * legDir.y
            local speed = self.state.legSpeed + alongError * self.config.escortSpeedGain
            speed = math.max(self.state.legSpeed * self.config.escortMinSpeedFactor,
                math.min(escort.maxSpeed, speed))

            group:getController():setTask(shipRoute(escortPos, stationEnd, speed))
        end
    end
end

-- =============================================================================
-- PLANE GUARD HELICOPTER
-- =============================================================================

function CarrierOps:spawnPlaneGuard(carrierUnit)
    local cfg = self.config.planeGuard
    local carrierPos = getUnitPosition2D(carrierUnit)
    local heading = getUnitHeading(carrierUnit)
    local station = offsetPoint(carrierPos, heading, cfg.ahead, cfg.starboard)

    local groupData = {
        name = cfg.groupName,
        task = "Transport",
        units = {
            [1] = {
                name = cfg.groupName .. "-1",
                type = cfg.type,
                skill = "Excellent",
                x = station.x,
                y = station.y,
                alt = cfg.altitude,
                alt_type = "RADIO",
                speed = getUnitSpeed(carrierUnit),
                heading = heading,
                payload = {
                    pylons = {},
                    fuel = 1000,
                    flare = 30,
                    chaff = 30,
                    gun = 100,
                },
            },
        },
        route = {
            points = {
                [1] = {
                    x = station.x,
                    y = station.y,
                    alt = cfg.altitude,
                    alt_type = "RADIO",
                    type = "Turning Point",
                    action = "Turning Point",
                    speed = cfg.cruiseSpeed,
                    task = { id = "ComboTask", params = { tasks = {} } },
                },
            },
        },
    }

    local ok, result = pcall(coalition.addGroup, cfg.countryId, Group.Category.HELICOPTER, groupData)
    if not ok or not result then
        log("ERROR: Failed to spawn plane guard: " .. tostring(result))
        return
    end

    local controller = result:getController()
    controller:setCommand({ id = "SetUnlimitedFuel", params = { value = true } })
    controller:setOption(AI.Option.Air.id.ROE, AI.Option.Air.val.ROE.WEAPON_HOLD)
    log("Plane guard " .. cfg.type .. " spawned on carrier's starboard side with unlimited fuel")
end

function CarrierOps:updatePlaneGuard()
    local cfg = self.config.planeGuard
    local carrierUnit = self:getCarrierUnit()
    if not carrierUnit then
        return
    end

    local group = Group.getByName(cfg.groupName)
    local unit = group and group:getUnit(1)
    if not unit or not unit:isExist() then
        local now = timer.getTime()
        if not self.state.planeGuardRespawnAt then
            self.state.planeGuardRespawnAt = now + cfg.respawnDelay
            log("Plane guard lost, respawning in " .. cfg.respawnDelay .. " s")
        elseif now >= self.state.planeGuardRespawnAt then
            self.state.planeGuardRespawnAt = nil
            if group then
                group:destroy()
            end
            self:spawnPlaneGuard(carrierUnit)
        end
        return
    end

    local carrierPos = getUnitPosition2D(carrierUnit)
    local heading = getUnitHeading(carrierUnit)
    local carrierSpeed = getUnitSpeed(carrierUnit)
    local station = offsetPoint(carrierPos, heading, cfg.ahead, cfg.starboard)
    local heloPos = getUnitPosition2D(unit)

    local dx = station.x - heloPos.x
    local dy = station.y - heloPos.y
    local distance = math.sqrt(dx * dx + dy * dy)

    local aimPoint
    local speed
    if distance > cfg.joinDistance then
        aimPoint = station
        speed = cfg.cruiseSpeed
    else
        -- Fly toward a point ahead of station, matching the carrier's speed and
        -- adding a correction for any along-track gap
        aimPoint = offsetPoint(station, heading, cfg.leadDistance, 0)
        local alongError = dx * math.cos(heading) + dy * math.sin(heading)
        speed = carrierSpeed + alongError * cfg.speedGain
        speed = math.max(cfg.minSpeed, math.min(cfg.cruiseSpeed, speed))
    end

    local function point(pos)
        return {
            x = pos.x,
            y = pos.y,
            alt = cfg.altitude,
            alt_type = "RADIO",
            type = "Turning Point",
            action = "Turning Point",
            speed = speed,
            speed_locked = true,
            task = { id = "ComboTask", params = { tasks = {} } },
        }
    end

    group:getController():setTask({
        id = "Mission",
        params = { route = { points = { point(heloPos), point(aimPoint) } } },
    })
end

-- =============================================================================
-- INITIALIZATION
-- =============================================================================

function CarrierOps:validateOpArea()
    local area = self.config.opArea
    local samples = 16
    local dryPoints = 0
    for i = 0, samples - 1 do
        local angle = i * TWO_PI / samples
        local pos = offsetPoint(area, angle, area.radius, 0)
        if not isDeepWater(pos) then
            dryPoints = dryPoints + 1
            log(string.format("WARNING: Operating area edge at bearing %03d is not deep water", toDegrees(angle)))
        end
    end
    if dryPoints == 0 then
        log("Operating area validated: all " .. samples .. " edge samples are deep water")
    end
end

function CarrierOps:init()
    local carrierUnit = self:getCarrierUnit()
    if not carrierUnit then
        log("ERROR: Carrier unit '" .. self.config.carrier.unitName .. "' not found; carrier ops disabled")
        return
    end

    self:validateOpArea()
    self:checkCarrier()
    self:spawnPlaneGuard(carrierUnit)

    timer.scheduleFunction(function(_, time)
        local ok, keepRunning = pcall(CarrierOps.checkCarrier, CarrierOps)
        if not ok then
            log("ERROR in checkCarrier: " .. tostring(keepRunning))
            return time + CarrierOps.config.carrier.checkInterval
        end
        if keepRunning then
            return time + CarrierOps.config.carrier.checkInterval
        end
        return nil
    end, nil, timer.getTime() + self.config.carrier.checkInterval)

    timer.scheduleFunction(function(_, time)
        local ok, err = pcall(CarrierOps.updateEscorts, CarrierOps)
        if not ok then
            log("ERROR in updateEscorts: " .. tostring(err))
        end
        return time + CarrierOps.config.escortCheckInterval
    end, nil, timer.getTime() + self.config.escortCheckInterval)

    timer.scheduleFunction(function(_, time)
        local ok, err = pcall(CarrierOps.updatePlaneGuard, CarrierOps)
        if not ok then
            log("ERROR in updatePlaneGuard: " .. tostring(err))
        end
        return time + CarrierOps.config.planeGuard.updateInterval
    end, nil, timer.getTime() + self.config.planeGuard.updateInterval)

    log("Carrier operations started")
end

CarrierOps:init()

env.info("[CarrierOps] Loaded successfully")

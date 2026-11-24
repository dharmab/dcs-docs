-- Carrier steering and systems. CarrierOps starts at script load, using the
-- Stennis group from the mission file.
local h = require("harness")

local KNOTS = 0.514444
local CARRIER = "CVN-74 John C. Stennis"

-- Wind blowing FROM `fromDegrees` at `speed` m/s. atmosphere.getWind returns
-- the direction the air moves toward, so negate it.
local function windFrom(fromDegrees, speed)
    local from = math.rad(fromDegrees)
    return { x = -speed * math.cos(from), z = -speed * math.sin(from) }
end

local function moveCarrierTo(env, pos)
    local unit = env.unitsByName[CARRIER]
    unit.x, unit.z = pos.x, pos.y
end

local function angleBetween(a, b)
    local diff = math.abs(a - b) % (2 * math.pi)
    return math.min(diff, 2 * math.pi - diff)
end

h.test("carrier systems match the comms plan", function()
    local env = h.load()
    local commands = {}
    for _, c in ipairs(env.groupsByName["CVN-74 Stennis"].commands) do
        commands[c.id] = c.params
    end
    -- TACAN 74X: X channels 64-126 start at 1151 MHz
    h.eq(commands.ActivateBeacon.frequency, 1161 * 1e6, "TACAN frequency")
    h.eq(commands.ActivateBeacon.callsign, "STN")
    h.eq(commands.ActivateICLS.channel, 4)
    h.eq(commands.ActivateLink4.frequency, 336 * 1e6, "Link 4 frequency")
    h.near(commands.SetFrequency.frequency, 254.7 * 1e6, 1, "radio frequency")
    h.ok(commands.ActivateACLS, "ACLS not activated")
end)

h.test("into-wind course is offset for the angled deck", function()
    h.load()
    local course, speed = CarrierOps:computeIntoWindLeg(0, 10 * KNOTS)
    h.near(math.deg(course), 9, 0.01, "course")
    local headwind = 10 * KNOTS * math.cos(math.rad(9))
    h.near(speed + headwind, CarrierOps.config.carrier.windOverDeck, 0.01, "wind over deck")
end)

h.test("into-wind speed stays within limits", function()
    h.load()
    local cfg = CarrierOps.config.carrier
    local _, strongWindSpeed = CarrierOps:computeIntoWindLeg(math.rad(90), 40 * KNOTS)
    h.near(strongWindSpeed, cfg.minSpeed, 0.001, "strong wind")
    local _, calmSpeed = CarrierOps:computeIntoWindLeg(0, 0)
    h.near(calmSpeed, cfg.maxSpeed, 0.001, "calm")
end)

h.test("calm wind uses the calm course", function()
    h.load()
    local course = CarrierOps:computeIntoWindLeg(math.rad(45), 0.5)
    h.near(course, CarrierOps.config.carrier.calmCourse, 0.001)
end)

h.test("carrier repositions downwind, then runs into the wind", function()
    -- North wind; the Stennis starts near the northeast edge of the area,
    -- so the into-wind leg is too short and it repositions first
    local env = h.load({ wind = windFrom(0, 10 * KNOTS) })
    h.eq(CarrierOps.state.phase, "REPOSITION")
    h.near(CarrierOps.state.windAxis, math.rad(9), 0.001, "wind axis")

    moveCarrierTo(env, CarrierOps.state.legEnd)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.eq(CarrierOps.state.phase, "INTO_WIND")
    h.near(CarrierOps.state.legCourse, math.rad(9), 0.001, "leg course")

    local area = CarrierOps.config.opArea
    local legEnd = CarrierOps.state.legEnd
    local fromCenter = math.sqrt((legEnd.x - area.x) ^ 2 + (legEnd.y - area.y) ^ 2)
    h.near(fromCenter, area.radius - area.margin, 1, "leg should end at the turn-back circle")

    local tasks = env.groupsByName["CVN-74 Stennis"].tasks
    local route = tasks[#tasks].params.route.points
    h.near(route[2].x, legEnd.x, 0.001)
    h.near(route[2].speed, CarrierOps.state.legSpeed, 0.001)
end)

h.test("wind shift replans the into-wind leg", function()
    local env = h.load({ wind = windFrom(0, 10 * KNOTS) })
    moveCarrierTo(env, CarrierOps.state.legEnd)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.eq(CarrierOps.state.phase, "INTO_WIND")

    env.wind = windFrom(30, 10 * KNOTS)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.ok(env.logContains("Wind changed, replanning"))
    h.ok(angleBetween(CarrierOps.state.plannedWindFrom, math.rad(30)) < 0.001, "planned wind")
end)

h.test("small wind shift keeps the current leg", function()
    local env = h.load({ wind = windFrom(0, 10 * KNOTS) })
    moveCarrierTo(env, CarrierOps.state.legEnd)
    env.advance(CarrierOps.config.carrier.checkInterval)
    env.wind = windFrom(5, 10 * KNOTS)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.ok(not env.logContains("Wind changed, replanning"))
end)

h.test("escorts steer to their stations within their speed limits", function()
    local env = h.load({ wind = windFrom(0, 10 * KNOTS) })
    env.advance(CarrierOps.config.escortCheckInterval)
    for _, escort in ipairs(CarrierOps.config.escorts) do
        local tasks = env.groupsByName[escort.groupName].tasks
        h.ok(#tasks > 0, escort.groupName .. " has no route")
        local points = tasks[#tasks].params.route.points
        h.ok(points[2].speed <= escort.maxSpeed + 0.001, escort.groupName .. " over max speed")
        h.ok(points[2].speed > 0, escort.groupName .. " stopped")
    end
end)

h.test("operating area is open water", function()
    local env = h.load()
    h.ok(env.logContains("Operating area validated"))
end)

h.test("plane guard spawns with unlimited fuel and weapons hold", function()
    local env = h.load()
    local angel = env.groupsByName[CarrierOps.config.planeGuard.groupName]
    h.ok(angel, "no plane guard")
    h.eq(angel.commands[1].id, "SetUnlimitedFuel")
    h.eq(angel.options[AI.Option.Air.id.ROE], AI.Option.Air.val.ROE.WEAPON_HOLD)
end)

-- Signed distance of `p` to the right of the line through `origin` along `course`
local function rightOf(p, origin, course)
    return -(p.x - origin.x) * math.sin(course) + (p.y - origin.y) * math.cos(course)
end

local function lastOrbit(env)
    local tasks = env.groupsByName[CarrierOps.config.recoveryTanker.groupName].tasks
    for _, task in ipairs(tasks[#tasks].params.route.points[1].task.params.tasks) do
        if task.id == "Orbit" then
            return task.params
        end
    end
end

-- Distance of `p` ahead of `origin` along `course`
local function aheadOf(p, origin, course)
    return (p.x - origin.x) * math.cos(course) + (p.y - origin.y) * math.sin(course)
end

h.test("recovery tanker anchors beside the into-wind leg, turning toward shore", function()
    local env = h.load({ wind = windFrom(0, 10 * KNOTS) })
    moveCarrierTo(env, CarrierOps.state.legEnd)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.eq(CarrierOps.state.phase, "INTO_WIND")
    h.ok(not env.logContains("Recovery tanker track is over land"), "track fell back to the carrier's leg")

    local cfg = CarrierOps.config.recoveryTanker
    local orbit = lastOrbit(env)
    h.eq(orbit.pattern, "Anchored")
    local course = CarrierOps.state.legCourse
    h.ok(angleBetween(orbit.hotLegDir, course) < 0.001, "hot leg not along the carrier's course")
    h.near(orbit.width, 2 * cfg.speed ^ 2 / (9.81 * math.tan(cfg.bank)), 1, "track width is not the turn diameter")
    h.ok(orbit.legLength >= cfg.minTrackLength - 1, "track shorter than minTrackLength")

    -- The ARCP ends the hot leg, level with the end of the carrier's leg or
    -- beyond it when the leg was extended to minTrackLength
    local legEnd = CarrierOps.state.legEnd
    h.ok(aheadOf(orbit.point, legEnd, course) > -1, "ARCP behind the end of the carrier's leg")

    local shoreSide = rightOf(cfg.shoreReference, legEnd, course) > 0 and 1 or -1
    local hotOffset = rightOf(orbit.point, legEnd, course) * shoreSide
    h.ok(hotOffset > 0 and hotOffset <= cfg.offset + 1, "hot leg not on the shore side within offset")
    -- Right turns put the return leg on the right: turn toward shore, away from the carrier
    h.eq(orbit.clockWise, shoreSide > 0, "tanker turns toward the carrier")

    local commands = env.groupsByName[cfg.groupName].commands
    h.eq(commands[#commands].params.frequency, 1190 * 1e6, "TACAN 103X frequency")
end)

h.test("recovery tanker keeps its racetrack when the next leg runs along it", function()
    local env = h.load({ wind = windFrom(0, 10 * KNOTS) })
    local tasks = env.groupsByName[CarrierOps.config.recoveryTanker.groupName].tasks
    local count = #tasks
    moveCarrierTo(env, CarrierOps.state.legEnd)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.eq(#tasks, count, "recovery tanker retasked for the same track")

    env.wind = windFrom(40, 10 * KNOTS)
    env.advance(CarrierOps.config.carrier.checkInterval)
    h.eq(#tasks, count + 1, "recovery tanker not retasked after the wind shift")
end)

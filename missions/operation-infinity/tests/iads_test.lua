-- IADS emission control scenarios on the mock clock
local h = require("harness")

-- Open steppe near Mozdok, away from the other scripts' units
local SITE = { x = -100000, y = 820000 }
local EWR_OFFSET = 30000
local KM = 1000

local function permanentGroup(name, center, unitType)
    return Virtualization:registerPermanentGroup({
        name = name,
        center = center,
        units = {
            { type = unitType, x = center.x, y = center.y },
            { type = unitType, x = center.x + 50, y = center.y },
        },
    })
end

-- An SA-10 site, optionally with an EWR nearby, enabled at the given difficulty
local function setup(options)
    options = options or {}
    local env = h.load({ seed = options.seed })
    local pSite = permanentGroup("Test-SA10", SITE, "S-300PS 40B6M tr")
    local samSite = IADS:registerSAMSite(pSite, "SA10", SITE)
    local pEwr
    if options.ewr ~= false then
        pEwr = permanentGroup("Test-EWR", { x = SITE.x + EWR_OFFSET, y = SITE.y }, "1L13 EWR")
        IADS:registerEWR(pEwr)
    end
    Virtualization:spawnPermanentGroupsBatched(function() end)
    env.advance(1)
    IADS:init()
    IADS:enable(options.difficulty or "Normal")
    env.advance(10)

    local ctx = { env = env, samSite = samSite }
    ctx.site = env.groupsByName[pSite.spawnedGroupName]
    ctx.ewr = pEwr and env.groupsByName[pEwr.spawnedGroupName]

    -- A blue fighter `distance` meters north of the site, seen by the EWR
    function ctx.intruder(distance)
        local player = env.addPlayer("Intruder", SITE.x + distance, SITE.y)
        env.detections[ctx.ewr.name] = { player.object }
        return player
    end
    function ctx.clearDetections()
        env.detections[ctx.ewr.name] = nil
    end
    -- An ARM `distance` meters north of the site, flying at `speed` m/s
    -- toward the site (or away from it)
    function ctx.fireARM(distance, speed, away)
        local shooter = env.addPlayer("Wild Weasel", SITE.x + distance + 1000, SITE.y)
        local weapon = env.makeWeapon({
            guidance = Weapon.GuidanceType.RADAR_PASSIVE,
            x = SITE.x + distance,
            z = SITE.y,
            vx = away and speed or -speed,
            vz = 0,
        })
        env.fireEvent({ id = world.event.S_EVENT_SHOT, initiator = shooter.object, weapon = weapon })
        return weapon
    end
    function ctx.emitting()
        return ctx.site.emission == true
    end
    return ctx
end

h.test("site stays dark with nothing to shoot at", function()
    local ctx = setup()
    h.eq(ctx.site.options[AI.Option.Ground.id.ALARM_STATE], AI.Option.Ground.val.ALARM_STATE.RED, "alarm state")
    ctx.env.advance(300)
    h.ok(not ctx.emitting())
end)

h.test("EWR track inside cue range turns the site on", function()
    local ctx = setup()
    ctx.intruder(80 * KM) -- SA-10 cue range is 75% of 120 km
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(ctx.emitting())
    h.eq(ctx.samSite.lastCueSource, "EWR cue")
end)

h.test("EWR detection of a blue missile is not a cue", function()
    local ctx = setup()
    local missile =
        ctx.env.makeWeapon({ guidance = Weapon.GuidanceType.RADAR_ACTIVE, x = SITE.x + 50 * KM, z = SITE.y })
    ctx.env.detections[ctx.ewr.name] = { missile }
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(not ctx.emitting())
end)

h.test("EWR track outside cue range leaves the site dark", function()
    local ctx = setup()
    ctx.intruder(100 * KM)
    ctx.env.advance(60)
    h.ok(not ctx.emitting())
end)

h.test("site holds after losing the cue, then goes dark", function()
    local ctx = setup()
    ctx.intruder(50 * KM)
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(ctx.emitting())
    ctx.clearDetections()
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(ctx.emitting(), "should hold for cueHoldTime")
    ctx.env.advance(IADS.config.cueHoldTime + IADS.config.updateInterval)
    h.ok(not ctx.emitting())
end)

h.test("HARM aimed at the site forces a dark period that overrides cues", function()
    local ctx = setup()
    ctx.intruder(50 * KM)
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(ctx.emitting())

    -- 10 km at 600 m/s is a 17 s ETA, inside every Normal shutdown roll
    local arm = ctx.fireARM(10 * KM, 600)
    ctx.env.advance(IADS.config.harmUpdateInterval)
    h.ok(not ctx.emitting(), "should go dark")

    arm.record.alive = false
    ctx.env.advance(IADS.config.darkPeriodMin - IADS.config.updateInterval)
    h.ok(not ctx.emitting(), "should stay dark despite the cue")

    ctx.env.advance(IADS.config.darkPeriodMax)
    h.ok(ctx.emitting(), "should come back on after the dark period")
    h.ok(not IADS.state.harmLoopRunning, "HARM loop should stop once no ARMs fly")
end)

h.test("HARM flying away from the site is ignored", function()
    local ctx = setup()
    ctx.intruder(50 * KM)
    ctx.env.advance(IADS.config.updateInterval)
    ctx.fireARM(10 * KM, 600, true)
    ctx.env.advance(IADS.config.harmUpdateInterval * 3)
    h.ok(ctx.emitting())
end)

h.test("HARM far away waits for the shutdown roll", function()
    local ctx = setup()
    ctx.intruder(50 * KM)
    ctx.env.advance(IADS.config.updateInterval)
    -- 60 km at 600 m/s is a 100 s ETA, beyond every Normal roll
    ctx.fireARM(60 * KM, 600)
    ctx.env.advance(IADS.config.harmUpdateInterval * 2)
    h.ok(ctx.emitting())
end)

h.test("Normal sites shut down earlier than Hard sites", function()
    local ctx = setup()
    for _ = 1, 200 do
        local eta = IADS:rollShutdownETA()
        h.ok(eta >= 30 and eta <= 60, "Normal roll " .. eta)
    end
    IADS.state.difficulty = "Hard"
    for _ = 1, 200 do
        local eta = IADS:rollShutdownETA()
        h.ok(eta >= 15 and eta <= 30, "Hard roll " .. eta)
    end
    h.ok(ctx)
end)

h.test("site keeps guiding while its own missile flies", function()
    local ctx = setup()
    local missile = ctx.env.makeWeapon({ guidance = Weapon.GuidanceType.RADAR_SEMI_ACTIVE, x = SITE.x, z = SITE.y })
    ctx.env.fireEvent({ id = world.event.S_EVENT_SHOT, initiator = ctx.site.units[1].object, weapon = missile })
    h.ok(ctx.emitting(), "should turn on at launch")
    ctx.env.advance(60)
    h.ok(ctx.emitting(), "should stay on while the missile flies")
    missile.record.alive = false
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(not ctx.emitting())
end)

h.test("site without a live EWR pulses on its own", function()
    local ctx = setup({ ewr = false })
    local onSeconds, offSeconds, longestOn, currentOn = 0, 0, 0, 0
    for _ = 1, 1800 do
        ctx.env.advance(1)
        if ctx.emitting() then
            onSeconds = onSeconds + 1
            currentOn = currentOn + 1
            longestOn = math.max(longestOn, currentOn)
        else
            offSeconds = offSeconds + 1
            currentOn = 0
        end
    end
    h.ok(ctx.samSite.autonomous, "site should be autonomous")
    h.ok(onSeconds > 0, "site never pulsed")
    h.ok(offSeconds > onSeconds, "site should be off more than on")
    h.ok(longestOn <= IADS.config.pulseOnMax + 1, "pulse lasted " .. longestOn .. " s")
end)

h.test("losing the only EWR makes the site autonomous", function()
    local ctx = setup()
    h.ok(not ctx.samSite.autonomous)
    for _, u in ipairs(ctx.ewr.units) do
        ctx.env.killUnit(u.name)
    end
    ctx.env.advance(IADS.config.updateInterval * 2)
    h.ok(ctx.samSite.autonomous)
end)

h.test("destroyed site is dropped", function()
    local ctx = setup()
    for _, u in ipairs(ctx.site.units) do
        ctx.env.killUnit(u.name)
    end
    ctx.env.advance(IADS.config.updateInterval)
    h.ok(not ctx.samSite.alive)
    h.eq(IADS:getStats().activeRadars, 0)
end)

h.test("Easy leaves emission to DCS default AI", function()
    local ctx = setup({ difficulty = "Easy" })
    ctx.intruder(50 * KM)
    ctx.env.advance(60)
    h.eq(ctx.site.emission, nil)
    h.ok(not IADS.state.enabled)
end)

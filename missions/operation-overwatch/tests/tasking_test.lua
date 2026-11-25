local h = require("harness")

local HELICOPTER = 1

local function hasMessage(env, pattern)
    for _, text in ipairs(env.messages) do
        if text:find(pattern) then
            return true
        end
    end
    return false
end

local function checkIn(env, name, playerOptions)
    h.takeOff(env, name, playerOptions)
    h.runGroupMenu(env, name, "Check In")
    local flight = Tasking.state.flights[name]
    return Tasking.state.taskings[flight.taskingId]
end

local function killAll(env, names)
    for _, name in ipairs(names) do
        if env.unitsByName[name] then
            env.killUnit(name)
        end
    end
end

h.test("takeoff adds Check In for CAS aircraft only", function()
    local env = h.load()
    h.takeOff(env, "Viper", { type = "F-16C_50" })
    h.takeOff(env, "Chinook", { type = "CH-47Fbl1", category = HELICOPTER })
    h.ok(Tasking.state.flights["Viper"], "Viper registered")
    h.eq(Tasking.state.flights["Chinook"], nil, "Chinook registered")
end)

h.test("Check In creates a tasking and sends the brief", function()
    local env = h.load()
    local tasking = checkIn(env, "Viper")
    h.ok(tasking, "tasking")
    h.ok(#tasking.spawned.enemyUnitNames > 0, "enemy spawned")
    local slot = tasking.slot
    h.ok(hasMessage(env, "^" .. slot.callsign .. ", " .. string.format("%.2f", slot.frequency) .. " AM"), "brief")
    h.eq(#env.smokes, 2, "smoke marks")
end)

h.test("the first tasking's JTAC varies between missions", function()
    local seen = {}
    for seed = 1, 30 do
        local env = h.load({ seed = seed })
        local tasking = checkIn(env, "Viper")
        seen[tasking.slotIndex] = true
    end
    local slotCount = #OperationOverwatch.config.jtacSlots
    for index = 1, slotCount do
        h.ok(seen[index], "slot " .. index .. " never chosen first")
    end
end)

h.test("consecutive solo taskings never reuse the JTAC", function()
    for seed = 1, 10 do
        local env = h.load({ seed = seed })
        local flightCategory = checkIn(env, "Viper").flightCategory
        local previous = nil
        for _ = 1, 10 do
            local tasking = Tasking:create(flightCategory)
            if previous then
                h.ok(tasking.slotIndex ~= previous, "seed " .. seed .. ": slot " .. previous .. " reused")
            end
            previous = tasking.slotIndex
            Tasking:finish(tasking, Tasking.EndReason.ABANDONED)
        end
    end
end)

h.test("the last free slot is used even if it was the previous JTAC", function()
    local env = h.load()
    local slotCount = #OperationOverwatch.config.jtacSlots
    local taskings = {}
    for i = 1, slotCount do
        taskings[i] = checkIn(env, "Flight" .. i)
    end
    local last = taskings[slotCount]
    Tasking:finish(last, Tasking.EndReason.ABANDONED)
    h.eq(Tasking:freeSlot(), last.slotIndex)
end)

h.test("the enemy is 400-900 m from the friendlies", function()
    for seed = 1, 30 do
        local env = h.load({ seed = seed })
        local tasking = checkIn(env, "Viper")
        local spawned = tasking.spawned
        local distance = Spatial:getDistance2D(spawned.friendlyCenter, spawned.enemyCenter)
        local inRange = distance >= 400 and distance <= 900
        h.ok(inRange, "seed " .. seed .. ": " .. distance)
    end
end)

h.test("a fifth Check In is told to use Join Tasking", function()
    local env = h.load()
    for i = 1, 4 do
        checkIn(env, "Flight" .. i)
    end
    h.eq(Tasking:activeCount(), 4)
    h.takeOff(env, "Flight5")
    h.runGroupMenu(env, "Flight5", "Check In")
    h.eq(Tasking:activeCount(), 4)
    h.ok(hasMessage(env, "Use Join Tasking"), "full message")
end)

h.test("Join Tasking lists active taskings most recent first and assigns", function()
    local env = h.load()
    local first = checkIn(env, "Viper")
    local second = checkIn(env, "Hornet")
    h.takeOff(env, "Hog")
    local entries = h.joinEntries(env, "Hog")
    h.eq(#entries, 2, "entries")
    h.ok(entries[1]:find("^" .. second.slot.callsign), entries[1])
    h.ok(entries[2]:find("^" .. first.slot.callsign), entries[2])
    h.runGroupMenu(env, "Hog", entries[2])
    h.eq(Tasking.state.flights["Hog"].taskingId, first.id)
end)

h.test("destroying every key unit ends the tasking and removes the scene", function()
    local env = h.load()
    EnemyForce.pool[3].chance = { fixed = 1, rotary = 1 } -- technicals always
    local tasking = checkIn(env, "Viper")
    h.ok(#tasking.spawned.keyUnitNames > 0, "key units")
    killAll(env, tasking.spawned.keyUnitNames)
    env.advance(10)
    h.eq(tasking.status, Tasking.Status.ENDED)
    h.eq(tasking.endReason, Tasking.EndReason.SUCCESS)
    h.ok(hasMessage(env, "Enemy is broken"), "broken call")
    h.ok(env.groupsByName[tasking.spawned.groupNames[1]], "scene stays up")
    h.eq(env.groupsByName[tasking.spawned.jtacGroupName], nil, "JTAC removed at once")
    env.advance(OperationOverwatch.config.removalDelaySeconds)
    for _, name in ipairs(tasking.spawned.groupNames) do
        h.eq(env.groupsByName[name], nil, name)
    end
    h.eq(table.concat(h.joinEntries(env, "Viper"), ", "), "No active taskings", "join entries")
end)

h.test("destroying 70% of the enemy ends the tasking", function()
    local env = h.load()
    local tasking = checkIn(env, "Viper")
    local names = tasking.spawned.enemyUnitNames
    local needed = math.ceil(#names * 0.7)
    local nonKey = {}
    local isKey = {}
    for _, name in ipairs(tasking.spawned.keyUnitNames) do
        isKey[name] = true
    end
    for _, name in ipairs(names) do
        if not isKey[name] then
            nonKey[#nonKey + 1] = name
        end
    end
    for i = 1, needed - 1 do
        env.killUnit(nonKey[i])
    end
    env.advance(10)
    h.eq(tasking.status, Tasking.Status.ACTIVE, "below 70%")
    env.killUnit(nonKey[needed])
    env.advance(10)
    h.eq(tasking.status, Tasking.Status.ENDED, "at 70%")
end)

h.test("a tasking ends 10 minutes after its last flight lands", function()
    local env = h.load()
    local tasking = checkIn(env, "Viper")
    local viper = env.unitObject("Viper")
    env.fireEvent({ id = world.event.S_EVENT_LAND, initiator = viper })
    env.advance(590)
    h.eq(tasking.status, Tasking.Status.ACTIVE, "before timeout")
    env.advance(15)
    h.eq(tasking.status, Tasking.Status.ENDED, "after timeout")
    h.eq(tasking.endReason, Tasking.EndReason.ABANDONED)
    for _, name in ipairs(tasking.spawned.groupNames) do
        h.eq(env.groupsByName[name], nil, name)
    end
end)

h.test("a joined flight keeps the tasking alive", function()
    local env = h.load()
    local tasking = checkIn(env, "Viper")
    h.takeOff(env, "Hog")
    h.runGroupMenu(env, "Hog", h.joinEntries(env, "Hog")[1])
    env.fireEvent({ id = world.event.S_EVENT_LAND, initiator = env.unitObject("Viper") })
    env.advance(900)
    h.eq(tasking.status, Tasking.Status.ACTIVE)
end)

h.test("the JTAC lasers a key unit on code 1688", function()
    local env = h.load()
    EnemyForce.pool[3].chance = { fixed = 1, rotary = 1 }
    local tasking = checkIn(env, "Viper")
    env.advance(10)
    local lasers = env.activeLasers()
    h.eq(#lasers, 1, "lasers")
    h.eq(lasers[1].code, 1688)
    local target = env.unitObject(tasking.spawned.keyUnitNames[1]):getPoint()
    h.eq(lasers[1].point.x, target.x)
end)

h.test("a MANPADS launch is called and makes it a key unit", function()
    local env = h.load()
    EnemyForce.pool[6].chance = { fixed = 1, rotary = 1 }
    local tasking = checkIn(env, "Viper")
    local manpads = tasking.spawned.manpadsUnitName
    h.ok(manpads, "MANPADS spawned")
    local distance = Spatial:getDistance2D(tasking.spawned.enemyCenter, {
        x = env.unitsByName[manpads].x,
        y = env.unitsByName[manpads].z,
    })
    local inRange = distance >= 1000 and distance <= 2000
    h.ok(inRange, "MANPADS distance " .. distance)
    env.fireEvent({ id = world.event.S_EVENT_SHOT, initiator = env.unitObject(manpads) })
    h.ok(hasMessage(env, "SAM launch"), "launch call")
    local keys = tasking.spawned.keyUnitNames
    h.eq(keys[#keys], manpads)
end)

h.test("a player hitting a friendly draws a cease fire call", function()
    local env = h.load()
    local tasking = checkIn(env, "Viper")
    env.fireEvent({
        id = world.event.S_EVENT_HIT,
        initiator = env.unitObject("Viper"),
        target = env.unitObject(tasking.spawned.friendlyUnitNames[1]),
    })
    h.ok(hasMessage(env, "CEASE FIRE"), "cease fire")
end)

h.test("rotary flights get taskings near a FARP", function()
    local env = h.load()
    local tasking = checkIn(env, "Apache", { type = "AH-64D_BLK_II", category = HELICOPTER })
    h.eq(tasking.flightCategory, "rotary")
    local distance = Spatial:getDistance2D(tasking.center, h.testFarps[1].position)
    h.ok(distance <= OperationOverwatch.config.rotaryTaskingRadius, "distance " .. distance)
end)

h.test("Check In without a configured area reports no tasking", function()
    local env = h.load({ noArea = true })
    h.takeOff(env, "Viper")
    h.runGroupMenu(env, "Viper", "Check In")
    h.eq(Tasking:activeCount(), 0)
    h.ok(hasMessage(env, "No tasking available"), "message")
end)

h.test("generation makes no unmocked API calls", function()
    for seed = 1, 10 do
        local env = h.load({ seed = seed })
        for i = 1, 4 do
            checkIn(env, "Flight" .. i)
        end
        env.advance(600)
        h.eq(next(env.unknown), nil, "seed " .. seed .. " unmocked API")
        for _, line in ipairs(env.log) do
            h.ok(not line:find("^ERROR"), line)
        end
    end
end)

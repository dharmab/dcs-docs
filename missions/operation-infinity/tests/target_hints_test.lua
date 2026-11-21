-- Fuzzed F10 map hints for artillery, supply depots, and fuel storage
local h = require("harness")

local SEEDS = { 1, 2, 3 }

local function circles(env)
    local result = {}
    for _, d in ipairs(env.drawings) do
        if d.kind == "circle" then
            result[#result + 1] = d
        end
    end
    return result
end

local function hintedGroups()
    local result = {}
    for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
        if vGroup.hint then
            result[#result + 1] = vGroup
        end
    end
    return result
end

local function distance(a, b)
    local dx, dy = a.x - b.x, a.y - b.y
    return math.sqrt(dx * dx + dy * dy)
end

h.test("deep strike targets get hint circles that contain them", function()
    local cfg = OperationInfinity.config.targetHints
    for _, seed in ipairs(SEEDS) do
        local env = h.load({ seed = seed })
        h.generate(env, "Normal", "180", "southeast")
        local groups = hintedGroups()
        h.ok(#groups > 0, "no hinted groups (seed " .. seed .. ")")
        h.eq(#circles(env), #groups, "one circle per hinted group (seed " .. seed .. ")")
        for _, vGroup in ipairs(groups) do
            local found = false
            for _, m in ipairs(env.markers) do
                if m.text == vGroup.hint and m.pos.x == vGroup.hintCenter.x and m.pos.z == vGroup.hintCenter.y then
                    found = true
                end
            end
            h.ok(found, vGroup.name .. " has no hint mark")
            local offset = distance(vGroup.center, vGroup.hintCenter)
            h.ok(offset <= cfg.radius * cfg.maxOffsetFraction, vGroup.name .. " is outside its hint circle")
            for _, u in ipairs(vGroup.units) do
                h.ok(distance(u, vGroup.hintCenter) <= cfg.radius, vGroup.name .. " unit outside its hint circle")
            end
        end
    end
end)

h.test("only artillery, depots, and fuel storage are hinted", function()
    local env = h.load()
    h.generate(env, "Normal", "180", "southeast")
    for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
        local expected = vGroup.name:match("^Artillery%-")
            or vGroup.name:match("^Depot%-")
            or vGroup.name:match("^FuelStorage%-")
        h.eq(vGroup.hint ~= nil, expected ~= nil, vGroup.name)
    end
end)

h.test("hint is removed when the last unit of the group dies", function()
    local env = h.load()
    h.generate(env, "Normal", "180", "southeast")
    local vGroup = hintedGroups()[1]
    local circleCount = #circles(env)
    local markCount = #env.markers

    env.addPlayer("Spawner", vGroup.center.x, vGroup.center.y)
    env.advance(120)
    h.ok(vGroup.isSpawned, vGroup.name .. " did not spawn")

    local live = env.groupsByName[vGroup.spawnedGroupName]
    for i, u in ipairs(live.units) do
        local unit = env.unitObject(u.name)
        env.fireEvent({ id = world.event.S_EVENT_DEAD, initiator = unit })
        env.killUnit(u.name)
        if i < #live.units then
            h.eq(#circles(env), circleCount, "hint removed before the group was destroyed")
        end
    end

    h.ok(vGroup.destroyed, vGroup.name .. " not marked destroyed")
    h.eq(#circles(env), circleCount - 1, "hint circle not removed")
    h.eq(#env.markers, markCount - 1, "hint mark not removed")
end)

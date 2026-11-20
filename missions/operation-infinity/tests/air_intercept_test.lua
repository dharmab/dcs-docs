-- Enemy fighter response to players entering airfield zones
local h = require("harness")

local INTERCEPTOR_PREFIX = "Erusea-Interceptor-"

local function setup(difficulty)
    local env = h.load()
    AirIntercept:init()
    AirIntercept:enable(difficulty or "Normal")
    return env
end

local function airfield(name)
    for _, a in ipairs(AirIntercept.config.airfields) do
        if a.name == name then
            return a
        end
    end
    error("no airfield " .. name)
end

local function interceptorGroups(env)
    local result = {}
    for _, g in ipairs(env.spawnedGroups()) do
        if g.name:find(INTERCEPTOR_PREFIX, 1, true) then
            result[#result + 1] = g
        end
    end
    return result
end

local function contains(list, value)
    for _, v in ipairs(list) do
        if v == value then
            return true
        end
    end
    return false
end

h.test("response grows with the number of intruders", function()
    h.load()
    local expected = { [0] = 0, 1, 1, 2, 3, 4, 4 }
    for intruders = 0, 6 do
        h.eq(AirIntercept:calculateResponseSize(intruders), expected[intruders], intruders .. " intruders")
    end
end)

h.test("airborne cap scales with weighted player count", function()
    local env = setup("Normal")
    local base = UnitTemplates.Fighters.Normal.maxAirborne
    h.eq(AirIntercept:calculateDynamicMaxAirborne(), base, "no players")
    env.addPlayer("Eagle", 0, 0, { type = "F-15C" }) -- weight 2
    h.eq(AirIntercept:calculateDynamicMaxAirborne(), base + 1, "one fighter")
    for i = 1, 20 do
        env.addPlayer("Eagle" .. i, 0, 0, { type = "F-15C" })
    end
    h.eq(AirIntercept:calculateDynamicMaxAirborne(), 8, "capped")
    AirIntercept.state.difficulty = "VeryEasy"
    h.eq(AirIntercept:calculateDynamicMaxAirborne(), 0, "VeryEasy")
end)

h.test("every player aircraft type has a threat weight", function()
    local env = h.load()
    for _, g in ipairs(env.groups) do
        if g.fromMission and g.data.units[1].skill == "Client" then
            local aircraftType = g.data.units[1].type
            h.ok(AirIntercept.config.aircraftWeights[aircraftType], aircraftType .. " (" .. g.name .. ") has no weight")
        end
    end
end)

h.test("every enemy fighter type has a payload", function()
    h.load()
    for difficulty, config in pairs(UnitTemplates.Fighters) do
        for _, fighterType in ipairs(config.types) do
            h.ok(
                UnitTemplates:getPayload(difficulty, fighterType),
                difficulty .. " " .. fighterType .. " has no payload"
            )
        end
    end
end)

h.test("airborne player in a zone draws interceptors", function()
    local env = setup("Normal")
    local mozdok = airfield("Mozdok")
    env.addPlayer("Viper", mozdok.zoneCenter.x, mozdok.zoneCenter.y)
    env.advance(AirIntercept.config.checkInterval)

    local groups = interceptorGroups(env)
    h.eq(#groups, 1, "interceptor groups")
    local g = groups[1]
    h.eq(g.side, coalition.side.RED)
    h.eq(#g.units, 1, "one intruder draws one fighter")
    h.ok(contains(UnitTemplates.Fighters.Normal.types, g.units[1].type), "unexpected type " .. g.units[1].type)
    h.eq(AirIntercept.state.totalAirborne, 1)
end)

h.test("player on the ground does not draw interceptors", function()
    local env = setup("Normal")
    local mozdok = airfield("Mozdok")
    env.addPlayer("Viper", mozdok.zoneCenter.x, mozdok.zoneCenter.y, { alt = 50 })
    env.advance(AirIntercept.config.checkInterval * 3)
    h.eq(#interceptorGroups(env), 0)
end)

h.test("VeryEasy never spawns interceptors", function()
    local env = setup("VeryEasy")
    local mozdok = airfield("Mozdok")
    env.addPlayer("Viper", mozdok.zoneCenter.x, mozdok.zoneCenter.y)
    env.advance(AirIntercept.config.checkInterval * 3)
    h.eq(#interceptorGroups(env), 0)
end)

h.test("airfield cooldown spaces out waves", function()
    local env = setup("Normal")
    local mozdok = airfield("Mozdok")
    env.addPlayer("Viper", mozdok.zoneCenter.x, mozdok.zoneCenter.y)
    env.advance(AirIntercept.config.checkInterval)
    local first = interceptorGroups(env)[1]
    for _, u in ipairs(first.units) do
        env.killUnit(u.name)
        env.fireEvent({ id = world.event.S_EVENT_DEAD, initiator = u.object })
    end
    env.advance(AirIntercept.config.spawnCooldownMin - AirIntercept.config.checkInterval)
    h.eq(#interceptorGroups(env), 1, "second wave inside the minimum cooldown")
    env.advance(AirIntercept.config.spawnCooldownMax)
    h.ok(#interceptorGroups(env) >= 2, "no second wave after the maximum cooldown")
end)

h.test("one loss raising several events frees one slot", function()
    local env = setup("Normal")
    local mozdok = airfield("Mozdok")
    for i = 1, 3 do
        env.addPlayer("Viper" .. i, mozdok.zoneCenter.x, mozdok.zoneCenter.y)
    end
    env.advance(AirIntercept.config.checkInterval)
    local g = interceptorGroups(env)[1]
    h.eq(AirIntercept.state.totalAirborne, 2)

    local unit = g.units[1].object
    env.fireEvent({ id = world.event.S_EVENT_CRASH, initiator = unit })
    env.fireEvent({ id = world.event.S_EVENT_DEAD, initiator = unit })
    env.fireEvent({ id = world.event.S_EVENT_UNIT_LOST, initiator = unit })
    h.eq(AirIntercept.state.totalAirborne, 1)
end)

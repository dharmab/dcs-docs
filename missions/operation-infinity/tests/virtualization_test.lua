-- Ground groups spawn near players and despawn when players leave
local h = require("harness")

local NM = 1852
local CENTER = { x = -100000, y = 820000 }

local function setup()
    local env = h.load()
    local vGroup = Virtualization:registerGroup({
        name = "Test-Platoon",
        center = CENTER,
        units = {
            { type = "T-72B", x = CENTER.x, y = CENTER.y },
            { type = "T-72B", x = CENTER.x + 30, y = CENTER.y },
            { type = "BMP-2", x = CENTER.x + 60, y = CENTER.y },
        },
    })
    Virtualization:init()
    return env, vGroup
end

-- Interval plus time for the batched queues to drain
local function nextUpdate(env)
    env.advance(Virtualization.config.updateInterval + 1)
end

local function placePlayer(player, distanceNm)
    player.x = CENTER.x + distanceNm * NM
    player.z = CENTER.y
end

local function liveGroup(env, vGroup)
    return vGroup.spawnedGroupName and env.groupsByName[vGroup.spawnedGroupName]
end

h.test("group stays virtual with no players", function()
    local env, vGroup = setup()
    env.advance(120)
    h.ok(not vGroup.isSpawned)
end)

h.test("group spawns inside 100 nm and despawns beyond 120 nm", function()
    local env, vGroup = setup()
    local player = env.addPlayer("Viper", 0, 0)

    placePlayer(player, 105)
    nextUpdate(env)
    h.ok(not vGroup.isSpawned, "spawned at 105 nm")

    placePlayer(player, 95)
    nextUpdate(env)
    h.ok(vGroup.isSpawned, "not spawned at 95 nm")
    h.eq(#liveGroup(env, vGroup).units, 3)

    placePlayer(player, 115)
    nextUpdate(env)
    h.ok(vGroup.isSpawned, "despawned at 115 nm, inside the hysteresis band")

    placePlayer(player, 125)
    nextUpdate(env)
    h.ok(not vGroup.isSpawned, "still spawned at 125 nm")
end)

h.test("destroyed units stay dead after respawn", function()
    local env, vGroup = setup()
    local player = env.addPlayer("Viper", 0, 0)
    placePlayer(player, 50)
    nextUpdate(env)
    local first = liveGroup(env, vGroup)
    env.killUnit(first.units[2].name)

    placePlayer(player, 150)
    nextUpdate(env)
    h.ok(not vGroup.isSpawned)
    h.eq(vGroup.units[2].health, 0)

    placePlayer(player, 50)
    nextUpdate(env)
    local second = liveGroup(env, vGroup)
    h.ok(second.name ~= first.name, "respawn should use a new group name")
    h.eq(#second.units, 2)
    h.eq(second.units[1].type, "T-72B")
    h.eq(second.units[2].type, "BMP-2")
end)

h.test("group with every unit destroyed never respawns", function()
    local env, vGroup = setup()
    local player = env.addPlayer("Viper", 0, 0)
    placePlayer(player, 50)
    nextUpdate(env)
    for _, u in ipairs(liveGroup(env, vGroup).units) do
        env.killUnit(u.name)
    end
    placePlayer(player, 150)
    nextUpdate(env)
    local groupCount = #env.groups
    placePlayer(player, 50)
    nextUpdate(env)
    h.ok(not vGroup.isSpawned)
    h.eq(#env.groups, groupCount)
end)

h.test("registerGroup rejects groups past the unit budget", function()
    local _, vGroup = setup()
    Virtualization.config.maxVirtualUnits = 4
    local rejected = Virtualization:registerGroup({
        name = "Test-Overflow",
        center = CENTER,
        units = {
            { type = "BRDM-2", x = CENTER.x, y = CENTER.y },
            { type = "BRDM-2", x = CENTER.x + 30, y = CENTER.y },
        },
    })
    h.eq(rejected, nil)
    local accepted = Virtualization:registerGroup({
        name = "Test-Fits",
        center = CENTER,
        units = { { type = "BRDM-2", x = CENTER.x, y = CENTER.y } },
    })
    h.ok(accepted, "group within the budget was rejected")
    h.eq(Virtualization:getRegisteredUnitCount(), #vGroup.units + 1)
end)

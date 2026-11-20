-- Full battlefield generation across every difficulty, region, and playtime
local h = require("harness")

local DIFFICULTIES = { "VeryEasy", "Easy", "Normal", "Hard" }
local SEEDS = { 1, 2, 3 }
local GENERATION_COMPLETE = "Battlefield generation complete"

-- Put a player over every target aerodrome and every virtual group so all
-- of them spawn, then check the spawned world
local function spawnEverything(env)
    for i, vGroup in ipairs(Virtualization.state.virtualGroups) do
        env.addPlayer("Spawner-" .. i, vGroup.center.x, vGroup.center.y)
    end
    env.advance(120)
end

local function checkUniqueIds(env)
    local groupIds, groupNames, unitIds, unitNames = {}, {}, {}, {}
    for _, g in ipairs(env.groups) do
        local id = g.groupId
        h.ok(not groupIds[id], "duplicate groupId " .. tostring(id) .. " (" .. g.name .. ")")
        groupIds[id] = g.name
        h.ok(not groupNames[g.name], "duplicate group name " .. g.name)
        groupNames[g.name] = true
        for _, u in ipairs(g.units) do
            h.ok(not unitIds[u.unitId], "duplicate unitId " .. tostring(u.unitId) .. " (" .. u.name .. ")")
            unitIds[u.unitId] = true
            h.ok(not unitNames[u.name], "duplicate unit name " .. u.name)
            unitNames[u.name] = true
        end
    end
end

local function checkUnitData(env)
    for _, g in ipairs(env.spawnedGroups()) do
        h.ok(#g.units > 0, g.name .. " has no units")
        for _, u in ipairs(g.units) do
            h.ok(type(u.type) == "string" and u.type ~= "", u.name .. " has no type")
            h.ok(u.x == u.x and u.z == u.z, u.name .. " has a NaN position")
        end
    end
end

local function checkLog(env)
    for _, line in ipairs(env.log) do
        h.ok(not line:find("ERROR") and not line:find("Error"), "error logged: " .. line)
    end
    local unknown = {}
    for name in pairs(env.unknown) do
        unknown[#unknown + 1] = name
    end
    table.sort(unknown)
    h.eq(#unknown, 0, "scripts used APIs missing from dcs_mock.lua: " .. table.concat(unknown, ", "))
end

local combos = h.regionPlaytimes()
for _, combo in ipairs(combos) do
    for _, difficulty in ipairs(DIFFICULTIES) do
        local name = string.format("%s %s min on %s", combo.region, combo.playtime, difficulty)
        h.test(name .. " generates a consistent battlefield", function()
            for _, seed in ipairs(SEEDS) do
                local env = h.load({ seed = seed })
                h.generate(env, difficulty, combo.playtime, combo.region)
                h.ok(env.logContains(GENERATION_COMPLETE), "generation did not complete (seed " .. seed .. ")")
                spawnEverything(env)
                for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
                    h.ok(vGroup.isSpawned, vGroup.name .. " did not spawn with a player overhead")
                end
                for _, pGroup in ipairs(Virtualization.state.permanentGroups) do
                    h.ok(pGroup.isSpawned, pGroup.name .. " permanent group did not spawn")
                end
                checkUniqueIds(env)
                checkUnitData(env)
                checkLog(env)
            end
        end)
    end
end

h.test("settings can only be chosen once", function()
    local env = h.load()
    h.generate(env, "Normal", "45", "northwest")
    local groupCount = #env.groups
    OperationInfinity:selectDifficulty("Hard")
    env.advance(600)
    h.eq(OperationInfinity.state.difficulty, "Normal")
    h.eq(#env.groups, groupCount, "a second generation spawned groups")
end)

h.test("F10 menu choices start generation and remove the settings menu", function()
    local env = h.load()
    env.runMenu("Normal (IADS, semi-active radar missiles)")
    h.ok(not OperationInfinity.state.missionGenerated, "generated before playtime was chosen")
    env.runMenu("45 Minutes (Western Caucasus)")
    env.advance(600)
    h.ok(env.logContains(GENERATION_COMPLETE))
    for _, m in ipairs(env.menus) do
        h.ok(m.name ~= "Mission Settings", "settings menu still present")
    end
end)

h.test("every playtime in the menu has a region", function()
    h.load()
    for _, playtime in ipairs({ "45", "90", "180" }) do
        h.ok(OperationInfinity:selectRegionForPlaytime(playtime), "no region for " .. playtime)
    end
end)

h.test("support aircraft activate with unlimited fuel and orbit once airborne", function()
    local env = h.load()
    h.generate(env, "Normal", "45", "northwest")
    for _, aircraft in ipairs(OperationInfinity.config.supportAircraft) do
        local g = env.groupsByName[aircraft.name]
        h.ok(g, "no group " .. aircraft.name)
        h.ok(g.active, aircraft.name .. " not activated")
        h.eq(g.commands[#g.commands].id, "SetUnlimitedFuel", aircraft.name)
        g.units[1].inAir = true
    end
    env.advance(60)
    for _, aircraft in ipairs(OperationInfinity.config.supportAircraft) do
        local g = env.groupsByName[aircraft.name]
        local task = g.tasks[#g.tasks]
        h.ok(task and task.id == "Orbit", aircraft.name .. " has no orbit task")
        h.near(task.params.altitude, aircraft.altitudeFt * 0.3048, 1, aircraft.name .. " orbit altitude")
        h.ok(task.params.speed > aircraft.iasKnots * 0.514444, aircraft.name .. " TAS should exceed IAS at altitude")
    end
end)

h.test("mission end flag is set when time runs out", function()
    local env = h.load()
    local limit = OperationInfinity.config.missionDuration or 28800
    env.advance(limit - 60)
    h.eq(env.flags[OperationInfinity.config.missionEndFlag], nil)
    env.advance(120)
    h.eq(env.flags[OperationInfinity.config.missionEndFlag], 1)
end)

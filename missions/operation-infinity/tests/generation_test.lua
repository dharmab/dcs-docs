-- Full battlefield generation across every difficulty, region, and playtime
local h = require("harness")

local DIFFICULTIES = { "VeryEasy", "Easy", "Normal", "Hard" }
local DEFAULT_SEED_COUNT = 3
-- GENERATION_SEEDS=N runs seeds 1 through N, for longer soak runs
local seedCount = tonumber(os.getenv("GENERATION_SEEDS") or DEFAULT_SEED_COUNT)
assert(seedCount and seedCount >= 1, "GENERATION_SEEDS must be a positive number")
local SEEDS = {}
for seed = 1, seedCount do
    SEEDS[seed] = seed
end
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

-- Every ground unit, not only its group's center, is on open ground
local function checkGroundPlacement(env)
    for _, g in ipairs(env.spawnedGroups()) do
        if g.category == Group.Category.GROUND then
            for _, u in ipairs(g.units) do
                local pos = { x = u.x, y = u.z }
                h.ok(Terrain:isValidUnitPosition(pos), u.name .. " is on forest or water")
            end
        end
    end
end

-- Erusean air defense units face the ISAF side: toward Krymsk, give or take
-- the frontline's angle and per-unit variance
local function checkAirDefenseFacing()
    local home = OperationInfinity.state.homeAirbase
    for _, pGroup in ipairs(Virtualization.state.permanentGroups) do
        if not pGroup.name:find("^EWR%-") then
            local dx = home.x - pGroup.center.x
            local dy = home.y - pGroup.center.y
            local dist = math.sqrt(dx * dx + dy * dy)
            for _, u in ipairs(pGroup.units) do
                local cosine = (math.cos(u.heading) * dx + math.sin(u.heading) * dy) / dist
                h.ok(cosine > 0, pGroup.name .. " " .. u.type .. " faces away from ISAF")
            end
        end
    end
end

-- Ground unit types on the ISAF faction lists, read from the docs so the
-- check follows them
local function isafGroundTypes()
    local types = {}
    for _, year in ipairs({ "2004", "2005" }) do
        local doc = h.readFile(h.missionDir .. "/../../../docs/factions/isaf-" .. year .. ".md")
        local groundSection = doc:match("## Ground Units\n(.-)\n## ")
        for unitType in groundSection:gmatch("%- %[([^%]]+)%]") do
            types[unitType] = true
        end
    end
    return types
end

-- Erusean groups use no ISAF vehicles, so players can tell friend from foe
local function checkNoIsafTypesInRedGroups()
    local isafTypes = isafGroundTypes()
    h.ok(next(isafTypes) ~= nil, "no ISAF ground types read from docs/factions")
    local groupLists = { Virtualization.state.virtualGroups, Virtualization.state.permanentGroups }
    for _, groups in ipairs(groupLists) do
        for _, group in ipairs(groups) do
            local isRed = group.countryId == country.id.CJTF_RED
            if isRed then
                for _, unit in ipairs(group.units) do
                    h.ok(not isafTypes[unit.type], group.name .. " uses ISAF type " .. unit.type)
                end
            end
        end
    end
end

-- Virtual and permanent groups together fit the mission's unit budget
local function checkUnitBudget()
    local config = OperationInfinity.config
    local virtualUnits = Virtualization:getRegisteredUnitCount()
    local permanentUnits = 0
    for _, pGroup in ipairs(Virtualization.state.permanentGroups) do
        permanentUnits = permanentUnits + #pGroup.units
    end
    h.ok(permanentUnits <= config.airDefenseUnitReserve, permanentUnits .. " permanent units exceed the reserve")
    local totalUnits = virtualUnits + permanentUnits
    h.ok(totalUnits <= config.maxSpawnedUnits, totalUnits .. " units exceed maxSpawnedUnits")
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
                checkUnitBudget()
                checkNoIsafTypesInRedGroups()
                checkAirDefenseFacing()
                spawnEverything(env)
                for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
                    h.ok(vGroup.isSpawned, vGroup.name .. " did not spawn with a player overhead")
                end
                for _, pGroup in ipairs(Virtualization.state.permanentGroups) do
                    h.ok(pGroup.isSpawned, pGroup.name .. " permanent group did not spawn")
                end
                checkUniqueIds(env)
                checkUnitData(env)
                checkGroundPlacement(env)
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

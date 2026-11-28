local h = require("harness")

local INFANTRY_CLEARANCE = 4
local VEHICLE_CLEARANCE = 10
local INFANTRY_TYPES = {
    ["Soldier M4"] = true,
    ["Soldier M249"] = true,
    ["Infantry AK Ins"] = true,
    ["Soldier RPG"] = true,
    ["Igla manpad INS"] = true,
}

-- Scenery objects on a square grid within radius of the origin, skipping the
-- ring between gapInner and gapOuter
local function sceneryGrid(spacing, radius, gapInner, gapOuter)
    local objects = {}
    for x = -radius, radius, spacing do
        for y = -radius, radius, spacing do
            local distance = math.sqrt(x * x + y * y)
            local inGap = gapInner and distance >= gapInner and distance <= gapOuter
            if distance <= radius and not inGap then
                objects[#objects + 1] = { x = x, y = y }
            end
        end
    end
    return objects
end

local function spawnAtOrigin()
    local tasking = {
        id = 1,
        slot = OperationOverwatch.config.jtacSlots[1],
        center = { x = 0, y = 0 },
        force = EnemyForce:roll("fixed"),
    }
    return Firefight:spawn(tasking)
end

local function nearestScenery(env, unitRecord)
    local nearest = math.huge
    for _, object in ipairs(env.scenery) do
        local dx = object.x - unitRecord.x
        local dz = object.y - unitRecord.z
        nearest = math.min(nearest, math.sqrt(dx * dx + dz * dz))
    end
    return nearest
end

local function spawnedUnits(env, spawned)
    local units = {}
    for _, names in ipairs({ spawned.friendlyUnitNames, spawned.enemyUnitNames }) do
        for _, name in ipairs(names) do
            units[#units + 1] = env.unitsByName[name]
        end
    end
    return units
end

h.test("without scenery both sides fight in the fields", function()
    h.load()
    local spawned = spawnAtOrigin()
    h.ok(spawned, "spawned")
    h.ok(not spawned.friendlyInCompound, "friendlies in the fields")
    h.ok(not spawned.enemyInCompound, "enemy in the fields")
end)

h.test("the enemy fights from a compound when one is in range", function()
    for seed = 1, 20 do
        -- Buildings everywhere except around the friendlies
        local env = h.load({ seed = seed, scenery = sceneryGrid(50, 1500, 0, 300) })
        Firefight.friendlyCompoundChance = 0
        local spawned = spawnAtOrigin()
        h.ok(spawned.enemyInCompound, "seed " .. seed .. ": enemy in a compound")
        h.ok(not spawned.friendlyInCompound, "seed " .. seed .. ": friendlies in the fields")
        local distance = Spatial:getDistance2D(spawned.friendlyCenter, spawned.enemyCenter)
        h.ok(distance >= 400 and distance <= 900, "seed " .. seed .. ": range " .. distance)
        for _, name in ipairs(spawned.enemyUnitNames) do
            local unit = env.unitsByName[name]
            if INFANTRY_TYPES[unit.type] and not name:find("MANPADS") then
                h.ok(nearestScenery(env, unit) <= 20 + 1, "seed " .. seed .. ": " .. name .. " next to a building")
            end
        end
    end
end)

h.test("the patrol holds a compound when the roll says so", function()
    for seed = 1, 20 do
        h.load({ seed = seed, scenery = sceneryGrid(50, 1500) })
        Firefight.friendlyCompoundChance = 1
        local spawned = spawnAtOrigin()
        h.ok(spawned.friendlyInCompound, "seed " .. seed)
        h.ok(Spatial:getDistance2D(spawned.friendlyCenter, { x = 0, y = 0 }) <= 250, "seed " .. seed .. ": near site")
    end
end)

h.test("units keep clear of scenery objects", function()
    for seed = 1, 20 do
        local env = h.load({ seed = seed, scenery = sceneryGrid(40, 1500) })
        Firefight.friendlyCompoundChance = 1
        local spawned = spawnAtOrigin()
        for _, unit in ipairs(spawnedUnits(env, spawned)) do
            local clearance = INFANTRY_TYPES[unit.type] and INFANTRY_CLEARANCE or VEHICLE_CLEARANCE
            local nearest = nearestScenery(env, unit)
            h.ok(nearest > clearance, string.format("seed %d: %s %.1f m from scenery", seed, unit.name, nearest))
        end
    end
end)

h.test("the brief says where each side is", function()
    h.load({ scenery = sceneryGrid(50, 1500, 0, 300) })
    Firefight.friendlyCompoundChance = 0
    local tasking = {
        id = 1,
        slot = OperationOverwatch.config.jtacSlots[1],
        center = { x = 0, y = 0 },
        force = EnemyForce:roll("fixed"),
    }
    tasking.spawned = Firefight:spawn(tasking)
    local brief = Tasking:briefText(tasking)
    h.ok(brief:find(", in the fields, marked by green smoke", 1, true), "friendlies in the fields")
    h.ok(brief:find("dismounts in compounds,", 1, true), "enemy in compounds")
end)

-- Frontline firefight: ISAF platoons are scenery and the Erusea platoons are
-- left for players to destroy
local h = require("harness")

local SEEDS = { 1, 2, 3 }

local function frontlineGroups(prefix)
    local result = {}
    for _, vGroup in ipairs(Virtualization.state.virtualGroups) do
        if vGroup.name:find("^" .. prefix) then
            result[#result + 1] = vGroup
        end
    end
    return result
end

local function killGroup(env, vGroup)
    local live = env.groupsByName[vGroup.spawnedGroupName]
    for _, u in ipairs(live.units) do
        local unit = env.unitObject(u.name)
        env.fireEvent({ id = world.event.S_EVENT_DEAD, initiator = unit })
        env.killUnit(u.name)
    end
end

h.test("ISAF platoons are scenery and Erusea frontline groups cannot be targeted by AI", function()
    for _, seed in ipairs(SEEDS) do
        local env = h.load({ seed = seed })
        h.generate(env, "Normal", "180", "northeast")
        local isaf = frontlineGroups("ISAF%-F")
        h.ok(#isaf > 0, "no ISAF platoons (seed " .. seed .. ")")
        for _, vGroup in ipairs(isaf) do
            h.ok(vGroup.options.invisible and vGroup.options.immortal, vGroup.name .. " is not immortal and invisible")
            h.eq(
                vGroup.options.fireAtPoint ~= nil,
                #vGroup.fireTargets > 0,
                vGroup.name .. " fires only when it has Erusea platoons"
            )
        end
        local erusea = frontlineGroups("Erusea%-F")
        for _, vGroup in ipairs(frontlineGroups("SHORAD%-F")) do
            erusea[#erusea + 1] = vGroup
        end
        h.ok(#erusea > 0, "no Erusea frontline groups (seed " .. seed .. ")")
        for _, vGroup in ipairs(erusea) do
            h.ok(vGroup.options.invisible, vGroup.name .. " is visible to the ISAF platoons")
            h.ok(not vGroup.options.immortal, vGroup.name .. " is immortal")
        end
    end
end)

h.test("ISAF platoon ceases fire once its Erusea platoons are destroyed", function()
    local env = h.load()
    h.generate(env, "Normal", "180", "northeast")
    local isafGroup
    for _, vGroup in ipairs(frontlineGroups("ISAF%-F")) do
        isafGroup = isafGroup or (#vGroup.fireTargets > 0 and vGroup) or nil
    end
    h.ok(isafGroup ~= nil, "no ISAF platoon with Erusea platoons")

    env.addPlayer("Spawner", isafGroup.center.x, isafGroup.center.y)
    env.advance(120)
    h.ok(isafGroup.isSpawned, isafGroup.name .. " did not spawn")
    local controllerRecord = env.groupsByName[isafGroup.spawnedGroupName]

    for i, target in ipairs(isafGroup.fireTargets) do
        h.ok(target.isSpawned, target.name .. " did not spawn")
        killGroup(env, target)
        env.advance(OperationInfinity.config.frontline.fireTargetWanderInterval * 2)
        if i < #isafGroup.fireTargets then
            h.ok(isafGroup.options.fireAtPoint ~= nil, "ceased fire with Erusea platoons left")
        end
    end

    h.eq(isafGroup.options.fireAtPoint, nil, "fireAtPoint not cleared")
    h.eq(#controllerRecord.tasks, 0, "FireAtPoint task not reset")
    h.ok(env.logContains("Cease fire for " .. isafGroup.name:gsub("%-", "%%-")), "cease fire not logged")
end)

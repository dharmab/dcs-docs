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
        local hasFireTargets = #vGroup.fireTargets > 0
        if hasFireTargets then
            isafGroup = vGroup
            break
        end
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

h.test("supply depots spread across the rear area behind the frontline", function()
    local minRearOffset = OperationInfinity.config.behindLines.depotRearOffset[1]
    for _, combo in ipairs(h.regionPlaytimes()) do
        for _, seed in ipairs(SEEDS) do
            local env = h.load({ seed = seed })
            h.generate(env, "Normal", combo.playtime, combo.region)
            local frontline = OperationInfinity.state.battlefield.frontline
            if #frontline.isafPositions > 0 then
                local depots = frontlineGroups("Depot%-")
                local label = combo.region .. " seed " .. seed
                h.ok(#depots > 0, "no depots in " .. label)
                for _, depot in ipairs(depots) do
                    local dx = depot.center.x - frontline.center.x
                    local dy = depot.center.y - frontline.center.y
                    local behind = dx * frontline.approachDir.x + dy * frontline.approachDir.y
                    h.ok(
                        behind >= minRearOffset,
                        depot.name .. " is " .. math.floor(behind) .. " m behind the front in " .. label
                    )
                end
            end
        end
    end
end)

h.test("artillery batteries have an ammo truck near every gun", function()
    local maxTruckDistance = 100
    for _, combo in ipairs(h.regionPlaytimes()) do
        for _, seed in ipairs(SEEDS) do
            local env = h.load({ seed = seed })
            h.generate(env, "Normal", combo.playtime, combo.region)
            for _, battery in ipairs(frontlineGroups("Artillery%-")) do
                local guns, trucks = {}, {}
                for _, unit in ipairs(battery.units) do
                    if unit.type == UnitTemplates.AmmoTruck then
                        trucks[#trucks + 1] = unit
                    elseif unit.type ~= "BRDM-2" then
                        guns[#guns + 1] = unit
                    end
                end
                local label = battery.name .. " in " .. combo.region .. " seed " .. seed
                h.ok(#guns > 0, label .. " has no guns")
                local trucksNeeded = math.ceil(#guns / UnitTemplates.GunsPerAmmoTruck)
                h.ok(#trucks >= trucksNeeded, label .. " has " .. #trucks .. " ammo trucks for " .. #guns .. " guns")
                for _, gun in ipairs(guns) do
                    local nearest = math.huge
                    for _, truck in ipairs(trucks) do
                        nearest = math.min(nearest, Spatial:getDistance2D(gun, truck))
                    end
                    h.ok(
                        nearest <= maxTruckDistance,
                        label .. " gun is " .. math.floor(nearest) .. " m from an ammo truck"
                    )
                end
            end
        end
    end
end)

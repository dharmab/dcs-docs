-- Shared helpers: Spatial, Units, Formations, BatchScheduler, Terrain, and
-- OperationInfinity utility functions
local h = require("harness")

local NM = 1852

h.test("random points stay inside the radius", function()
    h.load()
    local center = { x = 1000, y = -2000 }
    for _ = 1, 500 do
        local p = Spatial:randomPointInRadius(center, 300)
        h.ok(Spatial:getDistance2D(p, center) <= 300, "point outside radius")
    end
end)

h.test("IDs count up from 1001", function()
    h.load()
    h.eq(Units:getNextGroupId(), 1001)
    h.eq(Units:getNextGroupId(), 1002)
    h.eq(Units:getNextUnitId(), 1001)
end)

h.test("generated IDs start above the mission file's IDs", function()
    local env = h.load()
    local maxGroupId, maxUnitId = 0, 0
    for _, g in ipairs(env.groups) do
        maxGroupId = math.max(maxGroupId, g.data.groupId or 0)
        for _, u in ipairs(g.data.units) do
            maxUnitId = math.max(maxUnitId, u.unitId or 0)
        end
    end
    h.ok(Units.state.groupCounter >= maxGroupId, "group IDs overlap the mission file")
    h.ok(Units.state.unitCounter >= maxUnitId, "unit IDs overlap the mission file")
end)

h.test("formations have one position per unit and keep spacing", function()
    h.load()
    for _, formation in pairs(Formations.FormationType) do
        for count = 1, 8 do
            local positions = Formations:getFormationPositions(count, formation, 30)
            h.eq(#positions, count, formation)
            for i = 1, count do
                for j = i + 1, count do
                    h.ok(Spatial:getDistance2D(positions[i], positions[j]) >= 20, formation .. " units too close")
                end
            end
        end
    end
end)

h.test("unknown formation falls back to a line", function()
    h.load()
    local positions = Formations:getFormationPositions(3, "BOGUS", 10)
    h.eq(positions[1].x, -10)
    h.eq(positions[3].x, 10)
end)

h.test("rotation preserves distance", function()
    h.load()
    local p = Formations:rotatePosition({ x = 30, y = 40 }, 1.234)
    h.near(math.sqrt(p.x * p.x + p.y * p.y), 50, 1e-9)
end)

h.test("center pairs use line or wedge, side pairs never use line", function()
    h.load()
    for _ = 1, 100 do
        local center = Formations:getFormationTypeByPosition(3, 2)
        h.ok(center == "LINE" or center == "WEDGE", "center " .. center)
        h.ok(Formations:getFormationTypeByPosition(3, 1) ~= "LINE", "side pair used LINE")
    end
end)

h.test("platoon units follow the template", function()
    h.load()
    local template = { { type = "T-72B", count = 2 }, { type = "BMP-2", count = 3 } }
    local units = Formations:buildPlatoonUnits(template, { x = 0, y = 0 }, { formation = "LINE", facing = 0 })
    h.eq(#units, 5)
    h.eq(units[1].type, "T-72B")
    h.eq(units[5].type, "BMP-2")
    for _, u in ipairs(units) do
        h.ok(math.sqrt(u.x * u.x + u.y * u.y) < 100, "unit far from center")
    end
end)

h.test("processArray visits every item in order, then completes", function()
    local env = h.load()
    local seen, completed = {}, 0
    BatchScheduler:processArray({
        array = { "a", "b", "c" },
        callback = function(item, index)
            seen[#seen + 1] = item .. index
        end,
        onComplete = function()
            completed = completed + 1
        end,
    })
    env.advance(1)
    h.eq(table.concat(seen, ","), "a1,b2,c3")
    h.eq(completed, 1)
end)

h.test("processArray completes immediately for an empty array", function()
    h.load()
    local completed = false
    BatchScheduler:processArray({
        array = {},
        callback = function() end,
        onComplete = function()
            completed = true
        end,
    })
    h.ok(completed)
end)

h.test("runSequence runs steps in order and stops on error", function()
    local env = h.load()
    local ran, failedStep = {}, nil
    BatchScheduler:runSequence({
        steps = {
            {
                name = "one",
                fn = function(_, done)
                    ran[#ran + 1] = "one"
                    done()
                end,
            },
            {
                name = "two",
                fn = function(_, done)
                    ran[#ran + 1] = "two"
                    done("boom")
                end,
            },
            {
                name = "three",
                fn = function(_, done)
                    ran[#ran + 1] = "three"
                    done()
                end,
            },
        },
        onError = function(_, stepName)
            failedStep = stepName
        end,
    })
    env.advance(1)
    h.eq(table.concat(ran, ","), "one,two")
    h.eq(failedStep, "two")
end)

-- Points from TerrainData.lua decoded by hand: row 1 is "0,49,44,3,...",
-- so columns 1-49 are blocked and columns 50-93 are open
h.test("land cover mask decodes run lengths", function()
    h.load()
    local cell = TerrainData.cellSize
    local function cellCenter(row, column)
        return { x = TerrainData.northX - (row - 0.5) * cell, y = TerrainData.westZ + (column - 0.5) * cell }
    end
    h.ok(Terrain:isBlockedLandCover(cellCenter(1, 1)), "column 1 should be blocked")
    h.ok(Terrain:isBlockedLandCover(cellCenter(1, 49)), "column 49 should be blocked")
    h.ok(not Terrain:isBlockedLandCover(cellCenter(1, 50)), "column 50 should be open")
    h.ok(Terrain:isBlockedLandCover(cellCenter(1, 94)), "column 94 should be blocked")
    h.ok(not Terrain:isBlockedLandCover({ x = TerrainData.northX + cell, y = TerrainData.westZ }), "outside mask")
end)

-- A point in row 1 of the land cover mask, where columns 50-93 are open
local function openGroundPoint()
    local cell = TerrainData.cellSize
    return { x = TerrainData.northX - 0.5 * cell, y = TerrainData.westZ + 70.5 * cell }
end

h.test("a unit on a steep spot moves to nearby flat ground", function()
    local spike = nil
    local spikeRadius, spikeHeight = 12, 100
    h.load({
        heightAt = function(x, z)
            local d = math.sqrt((x - spike.x) ^ 2 + (z - spike.y) ^ 2)
            return math.max(0, spikeHeight * (1 - d / spikeRadius))
        end,
    })
    spike = openGroundPoint()
    local units = {
        { type = "SNR_75V", x = spike.x, y = spike.y },
        { type = "S_75M_Volhov", x = spike.x, y = spike.y + 30 },
    }
    h.ok(not Terrain:isValidUnitPosition(units[1]), "spike should be too steep")
    h.ok(Terrain:placeUnits(units), "units should be placed")

    local moved = math.sqrt((units[1].x - spike.x) ^ 2 + (units[1].y - spike.y) ^ 2)
    local maxMove = Terrain.config.unitProbeStep * Terrain.config.unitProbeRings
    h.ok(moved > 0 and moved <= maxMove + 1e-6, "moved " .. moved)
    h.ok(Terrain:isValidUnitPosition(units[1]), "moved unit should be on flat ground")
    local gap = math.sqrt((units[1].x - units[2].x) ^ 2 + (units[1].y - units[2].y) ^ 2)
    h.ok(gap >= Terrain.config.minUnitSeparation, "moved unit is " .. gap .. " m from its neighbor")
    h.eq(units[2].y, spike.y + 30, "unit on flat ground should not move")
end)

h.test("a layout is rejected when a unit has no flat ground nearby", function()
    -- Flat around the group center, a 45 degree ramp from 100 m east of it
    local center = nil
    h.load({
        heightAt = function(_, z)
            return math.max(0, z - center.y - 100)
        end,
    })
    center = openGroundPoint()
    h.ok(Terrain:isValidTerrainForUnits(center), "group center should be valid")
    local function buildUnits(pos)
        return {
            { type = "SNR_75V", x = pos.x, y = pos.y },
            { type = "S_75M_Volhov", x = pos.x, y = pos.y + 200 },
        }
    end
    local pos = Terrain:findValidLayout(center, 0, buildUnits, nil, 0)
    h.eq(pos, nil)
end)

h.test("aerodrome spawn points respect region constraints", function()
    h.load()
    local aerodrome = { x = 0, y = 0 }
    local constraints = { angleMin = math.pi * 0.5, angleMax = math.pi, minDistance = 5 * NM, maxDistance = 15 * NM }
    for _ = 1, 200 do
        local p = OperationInfinity:randomPointNearAerodrome(aerodrome, constraints)
        local d = Spatial:getDistance2D(p, aerodrome)
        h.ok(d >= 5 * NM - 1 and d <= 15 * NM + 1, "distance " .. d)
        local angle = math.atan2(p.y, p.x)
        h.ok(angle >= math.pi * 0.5 - 1e-9 and angle <= math.pi + 1e-9, "angle " .. angle)
    end
end)

h.test("every region has a support racetrack", function()
    h.load()
    for key in pairs(OperationInfinity.config.aerodromeRegions) do
        h.ok(OperationInfinity.config.supportRacetracks[key], "no racetrack for " .. key)
    end
end)

h.test("coordinates format as degrees and decimal minutes", function()
    h.load()
    local ll, mgrs = OperationInfinity:formatCoordinates({ x = 0, y = 0 })
    h.eq(ll, "45*00.000'N 033*00.000'E")
    h.eq(mgrs, "37TEK 12345 67890")
end)

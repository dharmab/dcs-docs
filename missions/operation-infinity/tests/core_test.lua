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
    h.eq(positions[1].y, -10)
    h.eq(positions[3].y, 10)
end)

h.test("formations are oriented along the facing", function()
    h.load()
    local east = math.pi / 2
    local noJitter = { jitterMin = 0, jitterMax = 0, facing = east }
    -- A line facing east spreads north-south
    noJitter.formation = "LINE"
    local line = Formations:buildPlatoonUnits({ { type = "M1A2", count = 4 } }, { x = 0, y = 0 }, noJitter)
    h.near(line[1].y, 0, 1e-9)
    h.ok(math.abs(line[4].x - line[1].x) > 50, "line not spread across the facing")
    -- A wedge facing east trails west of its lead
    noJitter.formation = "WEDGE"
    local wedge = Formations:buildPlatoonUnits({ { type = "M1A2", count = 3 } }, { x = 0, y = 0 }, noJitter)
    h.ok(wedge[2].y < wedge[1].y and wedge[3].y < wedge[1].y, "wedge trails ahead of its lead")
    for _, u in ipairs(wedge) do
        h.near(u.heading, east, math.rad(10) + 1e-9)
    end
end)

h.test("SAM launchers ring the site around its radars", function()
    h.load()
    OperationInfinity.state.battlefield.frontline.approachDir = { x = 0, y = 1 }
    local template = UnitTemplates.SAMSites.Hard.SA10
    local launcherTypes = {}
    for _, def in ipairs(template) do
        if def.launcher then
            launcherTypes[def.type] = true
        end
    end
    h.ok(next(launcherTypes) ~= nil, "SA10 template marks no launchers")
    local center = { x = 1000, y = 2000 }
    local ring = UnitTemplates.SAMLauncherRings.SA10
    local units = BattlefieldGeneration:buildSAMUnits("SA10", template, center)
    local launcherCount = 0
    for _, u in ipairs(units) do
        local dist = math.sqrt((u.x - center.x) ^ 2 + (u.y - center.y) ^ 2)
        if launcherTypes[u.type] then
            launcherCount = launcherCount + 1
            local onRing = math.abs(dist - ring.radius) <= ring.jitter + 1e-6
            h.ok(onRing, u.type .. " is " .. dist .. " m from the center, not on the ring")
        else
            h.ok(dist < 50, u.type .. " is " .. dist .. " m from the center, outside the core")
        end
    end
    h.eq(launcherCount, 6)
end)

h.test("every SAM site with launchers has a launcher ring", function()
    h.load()
    for difficulty, sites in pairs(UnitTemplates.SAMSites) do
        for samType, template in pairs(sites) do
            for _, def in ipairs(template) do
                if def.launcher then
                    local ring = UnitTemplates.SAMLauncherRings[samType]
                    h.ok(ring, difficulty .. " " .. samType .. " has no launcher ring")
                end
            end
        end
    end
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

-- Senaki from docs/data/terrains/Caucasus/places.csv: 42.285411 N,
-- 42.045822 E. The MGRS value is from the Python mgrs package.
h.test("coordinates format as degrees and decimal minutes", function()
    h.load()
    local ll, mgrs = OperationInfinity:formatCoordinates({ x = -276848.2, y = 646568.0 })
    h.eq(ll, "42*17.125'N 042*02.749'E")
    h.eq(mgrs, "38TKM 56427 85692")
end)

-- Open ground near Gudauta where a generated depot was placed
local OPEN_GROUND = { x = -195445, y = 528525 }

-- Replace the mock's road lookup; rawset keeps the type checker from
-- reporting a redefinition of the stubbed API
local function setNearestRoad(x, y)
    rawset(land, "getClosestPointOnRoads", function()
        return x, y
    end)
end

local function buildOneUnit(pos)
    return { { type = "Ural-375", x = pos.x, y = pos.y } }
end

h.test("road-bound layouts are placed near the road nearest the anchor", function()
    h.load()
    local road = { x = OPEN_GROUND.x - 3000, y = OPEN_GROUND.y }
    setNearestRoad(road.x, road.y)
    local maxRoadDistance = 200
    local anchor = { x = road.x + 3000, y = road.y }
    local pos = Terrain:findValidLayout(anchor, 300, buildOneUnit, { maxRoadDistance = maxRoadDistance })
    h.ok(pos, "no position found")
    h.ok(Spatial:getDistance2D(pos, road) <= maxRoadDistance, "position is too far from the road")
end)

h.test("road-bound layouts are skipped when the nearest road is too far", function()
    h.load()
    local farAway = OPEN_GROUND.x - Terrain.config.maxRoadSnapDistance - 1000
    setNearestRoad(farAway, OPEN_GROUND.y)
    local pos = Terrain:findValidLayout(OPEN_GROUND, 300, buildOneUnit, { maxRoadDistance = 200 })
    h.eq(pos, nil)
end)

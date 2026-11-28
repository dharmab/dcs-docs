local h = require("harness")

h.test("pointInPolygon", function()
    h.load()
    local square = h.testArea
    h.ok(Sites:pointInPolygon({ x = 0, y = 0 }, square), "center")
    h.ok(not Sites:pointInPolygon({ x = 60000, y = 0 }, square), "outside")
end)

h.test("bearingDegrees is true bearing with x north and y east", function()
    h.load()
    local origin = { x = 0, y = 0 }
    h.eq(Sites:bearingDegrees(origin, { x = 100, y = 0 }), 0, "north")
    h.eq(Sites:bearingDegrees(origin, { x = 0, y = 100 }), 90, "east")
    h.eq(Sites:bearingDegrees(origin, { x = -100, y = 0 }), 180, "south")
    h.eq(Sites:bearingDegrees(origin, { x = 0, y = -100 }), 270, "west")
end)

h.test("fixed-wing sites are inside the area of operations", function()
    for seed = 1, 50 do
        h.load({ seed = seed })
        local site = Sites:pickTaskingCenter("fixed")
        h.ok(site, "site for seed " .. seed)
        h.ok(Sites:isInAreaOfOperations(site), "seed " .. seed)
    end
end)

h.test("rotary sites are within the radius of a FARP", function()
    for seed = 1, 50 do
        h.load({ seed = seed })
        local site = Sites:pickTaskingCenter("rotary")
        local distance = Spatial:getDistance2D(site, h.testFarps[1].position)
        h.ok(distance <= OperationOverwatch.config.rotaryTaskingRadius, "seed " .. seed)
    end
end)

h.test("no site without an area of operations", function()
    h.load({ noArea = true })
    h.eq(Sites:pickTaskingCenter("fixed"), nil)
end)

h.test("sites avoid water", function()
    local WATER = 3
    local LAND = 1
    h.load({
        surfaceAt = function(x)
            return x < 0 and WATER or LAND
        end,
    })
    for _ = 1, 20 do
        local site = Sites:pickTaskingCenter("fixed")
        h.ok(site.x >= 0, "site on water at x=" .. site.x)
    end
end)

h.test("isSite reads the site grid", function()
    h.load()
    local grid = {
        cellSize = 100,
        northX = 1000,
        westZ = 0,
        columns = 4,
        -- Row 1: columns 2-3 are sites. Row 2: column 1 is a site.
        siteCounts = "2,1",
        rows = { "1,2,1", "0,1,3" },
    }
    OperationOverwatch.config.siteGrid = grid
    h.ok(not Sites:isSite({ x = 950, y = 50 }), "row 1 column 1")
    h.ok(Sites:isSite({ x = 950, y = 150 }), "row 1 column 2")
    h.ok(Sites:isSite({ x = 950, y = 250 }), "row 1 column 3")
    h.ok(not Sites:isSite({ x = 950, y = 350 }), "row 1 column 4")
    h.ok(Sites:isSite({ x = 850, y = 50 }), "row 2 column 1")
    h.ok(not Sites:isSite({ x = 850, y = 150 }), "row 2 column 2")
    h.ok(not Sites:isSite({ x = 1050, y = 150 }), "north of the grid")
    h.ok(not Sites:isSite({ x = 950, y = 450 }), "east of the grid")

    for _ = 1, 50 do
        local site = Sites:randomSite()
        h.ok(Sites:isSite(site), string.format("random site x=%.0f y=%.0f", site.x, site.y))
    end
end)

h.test("no site when the grid has no sites", function()
    h.load()
    OperationOverwatch.config.siteGrid = {
        cellSize = 100,
        northX = 1000,
        westZ = 0,
        columns = 2,
        siteCounts = "0",
        rows = { "2" },
    }
    h.eq(Sites:randomSite(), nil)
    h.eq(Sites:pickTaskingCenter("fixed"), nil)
end)

-- The tests below use the generated Afghanistan data in TerrainData.lua

h.test("FARPs and the check-in point are in the area of operations", function()
    h.load({ realTerrain = true })
    local config = OperationOverwatch.config
    h.ok(#config.farps > 0, "FARPs configured")
    for _, farp in ipairs(config.farps) do
        h.ok(Sites:isInAreaOfOperations(farp.position), farp.name)
    end
    h.ok(Sites:isInAreaOfOperations(config.checkInPoint), "check-in point")
end)

h.test("fixed-wing sites are on generated sites in the area of operations", function()
    for seed = 1, 50 do
        h.load({ seed = seed, realTerrain = true })
        local site = Sites:pickTaskingCenter("fixed")
        h.ok(site, "site for seed " .. seed)
        h.ok(Sites:isSite(site), "on a site, seed " .. seed)
        h.ok(Sites:isInAreaOfOperations(site), "in area, seed " .. seed)
    end
end)

h.test("rotary sites are on generated sites near a real FARP", function()
    for seed = 1, 50 do
        h.load({ seed = seed, realTerrain = true })
        local config = OperationOverwatch.config
        local site = Sites:pickTaskingCenter("rotary")
        h.ok(site, "site for seed " .. seed)
        h.ok(Sites:isSite(site), "on a site, seed " .. seed)
        local nearest = math.huge
        for _, farp in ipairs(config.farps) do
            nearest = math.min(nearest, Spatial:getDistance2D(site, farp.position))
        end
        h.ok(nearest <= config.rotaryTaskingRadius, "seed " .. seed)
    end
end)

h.test("every FARP has sites within the rotary radius", function()
    h.load({ realTerrain = true })
    local config = OperationOverwatch.config
    local SAMPLES = 2000
    local MIN_SITE_FRACTION = 0.05
    for _, farp in ipairs(config.farps) do
        local hits = 0
        for _ = 1, SAMPLES do
            local point = Spatial:randomPointInRadius(farp.position, config.rotaryTaskingRadius)
            if Sites:isSite(point) then
                hits = hits + 1
            end
        end
        local fraction = hits / SAMPLES
        h.ok(fraction >= MIN_SITE_FRACTION, string.format("%s site fraction %.3f", farp.name, fraction))
    end
end)

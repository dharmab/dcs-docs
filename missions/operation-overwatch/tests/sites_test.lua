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

-- The mock's terrain model (terrain_model.lua) against the terrain export
local h = require("harness")

local PLACES_CSV = h.missionDir .. "/../../../docs/data/terrains/Caucasus/places.csv"
-- places.csv rounds latitude and longitude to 6 decimals, about 0.1 m
local MAX_POSITION_ERROR_M = 0.5
local MAX_ANGLE_ERROR_DEG = 5e-6

local function readPlaces()
    local places = {}
    for line in io.lines(PLACES_CSV) do
        local name, lat, lon, x, z = line:match("^(.-),(-?[%d.]+),(-?[%d.]+),(-?[%d.]+),(-?[%d.]+)$")
        if name then
            places[#places + 1] =
                { name = name, lat = tonumber(lat), lon = tonumber(lon), x = tonumber(x), z = tonumber(z) }
        end
    end
    return places
end

h.test("coord.LLtoLO and LOtoLL match every place in places.csv", function()
    h.load()
    local places = readPlaces()
    h.ok(#places > 1000, "read only " .. #places .. " places")
    for _, place in ipairs(places) do
        local p = coord.LLtoLO(place.lat, place.lon)
        local positionError = math.sqrt((p.x - place.x) ^ 2 + (p.z - place.z) ^ 2)
        h.ok(positionError <= MAX_POSITION_ERROR_M, place.name .. " is " .. positionError .. " m off")
        local lat, lon = coord.LOtoLL({ x = place.x, y = 0, z = place.z })
        h.near(lat, place.lat, MAX_ANGLE_ERROR_DEG, place.name .. " latitude")
        h.near(lon, place.lon, MAX_ANGLE_ERROR_DEG, place.name .. " longitude")
    end
end)

-- Expected values from the Python mgrs package; one point is on a zone edge
h.test("coord.LLtoMGRS matches a reference implementation", function()
    h.load()
    local cases = {
        { lat = 45.0, lon = 33.0, square = "36TWQ", easting = 0, northing = 82950 },
        { lat = 43.5, lon = 41.25, square = "37TFJ", easting = 81902, northing = 18800 },
        { lat = 41.2, lon = 44.9, square = "38TML", easting = 91615, northing = 60964 },
    }
    for _, case in ipairs(cases) do
        local mgrs = coord.LLtoMGRS(case.lat, case.lon)
        h.eq(mgrs.UTMZone .. mgrs.MGRSDigraph, case.square)
        h.eq(math.floor(mgrs.Easting), case.easting, case.square .. " easting")
        h.eq(math.floor(mgrs.Northing), case.northing, case.square .. " northing")
    end
end)

h.test("surface types follow the land cover", function()
    h.load()
    local surface = land.SurfaceType
    -- Carrier operating area, Senaki town, Senaki runway (features.gpkg),
    -- and a river cell in landcover.tif
    h.eq(land.getSurfaceType({ x = -70000, y = 225000 }), surface.WATER, "Black Sea")
    h.eq(land.getSurfaceType({ x = -276848, y = 646568 }), surface.LAND, "Senaki")
    h.eq(land.getSurfaceType({ x = -281315, y = 647244 }), surface.RUNWAY, "Senaki runway")
    h.eq(land.getSurfaceType({ x = -300000, y = 669000 }), surface.SHALLOW_WATER, "river")
end)

h.test("the closest road point is on a road", function()
    h.load()
    local x, y = land.getClosestPointOnRoads("roads", -276848, 646568)
    h.ok(x, "no road found")
    h.eq(land.getSurfaceType({ x = x, y = y }), land.SurfaceType.ROAD)
    local distance = math.sqrt((x + 276848) ^ 2 + (y - 646568) ^ 2)
    h.ok(distance < 2000, "nearest road to Senaki is " .. distance .. " m away")
end)

h.test("mission scripts run without the globals DCS removes", function()
    h.load()
    local scriptEnv = getfenv(OperationInfinity.selectDifficulty)
    for _, name in ipairs(h.sanitizedGlobals) do
        h.eq(scriptEnv[name], nil, name)
        h.eq(scriptEnv._G[name], nil, "_G." .. name)
    end
    h.ok(rawget(scriptEnv._G, "TerrainData"), "scripts cannot see each other's globals through _G")
end)

-- =============================================================================
-- TERRAIN MODEL
-- Answers the mock's land and coord queries from mock_terrain.lua, which is
-- generated from the terrain export in docs/data/terrains. The export has no
-- elevation, so height stays flat in the mock.
-- =============================================================================

local TerrainModel = {}
TerrainModel.__index = TerrainModel

local SURFACE_LAND = 1
local SURFACE_ROAD = 4

-- getSurfaceType reports ROAD within this distance of a road line
local ROAD_HALF_WIDTH_M = 5
-- Road segments are indexed in square buckets of this size
local ROAD_BUCKET_M = 2000

-- WGS84
local SEMI_MAJOR_AXIS = 6378137
local FLATTENING = 1 / 298.257223563

local UTM_SCALE_FACTOR = 0.9996
local UTM_FALSE_EASTING = 500000
local UTM_FALSE_NORTHING_SOUTH = 10000000
local UTM_ZONE_WIDTH_DEG = 6
local MGRS_SQUARE_M = 100000
local MGRS_BAND_LETTERS = "CDEFGHJKLMNPQRSTUVWX"
local MGRS_BAND_HEIGHT_DEG = 8
local MGRS_SOUTH_LIMIT_DEG = -80
local MGRS_COLUMN_LETTERS = { "ABCDEFGH", "JKLMNPQR", "STUVWXYZ" }
local MGRS_ROW_LETTERS = "ABCDEFGHJKLMNPQRSTUV"
local MGRS_EVEN_ZONE_ROW_OFFSET = 5

-- -----------------------------------------------------------------------------
-- Transverse Mercator (Krüger series, accurate to millimetres within the
-- width of a DCS map)
-- -----------------------------------------------------------------------------

local n = FLATTENING / (2 - FLATTENING)
local n2, n3, n4 = n * n, n * n * n, n * n * n * n
local RECTIFYING_RADIUS = SEMI_MAJOR_AXIS / (1 + n) * (1 + n2 / 4 + n4 / 64)
local ALPHA = {
    n / 2 - 2 / 3 * n2 + 5 / 16 * n3 + 41 / 180 * n4,
    13 / 48 * n2 - 3 / 5 * n3 + 557 / 1440 * n4,
    61 / 240 * n3 - 103 / 140 * n4,
    49561 / 161280 * n4,
}
local BETA = {
    n / 2 - 2 / 3 * n2 + 37 / 96 * n3 - 1 / 360 * n4,
    1 / 48 * n2 + 1 / 15 * n3 - 437 / 1440 * n4,
    17 / 480 * n3 - 37 / 840 * n4,
    4397 / 161280 * n4,
}
local DELTA = {
    2 * n - 2 / 3 * n2 - 2 * n3,
    7 / 3 * n2 - 8 / 5 * n3,
    56 / 15 * n3,
}
local CONFORMAL_FACTOR = 2 * math.sqrt(n) / (1 + n)

local function atanh(x)
    return 0.5 * math.log((1 + x) / (1 - x))
end

-- Returns easting, northing
local function tmForward(proj, lat, lon)
    local phi = math.rad(lat)
    local dLambda = math.rad(lon - proj.centralMeridian)
    local sinPhi = math.sin(phi)
    local t = math.sinh(atanh(sinPhi) - CONFORMAL_FACTOR * atanh(CONFORMAL_FACTOR * sinPhi))
    local xiPrime = math.atan2(t, math.cos(dLambda))
    local etaPrime = atanh(math.sin(dLambda) / math.sqrt(1 + t * t))
    local xi, eta = xiPrime, etaPrime
    for j, a in ipairs(ALPHA) do
        xi = xi + a * math.sin(2 * j * xiPrime) * math.cosh(2 * j * etaPrime)
        eta = eta + a * math.cos(2 * j * xiPrime) * math.sinh(2 * j * etaPrime)
    end
    local k = proj.scaleFactor * RECTIFYING_RADIUS
    return proj.falseEasting + k * eta, proj.falseNorthing + k * xi
end

-- Returns latitude, longitude in degrees
local function tmInverse(proj, easting, northing)
    local k = proj.scaleFactor * RECTIFYING_RADIUS
    local xi = (northing - proj.falseNorthing) / k
    local eta = (easting - proj.falseEasting) / k
    local xiPrime, etaPrime = xi, eta
    for j, b in ipairs(BETA) do
        xiPrime = xiPrime - b * math.sin(2 * j * xi) * math.cosh(2 * j * eta)
        etaPrime = etaPrime - b * math.cos(2 * j * xi) * math.sinh(2 * j * eta)
    end
    local chi = math.asin(math.sin(xiPrime) / math.cosh(etaPrime))
    local phi = chi
    for j, d in ipairs(DELTA) do
        phi = phi + d * math.sin(2 * j * chi)
    end
    local lambda = math.atan2(math.sinh(etaPrime), math.cos(xiPrime))
    return math.deg(phi), proj.centralMeridian + math.deg(lambda)
end

-- -----------------------------------------------------------------------------
-- Construction
-- -----------------------------------------------------------------------------

local function parseNumbers(text)
    local values = {}
    for value in text:gmatch("-?%d+") do
        values[#values + 1] = tonumber(value)
    end
    return values
end

local function bucketKey(bx, bz)
    return bx .. ":" .. bz
end

local function indexRoads(roadStrings)
    local buckets = {}
    for _, text in ipairs(roadStrings) do
        local c = parseNumbers(text)
        for i = 1, #c - 3, 2 do
            local segment = { c[i], c[i + 1], c[i + 2], c[i + 3] }
            local bx1 = math.floor(math.min(segment[1], segment[3]) / ROAD_BUCKET_M)
            local bx2 = math.floor(math.max(segment[1], segment[3]) / ROAD_BUCKET_M)
            local bz1 = math.floor(math.min(segment[2], segment[4]) / ROAD_BUCKET_M)
            local bz2 = math.floor(math.max(segment[2], segment[4]) / ROAD_BUCKET_M)
            for bx = bx1, bx2 do
                for bz = bz1, bz2 do
                    local key = bucketKey(bx, bz)
                    local bucket = buckets[key]
                    if not bucket then
                        bucket = {}
                        buckets[key] = bucket
                    end
                    bucket[#bucket + 1] = segment
                end
            end
        end
    end
    return buckets
end

-- Build a model from the table mock_terrain.lua returns
function TerrainModel.new(data)
    local self = setmetatable({}, TerrainModel)
    self.projection = data.projection
    self.surface = data.surface
    self.decodedRows = {}
    self.roadBuckets = indexRoads(data.roads)
    local bounds = { minX = math.huge, maxX = -math.huge, minZ = math.huge, maxZ = -math.huge }
    for key in pairs(self.roadBuckets) do
        local bx, bz = key:match("^(-?%d+):(-?%d+)$")
        bx, bz = tonumber(bx), tonumber(bz)
        bounds.minX, bounds.maxX = math.min(bounds.minX, bx), math.max(bounds.maxX, bx)
        bounds.minZ, bounds.maxZ = math.min(bounds.minZ, bz), math.max(bounds.maxZ, bz)
    end
    self.bucketBounds = bounds
    return self
end

-- -----------------------------------------------------------------------------
-- Roads
-- -----------------------------------------------------------------------------

-- Buckets on the square ring `ring` buckets out from (cx, cz)
local function ringBuckets(cx, cz, ring)
    local cells = {}
    if ring == 0 then
        cells[1] = { cx, cz }
        return cells
    end
    for bx = cx - ring, cx + ring do
        cells[#cells + 1] = { bx, cz - ring }
        cells[#cells + 1] = { bx, cz + ring }
    end
    for bz = cz - ring + 1, cz + ring - 1 do
        cells[#cells + 1] = { cx - ring, bz }
        cells[#cells + 1] = { cx + ring, bz }
    end
    return cells
end

local function closestOnSegment(segment, x, z)
    local ax, az, bx, bz = segment[1], segment[2], segment[3], segment[4]
    local dx, dz = bx - ax, bz - az
    local lengthSquared = dx * dx + dz * dz
    local t = 0
    if lengthSquared > 0 then
        t = math.max(0, math.min(1, ((x - ax) * dx + (z - az) * dz) / lengthSquared))
    end
    local px, pz = ax + t * dx, az + t * dz
    return px, pz, (px - x) ^ 2 + (pz - z) ^ 2
end

-- Nearest point on any road line. Returns x, z, distance, or nil if there
-- are no roads.
function TerrainModel:closestRoadPoint(x, z)
    local cx = math.floor(x / ROAD_BUCKET_M)
    local cz = math.floor(z / ROAD_BUCKET_M)
    local b = self.bucketBounds
    -- Past this ring there are no more buckets with roads
    local lastRing =
        math.max(math.abs(cx - b.minX), math.abs(cx - b.maxX), math.abs(cz - b.minZ), math.abs(cz - b.maxZ))
    local bestX, bestZ, bestDistanceSquared
    for ring = 0, lastRing do
        -- Every bucket in this ring is at least (ring - 1) buckets away
        local ringMinDistance = math.max(0, ring - 1) * ROAD_BUCKET_M
        local ringIsBeyondBest = bestDistanceSquared and ringMinDistance * ringMinDistance > bestDistanceSquared
        if ringIsBeyondBest then
            break
        end
        for _, cell in ipairs(ringBuckets(cx, cz, ring)) do
            local bucket = self.roadBuckets[bucketKey(cell[1], cell[2])]
            for _, segment in ipairs(bucket or {}) do
                local px, pz, d2 = closestOnSegment(segment, x, z)
                if not bestDistanceSquared or d2 < bestDistanceSquared then
                    bestX, bestZ, bestDistanceSquared = px, pz, d2
                end
            end
        end
    end
    if not bestX then
        return nil
    end
    return bestX, bestZ, math.sqrt(bestDistanceSquared)
end

-- -----------------------------------------------------------------------------
-- Surface
-- -----------------------------------------------------------------------------

function TerrainModel:surfaceRow(row)
    local decoded = self.decodedRows[row]
    if decoded then
        return decoded
    end
    -- Expand value, run length pairs into run end columns
    local pairs_ = parseNumbers(self.surface.rows[row])
    decoded = { ends = {}, values = {} }
    local column = 0
    for i = 1, #pairs_, 2 do
        column = column + pairs_[i + 1]
        decoded.values[#decoded.values + 1] = pairs_[i]
        decoded.ends[#decoded.ends + 1] = column
    end
    self.decodedRows[row] = decoded
    return decoded
end

-- True within ROAD_HALF_WIDTH_M of a road line
function TerrainModel:isOnRoad(x, z)
    local maxDistanceSquared = ROAD_HALF_WIDTH_M * ROAD_HALF_WIDTH_M
    for bx = math.floor((x - ROAD_HALF_WIDTH_M) / ROAD_BUCKET_M), math.floor((x + ROAD_HALF_WIDTH_M) / ROAD_BUCKET_M) do
        for bz = math.floor((z - ROAD_HALF_WIDTH_M) / ROAD_BUCKET_M), math.floor((z + ROAD_HALF_WIDTH_M) / ROAD_BUCKET_M) do
            for _, segment in ipairs(self.roadBuckets[bucketKey(bx, bz)] or {}) do
                local _, _, d2 = closestOnSegment(segment, x, z)
                if d2 <= maxDistanceSquared then
                    return true
                end
            end
        end
    end
    return false
end

-- land.SurfaceType at DCS x, z. Outside the grid is LAND.
function TerrainModel:surfaceAt(x, z)
    if self:isOnRoad(x, z) then
        return SURFACE_ROAD
    end
    local grid = self.surface
    local row = math.floor((grid.northX - x) / grid.cellSize) + 1
    local column = math.floor((z - grid.westZ) / grid.cellSize)
    local insideRows = row >= 1 and row <= #grid.rows
    local insideColumns = column >= 0 and column < grid.columns
    if not (insideRows and insideColumns) then
        return SURFACE_LAND
    end
    local decoded = self:surfaceRow(row)
    -- Binary search for the run containing the column
    local lo, hi = 1, #decoded.ends
    while lo < hi do
        local mid = math.floor((lo + hi) / 2)
        if decoded.ends[mid] > column then
            hi = mid
        else
            lo = mid + 1
        end
    end
    return decoded.values[lo]
end

-- -----------------------------------------------------------------------------
-- Coordinates
-- -----------------------------------------------------------------------------

-- DCS x, z to latitude, longitude
function TerrainModel:toLatLon(x, z)
    return tmInverse(self.projection, z, x)
end

-- Latitude, longitude to DCS x, z
function TerrainModel:fromLatLon(lat, lon)
    local easting, northing = tmForward(self.projection, lat, lon)
    return northing, easting
end

-- Latitude, longitude to an MGRS table as coord.LLtoMGRS returns it. Ignores
-- the Norway and Svalbard zone exceptions, which no DCS map covers.
function TerrainModel.toMGRS(lat, lon)
    local zone = math.floor((lon + 180) / UTM_ZONE_WIDTH_DEG) + 1
    local bandIndex = math.floor((lat - MGRS_SOUTH_LIMIT_DEG) / MGRS_BAND_HEIGHT_DEG) + 1
    bandIndex = math.max(1, math.min(#MGRS_BAND_LETTERS, bandIndex))
    local band = MGRS_BAND_LETTERS:sub(bandIndex, bandIndex)
    local utm = {
        centralMeridian = (zone - 1) * UTM_ZONE_WIDTH_DEG - 180 + UTM_ZONE_WIDTH_DEG / 2,
        scaleFactor = UTM_SCALE_FACTOR,
        falseEasting = UTM_FALSE_EASTING,
        falseNorthing = lat < 0 and UTM_FALSE_NORTHING_SOUTH or 0,
    }
    local easting, northing = tmForward(utm, lat, lon)

    local columnLetters = MGRS_COLUMN_LETTERS[(zone - 1) % #MGRS_COLUMN_LETTERS + 1]
    local column = math.floor(easting / MGRS_SQUARE_M)
    local rowOffset = zone % 2 == 0 and MGRS_EVEN_ZONE_ROW_OFFSET or 0
    local row = (math.floor(northing / MGRS_SQUARE_M) + rowOffset) % #MGRS_ROW_LETTERS + 1
    return {
        UTMZone = zone .. band,
        MGRSDigraph = columnLetters:sub(column, column) .. MGRS_ROW_LETTERS:sub(row, row),
        Easting = easting % MGRS_SQUARE_M,
        Northing = northing % MGRS_SQUARE_M,
    }
end

return TerrainModel

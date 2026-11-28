-- =============================================================================
-- SITES
-- Chooses tasking locations at runtime.
-- Taskings are placed on tasking sites from TerrainData.lua: farmland and open
-- ground in the green zones of the area of operations. Fixed-wing taskings go
-- on any site. Rotary-wing taskings go on a site within a radius of a FARP.
--
-- The land cover does not show compounds, so they are found at runtime from
-- scenery objects (buildings and compound walls) near a site.
-- =============================================================================

if _G.SitesLoaded then
    env.info("[Sites] Script already loaded, skipping")
    return
end
_G.SitesLoaded = true

Sites = {}

local log = Logging:create("Sites")

local MAX_ATTEMPTS = 200
-- Rotary sites cover a small part of a FARP's radius, so rejection sampling
-- needs more attempts
local ROTARY_ATTEMPTS = 2000
local FULL_CIRCLE_DEGREES = 360
-- Candidate points tried when looking for a compound
local COMPOUND_CANDIDATES = 12
-- Scenery objects collected per compound search. More adds nothing to unit
-- placement and costs time in dense villages.
local COMPOUND_OBJECT_LIMIT = 60
-- Search spheres start this far above the ground
local SEARCH_HEIGHT_METERS = 1

-- Ray-casting point-in-polygon test. polygon is an array of { x, y }.
function Sites:pointInPolygon(point, polygon)
    local inside = false
    local j = #polygon
    for i = 1, #polygon do
        local a = polygon[i]
        local b = polygon[j]
        local edgeStraddlesPoint = (a.y > point.y) ~= (b.y > point.y)
        if edgeStraddlesPoint then
            local crossingX = (b.x - a.x) * (point.y - a.y) / (b.y - a.y) + a.x
            if point.x < crossingX then
                inside = not inside
            end
        end
        j = i
    end
    return inside
end

-- True bearing in degrees from one map point to another. DCS x is north and
-- y (z in 3D) is east.
function Sites:bearingDegrees(from, to)
    local degrees = math.deg(math.atan2(to.y - from.y, to.x - from.x))
    return (degrees + FULL_CIRCLE_DEGREES) % FULL_CIRCLE_DEGREES
end

-- A point at a bearing (radians, from north) and distance from origin
function Sites:offset(origin, bearing, distance)
    return {
        x = origin.x + distance * math.cos(bearing),
        y = origin.y + distance * math.sin(bearing),
    }
end

-- Decoded site mask rows, keyed by row index. Each row is a list of
-- cumulative run ends; odd runs are non-site, even runs are site.
local decodedRows = {}
local decodedGrid = nil
-- Cumulative site counts per row, built on the first pick
local cumulativeCounts = nil
local countsGrid = nil

local function siteGrid()
    return OperationOverwatch.config.siteGrid
end

local function decodeRow(grid, rowIndex)
    if decodedGrid ~= grid then
        decodedRows = {}
        decodedGrid = grid
    end
    local row = decodedRows[rowIndex]
    if row then
        return row
    end
    row = {}
    local columnEnd = 0
    for runLength in grid.rows[rowIndex]:gmatch("%d+") do
        columnEnd = columnEnd + tonumber(runLength)
        row[#row + 1] = columnEnd
    end
    decodedRows[rowIndex] = row
    return row
end

local function siteCounts(grid)
    if countsGrid ~= grid then
        cumulativeCounts = {}
        local total = 0
        for count in grid.siteCounts:gmatch("%d+") do
            total = total + tonumber(count)
            cumulativeCounts[#cumulativeCounts + 1] = total
        end
        countsGrid = grid
    end
    return cumulativeCounts
end

-- Index of the first entry in an ascending list that is >= value
local function firstAtLeast(list, value)
    local low, high = 1, #list
    while low < high do
        local middle = math.floor((low + high) / 2)
        if list[middle] >= value then
            high = middle
        else
            low = middle + 1
        end
    end
    return low
end

-- True when the point is on a tasking site cell
function Sites:isSite(point)
    local grid = siteGrid()
    if not grid then
        return false
    end
    local rowIndex = math.floor((grid.northX - point.x) / grid.cellSize) + 1
    local column = math.floor((point.y - grid.westZ) / grid.cellSize) + 1
    local rowIsInGrid = rowIndex >= 1 and rowIndex <= #grid.rows
    local columnIsInGrid = column >= 1 and column <= grid.columns
    if not (rowIsInGrid and columnIsInGrid) then
        return false
    end
    local row = decodeRow(grid, rowIndex)
    return firstAtLeast(row, column) % 2 == 0
end

-- A random point on a tasking site, each site cell equally likely, or nil
-- when the grid has no sites
function Sites:randomSite()
    local grid = siteGrid()
    if not grid then
        return nil
    end
    local counts = siteCounts(grid)
    local total = counts[#counts] or 0
    if total == 0 then
        return nil
    end

    local pick = math.random(total)
    local rowIndex = firstAtLeast(counts, pick)
    local previousRowsTotal = counts[rowIndex - 1] or 0
    local siteInRow = pick - previousRowsTotal

    -- Walk the site runs to the column of the nth site cell in the row
    local row = decodeRow(grid, rowIndex)
    local column = nil
    local runStart = 0
    for i, runEnd in ipairs(row) do
        local isSiteRun = i % 2 == 0
        local runLength = runEnd - runStart
        if isSiteRun then
            if siteInRow <= runLength then
                column = runStart + siteInRow
                break
            end
            siteInRow = siteInRow - runLength
        end
        runStart = runEnd
    end
    if not column then
        log("Site counts disagree with row " .. rowIndex)
        return nil
    end

    return {
        x = grid.northX - (rowIndex - 1 + math.random()) * grid.cellSize,
        y = grid.westZ + (column - 1 + math.random()) * grid.cellSize,
    }
end

function Sites:isValidPoint(point)
    local surface = land.getSurfaceType({ x = point.x, y = point.y })
    return surface == land.SurfaceType.LAND
end

function Sites:isInAreaOfOperations(point)
    local polygon = OperationOverwatch.config.areaOfOperations
    return polygon ~= nil and self:pointInPolygon(point, polygon)
end

-- Scenery objects within radius of a map point, as map points { x, y }. Stops
-- after limit objects when limit is given.
function Sites:sceneryNear(point, radius, limit)
    local found = {}
    local volume = {
        id = world.VolumeType.SPHERE,
        params = {
            point = { x = point.x, y = land.getHeight(point) + SEARCH_HEIGHT_METERS, z = point.y },
            radius = radius,
        },
    }
    world.searchObjects(Object.Category.SCENERY, volume, function(object)
        local ok, position = pcall(object.getPoint, object)
        if ok and position then
            found[#found + 1] = { x = position.x, y = position.z }
        end
        return limit == nil or #found < limit
    end)
    return found
end

-- True when a unit can stand at the point: valid ground and no scenery object
-- within clearance
function Sites:isClear(point, clearance)
    if not self:isValidPoint(point) then
        return false
    end
    return #self:sceneryNear(point, clearance, 1) == 0
end

-- The densest compound among points between minDistance and maxDistance from
-- origin: { center, buildings } where buildings are the scenery objects within
-- radius of center. nil when no candidate has scenery within radius.
function Sites:pickCompoundNear(origin, minDistance, maxDistance, radius)
    local best = nil
    for _ = 1, COMPOUND_CANDIDATES do
        local candidate = self:pickPointNear(origin, minDistance, maxDistance)
        if candidate then
            local buildings = self:sceneryNear(candidate, radius, COMPOUND_OBJECT_LIMIT)
            if #buildings > 0 and (not best or #buildings > #best.buildings) then
                best = { center = candidate, buildings = buildings }
            end
        end
    end
    return best
end

local function rotaryCandidate(config)
    local farp = config.farps[math.random(#config.farps)]
    local candidate = Spatial:randomPointInRadius(farp.position, config.rotaryTaskingRadius)
    if Sites:isSite(candidate) then
        return candidate
    end
    return nil
end

-- Pick the friendly element's position for a new tasking.
-- flightCategory: "fixed" or "rotary"
-- Returns a map point { x, y }, or nil when no valid site was found.
function Sites:pickTaskingCenter(flightCategory)
    local config = OperationOverwatch.config
    if not config.areaOfOperations then
        log("No area of operations configured")
        return nil
    end
    if not config.siteGrid then
        log("No site grid configured")
        return nil
    end
    local isRotary = flightCategory == "rotary"
    if isRotary and #config.farps == 0 then
        log("No FARPs configured")
        return nil
    end

    local attempts = isRotary and ROTARY_ATTEMPTS or MAX_ATTEMPTS
    for attempt = 1, attempts do
        local candidate
        if isRotary then
            candidate = rotaryCandidate(config)
        else
            candidate = self:randomSite()
        end

        if candidate then
            local candidateIsInArea = self:isInAreaOfOperations(candidate)
            local candidateIsOnValidGround = self:isValidPoint(candidate)
            if candidateIsInArea and candidateIsOnValidGround then
                log(
                    string.format(
                        "%s site after %d attempts: x=%.0f y=%.0f",
                        flightCategory,
                        attempt,
                        candidate.x,
                        candidate.y
                    )
                )
                return candidate
            end
        end
    end
    log("No valid " .. flightCategory .. " site after " .. attempts .. " attempts")
    return nil
end

-- A valid point at a random bearing and a distance in [minDistance, maxDistance]
-- from origin, or nil
function Sites:pickPointNear(origin, minDistance, maxDistance)
    for _ = 1, MAX_ATTEMPTS do
        local bearing = math.random() * 2 * math.pi
        local distance = minDistance + math.random() * (maxDistance - minDistance)
        local candidate = self:offset(origin, bearing, distance)
        if self:isValidPoint(candidate) then
            return candidate
        end
    end
    return nil
end

env.info("[Sites] Loaded successfully")

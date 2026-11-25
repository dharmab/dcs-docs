-- =============================================================================
-- SITES
-- Chooses tasking locations at runtime.
-- Fixed-wing taskings go anywhere in the area of operations. Rotary-wing
-- taskings go within a radius of a FARP.
--
-- The area of operations, FARP positions, and terrain rules wait for the
-- Afghanistan terrain export. Until then isValidPoint only checks the surface
-- type.
-- =============================================================================

if _G.SitesLoaded then
    env.info("[Sites] Script already loaded, skipping")
    return
end
_G.SitesLoaded = true

Sites = {}

local log = Logging:create("Sites")

local MAX_ATTEMPTS = 200
local FULL_CIRCLE_DEGREES = 360

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

function Sites:boundingBox(polygon)
    local box = { minX = math.huge, maxX = -math.huge, minY = math.huge, maxY = -math.huge }
    for _, p in ipairs(polygon) do
        box.minX = math.min(box.minX, p.x)
        box.maxX = math.max(box.maxX, p.x)
        box.minY = math.min(box.minY, p.y)
        box.maxY = math.max(box.maxY, p.y)
    end
    return box
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

-- TODO(terrain): add land cover, slope, and distance from towns and roads
-- once docs/data/terrains/Afghanistan/ exists.
function Sites:isValidPoint(point)
    local surface = land.getSurfaceType({ x = point.x, y = point.y })
    return surface == land.SurfaceType.LAND
end

function Sites:isInAreaOfOperations(point)
    local polygon = OperationOverwatch.config.areaOfOperations
    return polygon ~= nil and self:pointInPolygon(point, polygon)
end

local function randomPointInAreaOfOperations(polygon)
    local box = Sites:boundingBox(polygon)
    for _ = 1, MAX_ATTEMPTS do
        local candidate = {
            x = box.minX + math.random() * (box.maxX - box.minX),
            y = box.minY + math.random() * (box.maxY - box.minY),
        }
        if Sites:pointInPolygon(candidate, polygon) then
            return candidate
        end
    end
    return nil
end

-- Pick the friendly element's position for a new tasking.
-- flightCategory: "fixed" or "rotary"
-- Returns a map point { x, y }, or nil when no valid site was found.
function Sites:pickTaskingCenter(flightCategory)
    local config = OperationOverwatch.config
    local polygon = config.areaOfOperations
    if not polygon then
        log("No area of operations configured")
        return nil
    end

    for attempt = 1, MAX_ATTEMPTS do
        local candidate
        if flightCategory == "rotary" then
            if #config.farps == 0 then
                log("No FARPs configured")
                return nil
            end
            local farp = config.farps[math.random(#config.farps)]
            candidate = Spatial:randomPointInRadius(farp.position, config.rotaryTaskingRadius)
        else
            candidate = randomPointInAreaOfOperations(polygon)
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
    log("No valid " .. flightCategory .. " site after " .. MAX_ATTEMPTS .. " attempts")
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

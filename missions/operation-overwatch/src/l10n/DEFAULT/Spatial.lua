-- =============================================================================
-- SPATIAL UTILITIES
-- 2D geometry functions for distance calculations and random positioning
-- =============================================================================

-- Guard against multiple script loads
if _G.SpatialLoaded then
    env.info("[Spatial] Script already loaded, skipping")
    return
end
_G.SpatialLoaded = true

Spatial = {}

-- Calculate 2D Euclidean distance between two points
-- pos1, pos2: tables with x and y fields
function Spatial:getDistance2D(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    return math.sqrt(dx * dx + dy * dy)
end

-- Generate a random point within a given radius of a center point
-- Returns a table with x and y fields
function Spatial:randomPointInRadius(center, radius)
    local angle = math.random() * 2 * math.pi
    local distance = math.sqrt(math.random()) * radius
    return {
        x = center.x + distance * math.cos(angle),
        y = center.y + distance * math.sin(angle),
    }
end

env.info("[Spatial] Loaded successfully")

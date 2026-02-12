-- =============================================================================
-- FORMATIONS
-- Formation generators and unit positioning logic
-- =============================================================================

-- Guard against multiple script loads
if _G.FormationsLoaded then
    env.info("[Formations] Script already loaded, skipping")
    return
end
_G.FormationsLoaded = true

Formations = {}

-- Formation types
Formations.FormationType = {
    LINE = "LINE",
    WEDGE = "WEDGE",
    ECHELON_LEFT = "ECHELON_LEFT",
    ECHELON_RIGHT = "ECHELON_RIGHT",
}

-- Unit randomization settings (can be overridden)
Formations.config = {
    countVariance = 0.3,        -- +/-30% unit count variation
    missingUnitChance = 0.1,    -- 10% chance each unit is "missing"
    substitutionChance = 0.3,   -- 30% chance for unit type substitution
}

local log = Logging:create("Formations")

-- Get relative positions for a formation
function Formations:getFormationPositions(unitCount, formationType, spacing, widthMultiplier)
    spacing = spacing or 30
    widthMultiplier = widthMultiplier or 1.0
    local positions = {}

    if formationType == self.FormationType.LINE then
        -- Units spread perpendicular to facing direction
        local startOffset = -((unitCount - 1) * spacing) / 2
        for i = 1, unitCount do
            positions[#positions + 1] = {
                x = startOffset + (i - 1) * spacing,
                y = 0,
            }
        end

    elseif formationType == self.FormationType.WEDGE then
        -- Arrow/vee shape with lead unit at front
        positions[#positions + 1] = {x = 0, y = 0} -- Lead unit
        for i = 2, unitCount do
            local row = math.ceil((i - 1) / 2)
            local side = ((i - 1) % 2 == 0) and 1 or -1
            positions[#positions + 1] = {
                x = side * row * spacing * widthMultiplier,
                y = -row * spacing,
            }
        end

    elseif formationType == self.FormationType.ECHELON_LEFT then
        for i = 1, unitCount do
            positions[#positions + 1] = {
                x = -(i - 1) * spacing * widthMultiplier,
                y = -(i - 1) * spacing * 0.7,
            }
        end

    elseif formationType == self.FormationType.ECHELON_RIGHT then
        for i = 1, unitCount do
            positions[#positions + 1] = {
                x = (i - 1) * spacing * widthMultiplier,
                y = -(i - 1) * spacing * 0.7,
            }
        end

    else
        -- Default to line if unknown
        return self:getFormationPositions(unitCount, self.FormationType.LINE, spacing, widthMultiplier)
    end

    return positions
end

-- Rotate a relative position by heading
function Formations:rotatePosition(relPos, heading)
    local cos_h = math.cos(heading)
    local sin_h = math.sin(heading)
    return {
        x = relPos.x * cos_h - relPos.y * sin_h,
        y = relPos.x * sin_h + relPos.y * cos_h,
    }
end

-- Get a random formation type
function Formations:getRandomFormationType()
    local types = {
        self.FormationType.LINE,
        self.FormationType.WEDGE,
        self.FormationType.ECHELON_LEFT,
        self.FormationType.ECHELON_RIGHT,
    }
    return types[math.random(#types)]
end

-- Get formation type based on position within sector
-- Center positions use LINE or WEDGE, side positions use WEDGE or ECHELON
function Formations:getFormationTypeByPosition(numPairs, pairIndex)
    local isCenter = false

    if numPairs == 1 then
        -- Single pair is always center
        isCenter = true
    elseif numPairs == 2 then
        -- First pair is center, second is side
        isCenter = (pairIndex == 1)
    else
        -- For 3+ pairs, middle index is center
        local middleIndex = math.ceil(numPairs / 2)
        isCenter = (pairIndex == middleIndex)
    end

    if isCenter then
        -- Center formations: LINE (horizontal) or WEDGE (vee)
        local centerTypes = {
            self.FormationType.LINE,
            self.FormationType.WEDGE,
        }
        return centerTypes[math.random(#centerTypes)]
    else
        -- Side formations: WEDGE (vee) or ECHELON
        local sideTypes = {
            self.FormationType.WEDGE,
            self.FormationType.ECHELON_LEFT,
            self.FormationType.ECHELON_RIGHT,
        }
        return sideTypes[math.random(#sideTypes)]
    end
end

-- Randomize a template by varying counts and potentially removing units
-- Options:
--   skipSubstitutions: boolean - if true, do not substitute unit types (keeps homogenous compositions)
--   config: table - optional config override (countVariance, missingUnitChance, substitutionChance)
function Formations:randomizeTemplate(template, options)
    options = options or {}
    local cfg = options.config or self.config
    local variance = cfg.countVariance
    local missingChance = cfg.missingUnitChance
    local result = {}

    for _, def in ipairs(template) do
        -- Chance each unit definition is "missing" (casualties/detachments)
        if math.random() > missingChance then
            -- Vary count within +/-variance of base
            local baseCount = def.count
            local minCount = math.max(1, math.floor(baseCount * (1 - variance)))
            local maxCount = math.ceil(baseCount * (1 + variance))
            local newCount = math.random(minCount, maxCount)

            -- Apply unit type substitution (unless skipped for homogenous units like artillery)
            local unitType = def.type
            if not options.skipSubstitutions and UnitTemplates then
                unitType = UnitTemplates:getSubstitute(def.type, cfg.substitutionChance)
            end

            result[#result + 1] = {
                type = unitType,
                count = newCount,
            }
        end
    end

    -- Ensure at least one unit remains
    if #result == 0 and #template > 0 then
        local def = template[1]
        result[#result + 1] = {
            type = def.type,
            count = 1,
        }
    end

    return result
end

-- Build platoon units from a template with formation and positioning
-- Options:
--   formation: FormationType to use
--   facing: heading in radians
--   spacing: meters between units (default 30)
--   widthMultiplier: multiplier for formation width (default 1.0)
--   jitterMin: minimum random jitter in meters (default 10)
--   jitterMax: maximum random jitter in meters (default 15)
function Formations:buildPlatoonUnits(template, center, options)
    options = options or {}
    local formation = options.formation or self:getRandomFormationType()
    local facing = options.facing or (math.random() * 2 * math.pi)
    local spacing = options.spacing or 30
    local widthMultiplier = options.widthMultiplier or 1.0
    local jitterMin = options.jitterMin or 10
    local jitterMax = options.jitterMax or 15

    -- Count total units
    local totalUnits = 0
    for _, def in ipairs(template) do
        totalUnits = totalUnits + def.count
    end

    -- Get formation positions
    local formationPositions = self:getFormationPositions(totalUnits, formation, spacing, widthMultiplier)

    local units = {}
    local unitIndex = 1

    for _, def in ipairs(template) do
        for c = 1, def.count do
            local formPos = formationPositions[unitIndex] or {x = 0, y = 0}

            -- Rotate position to face the correct direction
            local rotatedPos = self:rotatePosition(formPos, facing)

            -- Add random jitter (10-15m, visible from aircraft altitude)
            local jitterAmount = jitterMin + math.random() * (jitterMax - jitterMin)
            local jitterAngle = math.random() * 2 * math.pi
            local jitterX = jitterAmount * math.cos(jitterAngle)
            local jitterY = jitterAmount * math.sin(jitterAngle)

            -- Add heading variance (+/-10 degrees from facing)
            local headingVariance = (math.random() - 0.5) * math.rad(20)
            local unitHeading = facing + headingVariance

            units[#units + 1] = {
                type = def.type,
                x = center.x + rotatedPos.x + jitterX,
                y = center.y + rotatedPos.y + jitterY,
                heading = unitHeading,
                -- Ground AI below "High" is ineffective; lower skills miss
                -- consistently and fail to engage targets at realistic ranges
                skill = "High",
            }
            unitIndex = unitIndex + 1
        end
    end

    return units
end

env.info("[Formations] Loaded successfully")

-- =============================================================================
-- ENEMY FORCE
-- Rolls a tasking's insurgent force from weighted pools. Placement is done
-- by Firefight.
-- =============================================================================

if _G.EnemyForceLoaded then
    env.info("[EnemyForce] Script already loaded, skipping")
    return
end
_G.EnemyForceLoaded = true

EnemyForce = {}

local log = Logging:create("EnemyForce")

-- Ground AI below "High" is ineffective (Operation Infinity, Formations.lua)
EnemyForce.skills = { "High", "Excellent" }

-- Element roles. Placement and grouping are by role.
EnemyForce.Role = {
    RIFLEMAN = "rifleman",
    RPG = "rpg",
    TECHNICAL = "technical",
    LIGHT_VEHICLE = "lightVehicle",
    ZU23 = "zu23",
    MANPADS = "manpads",
}

-- chance[flightCategory]: probability the element is present (1 = always)
-- key: the JTAC names these in the brief; destroying all of them succeeds
EnemyForce.pool = {
    {
        role = EnemyForce.Role.RIFLEMAN,
        types = { "Infantry AK Ins" },
        chance = { fixed = 1, rotary = 1 },
        count = { min = 6, max = 12 },
        key = false,
    },
    {
        role = EnemyForce.Role.RPG,
        types = { "Soldier RPG" },
        chance = { fixed = 1, rotary = 1 },
        count = { min = 1, max = 3 },
        key = false,
    },
    {
        role = EnemyForce.Role.TECHNICAL,
        types = { "HL_DSHK", "HL_KORD", "tt_DSHK", "tt_KORD" },
        chance = { fixed = 0.7, rotary = 0.7 },
        count = { min = 1, max = 3 },
        key = true,
    },
    {
        role = EnemyForce.Role.LIGHT_VEHICLE,
        types = { "UAZ-469", "VAZ Car" },
        chance = { fixed = 0.5, rotary = 0.5 },
        count = { min = 1, max = 2 },
        key = false,
    },
    {
        role = EnemyForce.Role.ZU23,
        types = { "HL_ZU-23", "tt_ZU-23", "ZU-23 Insurgent" },
        chance = { fixed = 0.25, rotary = 0.15 },
        count = { min = 1, max = 1 },
        key = true,
    },
    {
        -- Not key: the JTAC never names it. It becomes key after it launches.
        role = EnemyForce.Role.MANPADS,
        types = { "Igla manpad INS" },
        chance = { fixed = 0.15, rotary = 0.1 },
        count = { min = 1, max = 1 },
        key = false,
    },
}

local function pick(list)
    return list[math.random(#list)]
end

-- Roll an enemy force.
-- flightCategory: "fixed" or "rotary"
-- Returns { units = { { role, type, skill, key }, ... }, hasManpads = bool }
function EnemyForce:roll(flightCategory)
    local units = {}
    local hasManpads = false
    for _, element in ipairs(self.pool) do
        local chance = element.chance[flightCategory]
        local elementIsPresent = math.random() < chance
        if elementIsPresent then
            local count = math.random(element.count.min, element.count.max)
            for _ = 1, count do
                units[#units + 1] = {
                    role = element.role,
                    type = pick(element.types),
                    skill = pick(self.skills),
                    key = element.key,
                }
            end
            if element.role == self.Role.MANPADS then
                hasManpads = true
            end
        end
    end
    log("Rolled " .. #units .. " units for a " .. flightCategory .. " tasking, MANPADS " .. tostring(hasManpads))
    return { units = units, hasManpads = hasManpads }
end

-- Count units of a role in a rolled force
function EnemyForce:countRole(force, role)
    local count = 0
    for _, unit in ipairs(force.units) do
        if unit.role == role then
            count = count + 1
        end
    end
    return count
end

env.info("[EnemyForce] Loaded successfully")

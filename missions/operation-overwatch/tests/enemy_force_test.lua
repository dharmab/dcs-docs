local h = require("harness")

local ROLLS = 500

local function rollMany(category)
    local forces = {}
    for i = 1, ROLLS do
        h.load({ seed = i })
        forces[i] = EnemyForce:roll(category)
    end
    return forces
end

h.test("every force has 6-12 riflemen and 1-3 RPG gunners", function()
    for _, force in ipairs(rollMany("fixed")) do
        local riflemen = EnemyForce:countRole(force, EnemyForce.Role.RIFLEMAN)
        local rpgs = EnemyForce:countRole(force, EnemyForce.Role.RPG)
        h.ok(riflemen >= 6 and riflemen <= 12, "riflemen " .. riflemen)
        h.ok(rpgs >= 1 and rpgs <= 3, "RPGs " .. rpgs)
    end
end)

h.test("technicals and ZU-23s are key units, MANPADS is not", function()
    for _, force in ipairs(rollMany("fixed")) do
        for _, unit in ipairs(force.units) do
            local Role = EnemyForce.Role
            local shouldBeKey = unit.role == Role.TECHNICAL or unit.role == Role.ZU23
            h.eq(unit.key, shouldBeKey, unit.role)
        end
    end
end)

h.test("skills are High or Excellent", function()
    for _, force in ipairs(rollMany("rotary")) do
        for _, unit in ipairs(force.units) do
            local isUpperTier = unit.skill == "High" or unit.skill == "Excellent"
            h.ok(isUpperTier, unit.skill)
        end
    end
end)

h.test("rotary flights see fewer ZU-23s than fixed-wing flights", function()
    local function zuRate(category)
        local count = 0
        for _, force in ipairs(rollMany(category)) do
            if EnemyForce:countRole(force, EnemyForce.Role.ZU23) > 0 then
                count = count + 1
            end
        end
        return count / ROLLS
    end
    local fixed = zuRate("fixed")
    local rotary = zuRate("rotary")
    h.ok(fixed > rotary, string.format("fixed %.2f, rotary %.2f", fixed, rotary))
end)

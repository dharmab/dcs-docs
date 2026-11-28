-- The mission file agrees with OperationOverwatch.config.
local h = require("harness")

local function loadMission()
    local chunk = assert(loadfile(h.missionDir .. "/mission"))
    local sandbox = {}
    setfenv(chunk, sandbox)
    chunk()
    return sandbox.mission
end

local function blueCountry(mission)
    return mission.coalition.blue.country[1]
end

local function farpStatics(mission)
    local farps = {}
    for _, group in ipairs(blueCountry(mission).static.group) do
        for _, unit in ipairs(group.units) do
            if unit.category == "Heliports" then
                farps[unit.name] = unit
            end
        end
    end
    return farps
end

local function loadWarehouses()
    local chunk = assert(loadfile(h.missionDir .. "/warehouses"))
    local sandbox = {}
    setfenv(chunk, sandbox)
    chunk()
    return sandbox.warehouses
end

-- Template key for a base: "farp:<unitId>" for a FARP static, "airdrome:<id>"
-- for a map airbase
local function baseKey(farp, farps)
    if farp.airdromeId then
        return "airdrome:" .. farp.airdromeId
    end
    return "farp:" .. farps[farp.name].unitId
end

h.test("FARP statics match the configured FARPs", function()
    h.load({ realTerrain = true })
    local farps = farpStatics(loadMission())
    for _, farp in ipairs(OperationOverwatch.config.farps) do
        if not farp.airdromeId then
            local static = farps[farp.name]
            h.ok(static, "no FARP static named " .. farp.name)
            h.eq(static.x, farp.position.x, farp.name .. " x")
            h.eq(static.y, farp.position.y, farp.name .. " y")
        end
    end
end)

h.test("configured airbases have a blue dynamic spawn warehouse", function()
    h.load({ realTerrain = true })
    local airports = loadWarehouses().airports
    for _, farp in ipairs(OperationOverwatch.config.farps) do
        if farp.airdromeId then
            local warehouse = airports[farp.airdromeId]
            h.ok(warehouse, "no warehouse for " .. farp.name)
            h.eq(warehouse.coalition, "BLUE", farp.name .. " coalition")
            h.eq(warehouse.dynamicSpawn, true, farp.name .. " dynamic spawn")
        end
    end
end)

h.test("every rotary CAS type has a template at every FARP", function()
    h.load({ realTerrain = true })
    local mission = loadMission()
    local farps = farpStatics(mission)
    local templates = {}
    for _, group in ipairs(blueCountry(mission).helicopter.group) do
        local point = group.route.points[1]
        if group.dynSpawnTemplate then
            local key = point.linkUnit and ("farp:" .. point.linkUnit)
                or point.airdromeId and ("airdrome:" .. point.airdromeId)
            if key then
                templates[key .. "/" .. group.units[1].type] = true
            end
        end
    end
    for _, farp in ipairs(OperationOverwatch.config.farps) do
        for typeName in pairs(OperationOverwatch.config.rotaryCasTypes) do
            local key = baseKey(farp, farps) .. "/" .. typeName
            h.ok(templates[key], "no " .. typeName .. " template at " .. farp.name)
        end
    end
end)

h.test("every fixed-wing template presets every JTAC frequency", function()
    h.load({ realTerrain = true })
    local mission = loadMission()
    for _, group in ipairs(blueCountry(mission).plane.group) do
        local unit = group.units[1]
        if group.dynSpawnTemplate then
            h.ok(unit.Radio, group.name .. " has no radio presets")
            local preset = {}
            for _, r in ipairs(unit.Radio) do
                for _, channel in ipairs(r.channels) do
                    preset[channel] = true
                end
            end
            for _, slot in ipairs(OperationOverwatch.config.jtacSlots) do
                h.ok(preset[slot.frequency], group.name .. " lacks " .. slot.callsign .. " " .. slot.frequency)
            end
        end
    end
end)

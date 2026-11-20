-- The comms card exists in three places (displayCommsPlan, the blue-task
-- briefing, README.md) and must agree with the radios set in the mission
local h = require("harness")

local TANKERS = { "Texaco", "Arco", "Shell", "Arco 2" }

local function inGameCard(env)
    OperationInfinity:displayCommsPlan(1)
    return env.messages[#env.messages]
end

local function briefingCard()
    local chunk = assert(loadfile(h.scriptsDir .. "/dictionary"))
    local sandbox = {}
    setfenv(chunk, sandbox)
    chunk()
    return sandbox.dictionary.DictKey_descriptionBlueTask_1
end

-- Lines from the one matching startPattern up to the next matching
-- endPattern. Free-text notes are skipped; their wording differs between cards.
local function lines(text, startPattern, endPattern)
    local result, inside = {}, false
    for line in (text .. "\n"):gmatch("(.-)\n") do
        if line:find(startPattern) then
            inside = true
        elseif inside and line:find(endPattern) then
            break
        end
        if inside and not line:find("^Note:") and not line:find("^F%-4E has") then
            result[#result + 1] = line
        end
    end
    return result
end

local function missionGroup(env, name)
    local g = env.groupsByName[name]
    h.ok(g, "no mission group " .. name)
    return g.data
end

-- "Texaco11" -> "Texaco 1-1"
local function callsign(groupData)
    local name, flight, element = groupData.units[1].callsign.name:match("^(%a+)(%d)(%d)$")
    return name .. " " .. flight .. "-" .. element
end

local function tacan(groupData)
    for _, task in ipairs(groupData.route.points[1].task.params.tasks) do
        local action = task.params and task.params.action
        if action and action.id == "ActivateBeacon" then
            return action.params.channel .. action.params.modeChannel
        end
    end
    return nil
end

local function findLine(card, prefix)
    for _, line in ipairs(card) do
        if line:sub(1, #prefix) == prefix then
            return line
        end
    end
    return nil
end

h.test("primary presets are identical in game and in the briefing", function()
    local env = h.load()
    local game = lines(inGameCard(env), "^PRIMARY PRESETS", "^%s*$")
    local briefing = lines(briefingCard(), "^PRIMARY PRESETS", "^%s*$")
    h.ok(#game > 10, "preset table not found in game card")
    h.eq(table.concat(briefing, "\n"), table.concat(game, "\n"))
end)

h.test("tanker rows match in game and in the briefing", function()
    local env = h.load()
    local game = lines(inGameCard(env), "^TANKERS", "^%s*$")
    local briefing = lines(briefingCard(), "^TANKERS", "^%s*$")
    table.sort(game)
    table.sort(briefing)
    h.eq(table.concat(briefing, "\n"), table.concat(game, "\n"))
end)

h.test("tanker frequencies and TACANs match the mission groups", function()
    local env = h.load()
    for _, card in ipairs({ inGameCard(env), briefingCard() }) do
        local cardLines = {}
        for line in card:gmatch("[^\n]+") do
            cardLines[#cardLines + 1] = line
        end
        for _, name in ipairs(TANKERS) do
            local g = missionGroup(env, name)
            local cs = callsign(g)
            local preset = findLine(cardLines, cs .. " ")
            h.ok(preset, cs .. " missing from presets")
            h.eq(tonumber(preset:match("^%a+ %d%-%d%s+([%d.]+)")), g.frequency, cs .. " frequency")
            local tankerRows = lines(card, "^TANKERS", "^%s*$")
            local row = findLine(tankerRows, cs .. " ")
            h.ok(row, cs .. " missing from tanker table")
            h.eq(row:match("(%S+)%s*$"), tacan(g), cs .. " TACAN")
        end
    end
end)

h.test("support aircraft config matches the mission groups", function()
    local env = h.load()
    for _, aircraft in ipairs(OperationInfinity.config.supportAircraft) do
        local g = missionGroup(env, aircraft.name)
        if aircraft.radio then
            h.eq(aircraft.radio, g.frequency, aircraft.name .. " radio")
        end
        if aircraft.tacan then
            h.eq(aircraft.tacan, tacan(g), aircraft.name .. " TACAN")
        end
    end
end)

h.test("README lists every tanker frequency and TACAN", function()
    local env = h.load()
    local readme = h.readFile(h.missionDir .. "/../README.md")
    for _, name in ipairs(TANKERS) do
        local g = missionGroup(env, name)
        h.ok(readme:find(string.format("%.1f", g.frequency), 1, true), name .. " frequency missing from README")
        h.ok(readme:find(tacan(g), 1, true), name .. " TACAN missing from README")
    end
end)

h.test("carrier systems appear in every comms card", function()
    local env = h.load()
    local sys = CarrierOps.config.systems
    local readme = h.readFile(h.missionDir .. "/../README.md")
    for source, text in pairs({ game = inGameCard(env), briefing = briefingCard(), readme = readme }) do
        h.ok(text:find(sys.tacanChannel .. sys.tacanMode, 1, true), source .. ": TACAN")
        h.ok(text:find("ICLS " .. sys.iclsChannel, 1, true), source .. ": ICLS")
        h.ok(text:find(string.format("%.1f", sys.link4Frequency), 1, true), source .. ": Link 4")
        h.ok(text:find(string.format("%.1f", sys.radioFrequency), 1, true), source .. ": radio")
    end
end)

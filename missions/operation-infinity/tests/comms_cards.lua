-- =============================================================================
-- COMMS CARDS
-- Renders one Markdown comms card per player template from the mission's
-- radio presets. Carrier-capable types get a shore and a carrier card.
-- Usage: luajit tests/comms_cards.lua (writes ../comms/*.md)
-- =============================================================================

local CommsCards = {}

local FM = 1
local FM_BAND_TOP_MHZ = 88
local STEP = 0.2
local GROUP_SIZE = 5
local FREQ_TOLERANCE = 0.001

-- Display name, file name, and radio names in mission index order.
-- firstChannel is the cockpit number of mission channel 1 (default 1).
CommsCards.aircraft = {
    ["F-4E-45MC"] = { name = "F-4E Phantom II", file = "f-4e", radios = { "ARC-164 UHF", "Aux receiver" } },
    ["F-16C_50"] = { name = "F-16C Viper", file = "f-16c", radios = { "COMM1 ARC-164 UHF", "COMM2 ARC-222 VHF/FM" } },
    ["F-15ESE"] = { name = "F-15E Strike Eagle", file = "f-15e", radios = { "Radio 1 UHF", "Radio 2 V/UHF" } },
    ["F-15C"] = { name = "F-15C Eagle", file = "f-15c", refuel = "boom" },
    ["MiG-29A"] = { name = "MiG-29A Fulcrum (FC)", file = "mig-29a" },
    ["MiG-29S"] = { name = "MiG-29S Fulcrum (FC)", file = "mig-29s" },
    ["MiG-29G"] = { name = "MiG-29G Fulcrum (FC)", file = "mig-29g" },
    ["MiG-29 Fulcrum"] = {
        name = "MiG-29A Fulcrum",
        file = "mig-29-fulcrum",
        radios = { "R-862 V/UHF" },
        firstChannel = 0,
    },
    ["FA-18C_hornet"] = { name = "F/A-18C Hornet", file = "fa-18c", radios = { "COMM1 ARC-210", "COMM2 ARC-210" } },
    ["A-10C_2"] = {
        name = "A-10C Warthog",
        file = "a-10c",
        radios = { "ARC-210 V/UHF", "ARC-164 UHF", "ARC-186 FM" },
    },
    ["M-2000C"] = { name = "Mirage 2000C", file = "m-2000c", radios = { "UHF", "V/UHF" } },
    ["Mirage-F1CE"] = { name = "Mirage F1", file = "mirage-f1", radios = { "TRAP-136 V/UHF", "TRAP-137B UHF" } },
    ["F-14A-135-GR"] = {
        name = "F-14A Tomcat",
        file = "f-14a",
        radios = { "ARC-159 UHF (pilot)", "ARC-182 V/UHF (RIO)" },
    },
    ["F-14B"] = { name = "F-14B Tomcat", file = "f-14b", radios = { "ARC-159 UHF (pilot)", "ARC-182 V/UHF (RIO)" } },
    ["F-14BU"] = {
        name = "F-14B(U) Tomcat",
        file = "f-14bu",
        radios = { "ARC-159 UHF (pilot)", "ARC-182 V/UHF (RIO)" },
    },
    ["JF-17"] = { name = "JF-17 Thunder", file = "jf-17", radios = { "COMM1 and COMM2" } },
    ["Su-25"] = { name = "Su-25 Frogfoot", file = "su-25" },
    ["Su-25T"] = { name = "Su-25T Frogfoot", file = "su-25t" },
}

-- Tanker groups in card order. FC3 aircraft have no presets, so their
-- tankers come from the aircraft's refuel field; others get the tankers on
-- their presets. The recovery tanker is listed only on carrier cards.
CommsCards.tankers = {
    { group = "Texaco", type = "KC-135", note = "Fast boom", refuel = "boom" },
    { group = "Shell", type = "KC-135", note = "Slow boom", refuel = "boom" },
    { group = "Arco", type = "KC-135MPRS", note = "Basket", refuel = "probe" },
    { group = "Arco 2", type = "S-3B", note = "Recovery", refuel = "probe", carrierOnly = true },
}

-- Named frequencies in the comm plan, in the order FC3 cards list them
local function planFrequencies()
    local plan = {
        { 255.1, "Strike" },
        { 255.3, "Magic" },
        { 124.1, "Magic VHF" },
        { 32.1, "Magic FM" },
        { 254.1, "Krymsk TWR" },
        { 254.3, "Krymsk GND" },
        { 254.5, "Krymsk RDR" },
        { 254.7, "Stennis" },
        { 270.5, "Texaco 1-1" },
        { 270.7, "Shell 1-1" },
        { 270.1, "Arco 1-1" },
        { 270.3, "Arco 2-1" },
    }
    local blocks = {
        { "Red", 260.1 },
        { "Blue", 261.1 },
        { "Green", 262.1 },
        { "Yellow", 30.1 },
        { "Orange", 31.1 },
    }
    for _, block in ipairs(blocks) do
        for i = 1, GROUP_SIZE do
            plan[#plan + 1] = { block[2] + (i - 1) * STEP, block[1] .. " " .. i }
        end
    end
    plan[#plan + 1] = { 243.0, "Guard" }
    plan[#plan + 1] = { 121.5, "Civil Guard" }
    return plan
end

local function nameOf(plan, freq)
    for _, entry in ipairs(plan) do
        if math.abs(entry[1] - freq) < FREQ_TOLERANCE then
            return entry[2]
        end
    end
    return nil
end

local function formatFreq(freq, modulation)
    return string.format("%.1f %s", freq, modulation == FM and "FM" or "AM")
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

local function playerTemplates(env)
    local templates = {}
    for name, g in pairs(env.groupsByName) do
        local base = name:find(" Stennis Template$") and "carrier" or (name:find(" Template$") and "shore")
        if base then
            templates[#templates + 1] = { data = g.data, base = base }
        end
    end
    return templates
end

local function hasCarrierVariant(templates, unitType)
    for _, t in ipairs(templates) do
        if t.base == "carrier" and t.data.units[1].type == unitType then
            return true
        end
    end
    return false
end

-- Markdown table padded the way the repo formatter pads it
local MIN_COLUMN_WIDTH = 3

local function addTable(out, header, rows)
    local widths = {}
    for i, cell in ipairs(header) do
        widths[i] = math.max(MIN_COLUMN_WIDTH, #cell)
        for _, row in ipairs(rows) do
            widths[i] = math.max(widths[i], #row[i])
        end
    end
    local function line(cells)
        local padded = {}
        for i, cell in ipairs(cells) do
            padded[i] = cell .. string.rep(" ", widths[i] - #cell)
        end
        return "| " .. table.concat(padded, " | ") .. " |"
    end
    local rule = {}
    for i, width in ipairs(widths) do
        rule[i] = string.rep("-", width)
    end
    out[#out + 1] = line(header)
    out[#out + 1] = line(rule)
    for _, row in ipairs(rows) do
        out[#out + 1] = line(row)
    end
end

local function radioTable(out, plan, radio, firstChannel)
    local rows = {}
    local skipped = false
    local count = 0
    for ch in pairs(radio.channels) do
        count = math.max(count, ch)
    end
    for ch = 1, count do
        local freq = radio.channels[ch]
        local name = freq and nameOf(plan, freq)
        if name then
            local modulation = radio.modulations and radio.modulations[ch]
            rows[#rows + 1] = { tostring(ch - 1 + firstChannel), formatFreq(freq, modulation), name }
        elseif freq then
            skipped = true
        end
    end
    addTable(out, { "Ch", "Freq", "Name" }, rows)
    return skipped
end

-- The main radio has Strike on channel 1
local STRIKE_MHZ = 255.1

local function mainRadio(unit)
    for _, radio in ipairs(unit.Radio or {}) do
        if radio.channels[1] and math.abs(radio.channels[1] - STRIKE_MHZ) < FREQ_TOLERANCE then
            return radio
        end
    end
    return nil
end

local function channelOf(radio, freq)
    for ch, value in pairs(radio.channels) do
        if math.abs(value - freq) < FREQ_TOLERANCE then
            return ch
        end
    end
    return nil
end

local function render(env, template, plan, title, carrierCapable)
    local unit = template.data.units[1]
    local info = CommsCards.aircraft[unit.type]
    local out = { "# " .. title, "" }
    local presetFreqs = {}
    local firstChannel = info.firstChannel or 1

    if not unit.Radio then
        out[#out + 1] = "No mission presets. Tune these in SRS."
        out[#out + 1] = ""
        local rows = {}
        for _, entry in ipairs(plan) do
            local modulation = entry[1] < FM_BAND_TOP_MHZ and FM or 0
            rows[#rows + 1] = { formatFreq(entry[1], modulation), entry[2] }
            presetFreqs[#presetFreqs + 1] = entry[1]
        end
        addTable(out, { "Freq", "Name" }, rows)
        out[#out + 1] = ""
    else
        local skipped = false
        for i, radio in ipairs(unit.Radio) do
            out[#out + 1] = "## " .. info.radios[i]
            out[#out + 1] = ""
            skipped = radioTable(out, plan, radio, firstChannel) or skipped
            out[#out + 1] = ""
            for _, freq in pairs(radio.channels) do
                presetFreqs[#presetFreqs + 1] = freq
            end
        end
        if skipped then
            out[#out + 1] = "Unlisted presets keep their DCS defaults."
            out[#out + 1] = ""
        end
    end

    local main = mainRadio(unit)
    local rows = {}
    for _, tanker in ipairs(CommsCards.tankers) do
        local g = env.groupsByName[tanker.group].data
        local listed = false
        if unit.Radio then
            for _, freq in ipairs(presetFreqs) do
                listed = listed or math.abs(freq - g.frequency) < FREQ_TOLERANCE
            end
        else
            listed = info.refuel == tanker.refuel
        end
        if tanker.carrierOnly and template.base ~= "carrier" then
            listed = false
        end
        if listed then
            local row = {
                nameOf(plan, g.frequency),
                tanker.type,
                tanker.note,
                formatFreq(g.frequency, g.modulation),
                tacan(g),
            }
            if main then
                local ch = assert(channelOf(main, g.frequency), "tanker not on main radio")
                row[#row + 1] = tostring(ch - 1 + firstChannel)
            end
            rows[#rows + 1] = row
        end
    end
    local header = { "Callsign", "Type", "Note", "Freq", "TACAN" }
    if main then
        header[#header + 1] = "Preset"
    end
    if #rows > 0 then
        out[#out + 1] = "## Tankers"
        out[#out + 1] = ""
        addTable(out, header, rows)
        out[#out + 1] = ""
    end
    if #rows > 0 and rows[#rows][1] == "Arco 2-1" then
        out[#out + 1] = "DCS shows Arco 1-1 and Arco 2-1 both as Arco 1 in the radio menu."
        out[#out + 1] = ""
    end

    -- Only types that can recover aboard need the carrier
    if carrierCapable then
        local sys = CarrierOps.config.systems
        out[#out + 1] = "## CVN-74 Stennis"
        out[#out + 1] = ""
        out[#out + 1] = string.format(
            "%s, TACAN %d%s %s, ICLS %d, Link 4 %.1f, ACLS",
            formatFreq(sys.radioFrequency, sys.radioModulation),
            sys.tacanChannel,
            sys.tacanMode,
            sys.tacanCallsign,
            sys.iclsChannel,
            sys.link4Frequency
        )
    elseif out[#out] == "" then
        out[#out] = nil
    end
    return table.concat(out, "\n") .. "\n"
end

-- Map of file name to Markdown for every player template
function CommsCards.render(env)
    local plan = planFrequencies()
    local templates = playerTemplates(env)
    local cards = {}
    for _, template in ipairs(templates) do
        local unitType = template.data.units[1].type
        local info = assert(CommsCards.aircraft[unitType], "no comms card info for " .. unitType)
        local file, title = info.file, info.name
        local carrierCapable = hasCarrierVariant(templates, unitType)
        if carrierCapable then
            file = file .. "-" .. template.base
            title = title .. (template.base == "carrier" and " (Carrier)" or " (Shore)")
        end
        cards[file .. ".md"] = render(env, template, plan, title, carrierCapable)
    end
    return cards
end

CommsCards.dir = (debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or ".") .. "/../comms"

if arg and arg[0] and arg[0]:match("comms_cards%.lua$") then
    package.path = arg[0]:match("^(.*)/[^/]*$") .. "/?.lua;" .. package.path
    local env = require("harness").load()
    os.execute("mkdir -p '" .. CommsCards.dir .. "'")
    for file, content in pairs(CommsCards.render(env)) do
        local handle = assert(io.open(CommsCards.dir .. "/" .. file, "w"))
        handle:write(content)
        handle:close()
        print(file)
    end
end

return CommsCards

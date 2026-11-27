-- Every place that lists the mission scripts agrees with Harness.scripts.
-- AGENTS.md lists the places to update when adding a script.
local h = require("harness")

local function loadLuaTable(path, name)
    local chunk = assert(loadfile(path))
    local sandbox = {}
    setfenv(chunk, sandbox)
    chunk()
    return assert(sandbox[name], "no " .. name .. " table in " .. path)
end

local function expectedResKeys()
    local keys = {}
    for i, name in ipairs(h.scripts) do
        keys[i] = "ResKey_" .. name
    end
    return keys
end

local function expectedFiles()
    local files = {}
    for i, name in ipairs(h.scripts) do
        files[i] = name .. ".lua"
    end
    return files
end

local function eqList(actual, expected, what)
    h.eq(table.concat(actual, ", "), table.concat(expected, ", "), what)
end

h.test("every Lua file in l10n/DEFAULT is a mission script", function()
    local onDisk = {}
    local listing = assert(io.popen('ls "' .. h.scriptsDir .. '"'))
    for file in listing:lines() do
        if file:match("%.lua$") then
            onDisk[#onDisk + 1] = file
        end
    end
    listing:close()
    table.sort(onDisk)
    local expected = expectedFiles()
    table.sort(expected)
    eqList(onDisk, expected, "l10n/DEFAULT")
end)

h.test("mapResource maps each script's resource key to its file", function()
    local mapResource = loadLuaTable(h.scriptsDir .. "/mapResource", "mapResource")
    local luaEntries = 0
    for _, file in pairs(mapResource) do
        if file:match("%.lua$") then
            luaEntries = luaEntries + 1
        end
    end
    h.eq(luaEntries, #h.scripts, "Lua entries in mapResource")
    for _, name in ipairs(h.scripts) do
        h.eq(mapResource["ResKey_" .. name], name .. ".lua", "mapResource ResKey_" .. name)
    end
end)

h.test("the load trigger runs the scripts in order", function()
    local mission = loadLuaTable(h.missionDir .. "/mission", "mission")
    local ruleKeys = {}
    for _, rule in ipairs(mission.trigrules) do
        for _, action in ipairs(rule.actions) do
            if action.predicate == "a_do_script_file" then
                ruleKeys[#ruleKeys + 1] = action.file
            end
        end
    end
    eqList(ruleKeys, expectedResKeys(), "trigrules")

    local actionKeys = {}
    for _, action in ipairs(mission.trig.actions) do
        for key in action:gmatch('a_do_script_file%(getValueResourceByKey%("([^"]+)"%)%)') do
            actionKeys[#actionKeys + 1] = key
        end
    end
    eqList(actionKeys, expectedResKeys(), "trig.actions")
end)

h.test("pack_mission.py packs and requires the scripts in order", function()
    local source = h.readFile(h.missionDir .. "/../pack_mission.py")
    local required, packed = {}, {}
    for line in source:gmatch("[^\n]+") do
        local requiredFile = line:match('^%s+src_dir / "l10n" / "DEFAULT" / "([%w_]+%.lua)",$')
        local packedFile = line:match('^%s+"([%w_]+%.lua)",$')
        if requiredFile then
            required[#required + 1] = requiredFile
        elseif packedFile then
            packed[#packed + 1] = packedFile
        end
    end
    eqList(required, expectedFiles(), "required_files")
    eqList(packed, expectedFiles(), "l10n_files")
end)

h.test("scripts load without errors or unmocked API calls", function()
    local env = h.load()
    for _, line in ipairs(env.log) do
        h.ok(not line:find("^ERROR"), line)
    end
    h.eq(next(env.unknown), nil, "unmocked API")
end)

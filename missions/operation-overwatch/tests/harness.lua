-- =============================================================================
-- TEST HARNESS
-- Loads the mission scripts into a fresh mock DCS environment, and provides
-- a minimal test runner. Adapted from Operation Infinity. There is no mission
-- file yet, so the mock starts with no groups.
-- =============================================================================

local Mock = require("dcs_mock")

local Harness = {}

local testsDir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
local missionDir = testsDir .. "/../src"
local scriptsDir = missionDir .. "/l10n/DEFAULT"

-- Load order
Harness.scripts = {
    "Logging",
    "Units",
    "Spatial",
    "EnemyForce",
    "Sites",
    "Firefight",
    "Tasking",
    "OperationOverwatch",
}

Harness.missionDir = missionDir
Harness.scriptsDir = scriptsDir

-- A placeholder area of operations and FARP for tests, until the terrain
-- export gives real ones
Harness.testArea = {
    { x = -50000, y = -50000 },
    { x = 50000, y = -50000 },
    { x = 50000, y = 50000 },
    { x = -50000, y = 50000 },
}
Harness.testFarps = {
    { name = "Test FARP", position = { x = 0, y = 0 } },
}

-- Globals that Scripts/MissionScripting.lua sets to nil before mission
-- scripts run (docs/scripting/simulator-scripting-engine.md)
Harness.sanitizedGlobals = { "io", "lfs", "os", "require", "loadlib", "package" }
local sanitized = {}
for _, name in ipairs(Harness.sanitizedGlobals) do
    sanitized[name] = true
end

-- Mission scripts get their own global table: a copy of _G, which by then
-- holds the mock, minus the sanitized globals. Test code keeps the full
-- standard library and reads the scripts' globals through _G's __index.
local function newScriptEnvironment()
    local scriptEnv = {}
    for k, v in pairs(_G) do
        if not sanitized[k] then
            scriptEnv[k] = v
        end
    end
    scriptEnv._G = scriptEnv
    setmetatable(_G, { __index = scriptEnv })
    return scriptEnv
end

local baselineGlobals = {}
for k in pairs(_G) do
    baselineGlobals[k] = true
end

-- Remove every global created since the harness loaded: mock namespaces,
-- script modules, and the scripts' "already loaded" guards.
local function resetGlobals()
    local extra = {}
    for k in pairs(_G) do
        if not baselineGlobals[k] then
            extra[#extra + 1] = k
        end
    end
    for _, k in ipairs(extra) do
        _G[k] = nil
    end
end

-- Load the scripts into a fresh environment and return the mock state.
-- options.seed: math.randomseed value (default 1)
-- options.surfaceAt: passed to the mock
-- options.noArea: leave the area of operations and FARPs unset
function Harness.load(options)
    options = options or {}
    resetGlobals()
    math.randomseed(options.seed or 1)
    local env = Mock.install(options)
    local scriptEnv = newScriptEnvironment()
    for _, name in ipairs(Harness.scripts) do
        local chunk = assert(loadfile(scriptsDir .. "/" .. name .. ".lua"))
        setfenv(chunk, scriptEnv)
        chunk()
    end
    if not options.noArea then
        OperationOverwatch.config.areaOfOperations = Harness.testArea
        OperationOverwatch.config.farps = Harness.testFarps
    end
    return env
end

-- Add an airborne player and fire its takeoff event. Returns the unit record.
function Harness.takeOff(env, name, playerOptions)
    local player = env.addPlayer(name, 0, 0, playerOptions)
    player.inAir = true
    env.fireEvent({ id = world.event.S_EVENT_TAKEOFF, initiator = player.object })
    return player
end

-- Run the named F10 command in a player group's menu
function Harness.runGroupMenu(env, groupName, commandName)
    local groupId = env.groupObject(groupName):getID()
    for _, m in ipairs(env.menus) do
        local matches = m.groupId == groupId and m.fn and m.name == commandName
        if matches then
            m.fn(m.arg)
            return
        end
    end
    error("no menu command " .. commandName .. " for " .. groupName)
end

-- F10 command names under a group's Join Tasking submenu
function Harness.joinEntries(env, groupName)
    local groupId = env.groupObject(groupName):getID()
    local names = {}
    for _, m in ipairs(env.menus) do
        local underJoin = m.parent ~= nil and m.parent.name == "Join Tasking"
        if m.groupId == groupId and m.fn and underJoin then
            names[#names + 1] = m.name
        end
    end
    return names
end

function Harness.readFile(path)
    local file = assert(io.open(path, "r"))
    local content = file:read("*a")
    file:close()
    return content
end

-- -----------------------------------------------------------------------------
-- Test runner
-- -----------------------------------------------------------------------------

local tests = {}
local currentFile

function Harness.test(name, fn)
    tests[#tests + 1] = { name = name, fn = fn, file = currentFile }
end

local function describe(value)
    if type(value) == "string" then
        return string.format("%q", value)
    end
    return tostring(value)
end

function Harness.eq(actual, expected, message)
    if actual ~= expected then
        error(
            (message and (message .. ": ") or "") .. "expected " .. describe(expected) .. ", got " .. describe(actual),
            2
        )
    end
end

function Harness.ok(value, message)
    if not value then
        error(message or "expected a truthy value", 2)
    end
end

-- Load test files, run every registered test, and exit non-zero on failure
function Harness.run(files)
    for _, file in ipairs(files) do
        currentFile = file:match("([^/]+)$")
        dofile(file)
    end

    local failed = 0
    for _, t in ipairs(tests) do
        local ok, err = xpcall(t.fn, debug.traceback)
        if ok then
            io.write("ok    ", t.file, ": ", t.name, "\n")
        else
            failed = failed + 1
            io.write("FAIL  ", t.file, ": ", t.name, "\n", err, "\n")
        end
    end

    io.write(string.format("\n%d passed, %d failed\n", #tests - failed, failed))
    resetGlobals()
    os.exit(failed == 0 and 0 or 1)
end

return Harness

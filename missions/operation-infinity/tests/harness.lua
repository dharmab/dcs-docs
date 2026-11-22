-- =============================================================================
-- TEST HARNESS
-- Loads the mission scripts into a fresh mock DCS environment, and provides
-- a minimal test runner.
-- =============================================================================

local Mock = require("dcs_mock")
local TerrainModel = require("terrain_model")

local Harness = {}

local testsDir = debug.getinfo(1, "S").source:match("^@(.*)/[^/]*$") or "."
local missionDir = testsDir .. "/../src"
local scriptsDir = missionDir .. "/l10n/DEFAULT"

-- Same order as the "Load Mission Scripts" trigger
Harness.scripts = {
    "Logging",
    "Units",
    "Spatial",
    "BatchScheduler",
    "TerrainData",
    "Terrain",
    "UnitTemplates",
    "Formations",
    "Virtualization",
    "IADS",
    "AirIntercept",
    "BattlefieldGeneration",
    "CarrierOps",
    "OperationInfinity",
}

Harness.missionDir = missionDir
Harness.scriptsDir = scriptsDir

-- Built on first use and shared by every test; it is read-only
local terrain

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

-- Load the mission into a fresh environment and return the mock state.
-- options.seed: math.randomseed value (default 1)
-- options.surfaceAt, options.wind: passed to the mock
-- options.quiet: keep env.info output out of the console (default true)
function Harness.load(options)
    options = options or {}
    resetGlobals()
    math.randomseed(options.seed or 1)
    terrain = terrain or TerrainModel.new(dofile(testsDir .. "/mock_terrain.lua"))
    options.terrain = terrain
    local env = Mock.install(options)
    env.mission = env.loadMission(missionDir .. "/mission")
    local scriptEnv = newScriptEnvironment()
    for _, name in ipairs(Harness.scripts) do
        local chunk = assert(loadfile(scriptsDir .. "/" .. name .. ".lua"))
        setfenv(chunk, scriptEnv)
        chunk()
    end
    return env
end

-- Choose difficulty and playtime, optionally forcing the region, and run
-- generation to completion
function Harness.generate(env, difficulty, playtime, regionKey)
    if regionKey then
        -- Airbase positions were resolved at init, so only region selection
        -- still reads the region list
        local regions = OperationInfinity.config.aerodromeRegions
        OperationInfinity.config.aerodromeRegions = { [regionKey] = regions[regionKey] }
    end
    OperationInfinity:selectDifficulty(difficulty)
    OperationInfinity:selectPlaytime(playtime)
    env.advance(600)
end

-- Every region and playtime combination offered by the mission
function Harness.regionPlaytimes()
    local combos = {}
    Harness.load()
    for key, region in pairs(OperationInfinity.config.aerodromeRegions) do
        for _, playtime in ipairs(region.playtimes) do
            combos[#combos + 1] = { region = key, playtime = playtime }
        end
    end
    table.sort(combos, function(a, b)
        return a.region .. a.playtime < b.region .. b.playtime
    end)
    return combos
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

function Harness.near(actual, expected, tolerance, message)
    if type(actual) ~= "number" or math.abs(actual - expected) > tolerance then
        error(
            (message and (message .. ": ") or "")
                .. "expected "
                .. describe(expected)
                .. " +/- "
                .. tolerance
                .. ", got "
                .. describe(actual),
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

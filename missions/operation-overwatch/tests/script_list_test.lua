-- Every Lua file in l10n/DEFAULT is loaded by the harness. When the mission
-- file exists, extend this to the load trigger and mapResource as in
-- Operation Infinity.
local h = require("harness")

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
    local expected = {}
    for i, name in ipairs(h.scripts) do
        expected[i] = name .. ".lua"
    end
    table.sort(expected)
    h.eq(table.concat(onDisk, ", "), table.concat(expected, ", "), "l10n/DEFAULT")
end)

h.test("scripts load without errors or unmocked API calls", function()
    local env = h.load()
    for _, line in ipairs(env.log) do
        h.ok(not line:find("^ERROR"), line)
    end
    h.eq(next(env.unknown), nil, "unmocked API")
end)

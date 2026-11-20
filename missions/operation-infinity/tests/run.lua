-- Run Operation Infinity script tests under LuaJIT (Lua 5.1, like DCS).
-- Usage: luajit tests/run.lua tests/*_test.lua

local testsDir = arg[0]:match("^(.*)/[^/]*$") or "."
package.path = testsDir .. "/?.lua;" .. package.path

require("harness").run(arg)

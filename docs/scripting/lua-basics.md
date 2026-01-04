# Lua Basics for DCS Scripting

This document covers just enough Lua to start writing DCS World scripts. Lua is a small language that you can learn as you go; most of its features are intuitive once you see them in action.

## Variables and Basic Types

Variables store values. Use `local` to declare a variable, which limits its visibility to the current scope. Variables without `local` become global and can accidentally interfere with other scripts.

```lua
local callsign = "Viper 1-1"        -- a string (text)
local altitude = 25000              -- a number
local isAlive = true                -- a boolean (true or false)
local target = nil                  -- nil means "no value" or "nothing"
```

Lua does not distinguish between integers and floating-point numbers; everything is just a number. Strings can use single or double quotes interchangeably.

## Tables

Tables are Lua's only data structure, but they are versatile enough to serve as arrays, dictionaries, objects, and more.

As an array (ordered list of values):

```lua
local waypoints = {"Alpha", "Bravo", "Charlie"}
local first = waypoints[1]   -- "Alpha" (Lua arrays start at index 1, not 0)
local count = #waypoints     -- 3 (the # operator gives the length)
```

As a dictionary (key-value pairs):

```lua
local aircraft = {
    callsign = "Cowboy 1",
    fuel = 0.75,
    altitude = 15000
}
local name = aircraft.callsign       -- "Cowboy 1"
```

Dot notation works when keys are simple identifiers. For keys with spaces, special characters, or keys stored in variables, use bracket notation with a quoted string:

```lua
local unit = {
    ["unit name"] = "SA-10",         -- key with a space
    ["type-id"] = 42,                -- key with a hyphen
}
local description = unit["unit name"]    -- bracket access required
```

You can also use brackets with a variable to access keys dynamically:

```lua
local key = "fuel"
local value = aircraft[key]   -- same as aircraft.fuel
```

You can add and modify entries at any time:

```lua
aircraft.speed = 450          -- adds a new key
aircraft.fuel = 0.50          -- updates existing value
```

## Control Structures

Conditional execution uses `if`, `then`, `else`, and `end`:

```lua
local fuel = unit:getFuel()

if fuel < 0.2 then
    trigger.action.outText("Bingo fuel!", 10)
elseif fuel < 0.5 then
    trigger.action.outText("Fuel state is low", 10)
else
    trigger.action.outText("Fuel state is good", 10)
end
```

The `elseif` and `else` branches are optional.

Lua's boolean logic uses `and`, `or`, and `not` (not `&&`, `||`, `!`):

```lua
if isAlive and altitude > 1000 then
    -- both conditions must be true
end

if isDamaged or fuel < 0.1 then
    -- either condition can be true
end

if not isDestroyed then
    -- true when isDestroyed is false
end
```

## Loops

A `for` loop can iterate over a range of numbers:

```lua
for i = 1, 10 do
    trigger.action.outText("Count: " .. i, 1)
end
```

The `pairs` function iterates over table keys and values:

```lua
local scores = {red = 5, blue = 3}
for side, points in pairs(scores) do
    trigger.action.outText(side .. " has " .. points .. " points", 5)
end
```

The `ipairs` function iterates over array elements in order:

```lua
local targets = {"SAM Site", "Radar", "Command Post"}
for index, name in ipairs(targets) do
    trigger.action.outText("Target " .. index .. ": " .. name, 5)
end
```

A `while` loop repeats as long as a condition remains true:

```lua
local attempts = 0
while attempts < 3 do
    attempts = attempts + 1
    -- do something
end
```

Use `break` to exit a loop early.

## Functions

Functions are defined with the `function` keyword and called by name with parentheses:

```lua
local function calculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

local distance = calculateDistance(0, 0, 100, 100)
```

Functions can return multiple values:

```lua
local function getPosition()
    return 100, 200, 5000   -- x, y, altitude
end

local x, y, alt = getPosition()
```

## String Concatenation

Join strings with the `..` operator:

```lua
local message = "Unit " .. unitName .. " destroyed at " .. time .. " seconds"
```

Convert numbers to strings automatically through concatenation, or explicitly with `tostring()`.

## Comments

Single-line comments start with two dashes:

```lua
-- This is a comment
local x = 10  -- comments can follow code
```

Multi-line comments use bracket notation:

```lua
--[[
    This is a multi-line comment.
    It can span several lines.
]]
```

## Nil and Truthiness

In Lua, `nil` represents the absence of a value. Variables that have not been assigned are `nil`. Functions that do not explicitly return a value return `nil`.

When evaluating conditions, `nil` and `false` are considered false; everything else (including zero and empty strings) is considered true:

```lua
local unit = Unit.getByName("Bandit 1")
if unit then
    -- unit exists (is not nil)
else
    -- unit is nil (not found or destroyed)
end
```

This pattern appears constantly in DCS scripting because functions like `getByName` return `nil` when objects do not exist.
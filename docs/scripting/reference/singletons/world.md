# world

The world singleton provides event handling and object searching capabilities. See the [Events](../events/events.md) documentation for event handling details.

Functions that accept search volumes with coordinate parameters (such as `searchObjects` and `removeJunk`) may fail or produce unexpected results if the coordinates fall outside the current map's boundaries. When calling these functions with dynamically calculated positions, consider using `pcall()` to handle potential errors gracefully.

## world.addEventHandler

```lua
nil world.addEventHandler(table handler)
```

The `world.addEventHandler` function registers an event handler to receive game events. The handler must be a table with an `onEvent` function.

**Parameters:**
- `handler` (table): A table containing an `onEvent(self, event)` function.

```lua
local deathLogger = {}

function deathLogger:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD then
        local unit = event.initiator
        if unit then
            env.info(unit:getName() .. " was destroyed")
        end
    end
end

world.addEventHandler(deathLogger)
```

## world.removeEventHandler

```lua
nil world.removeEventHandler(table handler)
```

The `world.removeEventHandler` function unregisters a previously registered event handler.

**Parameters:**
- `handler` (table): The same handler table that was passed to `world.addEventHandler`.

## world.getPlayer

```lua
Unit world.getPlayer()
```

The `world.getPlayer` function returns the player's unit in single-player missions. This function only works in single-player; in multiplayer, use `coalition.getPlayers()` instead.

**Returns:** The player's Unit object, or nil in multiplayer.

## world.getAirbases

```lua
table world.getAirbases(number coalitionId)
```

The `world.getAirbases` function returns all airbases belonging to a coalition. The returned list includes airports, FARPs, and carrier ships.

**Parameters:**
- `coalitionId` (number): Optional. If provided, the function returns only airbases for that coalition.

**Returns:** An array of Airbase objects.

```lua
local blueAirbases = world.getAirbases(coalition.side.BLUE)
for i, airbase in ipairs(blueAirbases) do
    env.info("Blue airbase: " .. airbase:getName())
end
```

## world.searchObjects

```lua
nil world.searchObjects(number objectCategory, table searchVolume, function handler)
```

The `world.searchObjects` function searches for objects within a 3D volume and calls a handler function for each object found.

**Parameters:**
- `objectCategory` (number): The category of objects to search for, from the `Object.Category` enum. Valid values are UNIT, WEAPON, STATIC, BASE, SCENERY, and CARGO.
- `searchVolume` (table): A table that defines the search area. The table must have an `id` field specifying the volume type and a `params` field containing the volume parameters.
- `handler` (function): A function called for each found object. Return true from the handler to continue searching, or false to stop.

The `world.VolumeType` enum defines the available volume types:

```lua
world.VolumeType = {
    SEGMENT = 0,
    BOX = 1,
    SPHERE = 2,
    PYRAMID = 3
}
```

```lua
local searchVolume = {
    id = world.VolumeType.SPHERE,
    params = {
        point = {x = 100000, y = 0, z = 200000},
        radius = 5000
    }
}

local foundUnits = {}
world.searchObjects(Object.Category.UNIT, searchVolume, function(foundObject)
    table.insert(foundUnits, foundObject)
    return true
end)
```

## world.removeJunk

```lua
number world.removeJunk(table searchVolume)
```

The `world.removeJunk` function removes debris and wreckage within a volume.

**Parameters:**
- `searchVolume` (table): The area to clear. This table uses the same format as the `searchVolume` parameter of `world.searchObjects`.

**Returns:** The number of objects removed.

```lua
local clearZone = {
    id = world.VolumeType.SPHERE,
    params = {
        point = airbase:getPoint(),
        radius = 2000
    }
}
local removed = world.removeJunk(clearZone)
env.info("Removed " .. removed .. " debris objects")
```

## world.getMarkPanels

```lua
table world.getMarkPanels()
```

The `world.getMarkPanels` function returns all map markers currently visible.

**Returns:** An array of marker tables. Each marker table contains the following fields: `idx` (the marker ID), `time` (the creation time), `initiator` (the Unit that created the marker), `coalition` (the coalition the marker is visible to, or -1 for all coalitions), `groupID` (the group the marker is visible to, or -1 for all groups), `text` (the marker text), and `pos` (the marker position as a Vec3).

## See Also

- [events](../events/events.md) - Event system and event types
- [object](../classes/object.md) - Object categories and base class
- [coalition](coalition.md) - Coalition-specific object queries
- [airbase](../classes/airbase.md) - Airbase objects

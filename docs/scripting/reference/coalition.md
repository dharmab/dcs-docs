# coalition

The coalition singleton provides functions to query and spawn groups and static objects.

## coalition.addGroup

```lua
Group coalition.addGroup(number countryId, number groupCategory, table groupData)
```

The `coalition.addGroup` function dynamically spawns a group into the mission. This function is one of the most powerful scripting functions, enabling dynamic spawning of any unit type.

You must add a delay before accessing the group's controller after spawning, because issuing tasks immediately can crash the game. If a group or unit name matches an existing object, the game destroys the existing object. You cannot spawn aircraft with skill "Client" but can use "Player" in single-player, which destroys the current player aircraft. Spawn FARPs with `groupCategory = -1`.

**Parameters:**
- `countryId` (number): The country ID from the `country.id` enum.
- `groupCategory` (number): The category from `Group.Category`. Valid values are AIRPLANE, HELICOPTER, GROUND, SHIP, and TRAIN.
- `groupData` (table): The complete group definition. See the structure below.

**Returns:** The spawned Group object.

The `groupData` table has the following structure:

```lua
groupData = {
    name = string,
    task = string,
    units = {
        [1] = {
            name = string,
            type = string,
            x = number,
            y = number,
            alt = number,
            alt_type = string,
            speed = number,
            payload = table,
            callsign = table
        },
    },
    groupId = number,
    start_time = number,
    lateActivation = boolean,
    hidden = boolean,
    hiddenOnMFD = boolean,
    route = table,
    uncontrolled = boolean,
}
```

The required fields are `name` (a unique group name), `task` (the main task such as "Ground Nothing", "CAP", or "CAS"), and `units` (an array of unit definitions). Each unit definition requires `name` (a unique unit name), `type` (the unit type such as "M1A2" or "F-16C_50"), `x` (the East-West position), and `y` (the North-South position using Vec2 convention). Aircraft also require `alt` (altitude in meters), `alt_type` ("BARO" or "RADIO"), `speed` (speed in m/s), `payload` (weapons and fuel), and `callsign` (a table with name_index, number, and flight_number).

The optional fields are `groupId` (a custom group ID that is auto-generated if omitted), `start_time` (spawn delay in seconds where 0 means immediate), `lateActivation` (whether to require a trigger to activate), `hidden` (whether to hide from the F10 map), `hiddenOnMFD` (whether to hide from aircraft MFDs), `route` (waypoints and tasks), and `uncontrolled` (for aircraft, whether to spawn inactive).

```lua
local groupData = {
    name = "Reinforcement Tank",
    task = "Ground Nothing",
    units = {
        [1] = {
            name = "Tank 1",
            type = "M1A2",
            x = -288585,
            y = 616314,
            heading = 0,
            skill = "Average",
        },
    },
}

local newGroup = coalition.addGroup(country.id.USA, Group.Category.GROUND, groupData)

timer.scheduleFunction(function()
    local controller = newGroup:getController()
end, nil, timer.getTime() + 1)
```

## coalition.addStaticObject

```lua
StaticObject coalition.addStaticObject(number countryId, table staticData)
```

The `coalition.addStaticObject` function spawns a static object into the mission.

**Parameters:**
- `countryId` (number): The country ID from the `country.id` enum.
- `staticData` (table): The static object definition.

**Returns:** The spawned StaticObject.

```lua
local staticData = {
    name = "Cargo Crate",
    type = "uh1h_cargo",
    x = -288000,
    y = 616000,
    heading = 0,
}

coalition.addStaticObject(country.id.USA, staticData)
```

## coalition.getGroups

```lua
table coalition.getGroups(number coalitionId, number groupCategory)
```

The `coalition.getGroups` function returns all groups belonging to a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `groupCategory` (number): Optional. If provided, the function filters the results by `Group.Category`.

**Returns:** An array of Group objects.

```lua
local redAircraft = coalition.getGroups(coalition.side.RED, Group.Category.AIRPLANE)
for _, group in ipairs(redAircraft) do
    env.info("Red aircraft group: " .. group:getName())
end
```

## coalition.getStaticObjects

```lua
table coalition.getStaticObjects(number coalitionId)
```

The `coalition.getStaticObjects` function returns all static objects belonging to a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** An array of StaticObject objects.

## coalition.getPlayers

```lua
table coalition.getPlayers(number coalitionId)
```

The `coalition.getPlayers` function returns all human player units in a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** An array of Unit objects containing only player-controlled units.

```lua
local bluePlayers = coalition.getPlayers(coalition.side.BLUE)
for _, player in ipairs(bluePlayers) do
    local name = player:getPlayerName()
    env.info("Blue player: " .. (name or "Unknown"))
end
```

## coalition.getAirbases

```lua
table coalition.getAirbases(number coalitionId)
```

The `coalition.getAirbases` function returns all airbases belonging to a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** An array of Airbase objects.

## coalition.getServiceProviders

```lua
table coalition.getServiceProviders(number coalitionId, number serviceType)
```

The `coalition.getServiceProviders` function returns groups providing a specific service.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `serviceType` (number): The service type from the `coalition.service` enum. Valid values are ATC (0), AWACS (1), TANKER (2), and FAC (3).

**Returns:** An array of Group objects providing the specified service.

```lua
local tankers = coalition.getServiceProviders(coalition.side.BLUE, coalition.service.TANKER)
```

## coalition.addRefPoint

```lua
nil coalition.addRefPoint(number coalitionId, table refPoint)
```

The `coalition.addRefPoint` function adds a reference point (such as a bullseye or custom waypoint) for a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.
- `refPoint` (table): The reference point definition. This table must contain a `callsign` field (a string) and a `point` field (a Vec3).

## coalition.getRefPoints

```lua
table coalition.getRefPoints(number coalitionId)
```

The `coalition.getRefPoints` function returns all reference points for a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** A table of reference points indexed by callsign.

## coalition.getMainRefPoint

```lua
Vec3 coalition.getMainRefPoint(number coalitionId)
```

The `coalition.getMainRefPoint` function returns the main bullseye position for a coalition.

**Parameters:**
- `coalitionId` (number): The coalition from `coalition.side`.

**Returns:** The bullseye position as a Vec3.

```lua
local bullseye = coalition.getMainRefPoint(coalition.side.BLUE)
env.info("Blue bullseye at: " .. bullseye.x .. ", " .. bullseye.z)
```

## coalition.getCountryCoalition

```lua
number coalition.getCountryCoalition(number countryId)
```

The `coalition.getCountryCoalition` function returns which coalition a country belongs to.

**Parameters:**
- `countryId` (number): The country ID from the `country.id` enum.

**Returns:** The coalition from `coalition.side`.

## See Also

- [Data Types](data-types.md) - Coalition and country identifiers
- [group](group.md) - Group objects and categories
- [static-object](static-object.md) - Static object class
- [airbase](airbase.md) - Airbase objects
- [unit](unit.md) - Unit objects

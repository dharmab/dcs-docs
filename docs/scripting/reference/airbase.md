# Airbase

The Airbase class represents airports, FARPs (Forward Arming and Refueling Points), and ships with flight decks.

Inherits from: [Object](object.md), [CoalitionObject](coalition-object.md)

You can obtain Airbase objects using `Airbase.getByName("name")` to get an airbase by name, `coalition.getAirbases(coalitionId)` to get all airbases for a coalition, or `world.getAirbases()` to get all airbases in the mission.

The `Airbase.Category` enum defines the airbase categories:

```lua
Airbase.Category = {
    AIRDROME = 0,
    HELIPAD = 1,
    SHIP = 2
}
```

The `airbase:getCategory()` method returns `Object.Category.BASE`. Use `airbase:getDesc().category` to get a value from `Airbase.Category`.

## Airbase.getByName

```lua
Airbase Airbase.getByName(string name)
```

The `Airbase.getByName` function is a static function that returns an airbase by name.

**Parameters:**
- `name` (string): The airbase name, such as "Batumi" or "CVN-74 John C. Stennis".

**Returns:** An Airbase object, or nil if the airbase is not found.

```lua
local batumi = Airbase.getByName("Batumi")
local pos = batumi:getPoint()
```

## airbase:getCallsign

```lua
string airbase:getCallsign()
```

The `airbase:getCallsign` method returns the airbase's radio callsign.

**Returns:** The callsign as a string.

## airbase:getUnit

```lua
Unit airbase:getUnit(number index)
```

The `airbase:getUnit` method returns the ship unit for ship-based airbases.

**Parameters:**
- `index` (number): The unit index, typically 1.

**Returns:** A Unit object for ships, or nil for ground airbases.

## airbase:getParking

```lua
table airbase:getParking(boolean available)
```

The `airbase:getParking` method returns parking spot information.

**Parameters:**
- `available` (boolean): Optional. If true, the method returns only unoccupied spots.

**Returns:** An array of parking spot tables. Each table contains fields such as `Term_Index`, `vTerminalPos`, `fDistToRW`, and `Term_Type`.

```lua
local spots = airbase:getParking(true)
for _, spot in ipairs(spots) do
    env.info("Available spot: " .. spot.Term_Index)
end
```

## airbase:getRunways

```lua
table airbase:getRunways()
```

The `airbase:getRunways` method returns runway information.

**Returns:** An array of runway tables containing heading, length, and position data.

## airbase:getRadioSilentMode

```lua
boolean airbase:getRadioSilentMode()
```

The `airbase:getRadioSilentMode` method returns whether the airbase's radio is silenced.

**Returns:** True if the radio is silent, or false otherwise.

## airbase:setRadioSilentMode

```lua
nil airbase:setRadioSilentMode(boolean silent)
```

The `airbase:setRadioSilentMode` method enables or disables the airbase's radio.

**Parameters:**
- `silent` (boolean): Set to true to silence the radio, or false to enable it.

## airbase:setCoalition

```lua
nil airbase:setCoalition(number coalitionId)
```

The `airbase:setCoalition` method changes the airbase's coalition, effectively capturing it.

**Parameters:**
- `coalitionId` (number): The new coalition from `coalition.side`.

```lua
airbase:setCoalition(coalition.side.BLUE)
```

## airbase:autoCapture

```lua
nil airbase:autoCapture(boolean enable)
```

The `airbase:autoCapture` method enables or disables automatic capture when ground forces are nearby.

**Parameters:**
- `enable` (boolean): Set to true to enable auto-capture, or false to disable.

## airbase:autoCaptureIsOn

```lua
boolean airbase:autoCaptureIsOn()
```

The `airbase:autoCaptureIsOn` method returns whether auto-capture is enabled.

**Returns:** True if auto-capture is on, or false otherwise.

## airbase:getWarehouse

```lua
Warehouse airbase:getWarehouse()
```

The `airbase:getWarehouse` method returns the airbase's warehouse (logistics) object.

**Returns:** A Warehouse object.

## See Also

- [object](object.md) - Base class methods
- [coalition-object](coalition-object.md) - Coalition and country methods
- [coalition](coalition.md) - Airbase queries by coalition
- [world](world.md) - World airbase queries

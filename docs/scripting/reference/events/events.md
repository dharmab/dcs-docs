# Events

DCS creates an event each time something happens in the simulation, such as an aircraft taking off, a unit firing a weapon, or a unit being destroyed. An event is a table that describes what happened, including the event type, the time, and usually the object that caused it.

Scripts receive events through event handlers. An event handler is a table containing an `onEvent` function. After a script registers a handler with [`world.addEventHandler()`](../singletons/world.md#worldaddeventhandler), DCS calls the handler's `onEvent` function for every event.

## Event System Overview

To receive events, create a handler table with an `onEvent` function and register it:

```lua
local shotHandler = {}

function shotHandler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        -- Handle shot event
    end
end

world.addEventHandler(shotHandler)
```

All events contain at least:

- `id` (number): Event type from `world.event`
- `time` (number): Mission time when the event occurred

Many events include `initiator`, which is typically the Unit that caused the event. Nil-check `initiator`; it can be nil, especially in multiplayer.

## Event Handler Pitfalls

Event handlers have several known issues that scripts must handle defensively.

**Group Access May Fail:** In event handlers, `unit:getGroup()` or `Group.getByName()` sometimes returns nil for a group that exists, apparently from a timing or caching issue. Check for nil:

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD then
        local unit = event.initiator
        if unit then
            local group = unit:getGroup()
            if group then
                -- Safe to access group methods
                local remaining = group:getSize()
            end
        end
    end
end
```

**Destroyed Unit Properties Crash Scripts:** Reading properties of destroyed units can crash the scripting engine. In death events (`S_EVENT_DEAD`, `S_EVENT_CRASH`, `S_EVENT_UNIT_LOST`), the `initiator` may be partly destroyed. Check `unit:isExist()` and wrap property access in `pcall`.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD then
        local unit = event.initiator
        if unit and unit:isExist() then
            -- Safe to access unit properties
            local name = unit:getName()
        end
    end
end
```

**Event ID Enum:**

```lua
world.event = {
    S_EVENT_SHOT = 1,
    S_EVENT_HIT = 2,
    S_EVENT_TAKEOFF = 3,
    S_EVENT_LAND = 4,
    S_EVENT_CRASH = 5,
    S_EVENT_EJECTION = 6,
    S_EVENT_REFUELING = 7,
    S_EVENT_DEAD = 8,
    S_EVENT_PILOT_DEAD = 9,
    S_EVENT_BASE_CAPTURED = 10,
    S_EVENT_MISSION_START = 11,
    S_EVENT_MISSION_END = 12,
    S_EVENT_REFUELING_STOP = 14,
    S_EVENT_BIRTH = 15,
    S_EVENT_HUMAN_FAILURE = 16,
    S_EVENT_DETAILED_FAILURE = 17,
    S_EVENT_ENGINE_STARTUP = 18,
    S_EVENT_ENGINE_SHUTDOWN = 19,
    S_EVENT_PLAYER_ENTER_UNIT = 20,
    S_EVENT_PLAYER_LEAVE_UNIT = 21,
    S_EVENT_PLAYER_COMMENT = 22,
    S_EVENT_SHOOTING_START = 23,
    S_EVENT_SHOOTING_END = 24,
    S_EVENT_MARK_ADDED = 25,
    S_EVENT_MARK_CHANGE = 26,
    S_EVENT_MARK_REMOVE = 27,
    S_EVENT_KILL = 28,
    S_EVENT_SCORE = 29,
    S_EVENT_UNIT_LOST = 30,
    S_EVENT_LANDING_AFTER_EJECTION = 31,
    S_EVENT_DISCARD_CHAIR_AFTER_EJECTION = 32,
    S_EVENT_WEAPON_ADD = 33,
    S_EVENT_LANDING_QUALITY_MARK = 34,
    S_EVENT_AI_ABORT_MISSION = 35,
    S_EVENT_RUNWAY_TAKEOFF = 36,
    S_EVENT_RUNWAY_TOUCH = 37,
}
```

## Combat Events

### S_EVENT_SHOT

The `S_EVENT_SHOT` event fires when a unit fires a weapon such as a missile, bomb, or rocket. This event does not fire for guns; use `S_EVENT_SHOOTING_START` and `S_EVENT_SHOOTING_END` to detect gun fire.

**Event Table:**

```lua
{
    id = 1,
    time = number,
    initiator = Unit,
    weapon = Weapon
}
```

The `initiator` field is the Unit that fired the weapon. The `weapon` field is the Weapon of the projectile in flight.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_SHOT then
        local shooter = event.initiator
        local weapon = event.weapon
        if shooter and weapon then
            env.info(shooter:getName() .. " fired " .. weapon:getTypeName())
        end
    end
end
```

### S_EVENT_HIT

The `S_EVENT_HIT` event fires when a weapon hits a target. In multiplayer, the `weapon` field may be nil due to network desync.

**Event Table:**

```lua
{
    id = 2,
    time = number,
    initiator = Unit,
    weapon = Weapon,
    target = Object
}
```

The `initiator` field is the Unit that fired the weapon. The `weapon` field is the Weapon that hit the target. The `target` field is the Object that was struck.

### S_EVENT_SHOOTING_START

The `S_EVENT_SHOOTING_START` event fires when a unit begins firing guns or other continuous fire weapons.

**Event Table:**

```lua
{
    id = 23,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

The `initiator` field is the Unit that is firing. The `weapon_name` field is the type name of the weapon being fired.

### S_EVENT_SHOOTING_END

The `S_EVENT_SHOOTING_END` event fires when a unit stops firing guns.

**Event Table:**

```lua
{
    id = 24,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

The `initiator` field is the Unit that stopped firing. The `weapon_name` field is the type name of the weapon that was being fired.

### S_EVENT_KILL

The `S_EVENT_KILL` event fires when a unit kills another unit.

**Event Table:**

```lua
{
    id = 28,
    time = number,
    initiator = Unit,
    target = Unit,
    weapon = Weapon,
    weapon_name = string
}
```

The `initiator` field is the Unit that scored the kill. The `target` field is the Unit that was killed. The `weapon` field is the Weapon used in the kill. The `weapon_name` field is the type name of the weapon.

## Death and Damage Events

### S_EVENT_DEAD

The `S_EVENT_DEAD` event fires when a unit is destroyed and its hit points reach zero. For aircraft, `S_EVENT_CRASH` may fire instead of or in addition to `S_EVENT_DEAD`.

**Event Table:**

```lua
{
    id = 8,
    time = number,
    initiator = Object
}
```

The `initiator` field is the Object that was destroyed.

```lua
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_DEAD then
        local unit = event.initiator
        if unit then
            env.info(unit:getName() .. " was destroyed")
        end
    end
end
```

### S_EVENT_CRASH

The `S_EVENT_CRASH` event fires when an aircraft crashes into the ground and is completely destroyed.

**Event Table:**

```lua
{
    id = 5,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft that crashed.

### S_EVENT_PILOT_DEAD

The `S_EVENT_PILOT_DEAD` event fires when a pilot dies, which is tracked separately from aircraft destruction.

**Event Table:**

```lua
{
    id = 9,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft whose pilot died.

### S_EVENT_UNIT_LOST

The `S_EVENT_UNIT_LOST` event fires when any unit is lost from the mission for any reason.

**Event Table:**

```lua
{
    id = 30,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit that was lost.

### S_EVENT_HUMAN_FAILURE

The `S_EVENT_HUMAN_FAILURE` event fires when a player-controlled aircraft experiences a system failure.

**Event Table:**

```lua
{
    id = 16,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft that experienced the failure.

### S_EVENT_DETAILED_FAILURE

The `S_EVENT_DETAILED_FAILURE` event fires with detailed information about system failures.

**Event Table:**

```lua
{
    id = 17,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft that experienced the failure.

## Flight Events

### S_EVENT_TAKEOFF

The `S_EVENT_TAKEOFF` event fires when an aircraft takes off from an airbase, FARP, or ship. It fires several seconds after liftoff. Use `S_EVENT_RUNWAY_TAKEOFF` for the moment of liftoff.

**Event Table:**

```lua
{
    id = 3,
    time = number,
    initiator = Unit,
    place = Airbase,
    subPlace = number
}
```

The `initiator` field is the aircraft's Unit. The `place` field is the Airbase (airport, FARP, or ship) it departed from. The `subPlace` field is a sub-location identifier.

### S_EVENT_LAND

The `S_EVENT_LAND` event fires when an aircraft lands at an airbase, FARP, or ship and has stopped. Use `S_EVENT_RUNWAY_TOUCH` for the moment of touchdown.

**Event Table:**

```lua
{
    id = 4,
    time = number,
    initiator = Unit,
    place = Airbase,
    subPlace = number
}
```

The `initiator` field is the aircraft's Unit. The `place` field is the Airbase where it landed. The `subPlace` field is a sub-location identifier.

### S_EVENT_RUNWAY_TAKEOFF

The `S_EVENT_RUNWAY_TAKEOFF` event fires at the exact moment an aircraft leaves the ground. On some maps, runway terrain makes the aircraft bounce and fire this event early. Prefer `S_EVENT_TAKEOFF` unless you need the moment of liftoff.

**Event Table:**

```lua
{
    id = 36,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

The `initiator` field is the Unit of the aircraft. The `place` field is the Airbase.

### S_EVENT_RUNWAY_TOUCH

The `S_EVENT_RUNWAY_TOUCH` event fires at the exact moment an aircraft touches the ground after being airborne. On some maps, runway terrain makes the aircraft bounce and fire this event several times. Prefer `S_EVENT_LAND` unless you need the moment of touchdown.

**Event Table:**

```lua
{
    id = 37,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

The `initiator` field is the Unit of the aircraft. The `place` field is the Airbase.

### S_EVENT_REFUELING

The `S_EVENT_REFUELING` event fires when an aircraft connects with a tanker and begins taking on fuel.

**Event Table:**

```lua
{
    id = 7,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft receiving fuel.

### S_EVENT_REFUELING_STOP

The `S_EVENT_REFUELING_STOP` event fires when an aircraft disconnects from a tanker.

**Event Table:**

```lua
{
    id = 14,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft that disconnected from the tanker.

### S_EVENT_EJECTION

The `S_EVENT_EJECTION` event fires when a pilot ejects from an aircraft. For aircraft with ejector seats, the `target` field is the seat object rather than the pilot; wait for `S_EVENT_DISCARD_CHAIR_AFTER_EJECTION` to get the pilot. The pilot object is special and most scripting functions do not work on it.

**Event Table:**

```lua
{
    id = 6,
    time = number,
    initiator = Unit,
    target = Object
}
```

The `initiator` field is the aircraft's Unit. The `target` field is the ejector seat or pilot object.

### S_EVENT_DISCARD_CHAIR_AFTER_EJECTION

The `S_EVENT_DISCARD_CHAIR_AFTER_EJECTION` event fires when the ejector seat separates from the pilot.

**Event Table:**

```lua
{
    id = 32,
    time = number,
    initiator = Unit,
    target = Object
}
```

The `initiator` field is the Unit of the original aircraft. The `target` field is the pilot object.

### S_EVENT_LANDING_AFTER_EJECTION

The `S_EVENT_LANDING_AFTER_EJECTION` event fires when an ejected pilot lands after the parachute touchdown.

**Event Table:**

```lua
{
    id = 31,
    time = number,
    initiator = Unit,
    target = Object
}
```

The `initiator` field is the Unit of the original aircraft. The `target` field is the pilot object.

### S_EVENT_ENGINE_STARTUP

The `S_EVENT_ENGINE_STARTUP` event fires when an aircraft starts its engines.

**Event Table:**

```lua
{
    id = 18,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft that started its engines.

### S_EVENT_ENGINE_SHUTDOWN

The `S_EVENT_ENGINE_SHUTDOWN` event fires when an aircraft shuts down its engines.

**Event Table:**

```lua
{
    id = 19,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit of the aircraft that shut down its engines.

### S_EVENT_LANDING_QUALITY_MARK

The `S_EVENT_LANDING_QUALITY_MARK` event fires for carrier landings and includes LSO grade information.

**Event Table:**

```lua
{
    id = 34,
    time = number,
    initiator = Unit,
    place = Airbase,
    comment = string
}
```

The `initiator` field is the aircraft's Unit. The `place` field is the carrier's Airbase. The `comment` field contains the LSO grade comments.

## Player Events

### S_EVENT_BIRTH

The `S_EVENT_BIRTH` event fires when any unit spawns into the mission. Use it to track players entering aircraft and helicopters; `S_EVENT_PLAYER_ENTER_UNIT` only fires for Combined Arms ground vehicles.

**Event Table:**

```lua
{
    id = 15,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit that was spawned.

```lua
-- Set up player menus when they spawn or respawn
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_BIRTH then
        local unit = event.initiator
        if unit and unit:getPlayerName() then
            setupPlayerMenu(unit)
        end
    end
end
```

### S_EVENT_PLAYER_ENTER_UNIT

The `S_EVENT_PLAYER_ENTER_UNIT` event fires when a player takes control of a Combined Arms ground vehicle. This event **only** fires for Combined Arms units and does **not** fire when players enter aircraft or helicopters.

To track players entering aircraft or helicopters (respawns, slot-ins), use `S_EVENT_BIRTH` instead.

**Event Table:**

```lua
{
    id = 20,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit that the player is now controlling.

```lua
-- Track Combined Arms vehicle control
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_PLAYER_ENTER_UNIT then
        local unit = event.initiator
        local playerName = unit:getPlayerName()
        env.info(playerName .. " took control of Combined Arms unit " .. unit:getName())
    end
end
```

### S_EVENT_PLAYER_LEAVE_UNIT

The `S_EVENT_PLAYER_LEAVE_UNIT` event fires when a player leaves a unit, whether by disconnecting, spectating, or changing slot.

**Event Table:**

```lua
{
    id = 21,
    time = number,
    initiator = Unit
}
```

The `initiator` field is the Unit that the player left.

### S_EVENT_PLAYER_COMMENT

The `S_EVENT_PLAYER_COMMENT` event fires when a player sends a chat message.

**Event Table:**

```lua
{
    id = 22,
    time = number,
    initiator = Unit,
    comment = string
}
```

The `initiator` field is the Unit of the player who sent the message. The `comment` field is the chat message text.

## Mission Events

### S_EVENT_MISSION_START

The `S_EVENT_MISSION_START` event fires when the mission begins.

**Event Table:**

```lua
{
    id = 11,
    time = number
}
```

### S_EVENT_MISSION_END

The `S_EVENT_MISSION_END` event fires when the mission ends.

**Event Table:**

```lua
{
    id = 12,
    time = number
}
```

### S_EVENT_BASE_CAPTURED

The `S_EVENT_BASE_CAPTURED` event fires when an airbase changes coalition.

**Event Table:**

```lua
{
    id = 10,
    time = number,
    initiator = Unit,
    place = Airbase
}
```

The `initiator` field is the Unit that captured the base. The `place` field is the Airbase that was captured.

### S_EVENT_AI_ABORT_MISSION

The `S_EVENT_AI_ABORT_MISSION` event fires when an AI group aborts its mission.

**Event Table:**

```lua
{
    id = 35,
    time = number,
    initiator = Unit
}
```

The `initiator` field is a Unit from the group that aborted its mission.

## Marker Events

Map marker events allow scripts to respond to player map annotations.

### S_EVENT_MARK_ADDED

The `S_EVENT_MARK_ADDED` event fires when a mark or shape is added to the map.

**Event Table:**

```lua
{
    id = 25,
    time = number,
    initiator = Unit,
    idx = number,
    coalition = number,
    groupID = number,
    text = string,
    pos = Vec3
}
```

- `initiator`: The Unit that created the mark, or nil if a script created it.
- `idx` (number): Unique marker ID.
- `coalition` (number): Coalition that can see the marker, or -1 for all.
- `groupID` (number): Group that can see the marker, or -1 for all groups in the coalition.
- `text` (string): Marker text.
- `pos` (Vec3): Marker position.

```lua
-- React to player placing marks with keywords
function handler:onEvent(event)
    if event.id == world.event.S_EVENT_MARK_ADDED then
        if string.find(event.text, "CAS") then
            requestCAS(event.pos)
        end
    end
end
```

### S_EVENT_MARK_CHANGE

The `S_EVENT_MARK_CHANGE` event fires when a mark is modified.

**Event Table:**

```lua
{
    id = 26,
    time = number,
    initiator = Unit,
    idx = number,
    coalition = number,
    groupID = number,
    text = string,
    pos = Vec3
}
```

The fields have the same meanings as in `S_EVENT_MARK_ADDED`.

### S_EVENT_MARK_REMOVE

The `S_EVENT_MARK_REMOVE` event fires when a mark is deleted.

**Event Table:**

```lua
{
    id = 27,
    time = number,
    initiator = Unit,
    idx = number,
    coalition = number,
    groupID = number,
    pos = Vec3
}
```

The fields have the same meanings as in `S_EVENT_MARK_ADDED`.

## Weapon Events

### S_EVENT_WEAPON_ADD

The `S_EVENT_WEAPON_ADD` event fires when a weapon is added to a unit, such as during rearming.

**Event Table:**

```lua
{
    id = 33,
    time = number,
    initiator = Unit,
    weapon_name = string
}
```

The `initiator` field is the Unit that received the weapon. The `weapon_name` field is the type name of the weapon that was added.

## See Also

- [world](../singletons/world.md) - Event handler registration
- [unit](../classes/unit.md) - Unit class (common initiator)
- [weapon](../classes/weapon.md) - Weapon class (in shot events)
- [airbase](../classes/airbase.md) - Airbase class (in flight events)

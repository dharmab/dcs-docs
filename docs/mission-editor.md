# DCS World Mission Editor

The Mission Editor (ME) is the graphical interface for creating mission scenarios in DCS World. It enables mission designers to build standalone missions, campaign missions, training missions, and multiplayer missions with complex game logic using triggers, AI tasking, and environmental controls.

## Primary Components

The Mission Editor consists of seven primary elements:

1. **Interactive mapping system** - The World Map displaying topography, units, routes, and mission elements
2. **Unit placement tools** - For placing aircraft, helicopters, ground vehicles, ships, and static objects
3. **Weather editor** - Static and dynamic weather configuration
4. **File management system** - Mission saving, loading, and export
5. **Goal creation tool** - Victory/failure condition definition
6. **Trigger system** - Event-driven scripting for dynamic mission behavior
7. **Additional specialized panels** - Briefing, options, resource management, and more

## Interface Layout

The Mission Editor screen is divided into four primary areas:

**World Map**: The central area displaying the topographic map with units, routes, and mission elements. Navigate by holding the right mouse button and dragging to pan, or scrolling the mouse wheel to zoom.

**Tool Bar**: Located along the left side, providing quick access to unit placement, triggers, zones, goals, and file management functions.

**System Bar**: Along the top of the screen with pull-down menus for File, Edit, Flight, Campaign, Customize, Mission Generator, and Misc functions.

**Mission and Map Bar**: Along the bottom, displaying the mission name, cursor coordinates/altitude, map mode, and current time.

## Creating a New Mission

When creating a new mission, you first select the theater (map) and assign countries to coalitions. The coalition system supports three configurations:

- **Custom**: Manually assign countries to coalitions
- **Modern**: Based on contemporary geopolitical alliances
- **WWII**: Based on World War II historical alliances

Countries can be assigned to RED or BLUE coalitions, or left unassigned (neutral).

Always use Custom coalitions when creating new missions. Coalition assignments cannot be changed after mission creation, and the Modern and WWII presets offer no advantages over manually selecting the countries you need. Custom coalitions give you complete control over which countries appear on each side from the start.

When selecting countries for your coalitions, use only "Combined Joint Task Force Blue" for the blue coalition and "Combined Joint Task Force Red" for the red coalition. These fictional countries have unrestricted access to all equipment and liveries in the game. Real-world countries in DCS carry legacy restrictions that limit which aircraft, weapons, and paint schemes are available based on historical accuracy considerations. These restrictions create unnecessary complications when building missions and offer no gameplay benefit. Using the CJTF countries eliminates these issues entirely and gives mission designers full access to all game content.

## Unit Placement

### Aircraft and Helicopters

Aircraft groups consist of one to four units. Each group has configurable properties including:

- **Name**: Unique identifier for trigger references
- **Country**: Owning country within the coalition (use CJTF countries for unrestricted aircraft access)
- **Task**: Primary mission type affecting AI behavior and available actions
- **Skill**: AI competency level (Average, Good, High, Excellent, Random, Client, or Player)
- **Callsign**: Radio identification
- **Hidden on Map/Planner**: Visibility on F10 map and mission planner
- **Late Activation**: Group spawns only when triggered

Available aircraft tasks include:
- Nothing, AFAC, Anti-ship Strike, AWACS, CAP, CAS, Escort, Fighter Sweep, Ground Attack, Intercept, Pinpoint Strike, Reconnaissance, Refueling, Runway Attack, SEAD, and Transport

### Ground and Naval Units

Ground vehicles and ships are placed similarly to aircraft, with group-based organization and route planning. Ground units can capture airfields and FARPs by proximity (within 2000 meters).

### Static Objects

Static objects are non-moving scenery elements including buildings, fortifications, cargo, and decorative items. They can be configured with late activation for dynamic mission content.

## Route Planning

Routes consist of waypoints that define unit movement paths. Each waypoint can specify:

- **Type**: Turning point, Fly over point, Takeoff (runway/ramp/ground), Landing, LandingReFuAr
- **Altitude**: MSL (Mean Sea Level) or AGL (Above Ground Level)
- **Speed**: Desired ground speed
- **ETA**: Estimated time of arrival

Speed and ETA values can be locked or unlocked. When one is locked, the editor calculates the other automatically based on distance. Routes must have at least one waypoint with a locked ETA as a time reference.

## Trigger System

The trigger system enables event-driven scripting using a condition-action model. Triggers do not fire on events directly but rather when conditions evaluate to TRUE.

### Trigger Types

- **ONCE**: Executes once when conditions become true, then removed from memory
- **REPETITIVE ACTION**: Checks conditions every second; actions execute each second conditions are true
- **SWITCHED CONDITION**: Executes when conditions switch from false to true (edge-triggered)
- **MISSION START**: Evaluates only at mission start

### Trigger Events

Triggers can be limited to evaluate only on specific events:
- NO EVENT (evaluates continuously)
- ON DESTROY, ON SHOT, ON CRASH, ON EJECT
- ON REFUEL, ON REFUEL STOP
- ON PILOT DEAD, ON BASE CAPTURED
- ON TAKE CONTROL, ON FAILURE
- ON MISSION START, ON MISSION ENDS

### Trigger Conditions

Common conditions include:

**Zone-based conditions**:
- ALL/PART OF COALITION IN/OUT OF ZONE
- ALL/PART OF GROUP IN/OUT OF ZONE
- UNIT INSIDE/OUTSIDE ZONE
- UNIT INSIDE/OUTSIDE MOVING ZONE
- BOMB/MISSILE IN ZONE

**Unit state conditions**:
- GROUP/UNIT ALIVE, DEAD, DAMAGED
- GROUP ALIVE LESS THAN (percentage)
- UNIT'S LIFE LESS THAN (percentage)

**Flag conditions**:
- FLAG IS TRUE/FALSE
- FLAG EQUALS, FLAG IS LESS/MORE
- FLAG EQUALS FLAG, FLAG IS LESS/MORE THAN FLAG

**Time conditions**:
- TIME LESS/MORE (seconds from mission start)
- TIME SINCE FLAG

**Other conditions**:
- RANDOM (percentage probability)
- COALITION HAS AIRDROME/HELIPAD
- MISSION SCORE HIGHER/LOWER THAN
- PLAYER SCORES LESS/MORE
- UNIT'S ALTITUDE/SPEED/HEADING/BANK/PITCH IN LIMITS
- LUA PREDICATE (custom Lua scripting)

Multiple conditions operate with AND logic by default. Use the OR button to separate conditions into OR groups.

### Trigger Actions

Common actions include:

**Group/Unit control**:
- GROUP ACTIVATE/DEACTIVATE
- GROUP AI ON/OFF
- GROUP RESUME/STOP
- UNIT AI ON/OFF
- UNIT EMISSION ON/OFF
- EXPLODE UNIT

**Messaging**:
- MESSAGE TO ALL/COALITION/COUNTRY/GROUP
- SOUND TO ALL/COALITION/COUNTRY/GROUP
- RADIO TRANSMISSION

**Flag manipulation**:
- FLAG ON/OFF
- FLAG INCREASE/DECREASE
- SET FLAG VALUE
- FLAG SET RANDOM VALUE

**AI tasking**:
- AI TASK PUSH
- AI TASK SET

**Effects**:
- EXPLOSION, ILLUMINATING BOMB
- SMOKE MARKER (on zone or unit)
- SIGNAL FLARE (on zone or unit)
- SHELLING ZONE
- SCENERY DESTRUCTION/REMOVE OBJECTS ZONE

**Map markers**:
- MARK TO ALL/COALITION/GROUP
- REMOVE MARK

**Mission control**:
- END MISSION
- LOAD MISSION (multiplayer campaigns)
- DO SCRIPT, DO SCRIPT FILE (Lua execution)

## Weather Configuration

The weather editor provides two modes:

### Static Weather

Fixed weather conditions throughout the mission:

- **Season**: Summer, Winter, Spring, Fall (affects terrain appearance and vehicle camouflage)
- **Temperature**: Sea level air temperature in Celsius
- **Clouds**: Base altitude, thickness, density (0-10 scale), precipitation type
- **QNH**: Barometric pressure in mmHg
- **Wind**: Direction and speed at four altitude bands (10m, 500m, 2000m, 8000m)
- **Turbulence**: Ground-level turbulence in m/s
- **Fog**: Enable/disable, visibility, thickness
- **Dust/Smoke**: Enable/disable, visibility

### Dynamic Weather

Weather generated from atmospheric pressure systems:

- **Baric System**: Cyclone (low pressure), Anticyclone (high pressure), or None
- **Systems Quantity**: Number of pressure systems on the map
- **Pressure Deviation**: Pressure difference from ISA in Pascals

Dynamic weather creates evolving wind and cloud conditions based on pressure system interactions.

## Mission Goals

Goals define victory, draw, and failure conditions using a point-based system:
- 0-49 points: Mission failure
- 50 points: Mission draw
- 51+ points: Mission success

Each goal has a name, point score, and assignment (Offline/Player, RED, or BLUE). Goal conditions use the same system as trigger conditions.

## Resource Manager

The Resource Manager controls aircraft, fuel, and equipment availability at airbases and independent warehouses:

- **Aircraft inventory**: Available aircraft types and quantities
- **Fuel**: Available fuel in tons
- **Equipment**: Weapons, pods, fuel tanks

Warehouses can be linked in supply chains with configurable supply speed, periodicity, and delivery size. When resources fall to an operating level percentage, the warehouse requests resupply from linked suppliers.

## AI Task Planning

### Action Types

**Perform Task**: Primary combat actions executed sequentially (Attack Group, Orbit, FAC, etc.)

**Start Enroute Task**: Background actions active for the route duration, executed when conditions arise (Search Then Engage, etc.)

**Perform Command**: Instantaneous actions (Set Frequency, Set Callsign, etc.)

**Set Option**: Rules and limitations for the group (Formation, ROE, Weapon Usage, etc.)

### Action Priority

Tasks have higher priority than Enroute Tasks by default. Triggered tasks have higher priority than waypoint tasks. When multiple Enroute Tasks are active, the one with the lowest priority number (0 = highest) executes first.

### Start/Stop Conditions

Actions can have start conditions (time, flag state, probability, Lua predicate) and stop conditions (time, flag state, duration, last waypoint).

## Briefing Creation

The briefing panel includes:
- **Sortie**: Mission title
- **Coalition lists**: Automatically populated from assigned countries
- **Briefing images**: Custom images for RED and BLUE sides (recommended 1024x1024 pixels, JPG/PNG format)
- **Situation text**: General mission briefing
- **RED/BLUE Task text**: Coalition-specific objective descriptions

Custom kneeboard cards can be added by placing images in the `Saved Games\DCS\Kneeboard\[aircraft_name]\` folder.

## Mission Options

Mission-level options can be enforced on players:
- Permit Crash Recovery, External Views, F10 View Options
- Labels, Game Flight Mode, Game Avionic Mode
- Immortal, Unlimited Fuel/Weapons
- Easy Communication, Radio Assists
- Padlock, Tool Tips, Wake Turbulence
- G-Effect level, Random System Failures
- Civilian Traffic density, Bird Strike probability

## Battlefield Commanders (Multiplayer)

Multiplayer roles beyond pilots:
- **Game Master**: Full control and visibility of both sides
- **Tactical Commander**: Strategic ground unit control with JTAC capability
- **JTAC/Operator**: First-person vehicle control with JTAC capability
- **Observer**: Unlimited camera access without control

## Keyboard Shortcuts

- **Ctrl+C / Ctrl+V**: Copy/paste groups
- **Left click**: Place waypoint or select unit
- **Right click + drag**: Pan map view
- **Mouse wheel**: Zoom map
- **RShift+K**: Open kneeboard in-flight

## File Formats

- **.miz**: Mission file format (ZIP archive containing mission data and resources). See [MIZ File Format](miz-file-format.md) for complete documentation of the archive structure and contents.
- **.trk**: Track recording file for replay

## Further Reading

For advanced mission scripting capabilities beyond the GUI editor, see the Simulator Scripting Engine documentation which covers Lua-based mission scripting for complex scenarios that cannot be achieved through the Mission Editor alone.

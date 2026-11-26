# DCS World Mission Editor

The Mission Editor (ME) is the DCS World GUI for building standalone, campaign, training, and multiplayer missions. Mission designers control mission behavior with triggers, AI tasks, environment settings, and [Lua](https://www.lua.org/about.html) scripts.

## Contents

- [Primary Components](#primary-components)
- [Interface Layout](#interface-layout)
- [Creating a New Mission](#creating-a-new-mission)
- [Unit Placement](#unit-placement)
- [Route Planning](#route-planning)
- [Trigger System](#trigger-system)
- [Weather Configuration](#weather-configuration)
- [Mission Goals](#mission-goals)
- [Resource Manager](#resource-manager)
- [AI Task Planning](#ai-task-planning)
- [Briefing Creation](#briefing-creation)
- [Mission Options](#mission-options)
- [File Formats](#file-formats)
- [Further Reading](#further-reading)

## Primary Components

The Mission Editor contains these main components:

- **Map** - Shows the terrain, units, routes, and other mission elements.
- **Unit placement tools** - Place aircraft, helicopters, ground vehicles, ships, and static objects.
- **Weather editor** - Configures static and dynamic weather.
- **File management** - Saves, loads, and exports missions.
- **Goals** - Define victory and failure conditions.
- **Trigger system** - Runs actions when conditions are true.
- **Briefing panel** - Sets the mission title, situation text, coalition tasks, and briefing images.
- **Mission options** - Enforces realism and assistance settings on players.
- **Resource Manager** - Sets aircraft, fuel, and equipment stocks in warehouses.

## Interface Layout

The Mission Editor screen has four areas:

**World Map**: The central area shows the topographic map with units, routes, and mission elements. Drag with the right mouse button to pan, and scroll to zoom.

**Tool Bar**: The tool bar along the left side contains buttons for unit placement, triggers, zones, goals, and file management.

**System Bar**: The system bar along the top contains menus for File, Edit, Flight, Campaign, Customize, Mission Generator, and Misc.

**Mission and Map Bar**: The bar along the bottom shows the mission name, cursor coordinates and altitude, map mode, and current time.

## Creating a New Mission

A new mission starts with choosing the theater (map) and assigning countries to coalitions. There are three coalition presets:

- **Custom**: Manually assign countries to coalitions
- **Modern**: Based on contemporary geopolitical alliances
- **WWII**: Based on World War II historical alliances

Countries can be assigned to RED or BLUE coalitions, or left unassigned (neutral).

Always use Custom coalitions. Coalition assignments cannot change after mission creation, and the Modern and WWII presets have no advantage over choosing countries yourself.

Use only "Combined Joint Task Force Blue" for blue and "Combined Joint Task Force Red" for red. These fictional countries can use all equipment and liveries. Real-world countries have legacy restrictions on aircraft, weapons, and liveries that complicate mission building and add nothing to gameplay.

GPS has two restrictions. First, GPS only works in missions dated after March 28, 1994, when the real GPS constellation became fully operational. Second, DCS limits GPS to coalitions that include the United States. If players need GPS, set the mission date after March 1994 and include the USA or use CJTF countries.

## Unit Placement

### Aircraft and Helicopters

Aircraft groups consist of one to four units. Group properties include:

- **Name**: Unique identifier for trigger references
- **Country**: Owning country within the coalition (use CJTF countries for unrestricted aircraft access) <!-- TODO: QA - Verify that CJTF countries have unrestricted access to all liveries and weapons in current DCS version -->
- **Task**: Primary mission type affecting AI behavior and available actions
- **Skill**: AI skill (Average, Good, High, Excellent, Random) or player slot (Client or Player). Player makes the aircraft the default slot in a singleplayer mission. A mission can have only one Player aircraft. Client makes the aircraft a selectable player slot in singleplayer and multiplayer. To let the player choose between several aircraft in a singleplayer mission, use Client slots.
- **Callsign**: Radio identification
- **Hidden on Map/Planner**: Visibility on F10 map and mission planner
- **Late Activation**: Group spawns only when triggered

Available aircraft tasks include:

- Nothing, AFAC, Anti-ship Strike, AWACS, CAP, CAS, Escort, Fighter Sweep, Ground Attack, Intercept, Pinpoint Strike, Reconnaissance, Refueling, Runway Attack, SEAD, and Transport

### Ground and Naval Units

Ground vehicles and ships are placed in groups with routes. Ground units need flat, clear terrain, and ships need water deep enough for their draft. Ground units capture airfields and FARPs by coming within 2000 meters.

### Static Objects

Static objects are non-moving objects such as buildings, fortifications, cargo, and decorations. They can use late activation to appear during the mission.

## Route Planning

A route is a list of waypoints. Each waypoint is a map position with properties that control how the group navigates to it and behaves there. Actions attached to a waypoint control AI behavior at that point.

### Waypoint Management

The waypoint panel contains three mode buttons:

- **ADD**: Left-clicking on the map adds a new waypoint to the route (default mode when opening group properties)
- **EDIT**: Select existing waypoints on the map to modify their properties
- **DEL**: Delete the selected waypoint from the route

A waypoint can have a name, shown next to its marker on the map. Select waypoints with the arrow buttons or by clicking on the map.

### Waypoint Types

#### Aircraft Waypoints

**Turning Point** is the most common type. The aircraft starts its turn before the waypoint so it rolls out on course for the next one. As a result, it passes near the waypoint rather than over it.

**Fly Over Point** is like a turning point, but the aircraft passes directly over the waypoint before it starts its turn to the next waypoint. Because the turn starts late, the aircraft overshoots the line to the next waypoint and then turns back onto it.

**Takeoff from Runway** (waypoint 1 only) spawns the aircraft on the runway threshold with systems running. The waypoint snaps to the nearest airfield or FARP.

**Takeoff from Ramp** (waypoint 1 only) spawns the aircraft cold on the parking apron. AI aircraft perform a cold start before taxiing to the runway. The waypoint snaps to the nearest parking area.

**Takeoff from Parking Hot** (waypoint 1 only) spawns the aircraft on the parking apron with systems running. This skips the cold start, but the aircraft still taxis to the runway.

**Takeoff from Ground** and **Takeoff from Ground Hot** (waypoint 1 only) spawn helicopters and VTOL aircraft anywhere on the ground. The hot variant has systems running.

**Landing** (final waypoint only) lands the aircraft at the nearest airfield or FARP. The waypoint snaps to a valid landing location.

**LandingReFuAr** (any waypoint except 1) lands, refuels, and rearms the aircraft, then continues the route. Aircraft can fly several sorties without despawning. <!-- TODO: MISSING - Document the fuel/weapon states after LandingReFuAr - does the aircraft always refuel to 100%? Can you configure partial refueling or selective rearming? -->

#### Ground Unit Waypoints

Ground units use simpler waypoint types that control how they use the road network:

**On Road** waypoints make the unit pathfind along roads to the waypoint.

**Off Road** waypoints make the unit drive straight to the waypoint, ignoring roads.

**Rank** waypoints control formation positions within the group.

#### Naval Unit Waypoints

Ships use turning point waypoints and sail directly between them, subject to water depth.

### Speed and ETA System

Each waypoint has a speed and an ETA. The speed is the ground speed toward that waypoint. Each value has a lock checkbox. The designer sets a locked value, and the editor keeps it fixed. The editor calculates each unlocked value from the locked values on the route, and recalculates it when the route changes.

Every route needs at least one waypoint with a locked ETA as a time reference. The first waypoint's ETA is the group's spawn time.

Choose locks based on what the waypoint requires:

- **Lock the speed** when the group must fly a leg at a specific speed. The AI holds that speed, and the editor calculates when the group arrives.
- **Lock the ETA** when the group must arrive at a specific time, such as a time on target or a rendezvous with a tanker or escort. The AI adjusts its speed to arrive on time, and the editor calculates the required speed.
- **Leave both unlocked** on intermediate waypoints with no speed or timing requirement. The editor calculates both from the surrounding locked waypoints.

If the editor cannot find speeds and ETAs that satisfy every lock, the route is invalid. The editor shows this error by framing the speed and ETA checkboxes in red. Common causes of this error are conflicting locks (speed locked on every waypoint plus ETA locked at start and end) and ETAs that need speeds outside the aircraft's envelope.

### Altitude Settings

Each aircraft waypoint altitude is measured either from mean sea level (MSL) or from the ground directly below the aircraft (AGL).

**MSL (Mean Sea Level)** altitude is a constant height above sea level. The aircraft flies level at that altitude regardless of the terrain below. Use MSL for high-altitude cruise, where the aircraft stays well above the terrain. If the terrain along the route is higher than the MSL altitude, the aircraft can fly into the terrain.

**AGL (Above Ground Level)** altitude is a height above the terrain directly below the aircraft. The aircraft climbs and descends to keep that clearance above the ground. Use AGL for low-level flight through varied terrain.

## Trigger System

Triggers make a mission respond to what happens during play without Lua scripting. For example, a trigger can show a message when a player enters a zone, or activate an enemy group when another group is destroyed.

Each trigger has a type, a list of conditions, and a list of actions. The game checks the conditions during the mission. When the conditions are true, the trigger runs its actions. The trigger type controls when the game checks the conditions and how often the actions can run.

Events such as a unit being shot do not run triggers by themselves. A trigger runs only when its conditions are true. The trigger's event setting (see [Trigger Events](#trigger-events)) limits when the game checks the conditions.

For programmatic access to trigger functionality, see the [trigger singleton](scripting/reference/singletons/trigger.md) reference.

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

SCENERY REMOVE OBJECTS ZONE is unreliable in multiplayer: removed objects may stay visible or collidable for some clients.[^scenery-removal] Clear areas with FARPs instead, or avoid runtime scenery removal.

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

Dynamic weather is the legacy weather system. It generates weather from cyclones and anticyclones (baric systems) placed on the map:

- **Baric System**: Cyclone (low pressure), Anticyclone (high pressure), or None
- **Systems Quantity**: Number of pressure systems on the map
- **Pressure Deviation**: Pressure difference from ISA in Pascals

Do not use dynamic weather in new missions. Use static weather with cloud presets instead, as described in [Weather and Time Configuration](recipes/weather-time.md).

## Mission Goals

Goals define victory, draw, and failure conditions using a point-based system:

- 0-49 points: Mission failure
- 50 points: Mission draw
- 51+ points: Mission success

Each goal has a name, point score, and assignment (Offline/Player, RED, or BLUE). Goal conditions use the same system as trigger conditions.

## Resource Manager

The Resource Manager sets the aircraft, fuel, and equipment stocks in warehouses. Each airbase has its own warehouse, and a mission can also contain independent warehouses that do not belong to an airbase. Each warehouse contains:

- **Aircraft inventory**: Available aircraft types and quantities
- **Fuel**: Available fuel in tons
- **Equipment**: Weapons, pods, fuel tanks

Warehouses can be linked in supply chains with a supply speed, period, and delivery size. When stock falls to the operating level percentage, the warehouse requests resupply from linked suppliers.

## AI Task Planning

There are three ways to control AI:

- **Default behavior**: Place units and routes, and the AI uses its default behavior for its unit type and nearby enemies.
- **Advanced Actions Panel**: Configure tasks, enroute tasks, commands, and options for each group in the Mission Editor.
- **Lua scripting**: A script assigns tasks, commands, and options through a group's [controller](scripting/reference/classes/controller.md) while the mission runs. See [Further Reference](#further-reference).

The rest of this section covers the Advanced Actions Panel.

Actions apply to whole groups, not units. They activate when the group leader reaches a waypoint or a trigger condition is met. There are four action types.

### Action Types

**Perform Task** actions handle combat, targeting, and maneuvering, such as orbiting, attacking a target, or acting as a FAC. Tasks have the highest priority and usually set the group's main action at each waypoint. The AI runs multiple tasks in order or by priority. A task ends on its own (for example, when all targets are destroyed) or at a stop condition.

**Start Enroute Task** actions also target or engage, but stay active for the rest of the route instead of running once at a waypoint. They handle targets of opportunity detected along the route. Perform Tasks have known targets; Enroute Tasks have targets of unknown type or location. Several Enroute Tasks can be active, but only the highest-priority eligible one runs. Perform Tasks take priority over Enroute Tasks unless overridden.

**Perform Command** actions are instantaneous, such as changing the group's radio frequency or switching navigation lights.

**Set Option** actions set rules that last until changed, such as formation, radar use, weapons release authority, and threat reaction. Each is a name and value, such as Formation = Trail or Radar Use = Never.

### Action Priority

Priority is a whole number, with 0 as the highest priority. When several tasks are eligible, the AI runs the one with the lowest number.

By default, Perform Tasks take precedence over Enroute Tasks. A Perform Task interrupts an Enroute Task, which resumes afterward. Triggered tasks (set from the trigger menu) have higher priority than waypoint tasks.

### Action Activation

Waypoint actions activate when the group leader reaches the waypoint, then run in list order or by priority. Actions set from the trigger menu run when the trigger conditions are met, independent of waypoints.

### Start/Stop Conditions

All actions support start and stop conditions. Start conditions include mission time, flag state, activation probability, and Lua predicates. Stop conditions include duration, mission time, flag state, and reaching the last waypoint. An Enroute Task with no stop condition stays active while the group exists.

### Aircraft Tasks

Aircraft have the most tasks. The group task (Nothing, AFAC, Anti-ship Strike, AWACS, CAP, CAS, Escort, Fighter Sweep, Ground Attack, Intercept, Pinpoint Strike, Reconnaissance, Refueling, Runway Attack, SEAD, Transport) filters the actions in the Advanced Actions Panel and the default payloads.

Common Perform Tasks for aircraft include Orbit (hold position in a pattern), Attack Group and Attack Unit (engage specified targets), Bombing and Carpet Bombing (attack ground targets), Escort and Follow (accompany another group), Ground Escort (protect ground units), FAC - Assign Group (act as forward air controller for a unit), Land (land at a location), and Refueling (refuel from a tanker).

Common Enroute Tasks for aircraft include the Search Then Engage variants (automatically engage detected targets matching criteria), AWACS (provide early warning and control), Tanker (refuel requesting aircraft), and FAC/FAC - Engage Group (forward air controller operations along the route).

### Ground Unit Tasks

Ground units have fewer tasks. Perform Tasks include Hold (stop movement and hold position), Fire at Point (engage a map location), FAC - Assign Group (designate targets as a forward air controller), and Go to Waypoint (proceed to a specific waypoint out of sequence).

Enroute Tasks for ground units include FAC and FAC - Engage Group for forward air controller operations during movement.

### Naval Unit Tasks

Naval units support Perform Tasks including Fire at Point and Attack Group for engaging surface and land targets. The command and option structure is similar to aircraft groups.

### Further Reference

Lua scripts can assign the same tasks, commands, and options. See [Tasks](scripting/reference/ai/tasks.md), [Commands](scripting/reference/ai/commands.md), and [Options](scripting/reference/ai/options.md).

## Briefing Creation

The briefing panel includes:

- **Sortie**: Mission title
- **Coalition lists**: Automatically populated from assigned countries
- **Briefing images**: Custom images for RED and BLUE sides (recommended 1024x1024 pixels, JPG/PNG format)
- **Situation text**: General mission briefing
- **RED/BLUE Task text**: Coalition-specific objective descriptions

Custom kneeboard cards can be added by placing images in the `Saved Games\DCS\Kneeboard\[aircraft_name]\` folder.

## Mission Options

Mission-level options can be enforced on players. These settings control realism, assistance features, and environmental factors.

### Easy Communication

Always disable Easy Communication. It tunes frequencies automatically and skips radio procedures, which breaks scripts and third-party tools that depend on radio simulation, such as frequency monitors, radio-call triggers, and custom ATC. Popular mods and server features also depend on standard radio behavior.

### Civilian Traffic

This setting turns civilian road traffic on or off. Civilian traffic has no awareness of military vehicles or combat. Civilian cars do not stop for or steer around military vehicles, and they clip through them: a car can drive through the middle of a tank column, passing through the tank models. They also show up on thermal imaging next to military targets. Disable it except in peacetime missions or missions without ground combat.

### Bird Strikes

Disable bird strikes. Despite the name, DCS does not render birds that pilots could see and avoid. The option only adds a random chance of engine failure at low altitude with no visible cause, so the pilot can do nothing to prevent it.

### Other Options

Other mission options include:

- **Permit Crash Recovery**: In singleplayer, lets the player continue the mission after a crash. Without it, a crash ends the mission and opens the debriefing screen.
- **External Views**: Enable third-person camera views
- **F10 View Options**: Control what appears on the map view
- **Labels**: Show floating name labels above units
- **Immortal**: Units cannot be destroyed
- **Unlimited Fuel/Weapons**: Disable resource consumption
- **Radio Assists**: Provide radio frequency hints
- **Padlock**: Camera tracking of enemy aircraft
- **Tool Tips**: Show help text on cockpit controls
- **Wake Turbulence**: Simulate turbulence behind aircraft
- **G-Effect level**: Intensity of pilot blackout/redout effects
- **Random System Failures**: Enable random equipment malfunctions

## File Formats

### MIZ Files

A mission is a ZIP archive of mission data and resources. See [MIZ File Format](mission/miz-file-format.md).

### TRK Files (Track Recordings)

Track files record sessions for playback. They exist mainly to reproduce bugs for developers, not to preserve an exact record of a flight.

A .trk file contains a copy of its MIZ file, so the Mission Editor can open it to show the mission setup.

Track files store player and AI inputs, not events, and replay the mission from the start with those inputs. The simulation is non-deterministic (random numbers, floating-point timing, AI decisions), so playback can diverge from the original session. For example, a missile that hit its target in the original session might miss during playback, or an AI aircraft might make different tactical decisions.

Divergence grows over time. Tracks are usually accurate for the first few minutes; by the end of an hour-long mission they likely differ significantly.

Multiplayer track files generated by dedicated servers tend to be more reliable than those recorded in singleplayer.

## Further Reading

For Lua scripting beyond what the Mission Editor can do, see [Simulator Scripting Engine](scripting/simulator-scripting-engine.md).

<!-- TODO: MISSING - Document common mission testing/debugging workflows -->

## References

[^scenery-removal]: Reference bug reports: [Scenery Remove Objects Zone (not working in multiplayer)](https://forum.dcs.world/topic/199108-scenery-remove-objects-zone-not-working-in-multiplayer/), [SCENERY REMOVE OBJECTS ZONE and dedicated server](https://forum.dcs.world/topic/266304-scenery-remove-objects-zone-and-dedicated-server/), and [Scenery remove in area action does not work for clients](https://forum.dcs.world/topic/188083-reportedscenery-remove-in-area-action-does-not-work-for-clients).

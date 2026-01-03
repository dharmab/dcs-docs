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
- **Country**: Owning country within the coalition (use CJTF countries for unrestricted aircraft access) <!-- TODO: QA - Verify that CJTF countries have unrestricted access to all liveries and weapons in current DCS version -->
- **Task**: Primary mission type affecting AI behavior and available actions
- **Skill**: AI competency level (Average, Good, High, Excellent, Random) or player slot designation (Client or Player). The Client skill marks the aircraft as an available selectable player slot in both singleplayer and multiplayer. The Player skill marks the aircraft as the sole and default slot available in a singleplayer mission.
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

Routes define the movement paths for unit groups using a series of waypoints. Each waypoint represents a position on the map with associated properties that control how the unit navigates to and behaves at that location. Actions can be attached to waypoints to script AI behavior at specific points along the route.

### Waypoint Management

The waypoint control panel provides three mode buttons for route editing:

- **ADD**: Left-clicking on the map adds a new waypoint to the route (default mode when opening group properties)
- **EDIT**: Select existing waypoints on the map to modify their properties
- **DEL**: Delete the selected waypoint from the route

Each waypoint can be assigned a unique name that appears on the map next to its marker. The waypoint selector allows cycling through waypoints using arrow buttons or by clicking directly on the map.

### Waypoint Types

#### Aircraft Waypoints

**Turning Point** is the most common waypoint type and results in the aircraft performing a lead turn ahead of the actual waypoint location to complete the turn on course for the following waypoint. This produces smooth, efficient navigation but means the aircraft passes near rather than directly over the waypoint coordinates.

**Fly Over Point** works like a turning point but requires the aircraft to pass directly over the waypoint location before beginning its turn to the next waypoint. This results in a course correction after the waypoint but guarantees the aircraft crosses the exact position specified.

**Takeoff from Runway** is only available for waypoint 1 and spawns the aircraft on the runway threshold with all systems running and ready for immediate takeoff. The waypoint automatically snaps to the nearest airfield or FARP.

**Takeoff from Ramp** is only available for waypoint 1 and spawns the aircraft on the parking apron with systems shut down. AI aircraft will perform a cold start sequence before taxiing to the runway. The waypoint snaps to the nearest parking area.

**Takeoff from Parking Hot** is only available for waypoint 1 and spawns the aircraft on the parking apron with all systems already running. This saves time compared to the cold start sequence while still requiring the aircraft to taxi to the runway.

**Takeoff from Ground** and **Takeoff from Ground Hot** are only available for waypoint 1 and allow helicopters and VTOL aircraft to spawn at arbitrary ground locations rather than at airfields. The "hot" variant has systems already running.

**Landing** is only available for the final waypoint in the route and causes the aircraft to land at the nearest airfield or FARP. The waypoint automatically snaps to a valid landing location.

**LandingReFuAr** can be placed at any waypoint other than waypoint 1 and causes the aircraft to land, refuel, and rearm before continuing along its route. This enables designing missions where aircraft fly multiple sorties without despawning. <!-- TODO: MISSING - Document the fuel/weapon states after LandingReFuAr - does the aircraft always refuel to 100%? Can you configure partial refueling or selective rearming? -->

#### Ground Unit Waypoints

Ground units navigate using simpler waypoint types that control their relationship with the road network:

**On Road** waypoints cause the unit to follow the road network to reach the destination. The AI pathfinding system calculates a route using available roads.

**Off Road** waypoints cause the unit to move directly toward the destination, ignoring roads and crossing terrain in a straight line.

**Rank** waypoints control formation positioning for units within the group.

#### Naval Unit Waypoints

Ships use standard turning point waypoints and navigate directly between positions on the water, subject to water depth constraints.

### Speed and ETA System

Each waypoint has a speed setting (the desired ground speed when traveling toward that waypoint) and an ETA setting (the estimated time of arrival at that waypoint). Both values have lock checkboxes that control whether the mission designer specifies the value manually or allows the editor to calculate it automatically.

The fundamental rule is that every route must have at least one waypoint with a locked ETA to serve as a time reference. The initial waypoint's ETA lock controls the group's spawn time in the mission. Locking the ETA for later waypoints creates timing constraints that the AI attempts to meet by adjusting its speed.

When speed is locked and ETA is unlocked, the AI maintains the specified speed and the editor calculates when the aircraft will arrive. When ETA is locked and speed is unlocked, the AI adjusts its speed to arrive at the designated time and the editor calculates the required speed. When both are unlocked for intermediate waypoints, the editor calculates both values based on the constraints of surrounding locked waypoints.

Invalid route configurations occur when the editor cannot find a valid solution for the lock settings. When this happens, the speed and ETA checkboxes are framed in red to indicate an error. Common causes include locking incompatible combinations (such as locking speed for all waypoints while also locking ETA for start and end) or specifying ETAs that require speeds outside the aircraft's flight envelope.

### Altitude Settings

Aircraft waypoints include altitude configuration with two reference systems:

**MSL (Mean Sea Level)** sets the altitude as a constant height above sea level. The aircraft maintains level flight at the specified altitude regardless of terrain below. This is appropriate for high-altitude cruise flight but can result in terrain collisions if the MSL altitude is set below the terrain elevation along the route.

**AGL (Above Ground Level)** sets the altitude as a height above the terrain directly below the aircraft. This creates terrain-following flight where the aircraft climbs and descends to maintain a consistent clearance above the ground. AGL altitude is appropriate for low-level flight through varied terrain.

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

**Note:** The Cyclone/Anticyclone baric system settings are part of the legacy non-dynamic weather system and should not be used in new missions. New missions should use weather presets instead. <!-- TODO: UNCLEAR - Clarify the relationship between Dynamic Weather section heading and this legacy note - the section is titled "Dynamic Weather" but describes baric systems as legacy -->

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

Mission building involves two fundamental approaches to controlling AI behavior. The simple approach relies on placing units and routes with minimal configuration, allowing the AI to behave according to its default programming based on unit type and proximity to enemies. The advanced approach uses the Advanced Actions Panel to manually configure specific tasks, enroute tasks, commands, and options for precise control over AI behavior.

Actions are set for entire groups rather than individual units within a group. The group leader determines when actions activate based on reaching waypoints or satisfying trigger conditions. Understanding the four categories of actions is essential for effective AI scripting.

### Action Types

**Perform Task** actions are primary combat engagements, targeting operations, and maneuvering behaviors. When a Perform Task is set, the AI executes a specific combat function such as orbiting at a location, attacking a designated target, or acting as a forward air controller. Tasks have the highest execution priority and are generally used to set the primary group action for each waypoint. The AI performs multiple tasks sequentially according to their order or priority setting. Task execution ends either automatically (for example, when all designated targets are destroyed) or according to stop conditions set by the mission designer.

**Start Enroute Task** actions are similar to Perform Tasks in that they involve targeting or engagement, but they remain active for the duration of the group's route rather than executing once at a waypoint. Enroute Tasks handle "pop-up" situations where the AI should respond to targets of opportunity as they are detected along the route. The key distinction is that Perform Tasks involve known, pre-set targets while Enroute Tasks allow uncertainty in target type or location. Multiple Enroute Tasks can be active simultaneously, but only one executes at a time based on priority when conditions for several are true. Perform Tasks always take priority over concurrent Enroute Tasks unless manually overridden.

**Perform Command** actions are instantaneous group actions executed immediately upon activation. Examples include changing the group's radio frequency or switching navigation lights. Commands do not involve sustained behavior; they simply apply a change and complete.

**Set Option** actions establish rules and limitations for the group that persist for the mission duration or until changed. Options control behaviors such as formation, radar usage, weapons release authority, and reaction to threats. They use a variable-value format such as setting Formation to Trail or Radar Use to Never.

### Action Priority

The priority system determines which action the AI executes when multiple actions are available. Priority is expressed as a whole number starting with 0 as the highest priority. When conditions for multiple tasks are satisfied, the AI selects the one with the lowest priority number.

Perform Tasks always take precedence over Enroute Tasks by default. An Enroute Task can be interrupted by a Perform Task and resumed after the task completes. Triggered tasks (set through the trigger menu rather than at waypoints) have higher priority than waypoint tasks.

### Action Activation

Waypoint-based actions activate when the group leader reaches the associated waypoint. Actions are then performed sequentially based on their order in the action list or their priority settings. Actions can also be activated independently of waypoints through the trigger menu, in which case they execute when the trigger conditions are met rather than at a specific route position.

### Start/Stop Conditions

All actions support conditions that control when they begin and end. Start conditions include mission time (the action activates at a specific time), flag state (the action activates when a flag is true or false), activation probability (a percentage chance the action activates), and Lua predicates (custom scripting logic). Stop conditions include duration time limits, mission time limits, flag states, and reaching the last waypoint. If no stop conditions are set for an Enroute Task, it remains active for the duration of the group's existence in the mission.

### Aircraft Tasks

Aircraft groups have the most extensive task options. The group-level task setting (Nothing, AFAC, Anti-ship Strike, AWACS, CAP, CAS, Escort, Fighter Sweep, Ground Attack, Intercept, Pinpoint Strike, Reconnaissance, Refueling, Runway Attack, SEAD, Transport) serves as a filter that determines which actions are available in the Advanced Actions Panel and which default payload packages are offered.

Common Perform Tasks for aircraft include Orbit (hold position in a pattern), Attack Group and Attack Unit (engage specified targets), Bombing and Carpet Bombing (attack ground targets), Escort and Follow (accompany another group), Ground Escort (protect ground units), FAC - Assign Group (act as forward air controller for a unit), Land (land at a location), and Refueling (refuel from a tanker).

Common Enroute Tasks for aircraft include the Search Then Engage variants (automatically engage detected targets matching criteria), AWACS (provide early warning and control), Tanker (refuel requesting aircraft), and FAC/FAC - Engage Group (forward air controller operations along the route).

### Ground Unit Tasks

Ground units have a more limited but still useful set of tasks. Perform Tasks include Hold (stop movement and hold position), Fire at Point (engage a map location), FAC - Assign Group (designate targets as a forward air controller), and Go to Waypoint (proceed to a specific waypoint out of sequence).

Enroute Tasks for ground units include FAC and FAC - Engage Group for forward air controller operations during movement.

### Naval Unit Tasks

Naval units support Perform Tasks including Fire at Point and Attack Group for engaging surface and land targets. The command and option structure is similar to aircraft groups.

### Further Reference

The tasks, commands, and options available in the Mission Editor can also be assigned dynamically through Lua scripting. See the [Simulator Scripting Engine](simulator-scripting-engine.md) AI Control section for detailed documentation of task definitions, parameters, and the programmatic API for controlling AI behavior.

## Briefing Creation

The briefing panel includes:
- **Sortie**: Mission title
- **Coalition lists**: Automatically populated from assigned countries
- **Briefing images**: Custom images for RED and BLUE sides (recommended 1024x1024 pixels, JPG/PNG format)
- **Situation text**: General mission briefing
- **RED/BLUE Task text**: Coalition-specific objective descriptions

Custom kneeboard cards can be added by placing images in the `Saved Games\DCS\Kneeboard\[aircraft_name]\` folder.

## Mission Options

Mission-level options can be enforced on players. These settings control gameplay realism, assistance features, and environmental factors.

### Easy Communication

Always disable Easy Communication. This option simplifies radio communication by automatically tuning frequencies and bypassing proper radio procedures, but it breaks many scripting features and third-party tools that rely on proper radio simulation. Scripts that monitor radio frequencies, trigger events based on radio calls, or implement custom ATC systems will malfunction when Easy Communication is enabled. Even casual players encounter problems with this setting enabled, as popular mods and server-side features depend on the standard radio behavior.

### Civilian Traffic

This setting controls the density of civilian vehicles on roads. Civilian traffic in DCS is entirely oblivious to combat operations, which creates immersion problems in mission scenarios. Civilian cars will drive directly through tank columns, appear on thermal imaging alongside military targets, and generally ignore the fact that a war is happening around them. Disable civilian traffic in combat missions to avoid these immersion-breaking situations. The option is suitable only for peacetime scenarios or missions where ground combat is not a factor.

### Bird Strikes

Disable bird strikes. Despite the name, DCS does not render flocks of birds that pilots could see and avoid. Instead, this option simply applies a random chance of engine failure at low altitudes with no visual indication of what caused it. The result feels like arbitrary bad luck rather than a realistic hazard, since there is nothing the pilot could have done differently to prevent it.

### Other Options

Additional mission options include:
- **Permit Crash Recovery**: Allow players to respawn after crashes
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

Mission file format stored as a ZIP archive containing mission data and resources. See [MIZ File Format](miz-file-format.md) for complete documentation of the archive structure and contents.

### TRK Files (Track Recordings)

Track files record gameplay sessions for later playback. Their primary design purpose is reproducing bugs in bug reports to help developers diagnose issues, rather than perfectly capturing gameplay footage or preserving mission recordings.

A .trk file internally contains a complete copy of the MIZ file from which it was generated. This means track files can be opened directly in the Mission Editor to examine the mission setup that produced the recording.

Track files do not store the actual events that occurred during gameplay. Instead, they record the inputs provided by players and AI, then replay the mission from the beginning using those inputs. Because the simulation contains non-deterministic elements (random numbers, floating-point timing variations, AI decision-making), replayed tracks can diverge from what actually happened during the original session. A missile that hit its target in the original flight might miss during playback, or an AI aircraft might make different tactical decisions.

This divergence accumulates over time. Tracks typically remain reasonably accurate for the first few minutes but become increasingly unreliable the longer they run. A track recording of an hour-long mission will likely show significant differences from the original flight by the end.

Multiplayer track files generated by dedicated servers tend to be more reliable than those recorded in singleplayer.

## Further Reading

For advanced mission scripting capabilities beyond the GUI editor, see the Simulator Scripting Engine documentation which covers Lua-based mission scripting for complex scenarios that cannot be achieved through the Mission Editor alone.

<!-- TODO: MISSING - Document common mission testing/debugging workflows -->

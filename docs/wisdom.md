# Mission Design Wisdom

This document collects general mission-making tips and best practices that don't fit neatly into a specific recipe.

## Performance Considerations

The scripting engine is unreliable immediately after a mission starts while game assets are still loading. Mission scripts should be delayed by at least 5 seconds after mission start, and possibly longer for players on slower machines.

Too many blocking script calls can cause DCS to freeze or stutter. For large amounts of work, chunk the work into small batches and periodically release control back to the game. A callback execution model similar to the Node.js event loop can be a useful design pattern for this.

Keep total unit counts under 1000.[^unit-limits] Above this threshold, the scripting engine becomes unreliable, and somewhere before 2000 units it fails entirely—scripts may not execute at all. For large-scale battles, spawn units dynamically as players approach rather than placing everything at mission start.

Ground unit AI pathfinding is expensive regardless of terrain. Whether units are on roads or cross-country, in open fields or urban areas, any movement commands consume significant resources. Limit pathfinding to a small number of groups, and keep their routes simple.

Smoke and fire effects have a noticeable performance cost. A few burning vehicles add atmosphere, but large numbers will degrade framerate.

Static objects and vehicles placed as airbase or carrier decoration add visual interest, but more than a handful will hurt multiplayer performance.

## Difficulty and Balancing

Avoid requiring players to launch by a specific time. Equipment problems, software issues, and rusty startup procedures are common, especially in public servers. Time pressure works for private squadrons with regular training, but frustrates pickup groups.

Bias toward easier encounters. DCS has a steep learning curve, and even experienced players make mistakes under pressure. A SAM or beyond-visual-range missile they didn't see coming ends their session abruptly. Use older or less capable enemy equipment and lighter defenses to give players room to recover from errors.

Air-to-air combat is difficult, and most players are not particularly good at it. A handful of enemy fighters provides a meaningful challenge for the average group. Resist the urge to spawn large opposing forces—two or four bandits will keep players busy, while a dozen will slaughter them.

One well-designed, layered SAM site creates a more engaging SEAD/DEAD experience than multiple scattered batteries. A single complex site with overlapping coverage, point defense, and supporting assets gives players a tactical puzzle to solve—they must identify components, plan an attack sequence, and execute precisely. Several isolated SAM sites just mean repeating the same attack pattern in different locations, which quickly becomes tedious.

Populate target areas generously with ground vehicles. After players have fought through enemy air defenses and interceptors, destroying soft targets is their reward. A convoy of trucks, a motor pool full of APCs, or an artillery battery provides satisfying explosions and a sense of accomplishment. Sparse target areas feel anticlimactic after a difficult ingress.

Keep objectives simple, especially for multiplayer. Complex strike requirements and intricate success conditions become exponentially harder to achieve as player count increases. For large groups, straightforward goals work best—destroying enemies in a target area requires no coordination beyond showing up. Reserve elaborate multi-step objectives for singleplayer or small cooperative sessions where communication is manageable.

Design missions for a focused set of similar aircraft rather than trying to accommodate every flyable module. When player slots span everything from the A-10C to the F-16, balancing becomes nearly impossible. An air defense network that challenges a Hornet pilot will annihilate a Huey; a target set appropriate for an attack helicopter is trivial for a fast jet with standoff weapons. Speed differences alone create problems—a mixed formation of Viggens and Tucanos cannot realistically coordinate timing over a target. Adding helicopters to a fixed-wing mission compounds the difficulty further, since rotary-wing aircraft operate at completely different altitudes, speeds, and ranges, and require their own threat environments and objectives to feel meaningful. Tanker placement, waypoint distances, and threat rings must all be tuned differently for each aircraft class. Briefings grow unwieldy when they must explain five different approach profiles. A mission built around fourth-generation fighters, or around attack helicopters, or around warbirds will always play better than one that attempts to serve everyone equally. If variety is essential, consider separate objective areas tailored to each aircraft category rather than forcing all platforms through the same scenario.

## Communications

Configure radio presets for all player aircraft and document a communications plan in the briefing. Players should not have to manually tune frequencies in the cockpit to coordinate with their flight or contact support assets. At minimum, provide a strike-wide common frequency for package coordination and dedicated interflight frequencies so wingmen within each flight can communicate without cluttering the main channel. Include tanker and JTAC frequencies as appropriate. A clear frequency card in the briefing transforms a chaotic radio environment into organized communication.

Avoid relying on DCS's built-in ATC and AWACS—both are poorly implemented and frustrating to use. For AWACS functionality, external tools like SkyEye[^skyeye] provide a far superior experience with realistic GCI calls and proper brevity. For ATC, players generally coordinate landing order themselves over common frequencies or simply use the airfield visually.

## AI Behavior

DCS AI aircraft are notoriously poor at fuel management. They fly at inefficient throttle settings and often run dry long before completing their assigned routes. A practical workaround is to give AI aircraft partial fuel loads for realistic weight and performance, then use the [`SetUnlimitedFuel`](scripting/reference/ai/commands.md#setunlimitedfuel) command to prevent them from flaming out mid-mission.

AI pilots set to Ace skill are highly consistent, which paradoxically makes them feel robotic and predictable after a few engagements. Mixing skill levels among enemy flights—or randomizing skills—introduces variety that makes combat feel less formulaic. Stick to the upper skill tiers, though. Lower skill levels introduce erratic behavior where AI will inexplicably stop maneuvering or make suicidal decisions mid-fight, breaking immersion rather than providing an easier challenge.

## Engine Quirks and Workarounds

DCS World has accumulated various quirks, bugs, and undocumented behaviors over its long development history. These issues affect mission makers and scripters; understanding them helps avoid frustration and wasted debugging time.

### Airfield Parking Bugs

Certain parking slots on specific maps are broken and cause aircraft to fail to spawn, get stuck, or collide with terrain.

**Nevatim Airfield (Sinai):** Only parking slots 55-66 work reliably. All other ramp starts frequently fail due to persistent bugs in the airfield definition.[^nevatim-bugs]

**Ramon Airbase (Sinai):** Parking slots 1-6, 13-18, and 61 are broken. Aircraft spawning in these slots will fail or behave erratically.[^ramon-bugs] Filter these slots when programmatically selecting spawn locations.

**Kerman Airfield (Persian Gulf):** This is the highest-elevation airfield in the Persian Gulf map at approximately 5,700 feet MSL. When spawning aircraft in flight, remember that altitude values are referenced to mean sea level. An aircraft spawned at "2000 meters altitude" will be below ground level at Kerman. Always account for terrain elevation when calculating in-flight spawn altitudes on this map.

### Aircraft Spawn Issues

**AI Parking Starts Are Unreliable:** AI aircraft starting from parking positions—at airfields, FARPs, or carriers—frequently experience pathfinding failures. They may get stuck taxiing, collide with obstacles, or never reach the runway. For maximum reliability, spawn AI aircraft with runway or catapult starts rather than parking starts. Reserve parking spawns for player aircraft where the human can resolve any issues.

**Carrier Spawns Deadlock at Time Zero:** Aircraft configured to spawn on a carrier at mission time 0 (the exact start time) can deadlock on the flight deck, failing to launch. The workaround is simple: set the spawn time to mission start plus 1 second rather than exactly 0.

**Large Aircraft Need Large Parking Slots:** Aircraft with wingspan exceeding approximately 40 meters (such as the C-130 Hercules) may fail to spawn in standard parking slots. When programmatically assigning parking positions, attempt large parking spots first, then fall back to standard ramp slots if large spots are unavailable.

### Ground Unit Behavior

**Vehicle Movement Heading Bug:** DCS does not reliably command vehicles to move when their target waypoint heading exactly matches their current heading. If a vehicle is facing north and you assign a waypoint requiring it to face north, it may not move. The workaround is to offset waypoint headings by a small amount—typically negative one degree—to ensure the vehicle recognizes that movement is required.

### Coordinate System Quirks

**Unit Offset X/Y Reversal:** When calculating unit positions as offsets from a group center using heading-based rotation, the X and Y coordinates appear to be reversed relative to expected mathematical conventions. Transformation code must apply backward rotation (using `PI - heading` rather than `heading`) to place units correctly. This affects mission generators and scripts that programmatically position units in formations.

### Scripting Engine Hazards

**Destroyed Unit References Crash Scripts:** Accessing properties of destroyed units can crash the scripting engine. Always validate that a unit exists and is alive before calling methods on it. Use [`unit:isExist()`](scripting/reference/classes/object.md#objectisexist) checks and guard against nil returns from functions like [`Unit.getByName()`](scripting/reference/classes/unit.md#unitgetbyname).

**Group Access Fails in Event Handlers:** Within event handlers, calling `Group.getByName()` for a unit's group sometimes returns nil even when the group should exist. This appears to be a timing or caching issue. Scripts must handle this gracefully with nil checks rather than assuming the group lookup will succeed.

**Generic Crash Model Objects:** When units are destroyed, DCS creates "GENERIC_CRASH_MODEL" objects representing the wreckage. Scripts that track objects in the world—such as those monitoring unit counts or iterating over all objects—should filter out these crash models to avoid counting destroyed units as living objects.

**Spawn Confirmation Is Asynchronous:** When spawning groups via the scripting API, the spawn operation is asynchronous. The function returns immediately, but the group may not be accessible for a brief period afterward. Do not attempt to access or manipulate a newly spawned group in the same script block that spawned it; use [`timer.scheduleFunction()`](scripting/reference/singletons/timer.md#timerschedulefunction) to defer follow-up operations by at least one second.

### Engine Crashes

Several DCS features can cause the game to crash under specific circumstances. These crashes may occur during mission execution and can disrupt multiplayer servers.

**Static Object Destruction:** In some DCS versions, destroying static objects via scripting can cause the game to crash. Scripts that destroy static objects should handle this defensively, and mission designers should test static destruction thoroughly before deploying to multiplayer servers.

**Sling-Loading Instability:** Helicopter sling-loading operations can cause crashes in some configurations, particularly in multiplayer. Scripts that use sling-loading should consider offering a simulated alternative (hover-based loading without physics) for stability.

**F-16C Datalink on Dedicated Servers:** Missions containing F-16C Block 50 aircraft using datalink have caused crashes on dedicated servers. The workaround is to re-save the mission in the DCS Mission Editor after any changes; this appears to resolve whatever data corruption causes the crash.

### Geometry and Zone Issues

**Polygon Winding Order Bug:** DCS expects polygon zones to use clockwise vertex ordering, but the engine sometimes returns zone coordinates in counter-clockwise order. Scripts processing zone geometry should detect the winding order (by calculating the signed area) and reverse the point order if the polygon is counter-clockwise.

**Quad Zones Have Limited Support:** Circular trigger zones work reliably for most operations, including scenery removal. Quad (rectangular) zones may load without errors but misbehave in certain contexts. Prefer circular zones when reliability is critical.

**NavMesh Range Cap:** The pathfinding system (NavMesh) has difficulty with threat ranges exceeding 400 kilometers. Scripts that calculate threat areas or pathfinding avoidance zones should cap maximum threat range values at 400 km to avoid calculation failures or performance issues.

**Drawing Polygon Point Restrictions:** The DCS drawing API restricts zone polygons to exactly 1, 4, 8, or 16 points. Polygons with other point counts will fail or fall back to single-point rendering. Scripts generating dynamic zone visualizations must validate point counts before creating polygon drawings.

### Multiplayer-Specific Issues

**Scenery Removal Is Unreliable in Multiplayer:** The "SCENERY REMOVE OBJECTS ZONE" trigger action does not work reliably in multiplayer sessions.[^scenery-removal] Static objects removed via this trigger may remain visible or collidable for some clients. Using FARPs to clear areas or avoiding dynamic scenery removal improves reliability.

### Task and Mission Assignment Limitations

**S-3B Viking Cannot Execute OCA/Aircraft:** The S-3B Viking is coded in DCS as an anti-ship aircraft and cannot execute Offensive Counter Air (OCA) aircraft attack tasks. If you need an S-3B to engage aircraft, use the Anti-Ship Strike task as a fallback—though this is a workaround for an aircraft limitation rather than correct behavior.

**Radar-Guided AAA Lacks Max Firing Height:** Radar-guided anti-aircraft artillery units (like the Shilka) do not expose a maximum firing height parameter in their unit definitions. When scripts need to estimate AAA engagement envelopes, use the weapon's vertical range as a substitute for the missing parameter.

## References

[^unit-limits]: Community discussions suggest 800-1,000 units is a practical ceiling for mission stability. See [Maximum units for a mission?](https://forum.dcs.world/topic/132003-maximum-units-for-a-mission/) on the DCS Forums.

[^skyeye]: SkyEye is a self-hostable AI-powered GCI bot that provides realistic AWACS functionality using modern voice recognition and proper brevity. See the [SkyEye GitHub repository](https://github.com/dharmab/skyeye) and the [DCS Forums announcement thread](https://forum.dcs.world/topic/345389-skyeye-ai-powered-gci-bot-talk-to-your-awacs-over-srs/).

[^nevatim-bugs]: Multiple bug reports document Nevatim parking issues: [2.9 Nevatim ramp starts still bugged](https://forum.dcs.world/topic/335545-29-nevatim-ramp-starts-still-bugged), [Nevatim Parking spots 8-22 cannot accommodate large aircraft](https://forum.dcs.world/topic/356219-nevatim-parking-spots-8-22-cannot-accommodate-large-aircraft/), and [NEVATIM TAXI ROUTES](https://forum.dcs.world/topic/379511-nevatim-taxi-routes/).

[^ramon-bugs]: Ramon Airbase issues are documented in [Ramon Airbase taxiways and parking spots](https://forum.dcs.world/topic/343531-ramon-airbase-taxiways-and-parking-spots/) and [Sticky Tarmac at Ramon Airbase](https://forum.dcs.world/topic/364031-sticky-tarmac-at-ramon-airbase/).

[^scenery-removal]: Multiple bug reports confirm this issue: [Scenery Remove Objects Zone (not working in multiplayer)](https://forum.dcs.world/topic/199108-scenery-remove-objects-zone-not-working-in-multiplayer/), [SCENERY REMOVE OBJECTS ZONE and dedicated server](https://forum.dcs.world/topic/266304-scenery-remove-objects-zone-and-dedicated-server/), and [Scenery remove in area action does not work for clients](https://forum.dcs.world/topic/188083-reportedscenery-remove-in-area-action-does-not-work-for-clients).

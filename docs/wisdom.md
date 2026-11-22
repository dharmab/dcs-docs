# Mission Design Wisdom

This document collects mission design tips that don't fit into a specific recipe.

## Performance Considerations

Keep total unit counts under 1000.[^unit-limits] Above this threshold, the scripting engine becomes unreliable, and somewhere before 2000 units it fails entirely, so scripts may not run at all. For large-scale battles, spawn units dynamically as players approach rather than placing everything at mission start.

Ground unit AI pathfinding is expensive on any terrain. Movement commands consume significant resources whether units are on roads or cross-country, in open fields or urban areas. Limit pathfinding to a small number of groups, and keep their routes simple.

Smoke and fire effects have a noticeable performance cost. A few burning vehicles add atmosphere, but large numbers will degrade framerate.

Static objects and vehicles placed as airbase or carrier decoration add visual interest, but more than a handful will hurt multiplayer performance.

## Difficulty and Balancing

Avoid requiring players to launch by a specific time. Equipment problems, software issues, and rusty startup procedures are common, especially in public servers. Time pressure works for private squadrons with regular training, but frustrates pickup groups.

Bias toward easier encounters. DCS has a steep learning curve, and even experienced players make mistakes under pressure. A SAM or beyond-visual-range missile they didn't see coming ends their session abruptly. Use older or less capable enemy equipment and lighter defenses to give players room to recover from errors.

Air-to-air combat is difficult, and most players are not particularly good at it. A handful of enemy fighters provides a meaningful challenge for the average group. Resist the urge to spawn large opposing forces—two or four bandits will keep players busy, while a dozen will slaughter them.

One well-designed, layered SAM site creates a more engaging SEAD/DEAD experience than multiple scattered batteries. A single complex site with overlapping coverage, point defense, and supporting assets requires players to identify components, plan an attack sequence, and execute it precisely. Several isolated SAM sites just mean repeating the same attack pattern in different locations, which quickly becomes tedious.

Populate target areas generously with ground vehicles. After players have fought through enemy air defenses and interceptors, destroying soft targets is their reward. A convoy of trucks, a motor pool full of APCs, or an artillery battery provides satisfying explosions and a sense of accomplishment. Sparse target areas feel anticlimactic after a difficult ingress.

Keep objectives simple, especially for multiplayer. Complex strike requirements and success conditions become much harder to achieve as player count increases. For large groups, straightforward goals work best: destroying enemies in a target area requires no coordination beyond showing up. Reserve elaborate multi-step objectives for singleplayer or small cooperative sessions where communication is manageable.

Design missions for a focused set of similar aircraft rather than trying to accommodate every flyable module. When player slots span everything from the CH-47 to the F-16, balancing becomes nearly impossible. An air defense network that challenges a Hornet pilot will destroy a Huey; a target set appropriate for an attack helicopter is trivial for a fast jet with standoff weapons. Speed differences alone create problems: a mixed formation of Viggens and Tucanos cannot realistically coordinate timing over a target. Adding helicopters to a fixed-wing mission compounds the difficulty further, since rotary-wing aircraft operate at completely different altitudes, speeds, and ranges, and require their own threat environments and objectives to feel meaningful. Tanker placement, waypoint distances, and threat rings must all be tuned differently for each aircraft class. Briefings grow unwieldy when they must explain five different approach profiles. A mission built around fourth-generation fighters, or around attack helicopters, or around warbirds will always play better than one that attempts to serve everyone equally. If variety is essential, consider separate objective areas tailored to each aircraft category rather than forcing all platforms through the same scenario.

## Communications

Configure radio presets for all player aircraft and document a communications plan in the briefing. Players should not have to manually tune frequencies in the cockpit to coordinate with their flight or contact support assets. At minimum, provide a strike-wide common frequency for package coordination and dedicated interflight frequencies so wingmen within each flight can communicate without cluttering the main channel. Include tanker and JTAC frequencies as appropriate. A clear frequency card in the briefing keeps radio traffic organized.

Avoid relying on DCS's built-in ATC and AWACS. Both are poorly implemented and frustrating to use. For AWACS, external tools like SkyEye[^skyeye] provide realistic GCI calls and proper brevity. For ATC, players generally coordinate takeoffs, the traffic pattern, and landing order themselves over common frequencies, or watch for other traffic and sequence themselves visually.

## AI Behavior

DCS AI aircraft are poor at fuel management. They fly at inefficient throttle settings and often run dry long before completing their assigned routes. A practical workaround is to load AI aircraft with partial fuel for realistic weight and performance, then use the [`SetUnlimitedFuel`](scripting/reference/ai/commands.md#setunlimitedfuel) command to prevent them from flaming out mid-mission.

AI pilots set to Ace skill are highly consistent, which makes them feel robotic and predictable after a few engagements. Mixing or randomizing skill levels among enemy flights makes combat less formulaic. Stick to the upper skill tiers, though. At lower skill levels, AI will sometimes stop maneuvering or make suicidal decisions mid-fight, which breaks immersion instead of making the fight easier.

## Known Crashes

**Sling-Loading Instability:** Helicopter sling-loading can crash the game, especially in multiplayer. Consider a simulated alternative (hover-based loading without physics) for stability.

**F-16C Datalink on Dedicated Servers:** Missions with F-16C Block 50 aircraft using datalink have crashed dedicated servers. Re-saving the mission in the Mission Editor after any change appears to fix it.

## References

[^unit-limits]: Community discussions suggest 800-1,000 units is a practical ceiling for mission stability. See [Maximum units for a mission?](https://forum.dcs.world/topic/132003-maximum-units-for-a-mission/) on the DCS Forums.

[^skyeye]: SkyEye is a self-hostable GCI bot that uses voice recognition and proper brevity. See the [SkyEye GitHub repository](https://github.com/dharmab/skyeye) and the [DCS Forums announcement thread](https://forum.dcs.world/topic/345389-skyeye-ai-powered-gci-bot-talk-to-your-awacs-over-srs/).

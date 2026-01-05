# Mission Design Wisdom

This document collects general mission-making tips and best practices that don't fit neatly into a specific recipe.

## Performance Considerations

Keep total unit counts under 1000. Above this threshold, the scripting engine becomes unreliable, and somewhere before 2000 units it fails entirely—scripts may not execute at all. For large-scale battles, spawn units dynamically as players approach rather than placing everything at mission start.

Ground unit AI pathfinding is expensive regardless of terrain. Whether units are on roads or cross-country, in open fields or urban areas, any movement commands consume significant resources. Limit pathfinding to a small number of groups, and keep their routes simple.

Smoke and fire effects have a noticeable performance cost. A few burning vehicles add atmosphere, but large numbers will degrade framerate.

Static objects and vehicles placed as airbase or carrier decoration add visual interest, but more than a handful will hurt multiplayer performance.

## Difficulty and Balancing

Avoid requiring players to launch by a specific time. Equipment problems, software issues, and rusty startup procedures are common, especially in public servers. Time pressure works for private squadrons with regular training, but frustrates pickup groups.

Bias toward easier encounters. DCS has a steep learning curve, and even experienced players make mistakes under pressure. A SAM or beyond-visual-range missile they didn't see coming ends their session abruptly. Use older or less capable enemy equipment and lighter defenses to give players room to recover from errors.

Keep objectives simple, especially for multiplayer. Complex strike requirements and intricate success conditions become exponentially harder to achieve as player count increases. For large groups, straightforward goals work best—destroying enemies in a target area requires no coordination beyond showing up. Reserve elaborate multi-step objectives for singleplayer or small cooperative sessions where communication is manageable.

Design missions for a focused set of similar aircraft rather than trying to accommodate every flyable module. When player slots span everything from the A-10C to the F-16, balancing becomes nearly impossible. An air defense network that challenges a Hornet pilot will annihilate a Huey; a target set appropriate for an attack helicopter is trivial for a fast jet with standoff weapons. Speed differences alone create problems—a mixed formation of Viggens and Tucanos cannot realistically coordinate timing over a target. Adding helicopters to a fixed-wing mission compounds the difficulty further, since rotary-wing aircraft operate at completely different altitudes, speeds, and ranges, and require their own threat environments and objectives to feel meaningful. Tanker placement, waypoint distances, and threat rings must all be tuned differently for each aircraft class. Briefings grow unwieldy when they must explain five different approach profiles. A mission built around fourth-generation fighters, or around attack helicopters, or around warbirds will always play better than one that attempts to serve everyone equally. If variety is essential, consider separate objective areas tailored to each aircraft category rather than forcing all platforms through the same scenario.

## Communications

Configure radio presets for all player aircraft and document a communications plan in the briefing. Players should not have to manually tune frequencies in the cockpit to coordinate with their flight or contact support assets. At minimum, provide a strike-wide common frequency for package coordination and dedicated interflight frequencies so wingmen within each flight can communicate without cluttering the main channel. Include tanker and JTAC frequencies as appropriate. A clear frequency card in the briefing transforms a chaotic radio environment into organized communication.

Avoid relying on DCS's built-in ATC and AWACS—both are poorly implemented and frustrating to use. For AWACS functionality, external tools like SkyEye provide a far superior experience with realistic GCI calls and proper brevity. For ATC, players generally coordinate landing order themselves over common frequencies or simply use the airfield visually.


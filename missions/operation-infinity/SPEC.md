# Operation Infinity

Operation Infinity is a randomizer mission for DCS World for 1-12 players.

## Concept

Players spawn using Dynamic Slots at Krymsk airport in the northwest of the Caucasus map. After a few seconds, a hint tells the players to use the F10 command menu to select:

1. A difficulty setting
2. A target playtime

The first player to make both selections locks the settings for all players. Scripts within the mission will generate a battlefield that fits these parameters somewhere on the map. The scripts will then display the coordinates of the battlefield to all players in both MGRS and Lat/Lon format. The players are free to fly to that area and destroy whatever targets they can find.

This is a sandbox mission with no win condition. Players fly until they choose to stop.

## Setting

Players are the ISAF faction and the enemy is the Erusea faction. Map is Caucasus. ISAF has a foothold in the northwest (Anapa/Krymsk). ISAF troops are fighting throughout the region and ISAF is launching air support, interdiction and SEAD missions in support of ground troops. Erusea's HQ is in Tbilisi, and they have a major base at Mozdok. They also control other military airbases throughout the map such as Kobuleti, Kutaisi, and Sukhumi-Babushara.

## Player Aircraft

Players can choose from these aircraft using Dynamic Spawn templates at Krymsk (airdromeId 15):

| Aircraft | DCS Type String |
|----------|-----------------|
| F-4E Phantom II | F-4E-45MC |
| F-16C Viper | F-16C_50 |
| F-15E Strike Eagle | F-15ESE |
| F-15C Eagle | F-15C |
| MiG-29A Fulcrum | MiG-29A |
| F/A-18C Hornet | F/A-18C_hornet |
| A-10C Warthog | A-10C_2 |
| Mirage 2000C | M-2000C |
| Mirage F1 | Mirage-F1CE |
| F-14A Tomcat | F-14A-135-GR |
| F-14B Tomcat | F-14B |

Warehouse is configured for unlimited weapons of all types.

## Communications Plan

Use the standardized comm plan from `docs/recipes/comm-plan.md`:

| Purpose | Frequency | Notes |
|---------|-----------|-------|
| Tower | 254.1 MHz AM | Krymsk tower |
| Strike | 255.1 MHz AM | Package-wide coordination |
| GCI UHF | 255.3 MHz AM | Primary GCI - use with SkyEye |
| In-Game AWACS | 255.5 MHz AM | Fallback for DCS AI AWACS (datalink only) |
| Red 1-5 | 260.1-260.9 MHz AM | Flight internal |
| Blue 1-5 | 261.1-261.9 MHz AM | Flight internal |
| Green 1-5 | 262.1-262.9 MHz AM | Flight internal |
| Yellow 1-5 | 30.1-30.9 MHz FM | A-10/helo flights |
| Orange 1-5 | 31.1-31.9 MHz FM | A-10/helo flights |
| Basket Tanker | 270.1 MHz AM | KC-135MPRS drogue |
| Fighter Boom Tanker | 270.5 MHz AM | KC-135 boom |
| Military Guard | 243.0 MHz AM | Emergency |

Player aircraft radio presets should include Strike, GCI, appropriate flight tactical, and tanker frequencies.

## Multiplayer Rules

- First player to select both difficulty and playtime locks the settings
- Players can respawn unlimited times after death
- Late joiners are fully supported and receive target coordinates automatically
- No AI wingmen or friendly AI aircraft (ground forces only)

## Difficulty Settings

### Very Easy (Training)
Enemy is Erusea 2004 equipment. Ground targets only. Targets do not shoot back. No enemy fighters. No air defense systems. Suitable for training, practice, and learning aircraft systems.

### Easy
Enemy is Erusea 2004. Ground targets with light defenses:
- Small arms, scattered AAA guns (ZU-23, Shilka)
- MANPADS (Stinger, Igla) near high-value targets
- Single-vehicle SAMs not coordinated (SA-9, SA-13)
- 1-2 incomplete SA-2 batteries
- Enemy fighters: MiG-21Bis, F-5E, F-5E-3, A-10A with IR missiles only (R-60, AIM-9B)
- Enemy helicopters: Mi-24P, Mi-24V, Ka-50
- Max 2 enemy fighters airborne (scaled by player count/type)
- Fighter skill: Random from Average to Ace

### Normal
Enemy is Erusea 2004, with some rare appearances of Erusea 2005 equipment. Proper air defense network:
- Basic IADS with EWRs (1L13, P-19)
- SA-2, SA-3 batteries with proper composition
- SA-6 mobile batteries
- SA-8 Osa SHORAD
- AAA: Shilka, Gepard batteries
- Roland ADS near key locations
- Enemy fighters: MiG-29A, MiG-29S, Mirage 2000-5, F-16A, Tornado IDS with IR and semi-active radar guided missiles (R-73, R-27R)
- Enemy helicopters: Mi-24P, Ka-50, AH-64A
- Max 4 enemy fighters airborne (scaled by player count/type)
- Fighter skill: Random from Average to Ace

### Hard
Enemy is Erusea 2005. Modern threat environment with layered IADS:
- Emission-controlled IADS with coordinated radar coverage
- SA-10 battery with SA-15 SHORAD protection
- SA-11 Buk batteries
- Multiple SA-6, SA-8 sites
- Heavy AAA coverage
- Enemy fighters: F-15C, F-15E, F/A-18A, F/A-18C, F-16C, Su-27, J-11A, F-14A with active radar guided missiles (AIM-120, R-77)
- Enemy helicopters: AH-64D, Ka-50
- Max 6 enemy fighters airborne (scaled by player count/type)
- Fighter skill: Random from Average to Ace

### Dynamic Max Airborne

Max airborne enemy fighters scales based on players in the combat area, weighted by aircraft type:

| Player Aircraft Category | Weight |
|-------------------------|--------|
| A-A Fighters (F-15C, F-14A/B) | 2.0 |
| Multirole (F-16C, F/A-18C, MiG-29A, M-2000C, F-15E, F-4E) | 1.5 |
| Attack/CAS (A-10C, Mirage F1) | 0.5 |

Formula: `baseMax + floor(log2(weightedPlayerCount + 1))`, capped at 8.

## Playtime

### 45 Minutes (Close Air Support)
Fast CAS missions near the player airbase. Battlefield generated in the Anapa/Novorossiysk area (center approximately X=-40000, Y=320000, radius 30km). Short transit, more time on target.

### 90 Minutes (Interdiction)
Air support, interdiction and SEAD missions in the middle of the Caucasus map. Battlefield generated in the Sukhumi/Zugdidi area (center approximately X=-220000, Y=560000, radius 50km).

### 180 Minutes (Deep Strike)
Deep strike missions into the eastern and extreme areas of the map. Battlefield generated in the Kutaisi/Tbilisi region (center approximately X=-290000, Y=700000, radius 60km). Long transit, tanker support recommended.

## Air Defense Details

On lower difficulties the Erusean air defenses are scattered, mostly single vehicles that aren't well coordinated. As difficulties increase the Eruseans gain a basic air defense network with coordination, EWRs, and short and mid range SAMs. It's not an impenetrable long-range air defense network, but rather a flawed network with vulnerabilities being operated in an intelligent and unpredictable way.

EWRs (1L13, P-19) are always present at mission start across Erusean territory since their radars are detectable from over 100 nautical miles away. SAM tracking radars are also spawned at mission start.

On Normal and Hard difficulties, the IADS script controls radar emissions:
- EWRs always active
- Search radars pulse on/off when threats detected
- Tracking radars activate when targets enter engagement range

## Ground Units

### Frontline Firefight

Generate 3-5 frontline fighting areas spread across the battlefield zone. Each area represents a contested sector with active combat.

**Per Fighting Area** (each has 2-3 platoon engagements):

**ISAF Platoon** (immortal/invisible per ground-firefight recipe):
- 2x M-1 Abrams
- 2x M-2 Bradley
- 1x M163 Vulcan (tracers for visual effect)

**Erusea Platoon** (vulnerable - valid targets):
- 2x Leclerc
- 2x Marder
- 1x Gepard or ZSU-23-4 Shilka

**Layout**:
- 2-3 ISAF platoons facing 2-3 Erusea platoons per fighting area
- Platoons positioned 500-1000m apart along the front
- Each pair uses FireAtPoint task with 50-100m offset for sustained but non-lethal exchange

**SHORAD Coverage** (separate groups):
- 1-2x Ural-375 ZU-23 per fighting area
- MANPADS teams near Erusean positions (difficulty-dependent)

**Total**: 15-25 ISAF platoons (immortal), 15-25 Erusea platoons (targets), creating a visually active warzone.

### Behind-Lines Targets

**Logistics Convoys** (virtualized):
- 4-6x Ural-375
- 1-2x BRDM-2
- 1x Ural-375 ZU-23 (escort)

**Artillery Batteries**:
- 4x SAU Akatsia
- 1x Ural-375 (ammo)
- 1x BRDM-2 (command)

**Air Assets** (virtualized behind lines):
- CH-47D Chinooks on transport missions (soft targets)
- AH-64 attack patrols near frontline

**Scattered Presence** (throughout Erusean territory):
- Random patrol vehicles
- Checkpoint clusters
- Occasional helicopter patrols (Mi-24P, Ka-50, AH-64A)

### Unit Virtualization

To stay under the 800-1000 unit limit for scripting stability:
- Most ground units are "virtual" - tracked in scripts but not spawned
- Units spawn when any player approaches within 100 nautical miles
- Units despawn when all players are beyond 120 nautical miles (hysteresis prevents flapping)
- Unit health tracked as float (0.0-1.0 ratio of current/max life)
- Health preserved across spawn/despawn cycles using `unit:getLife()` / `unit:getLife0()`
- EWRs and SAM radars are always spawned (detectable at extreme range)

## Enemy Aircraft

Erusean interceptors spawn dynamically from their airfields when players enter defense zones:

| Airfield | Zone Radius |
|----------|-------------|
| Mozdok | 50 km |
| Tbilisi-Lochini | 45 km |
| Kutaisi | 45 km |
| Kobuleti | 40 km |
| Sukhumi-Babushara | 50 km |

Spawn cooldown: 120 seconds between waves from the same airfield.

Response scaling (errs on easier side):
- 1-2 players in zone: 1 interceptor
- 3 players: 2 interceptors
- 4 players: 3 interceptors
- 5+ players: 4 interceptors (maximum per wave)

## Support Assets

### AWACS
E-3A "Overlord" on east-west racetrack pattern northwest of Krymsk at 30,000 ft. Oriented to cover the southeast threat axis. EPLRS enabled for datalink contacts (primary purpose). Frequency: 255.5 MHz AM.

Note: DCS AI AWACS radio is poor quality and only serves as a fallback. Players should use SkyEye on 255.3 MHz for actual GCI.

### Tankers
Both tankers orbit near Anapa on racetrack patterns.

**KC-135 "Texaco"** (boom refueling):
- For: F-15E, F-16C, A-10C, F-4E
- Altitude: 25,000 ft
- Frequency: 270.5 MHz AM
- TACAN: 100X

**KC-135MPRS "Arco"** (basket refueling):
- For: F/A-18C, F-14A/B, M-2000C, Mirage F1
- Altitude: 22,000 ft
- Frequency: 270.1 MHz AM
- TACAN: 101X

## Weather and Time

**Time of Day**: Random between 0700-1700 local (daylight hours only)

**Weather**: Light randomization
- Cloud preset: Clear or partly cloudy only
- No fog, dust storms, or heavy precipitation
- Visibility: 80+ km
- Temperature: 15-25 C (seasonal)
- Wind: Light, 0-15 knots

## Technical Notes

### F10 Menu Structure
```
F10 Other
├── Mission Settings
│   ├── Difficulty
│   │   ├── Very Easy (Training - no enemies shoot back)
│   │   ├── Easy
│   │   ├── Normal
│   │   └── Hard
│   └── Playtime
│       ├── 45 Minutes (CAS - targets near Krymsk)
│       ├── 90 Minutes (Interdiction - central Caucasus)
│       └── 180 Minutes (Deep Strike - eastern Caucasus)
```

### Late Joiner Support
Timer function checks every 60 seconds for new players. If mission is already generated, late joiners receive:
- Target coordinates via text message
- Addition to EPLRS datalink network

### Performance Targets
- Maximum 800 units spawned at any time
- Stationary ground units (no pathfinding except convoys)
- Limited smoke/fire effects
- SAM sites do not relocate

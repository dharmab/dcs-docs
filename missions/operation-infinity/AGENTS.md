# Operation Infinity - Technical Specification

This document provides technical details for AI agents generating or modifying the Operation Infinity mission.

## Mission Structure

Players spawn via Dynamic Slots at Krymsk (airdromeId 15) or on the CVN-74 Stennis (ship warehouse keyed by unitId 20; carrier types only). On load, an F10 menu allows selection of difficulty and playtime. First player to select both locks settings. Scripts generate a randomized battlefield and display coordinates to players.

## Player Aircraft

| Aircraft | DCS Type String |
|----------|-----------------|
| F-4E Phantom II | F-4E-45MC |
| F-16C Viper | F-16C_50 |
| F-15E Strike Eagle | F-15ESE |
| F-15C Eagle | F-15C |
| MiG-29A Fulcrum | MiG-29A |
| F/A-18C Hornet | FA-18C_hornet |
| A-10C Warthog | A-10C_2 |
| Mirage 2000C | M-2000C |
| Mirage F1 | Mirage-F1CE |
| F-14A Tomcat | F-14A-135-GR |
| F-14B Tomcat | F-14B |
| F-14B(U) Tomcat | F-14BU |
| JF-17 Thunder | JF-17 |
| Su-25 Frogfoot | Su-25 |
| Su-25T Frogfoot | Su-25T |

Warehouse: unlimited weapons of all types. Hot or cold start is the player's choice (`allowHotStart = true`).

### Carrier Slots (CVN-74 Stennis)

Dynamic spawn on the Stennis offers only these types (`unlimitedAircrafts = false`, each type `unlimited = true`), hot or cold start (`allowHotStart = true`):

| Aircraft | DCS Type String | Template Group (groupId) |
|----------|-----------------|--------------------------|
| F/A-18C Hornet | FA-18C_hornet | FA-18C Stennis Template (25) |
| F-14A Tomcat | F-14A-135-GR | F-14A Stennis Template (26) |
| F-14B Tomcat | F-14B | F-14B Stennis Template (27) |
| F-14B(U) Tomcat | F-14BU | F-14B(U) Stennis Template (28) |

`F-14BU` comes from Quaggles' datamine (DCS 2.9.31.29434, `db/Units/Planes/Plane/F-14BU.lua`; display name "F-14B(U)").

## Communications Plan

Reference `docs/recipes/comm-plan.md` for the standardized frequencies and per-aircraft radio capabilities.

Radio presets live in each dynamic spawn template's `Radio` table (groups 1-14 and 29 at Krymsk, 25-28 on the Stennis). Templates only apply when the base's warehouse stock entry links them with `linkDynTempl`, so Krymsk stocks each player type explicitly (`unlimitedAircrafts = false`, per-type `unlimited = true`).

Main (UHF) radio, identical in every aircraft. 18 channels so the F-4E fits; priority is Strike, SkyEye, all three ATC frequencies (human controllers on SRS), carrier, tankers, then interflight with whatever is left:

| Ch | Use | MHz |
|----|-----|-----|
| 1 | Strike | 255.1 |
| 2 | SkyEye GCI | 255.3 |
| 3-5 | Krymsk Tower / Ground / Radar | 254.1 / 254.3 / 254.5 |
| 6 | Stennis | 254.7 |
| 7-9 | Texaco / Arco / Shell | 270.5 / 270.1 / 270.7 |
| 10-14 | Red 1-5 | 260.1-260.9 |
| 15-18 | Blue 1-4 | 261.1-261.7 |
| 19 | Blue 5 (20-channel radios) | 261.9 |
| 20 | Guard (20-channel radios) | 243.0 |

Second radios ("radio 1 to talk, radio 2 on SkyEye"):

- V/UHF radios (F/A-18 COMM2, F-15E Radio 2, F-14 ARC-182, A-10 ARC-210, M-2000C V/UHF, F1 TRAP-136): ch1 SkyEye VHF 124.1, ch2-20 = main ch1-19. Radios with more than 20 channels continue with Guard, Green 1-5, SkyEye FM, Yellow/Orange FM, Civil Guard, JTAC.
- F-16 COMM2 (VHF AM 116-156 / FM 30-88 only): 124.1, 32.1 FM, 121.5, Yellow 1-5, Orange 1-5, JTAC 1-4.
- A-10 ARC-186 (FM only): 32.1, Yellow 1-5, Orange 1-5, JTAC 1-4.
- F-4E aux receiver (265-284.9): Texaco, Arco, Shell; remaining channels are module defaults.
- JF-17: one shared 20-preset list for COMM1/COMM2 = main layout.
- F-15C, MiG-29A, Su-25, Su-25T (FC3): no mission presets; players tune in SRS.

The in-game AWACS (Magic) has `communication = false`; it exists for datalink only. Voice GCI is SkyEye on 255.3 AM / 124.1 AM / 32.1 FM. The comms card text is the `displayCommsPlan` long string in `OperationInfinity.lua`; the blue-task briefing in `dictionary` carries the same card.

## Factions

- **ISAF:** Use faction list from `docs/factions/isaf-2004.md` or `isaf-2005.md`
- **Erusea:** Use `docs/factions/erusea-2004.md` for Easy/Normal, `erusea-2005.md` for Hard

## Difficulty Settings

Enemy helicopters listed below are planned but not implemented; no script spawns them.

### Very Easy (Training)
- Erusea 2004 equipment
- Ground targets only
- No enemy fighters, SAMs, EWRs or SHORAD
- Planned, not implemented: targets immortal and holding fire. Today Erusean groups have neither option set.

### Easy
- Erusea 2004 equipment
- Scattered defenses: ZU-23, Shilka, MANPADS, SA-9, SA-13
- 1-2 incomplete SA-2 batteries (P-19, SNR-75 and 3 launchers), 1-2 SA-9, 1-2 SA-13 (`samCounts.Easy`). Not under IADS emission control.
- Enemy fighters: MiG-21Bis, F-5E, F-5E-3, A-10A with IR missiles (R-60, AIM-9B)
- Enemy helicopters (planned): Mi-24P, Mi-24V, Ka-50
- Max 2 fighters airborne, skill Average-Ace

### Normal
- Erusea 2004 with rare 2005 equipment
- IADS: EWRs (1L13, P-19), SA-2, SA-3, SA-6, SA-8 Osa
- AAA: Shilka, Gepard, Roland ADS
- Enemy fighters: MiG-29A, MiG-29S, Mirage 2000-5, F-16A, Tornado IDS with R-73, R-27R
- Enemy helicopters (planned): Mi-24P, Ka-50, AH-64A
- Max 4 fighters airborne, skill Average-Ace

### Hard
- Erusea 2005 equipment
- Layered IADS: EWRs (1L13, 55G6), SA-10 and SA-11 Buk with SA-15 point defense, SA-6
- Emission control on radar systems
- Enemy fighters: F-15C, F-15E, F/A-18A, F/A-18C, F-16C, Su-27, J-11A, F-14A with AIM-120, R-77
- Enemy helicopters (planned): AH-64D, Ka-50
- Max 6 fighters airborne, skill Average-Ace

`UnitTemplates.AAA` is defined but not used.

### Dynamic Fighter Scaling

Max airborne fighters scales by weighted player count in combat area:

| Aircraft Category | Weight |
|-------------------|--------|
| A-A Fighters (F-15C, F-14A/B) | 2.0 |
| Multirole (F-16C, F/A-18C, MiG-29A, M-2000C, F-15E, F-4E, JF-17) | 1.5 |
| Attack/CAS (A-10C, Mirage F1, Su-25, Su-25T) | 0.5 |

Formula: `baseMax + floor(log2(weightedPlayerCount + 1))`, capped at 8.

## Playtime Regions

Each playtime picks one random region from `OperationInfinity.config.aerodromeRegions`. Targets are placed around the region's aerodromes.

| Region key | Aerodromes | Playtimes | Notes |
|------------|------------|-----------|-------|
| `northwest` | Maykop-Khanskaya | 45 | Frontline |
| `central_coast` | Gudauta, Sukhumi-Babushara | 45, 90 | No frontline; dense approach-route targets starting 50 nm from Krymsk |
| `southwest_coast` | Kobuleti, Senaki-Kolkhi, Kutaisi | 90 | Frontline 5-15 nm NW of the aerodromes |
| `northeast` | Mozdok | 180 | Frontline |
| `southeast` | Tbilisi-Lochini, Vaziani | 180 | No frontline; deep strike targets plus approach-route targets past 120 nm |

## IADS Behavior

EWRs, SAM sites and airbase SHORAD are permanent groups, spawned once after generation and never virtualized. Emission control (`IADS.lua`) runs on Normal and Hard only and covers long-range sites (SA-2, SA-3, SA-6, SA-10, SA-11). Sites stay in alarm state RED; the script switches radars with `group:enableEmission`. Rules in priority order:

1. **HARM defense.** `S_EVENT_SHOT` tracks blue anti-radiation missiles (`RADAR_PASSIVE` guidance). A 2 s loop runs only while one is in flight. An ARM is aimed at a site when the site is inside a 15-degree cone around its horizontal velocity. The first time, the site rolls a shutdown ETA (Normal 30-60 s, biased high; Hard 15-30 s, biased low). When the ARM's ETA drops below the roll, the site goes dark for 60-180 s, even with its own missiles in flight.
2. **Keep guiding.** A site stays on while any missile it fired still exists.
3. **Cueing.** Every 10 s the script merges radar detections from live EWRs with spy reports. Spies report every blue aircraft below 5000 ft AGL within 60 km of a target aerodrome on a random 2-4 minute cycle; each report arrives 20-40 s later with the old position and lasts 60 s. Spies can't be killed. A site turns on when a cued target is inside 75% of its max range and turns off 20 s after the last cue.
4. **Autonomous fallback.** A site with no live EWR within 250 km pulses: 10-20 s on, 90-240 s off. During a pulse it stays on while its own radar tracks a blue aircraft inside 50% of max range.

Max ranges are launcher `ThreatRange` values from Quaggles' datamine (DCS 2.9.27):

| Site | Max range | Cue (75%) | Autonomous (50%) |
|------|-----------|-----------|------------------|
| SA-2 | 43 km | 32 km | 21.5 km |
| SA-3 | 18 km | 13.5 km | 9 km |
| SA-6 | 25 km | 19 km | 12.5 km |
| SA-10 | 120 km | 90 km | 60 km |
| SA-11 | 50 km | 37.5 km | 25 km |

SA-8 and SA-15 are point defense on DCS default AI, always on. Generation places one SHORAD 1-3 km from each long-range site, longest range first: SA-15 with the SA-10 and SA-11 (Hard), SA-8 with the SA-3 and SA-6 (Normal). SA-2 and Hard SA-6 get none. Leftover SHORAD is placed at random. Easy SAMs are not under emission control.

Every state change is logged to `dcs.log` with an `[IADS]` prefix and its reason.

## Ground Unit Composition

### Frontline Firefights

Regions without `noFrontline` get one frontline perpendicular to the Krymsk-to-target axis, centered between the battlefield distance limits (default 10-40 nm from the aerodromes). It has 4-8 engagement points 3-7 nm apart.

Each engagement point has one ISAF platoon facing 2-3 Erusean platoons, 300-1000 m apart.

**ISAF Platoon** (immortal, invisible, weapons hold, per ground-firefight recipe):
- 2x M-1 Abrams
- 2x M-2 Bradley
- 1x M163 Vulcan
- 1x M1083 truck

**Erusea Platoon** (targets):
- 2x Leclerc
- 2x Marder
- 1x Shilka (Easy) or Gepard (Normal/Hard); none on Very Easy

Each side's FireAtPoint target starts 300 m past the opposing platoon. Every 15 s the target moves to a random point within 150 m of that start, around the enemy and never the shooter.

Frontline SHORAD: one group behind Erusean lines at every second engagement point (Easy: ZU-23, SA-9. Normal: ZU-23, SA-13, Shilka. Hard: Gepard, SA-13, Tunguska).

### Behind-Lines Targets

**Logistics Convoys** (virtualized):
- 4-6x Ural-375, 1-2x BRDM-2, 1x Ural-375 ZU-23

**Artillery Batteries**:
- 4x SAU Akatsia, 1x Ural-375, 1x BRDM-2

**Scattered Presence**: Patrol vehicles and checkpoints

Planned, not implemented: virtualized air assets (CH-47D transport, AH-64 patrols) and helicopter patrols (Mi-24P, Ka-50, AH-64A).

## Unit Virtualization

Performance target: 800-1000 max spawned units.

- Most ground units tracked in scripts, not spawned
- Spawn when player within 100 NM
- Despawn when all players beyond 120 NM (hysteresis)
- Health tracked as float 0.0-1.0, preserved across cycles via `unit:getLife()` / `unit:getLife0()`
- EWRs and SAM radars always spawned

## Enemy Aircraft Spawning

Dynamic interceptor spawns from Erusean airfields:

| Airfield | Zone Radius |
|----------|-------------|
| Mozdok | 50 km |
| Tbilisi-Lochini | 45 km |
| Kutaisi | 45 km |
| Kobuleti | 40 km |
| Sukhumi-Babushara | 50 km |

No zone covers Maykop, Gudauta, Senaki or Vaziani, so the 45-minute Maykop region has no enemy fighters.

Spawn cooldown: random 300-780 seconds between waves per airfield, plus a 180-second global cooldown across all airfields (zones overlap near Sukhumi/Kobuleti/Kutaisi). Interceptors take off from the runway; the spawn point is read from the airbase at runtime (`world.getAirbases()` by airdromeId), since a route point off the airdrome makes DCS air-start the group.

An interceptor leaves the airborne count when it is lost (DEAD, CRASH, UNIT_LOST) or lands (S_EVENT_LAND). A landed interceptor is destroyed 60 s after touchdown. Removals are de-duplicated by unit name because several of these events can fire for one aircraft.

Response scaling:
- 1-2 players: 1 interceptor
- 3 players: 2 interceptors
- 4 players: 3 interceptors
- 5+ players: 4 interceptors max

## Support Assets

### AWACS
E-3A "Magic" on the regional support racetrack, 30,000 ft, 280 KIAS. EPLRS datalink enabled, radio disabled. Players should use SkyEye GCI on 255.3 MHz, 124.1 VHF, or 32.1 FM.

### Tankers

**KC-135 "Texaco"** (boom): 25,000 ft, 280 KIAS, 270.5 MHz AM, TACAN 100X

**KC-135MPRS "Arco"** (basket): 21,000 ft, 250 KIAS, 270.1 MHz AM, TACAN 101X

**KC-135 "Shell"** (slow boom, A-10/Su-25): 15,000 ft, 200 KIAS, 270.7 MHz AM, TACAN 102X

All four support aircraft are late-activated when the battlefield is generated and are immortal and invisible. The script sets `SetUnlimitedFuel` on activation so they stay on station for the whole mission. Orbits are pushed by `OperationInfinity.lua` once each aircraft is airborne, on a racetrack chosen by the selected region. `supportAircraft` stores altitude in feet and target IAS in knots; the Orbit task's TAS is computed at runtime from the ISA density model, so changing an altitude doesn't require recomputing speeds. Racetracks are offset 5 km laterally per aircraft; altitude separation comes only from each aircraft's own altitude.

### Carrier Strike Group

Managed by `CarrierOps.lua`, independent of the F10 settings (starts at mission load).

| Ship | Group / Unit Name | Type |
|------|-------------------|------|
| CVN-74 John C. Stennis | `CVN-74 Stennis` / `CVN-74 John C. Stennis` | `Stennis` |
| Cruiser | `CSG Cruiser` | `TICONDEROG` |
| Destroyer x2 | `CSG Destroyer 1`, `CSG Destroyer 2` | `USS_Arleigh_Burke_IIa` |
| Frigate | `CSG Frigate` | `PERRY` |
| Plane guard (script-spawned) | `Angel` | `SH-60B` |

- Operating area: 30 km radius circle centered X=-70000, Y=225000 (open water SW of Anapa, ~50 nm from Krymsk)
- Carrier systems: radio 254.7 MHz AM, TACAN 74X "STN", ICLS 4, Link 4 336.0 MHz, ACLS. Set on waypoint 1 in the mission file and re-applied by the script after every route change.
- Into-wind leg: course = wind-from + 9 degrees (angled deck), speed = 25 kt WOD minus headwind, clamped 5-25 kt. Wind is read at runtime with `atmosphere.getWind()`.
- Repositioning leg: 25 kt back to the downwind edge of the area when the into-wind leg reaches the edge.
- Escorts: separate groups, each held at a fixed offset along the wind axis (not the carrier's heading) so tracks stay parallel through turnarounds. Re-steered every 60 s.
- Plane guard: SH-60B on the carrier's starboard side (900 m starboard, 300 m ahead, 300 ft RADIO), clear of the port-side Case I pattern. Unlimited fuel, weapons hold, re-steered every 3 s, respawned 120 s after loss.

## Weather and Time

- Time: Random 0700-1700 local
- Clouds: Clear or partly cloudy only
- No fog, dust, or heavy precipitation
- Visibility: 80+ km
- Temperature: 15-25 C
- Wind: 0-15 knots

## F10 Menu Structure

```
F10 Other
├── Mission Settings          (removed once settings lock)
│   ├── Difficulty
│   │   ├── Very Easy (Training - no enemies shoot back)
│   │   ├── Easy (Light defenses, IR missiles only)
│   │   ├── Normal (IADS, semi-active radar missiles)
│   │   └── Hard (Layered IADS, active radar missiles)
│   └── Target Playtime
│       ├── 45 Minutes (Western Caucasus)
│       ├── 90 Minutes (Central Caucasus)
│       └── 180 Minutes (Eastern Caucasus)
├── Comms Plan
└── Mission Info              (added after generation)
```

## Late Joiner Support

A timer checks every 5 seconds for new players. Each new player triggers a coalition-wide message: the welcome text before generation, or the target area and support assets after it. Planned, not implemented: EPLRS datalink membership for late joiners.

## Mission Time Limit

The mission runs 8 hours (`missionDuration = 28800`). Warnings go out at 60, 30, 15, 10 and 5 minutes remaining. At expiry the script sets flag `MISSION_TIME_EXPIRED`, and a mission trigger ends the mission.

## Lua Style Choices

- Use `array[#array + 1] = value` instead of `table.insert()` for performance
- Name all magic numbers except -1, 0, and 1 as constants
- Verbose logging is intentional due to limited DCS observability
- Use shared utility libraries (`Logging`, `Units`, `Spatial`) for common functionality

## Script Loading Order

Scripts must be loaded in this order to satisfy dependencies:

1. `Logging.lua`
2. `Units.lua`
3. `Spatial.lua`
4. `BatchScheduler.lua`
5. `Terrain.lua`
6. `UnitTemplates.lua`
7. `Formations.lua`
8. `Virtualization.lua`
9. `IADS.lua`
10. `AirIntercept.lua`
11. `BattlefieldGeneration.lua`
12. `CarrierOps.lua`
13. `OperationInfinity.lua`

When adding a script, update all four places: the "Load Mission Scripts" trigger (`trigrules` and `trig.actions` in `src/mission`), `src/l10n/DEFAULT/mapResource`, and both file lists in `pack_mission.py`.

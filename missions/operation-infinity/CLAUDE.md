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
| JF-17 Thunder | JF-17 |
| Su-25 Frogfoot | Su-25 |
| Su-25T Frogfoot | Su-25T |

Warehouse: unlimited weapons of all types.

### Carrier Slots (CVN-74 Stennis)

Dynamic spawn on the Stennis offers only these types (`unlimitedAircrafts = false`, each type `unlimited = true`), cold start only (`allowHotStart = false`):

| Aircraft | DCS Type String | Template Group (groupId) |
|----------|-----------------|--------------------------|
| F/A-18C Hornet | FA-18C_hornet | FA-18C Stennis Template (25) |
| F-14A Tomcat | F-14A-135-GR | F-14A Stennis Template (26) |
| F-14B Tomcat | F-14B | F-14B Stennis Template (27) |
| F-14B(U) Tomcat | F-14BU | F-14B(U) Stennis Template (28) |

`F-14BU` comes from Quaggles' datamine (DCS 2.9.31.29434, `db/Units/Planes/Plane/F-14BU.lua`; display name "F-14B(U)").

## Communications Plan

Reference `docs/recipes/comm-plan.md` for the standardized frequencies and per-aircraft radio capabilities.

Radio presets live in each dynamic spawn template's `Radio` table (groups 1-14 at Krymsk, 25-28 on the Stennis). Templates only apply when the base's warehouse stock entry links them with `linkDynTempl`, so Krymsk stocks each player type explicitly (`unlimitedAircrafts = false`, per-type `unlimited = true`).

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

### Very Easy (Training)
- Erusea 2004 equipment
- Ground targets only, immortal (do not shoot back)
- No enemy fighters or air defense systems

### Easy
- Erusea 2004 equipment
- Scattered defenses: ZU-23, Shilka, MANPADS, SA-9, SA-13
- 1-2 incomplete SA-2 batteries
- Enemy fighters: MiG-21Bis, F-5E, F-5E-3, A-10A with IR missiles (R-60, AIM-9B)
- Enemy helicopters: Mi-24P, Mi-24V, Ka-50
- Max 2 fighters airborne, skill Average-Ace

### Normal
- Erusea 2004 with rare 2005 equipment
- IADS: EWRs (1L13, P-19), SA-2, SA-3, SA-6, SA-8 Osa
- AAA: Shilka, Gepard, Roland ADS
- Enemy fighters: MiG-29A, MiG-29S, Mirage 2000-5, F-16A, Tornado IDS with R-73, R-27R
- Enemy helicopters: Mi-24P, Ka-50, AH-64A
- Max 4 fighters airborne, skill Average-Ace

### Hard
- Erusea 2005 equipment
- Layered IADS: SA-10 with SA-15 SHORAD, SA-11 Buk, multiple SA-6/SA-8
- Emission control on radar systems
- Enemy fighters: F-15C, F-15E, F/A-18A, F/A-18C, F-16C, Su-27, J-11A, F-14A with AIM-120, R-77
- Enemy helicopters: AH-64D, Ka-50
- Max 6 fighters airborne, skill Average-Ace

### Dynamic Fighter Scaling

Max airborne fighters scales by weighted player count in combat area:

| Aircraft Category | Weight |
|-------------------|--------|
| A-A Fighters (F-15C, F-14A/B) | 2.0 |
| Multirole (F-16C, F/A-18C, MiG-29A, M-2000C, F-15E, F-4E, JF-17) | 1.5 |
| Attack/CAS (A-10C, Mirage F1, Su-25, Su-25T) | 0.5 |

Formula: `baseMax + floor(log2(weightedPlayerCount + 1))`, capped at 8.

## Playtime Zones

| Duration | Area | Center (approx) | Radius |
|----------|------|-----------------|--------|
| 45 min | Anapa/Novorossiysk | X=-40000, Y=320000 | 30km |
| 90 min | Sukhumi/Zugdidi | X=-220000, Y=560000 | 50km |
| 180 min | Kutaisi/Tbilisi | X=-290000, Y=700000 | 60km |

## IADS Behavior

EWRs (1L13, P-19) always spawned at mission start. SAM tracking radars also spawned at start.

On Normal/Hard:
- EWRs always active
- Search radars pulse on/off when threats detected
- Tracking radars activate when targets enter engagement range

## Ground Unit Composition

### Frontline Firefights

Generate 3-5 fighting areas spread across the battlefield. Each area has 2-3 platoon engagements.

**ISAF Platoon** (immortal/invisible per ground-firefight recipe):
- 2x M-1 Abrams
- 2x M-2 Bradley
- 1x M163 Vulcan

**Erusea Platoon** (targets):
- 2x Leclerc
- 2x Marder
- 1x Gepard or ZSU-23-4 Shilka

Layout: Platoons 500-1000m apart, using FireAtPoint with 50-100m offset for sustained visual combat.

SHORAD per area: 1-2x Ural-375 ZU-23, MANPADS near Erusean positions.

Total: 15-25 platoons per side.

### Behind-Lines Targets

**Logistics Convoys** (virtualized):
- 4-6x Ural-375, 1-2x BRDM-2, 1x Ural-375 ZU-23

**Artillery Batteries**:
- 4x SAU Akatsia, 1x Ural-375, 1x BRDM-2

**Air Assets** (virtualized): CH-47D transport, AH-64 patrols

**Scattered Presence**: Patrol vehicles, checkpoints, helicopter patrols (Mi-24P, Ka-50, AH-64A)

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

Spawn cooldown: random 300-780 seconds between waves per airfield, plus a 180-second global cooldown across all airfields (zones overlap near Sukhumi/Kobuleti/Kutaisi). Interceptors take off from the runway; the spawn point is read from the airbase at runtime (`world.getAirbases()` by airdromeId), since a route point off the airdrome makes DCS air-start the group. Unit losses are de-duplicated by name because DEAD, CRASH and UNIT_LOST can all fire for one aircraft.

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

Orbits are pushed by `OperationInfinity.lua` once each aircraft is airborne, on a racetrack chosen by the selected region. `supportAircraft` stores altitude in feet and target IAS in knots; the Orbit task's TAS is computed at runtime from the ISA density model, so changing an altitude doesn't require recomputing speeds. Racetracks are offset 5 km laterally per aircraft; altitude separation comes only from each aircraft's own altitude.

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
├── Mission Settings
│   ├── Difficulty
│   │   ├── Very Easy (Training)
│   │   ├── Easy
│   │   ├── Normal
│   │   └── Hard
│   └── Playtime
│       ├── 45 Minutes (Western Caucasus)
│       ├── 90 Minutes (Central Caucasus)
│       └── 180 Minutes (Eastern Caucasus)
```

## Late Joiner Support

Timer checks every 60 seconds for new players. Late joiners receive target coordinates and EPLRS datalink membership.

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

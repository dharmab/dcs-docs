# Operation Infinity - Technical Specification

This document provides technical details for AI agents generating or modifying the Operation Infinity mission.

## Mission Structure

Players spawn via Dynamic Slots at Krymsk (airdromeId 15). On load, an F10 menu allows selection of difficulty and playtime. First player to select both locks settings. Scripts generate a randomized battlefield and display coordinates to players.

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

## Communications Plan

Reference `docs/recipes/comm-plan.md` for the standardized frequencies. Player aircraft presets should include Strike (255.1), GCI (255.3), appropriate flight tactical, and tanker frequencies.

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

Spawn cooldown: 120 seconds between waves per airfield.

Response scaling:
- 1-2 players: 1 interceptor
- 3 players: 2 interceptors
- 4 players: 3 interceptors
- 5+ players: 4 interceptors max

## Support Assets

### AWACS
E-3A "Overlord" on E-W racetrack NW of Krymsk, 30,000 ft. EPLRS enabled. Frequency 255.5 MHz AM.

### Tankers

**KC-135 "Texaco"** (boom): 25,000 ft, 270.5 MHz AM, TACAN 100X

**KC-135MPRS "Arco"** (basket): 22,000 ft, 270.1 MHz AM, TACAN 101X

Both orbit near Anapa.

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

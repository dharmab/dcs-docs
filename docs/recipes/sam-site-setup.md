# SAM Site Deployment Guide

This recipe describes how to deploy Surface-to-Air Missile (SAM) sites by directly editing the mission Lua file. Proper SAM deployment requires understanding system compositions, radar dependencies, and tactical placement principles.

> **Note:** Many SAM systems in DCS require multiple vehicles to function. A launcher typically needs a tracking radar, and the radar may need a search radar or command post. Placing a launcher alone will result in a non-functional system.

## Overview

A complete SAM site requires:

- **Launchers** - Fire the missiles at targets
- **Tracking Radar (TR/STR)** - Guides missiles to targets
- **Search Radar (SR)** - Detects targets and provides early warning (often optional)
- **Command Post (CP)** - Coordinates battery operations (system-dependent)

## Mission File Structure

Ground units are placed in `coalition.[side].country[n].vehicle.group`. Each group contains multiple units that form the SAM battery.

```lua
["coalition"] = {
    ["red"] = {
        ["country"] = {
            [1] = {
                ["id"] = 0,  -- Russia
                ["name"] = "Russia",
                ["vehicle"] = {
                    ["group"] = {
                        [1] = {
                            -- SAM group definition here
                        },
                    },
                },
            },
        },
    },
},
```

## General Placement Principles

### Separation and Survivability

- **Separate radars from launchers** to prevent single-weapon kills destroying the entire battery
- **Offset early warning radars** several kilometers from the main battery
- **Avoid symmetrical layouts** for realism and survivability
- **Use terrain masking** to protect radars from low-level attack

### Layered Defense

- **Long-range systems** (SA-10, SA-5, Patriot) engage high-altitude, distant targets
- **Medium-range systems** (SA-11, SA-6, Hawk) fill the gap against maneuvering aircraft
- **Short-range systems** (SA-15, SA-19, SA-8) protect against low-level penetrators, cruise missiles, and HARMs
- **Always layer systems** to create overlapping coverage with no gaps

### Terrain Considerations

- Place radars on **elevated terrain** for maximum radar horizon
- Avoid placing systems in **valleys** where terrain masks their radar coverage
- Consider **approach routes** aircraft might use for terrain masking attacks

---

## Russian / Soviet-Origin Systems

### SA-2 (S-75 Dvina)

**Intended Use:** Medium- to high-altitude defense of fixed sites (airfields, cities, strategic facilities). Poor against low-level penetration.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| SM-90 Launcher | `S_75M_Volhov` | Launcher (1 missile) |
| SNR-75 Fan Song | `SNR_75V` | Tracking radar |
| RD-75 Amazonka | `RD_75` | Radio direction finding (optional) |

**Battery Composition:**

- 1× SNR-75 Fan Song (tracking radar)
- 6× SM-90 Launchers
- 1× EWR (P-19 or 1L13, optional but recommended)

**Recommended Layout:**

- Place Fan Song at the center of the site
- Arrange six launchers in a circular "flower" pattern, 1–2 km from the radar
- Position EWR several kilometers away to avoid single-weapon kills
- Best deployed on flat terrain with clear radar horizon

**Example Group Definition:**

```lua
[1] = {
    ["groupId"] = 200,
    ["name"] = "SA-2 Battery",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -100000,
    ["y"] = 500000,
    ["units"] = {
        [1] = {
            ["unitId"] = 200,
            ["name"] = "SA-2-STR",
            ["type"] = "SNR_75V",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 500000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 201,
            ["name"] = "SA-2-LN1",
            ["type"] = "S_75M_Volhov",
            ["skill"] = "High",
            ["x"] = -100000,
            ["y"] = 501500,  -- 1.5 km north
            ["heading"] = 3.14159,  -- Facing south toward radar
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 202,
            ["name"] = "SA-2-LN2",
            ["type"] = "S_75M_Volhov",
            ["skill"] = "High",
            ["x"] = -98700,
            ["y"] = 500750,  -- 1.5 km northeast
            ["heading"] = 3.93,  -- Facing southwest
            ["playerCanDrive"] = false,
        },
        -- Continue pattern for remaining 4 launchers...
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -100000,
                ["y"] = 500000,
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
        },
    },
},
```

---

### SA-3 (S-125 Neva)

**Intended Use:** Medium-altitude defense with limited low-altitude capability around fixed sites.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 5P73 Launcher | `5p73 s-125 ln` | Launcher (4 missiles) |
| SNR-125 Low Blow | `snr s-125 tr` | Tracking radar |
| P-19 Flat Face | `p-19 s-125 sr` | Search radar |

**Battery Composition:**

- 1× SNR-125 Low Blow (tracking radar)
- 4× 5P73 Launchers
- 1× P-19 Flat Face (search radar, recommended)

**Recommended Layout:**

- Low Blow at center
- Four launchers in a square or shallow arc, 500–1500 m from radar
- P-19 search radar several km away
- Often layered inside SA-2 or SA-5 coverage

---

### SA-5 (S-200 Angara)

**Intended Use:** Long-range, high-altitude area defense against aircraft and cruise missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 5P72 Launcher | `S-200_Launcher` | Launcher (1 large missile) |
| RPC 5N62V Square Pair | `RPC_5N62V` | Tracking radar |
| P-14 Tall King | `P14_SR` | Search radar |
| 19J6 | `RLS_19J6` | Search radar (alternate) |

**Battery Composition:**

- 1× RPC 5N62V Square Pair (tracking radar)
- 1× P-14 or 19J6 (search radar)
- Up to 12× 5P72 Launchers

**Recommended Layout:**

- Square Pair central, search radar nearby but separated
- Launchers widely spaced (2–5 km) in arcs or clusters
- Treat as a fixed installation; protect with short-range SAMs
- The SA-5's extreme range makes it a priority SEAD target

---

### SA-6 (2K12 Kub)

**Intended Use:** Mobile medium-range defense against low- to medium-altitude aircraft.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 2P25 TEL | `Kub 2P25 ln` | Launcher (3 missiles) |
| 1S91 Straight Flush | `Kub 1S91 str` | Combined search/track radar |

**Battery Composition:**

- 1× 1S91 Straight Flush (radar)
- 4× 2P25 TELs
- 1× P-19 EWR (optional)

**Recommended Layout:**

- Straight Flush at center
- TELs 500–1500 m away with clear line of sight to radar
- Suitable for frontline or maneuver warfare scenarios
- Mobile—can relocate after engagements to avoid SEAD

---

### SA-8 (9K33 Osa)

**Intended Use:** Short-range mobile defense against low-flying aircraft, helicopters, and cruise missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 9A33 TLAR | `Osa 9A33 ln` | Self-contained launcher with radar |

**Battery Composition:**

- 4× 9A33 TLARs
- 1× Command vehicle (optional)
- 1× P-19 EWR (optional)

**Recommended Layout:**

- TLARs dispersed 1–3 km apart
- No fixed center required; each vehicle operates autonomously
- Ideal for convoy escort or point defense
- Each TLAR has its own search and tracking radar

---

### SA-10 (S-300PS)

**Intended Use:** Long-range, high-performance area defense against aircraft, HARMs, and cruise missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 5P85C TEL | `S-300PS 5P85C ln` | Launcher (4 missiles, truck) |
| 5P85D TEL | `S-300PS 5P85D ln` | Launcher (4 missiles, trailer) |
| 30N6 Flap Lid | `S-300PS 5H63C 30H6_tr` | Tracking radar |
| 40B6M | `S-300PS 40B6M tr` | Tracking radar (alternate) |
| 40B6MD Clam Shell | `S-300PS 40B6MD sr` | Search radar |
| 64H6E Big Bird | `S-300PS 64H6E sr` | Search radar (alternate) |
| 54K6 | `S-300PS 54K6 cp` | Command post |

**Battery Composition:**

- 1× Flap Lid (tracking radar)
- 1× Clam Shell or Big Bird (search radar)
- 4–8× TELs (mix of 5P85C and 5P85D)
- 1× 54K6 Command post

**Recommended Layout:**

- Flap Lid centrally located
- TELs dispersed 1–3 km around the radar
- Search radar several km away, can support multiple batteries
- **Always protect with SHORAD** (SA-15, SA-19)

**Example Group Definition:**

```lua
[1] = {
    ["groupId"] = 300,
    ["name"] = "SA-10 Battery",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -150000,
    ["y"] = 550000,
    ["units"] = {
        [1] = {
            ["unitId"] = 300,
            ["name"] = "SA-10-CP",
            ["type"] = "S-300PS 54K6 cp",
            ["skill"] = "High",
            ["x"] = -150000,
            ["y"] = 550000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 301,
            ["name"] = "SA-10-SR",
            ["type"] = "S-300PS 40B6MD sr",
            ["skill"] = "High",
            ["x"] = -150200,
            ["y"] = 550200,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 302,
            ["name"] = "SA-10-TR",
            ["type"] = "S-300PS 5H63C 30H6_tr",
            ["skill"] = "High",
            ["x"] = -150000,
            ["y"] = 550500,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [4] = {
            ["unitId"] = 303,
            ["name"] = "SA-10-LN1",
            ["type"] = "S-300PS 5P85C ln",
            ["skill"] = "High",
            ["x"] = -148500,
            ["y"] = 550000,  -- 1.5 km east
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [5] = {
            ["unitId"] = 304,
            ["name"] = "SA-10-LN2",
            ["type"] = "S-300PS 5P85C ln",
            ["skill"] = "High",
            ["x"] = -151500,
            ["y"] = 550000,  -- 1.5 km west
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [6] = {
            ["unitId"] = 305,
            ["name"] = "SA-10-LN3",
            ["type"] = "S-300PS 5P85D ln",
            ["skill"] = "High",
            ["x"] = -150000,
            ["y"] = 551500,  -- 1.5 km north
            ["heading"] = 3.14159,
            ["playerCanDrive"] = false,
        },
        [7] = {
            ["unitId"] = 306,
            ["name"] = "SA-10-LN4",
            ["type"] = "S-300PS 5P85D ln",
            ["skill"] = "High",
            ["x"] = -150000,
            ["y"] = 548500,  -- 1.5 km south
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -150000,
                ["y"] = 550000,
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
        },
    },
},
```

---

### SA-11 (9K37 Buk)

**Intended Use:** Mobile medium-range defense against aircraft, HARMs, and cruise missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 9A310M1 TELAR | `SA-11 Buk LN 9A310M1` | Launcher with onboard radar |
| 9S470M1 | `SA-11 Buk CC 9S470M1` | Command post |
| 9S18M1 Snow Drift | `SA-11 Buk SR 9S18M1` | Search radar |

**Battery Composition:**

- 4–6× 9A310M1 TELARs
- 1× 9S18M1 Snow Drift (search radar)
- 1× 9S470M1 Command post

**Recommended Layout:**

- TELARs dispersed in a loose formation (1–2 km spacing)
- Snow Drift centrally placed but not co-located with TELARs
- Very effective when frequently repositioned
- Each TELAR can engage independently using its own radar

---

### SA-13 (9K35 Strela-10)

**Intended Use:** Very short-range IR defense against helicopters and low-flying aircraft.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 9A35M3 TELAR | `Strela-10M3` | IR-guided launcher |

**Battery Composition:**

- 4–6× Strela-10M3 TELARs
- 1× Command vehicle (optional)

**Recommended Layout:**

- Loose dispersion around defended asset
- Use terrain masking and ambush placement
- Ideal as last-ditch inner layer defense
- Passive IR guidance—no radar emission to warn targets

---

### SA-15 (9K330 Tor)

**Intended Use:** High-end SHORAD against aircraft, cruise missiles, and HARMs.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 9A331 | `Tor 9A331` | Self-contained launcher with radar |
| Tor-M2 | `CHAP_TorM2` | Improved variant |

**Battery Composition:**

- 4× Tor TLARs
- 1× Command vehicle (optional)

**Recommended Layout:**

- TLARs spread 500 m–2 km apart
- Each vehicle operates autonomously
- **Primary role: Protect SA-10/SA-11 sites from HARMs**
- Fast reaction time makes it effective against cruise missiles

---

### SA-19 (2S6 Tunguska)

**Intended Use:** Point defense against low-level aircraft, helicopters, and missiles. Combined gun/missile system.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| 2S6 Tunguska | `2S6 Tunguska` | Combined gun/missile system |

**Battery Composition:**

- 4× 2S6 Tunguska
- 1× Command vehicle (optional)

**Recommended Layout:**

- Dispersed close to defended asset
- Overlapping coverage preferred
- Guns effective to ~3 km, missiles to ~8 km
- Mix radar and EO engagements in high-threat areas

---

### Pantsir-S1 (SA-22)

**Intended Use:** Short-range defense protecting strategic SAM sites (S-300/S-400) against cruise missiles and aircraft.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| Pantsir-S1 | `CHAP_PantsirS1` | Combined gun/missile system |

**Battery Composition:**

- 2–4× Pantsir-S1

**Recommended Layout:**

- Position to protect high-value SAM radars
- Overlapping fields of fire
- 20 km missile range provides buffer against standoff weapons

---

### ZSU-23-4 (Shilka)

**Intended Use:** Gun-based short-range defense against low, slow targets.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| ZSU-23-4 Shilka | `ZSU-23-4 Shilka` | Radar-guided AAA |

**Battery Composition:**

- 4× ZSU-23-4 Shilka
- 1× Command vehicle (optional)

**Recommended Layout:**

- Place in a ring around defended asset
- Overlapping fields of fire required
- Highly vulnerable to standoff weapons
- Effective only against low, slow targets within ~2.5 km

---

## US-Origin Systems

### MIM-23 Hawk

**Intended Use:** Medium-range defense against medium/high-altitude aircraft and cruise missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| M192 Launcher | `Hawk ln` | Launcher (3 missiles) |
| AN/MPQ-46 TR | `Hawk tr` | Tracking radar (illuminator) |
| AN/MPQ-50 SR | `Hawk sr` | Search radar |
| AN/MPQ-55 CWAR | `Hawk cwar` | Continuous wave acquisition radar |
| PCP | `Hawk pcp` | Platoon Command Post |

**Battery Composition:**

- 1× Hawk PCP (command post)
- 2× AN/MPQ-50 SR or AN/MPQ-55 CWAR (or both)
- 2× AN/MPQ-46 TR (tracking radars)
- 6× M192 Launchers

**Recommended Layout:**

- Command post at protected central location
- Tracking radars positioned to cover threat axis
- Launchers in arcs 1–2 km from tracking radars
- Search radars offset from tracking radars

---

### MIM-104 Patriot

**Intended Use:** Long-range defense against aircraft, cruise missiles, and HARMs.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| M901 Launcher | `Patriot ln` | Launcher (4 missiles) |
| AN/MPQ-53 STR | `Patriot str` | Search/track radar (phased array) |
| ECS | `Patriot ECS` | Engagement Control Station |
| EPP-III | `Patriot EPP` | Electric Power Plant |
| ICC | `Patriot cp` | Information Coordination Central |
| AMG AN/MRC-137 | `Patriot AMG` | Communications relay |

**Battery Composition:**

- 1× AN/MPQ-53 STR (radar)
- 1× ECS (engagement control)
- 1× ICC (command post)
- Up to 8× M901 Launchers
- 1× EPP (power, optional in DCS)
- 1× AMG (comms, optional in DCS)

**Recommended Layout:**

- **Radar has limited scan sector**—orient toward threat axis
- Launchers clustered 500 m–2 km from radar
- Command elements protected but within cable range
- **Always support with SHORAD** (Avenger, Chaparral)

**Example Group Definition:**

```lua
[1] = {
    ["groupId"] = 400,
    ["name"] = "Patriot Battery",
    ["task"] = "Ground Nothing",
    ["start_time"] = 0,
    ["visible"] = false,
    ["hidden"] = false,
    ["x"] = -200000,
    ["y"] = 600000,
    ["units"] = {
        [1] = {
            ["unitId"] = 400,
            ["name"] = "Patriot-ICC",
            ["type"] = "Patriot cp",
            ["skill"] = "High",
            ["x"] = -200000,
            ["y"] = 600000,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [2] = {
            ["unitId"] = 401,
            ["name"] = "Patriot-ECS",
            ["type"] = "Patriot ECS",
            ["skill"] = "High",
            ["x"] = -200100,
            ["y"] = 600100,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [3] = {
            ["unitId"] = 402,
            ["name"] = "Patriot-STR",
            ["type"] = "Patriot str",
            ["skill"] = "High",
            ["x"] = -200000,
            ["y"] = 600300,
            ["heading"] = 0,  -- Facing north (threat axis)
            ["playerCanDrive"] = false,
        },
        [4] = {
            ["unitId"] = 403,
            ["name"] = "Patriot-LN1",
            ["type"] = "Patriot ln",
            ["skill"] = "High",
            ["x"] = -199200,
            ["y"] = 600500,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [5] = {
            ["unitId"] = 404,
            ["name"] = "Patriot-LN2",
            ["type"] = "Patriot ln",
            ["skill"] = "High",
            ["x"] = -200800,
            ["y"] = 600500,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [6] = {
            ["unitId"] = 405,
            ["name"] = "Patriot-LN3",
            ["type"] = "Patriot ln",
            ["skill"] = "High",
            ["x"] = -199200,
            ["y"] = 601200,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
        [7] = {
            ["unitId"] = 406,
            ["name"] = "Patriot-LN4",
            ["type"] = "Patriot ln",
            ["skill"] = "High",
            ["x"] = -200800,
            ["y"] = 601200,
            ["heading"] = 0,
            ["playerCanDrive"] = false,
        },
    },
    ["route"] = {
        ["points"] = {
            [1] = {
                ["x"] = -200000,
                ["y"] = 600000,
                ["type"] = "Turning Point",
                ["action"] = "Off Road",
                ["speed"] = 0,
                ["ETA"] = 0,
                ["ETA_locked"] = true,
                ["formation_template"] = "",
                ["task"] = {
                    ["id"] = "ComboTask",
                    ["params"] = {
                        ["tasks"] = {},
                    },
                },
            },
        },
    },
},
```

---

### NASAMS

**Intended Use:** Medium-range defense using networked AIM-120 AMRAAM missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| LCHR (AIM-120B) | `NASAMS_LN_B` | Launcher |
| LCHR (AIM-120C) | `NASAMS_LN_C` | Launcher |
| AN/MPQ-64F1 | `NASAMS_Radar_MPQ64F1` | Sentinel search radar |
| FDC | `NASAMS_Command_Post` | Fire Distribution Center |

**Battery Composition:**

- 1× FDC (command post)
- 1× AN/MPQ-64F1 (radar)
- 4–6× LCHR Launchers

**Recommended Layout:**

- FDC at protected central location
- Radar positioned for best coverage
- Launchers can be widely dispersed (networked)
- Active radar homing missiles—fire and forget

---

### M48 Chaparral

**Intended Use:** Short-range defense using adapted AIM-9 Sidewinder missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| M48 Chaparral | `M48 Chaparral` | IR-guided launcher |

**Battery Composition:**

- 4× M48 Chaparral

**Recommended Layout:**

- Disperse evenly around defended asset
- IR-guided—no radar warning for targets
- Limited against fast, maneuvering jets

---

### M1097 Avenger

**Intended Use:** Short-range mobile defense with Stinger missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| M1097 Avenger | `M1097 Avenger` | Stinger launcher on HMMWV |

**Battery Composition:**

- 4–6× M1097 Avenger

**Recommended Layout:**

- Highly mobile—can escort convoys
- Disperse around defended asset
- IR-guided Stingers provide no radar warning

---

### M163 VADS

**Intended Use:** Gun-based close-in defense against low, slow aircraft.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| M163 Vulcan | `M163 Vulcan` | 20mm Gatling gun on M113 |

**Battery Composition:**

- 4× M163 Vulcan

**Recommended Layout:**

- Disperse evenly around defended unit
- Clear fields of fire required
- No central radar dependency
- Effective only at very short range (~1.5 km)

---

### M6 Linebacker

**Intended Use:** Air defense integrated with armored formations.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| M6 Linebacker | `M6 Linebacker` | Bradley with Stinger missiles |

**Battery Composition:**

- 2–4× M6 Linebacker per armored company

**Recommended Layout:**

- Integrate with armored formations
- Provides organic air defense for maneuver units

---

## Other Systems

### Rapier

**Intended Use:** British short-range defense with optical/radar tracking.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| Launcher | `rapier_fsa_launcher` | Launcher (4 missiles) |
| Blindfire TR | `rapier_fsa_blindfire_radar` | Tracking radar |
| Optical Tracker | `rapier_fsa_optical_tracker_unit` | Optical tracking |

**Battery Composition:**

- 1× Blindfire radar
- 1× Optical tracker
- 4× Launchers

**Recommended Layout:**

- Blindfire radar central for all-weather operation
- Optical tracker co-located or nearby
- Launchers 200–500 m from radar

---

### IRIS-T SLM

**Intended Use:** Modern German medium-range defense with IR-guided missiles.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| Launcher | `CHAP_IRISTSLM_LN` | Vertical launcher |
| STR | `CHAP_IRISTSLM_STR` | Search/track radar |
| C2 | `CHAP_IRISTSLM_CP` | Command post |

**Battery Composition:**

- 1× C2 (command post)
- 1× STR (radar)
- 3–4× Launchers

**Recommended Layout:**

- Radar oriented toward threat axis
- Launchers dispersed 500 m–1 km apart
- IR seeker immune to radar jamming

---

### HQ-7 (FM-80/90)

**Intended Use:** Chinese short-range mobile defense.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| TELAR | `HQ-7_LN_SP` | Self-contained launcher with radar |
| SR | `HQ-7_STR_SP` | Search radar (optional) |

**Battery Composition:**

- 3–4× HQ-7 TELARs
- 1× HQ-7 SR (optional)

**Recommended Layout:**

- TELARs can operate independently
- Search radar improves detection range
- Similar employment to SA-8 but shorter range

---

### Roland ADS

**Intended Use:** Franco-German short-range mobile defense.

**Unit Type Strings:**

| Component | Type ID | Role |
|-----------|---------|------|
| Roland ADS | `Roland ADS` | Self-contained launcher |

**Battery Composition:**

- 4× Roland ADS

**Recommended Layout:**

- Disperse around defended asset
- Each vehicle operates independently
- ~6 km engagement range

---

## Early Warning Radars

Early warning radars extend detection range and provide cueing to SAM batteries. Place them several kilometers from SAM sites to avoid single-weapon kills.

| Radar | Type ID | Notes |
|-------|---------|-------|
| 1L13 EWR | `1L13 EWR` | Soviet long-range search |
| P-19 Flat Face | `p-19 s-125 sr` | Soviet medium-range |
| P-14 Tall King | `P14_SR` | Soviet long-range |
| 55G6 EWR | `55G6 EWR` | Modern Russian |
| AN/FPS-117 | `FPS-117` | US long-range |
| AN/TPS-80 | `AN/TPS-80` | US G/ATOR |

---

## Integrated Air Defense System (IADS) Example

A realistic IADS layers multiple systems:

```
Outer Layer (50+ km):
  └── SA-10 Battery (long-range)
  └── SA-5 Battery (very long-range, high altitude)

Middle Layer (20-50 km):
  └── SA-11 Battery (medium-range, mobile)
  └── Hawk Battery (medium-range)

Inner Layer (0-20 km):
  └── SA-15 Tor (protecting SA-10 radar)
  └── SA-19 Tunguska (point defense)
  └── SA-8 Osa (mobile gap filler)

Point Defense (0-5 km):
  └── ZSU-23-4 Shilka (AAA)
  └── SA-13 Strela-10 (IR ambush)
  └── MANPADS teams

Early Warning:
  └── 1L13 EWR (offset 10+ km)
  └── P-19 radar (offset 5+ km)
```

> **Gameplay Note:** The outer layer (SA-5, SA-10 at long range) is often excluded from missions. DCS lacks the strategic assets (B-52s, cruise missiles, dedicated SEAD packages) and operational scale needed to realistically counter these systems. Very long-range SAMs tend to create frustrating gameplay where players are engaged before they can meaningfully respond. For enjoyable SEAD/DEAD missions, consider starting with the middle layer as your longest-range threat.
>
> Cold War-era systems (SA-2, SA-3, SA-5, SA-6, SA-8) often provide more engaging gameplay than modern systems, even in contemporary settings. Their longer radar scan times, slower missile performance, and exploitable limitations give players more opportunities for tactical maneuvering and counterplay. Many real-world conflicts still feature these legacy systems, so their inclusion remains plausible.

### Basic IADS Script

The following script implements emission control for a layered IADS. Early warning radars stay on continuously to detect threats. Search radars pulse at medium intervals when the EWR detects hostiles in the general area. Track radars activate only when targets enter effective engagement range.

**Group naming convention:** The script expects groups to be named with prefixes:
- `EWR-` for early warning radars (e.g., `EWR-North`, `EWR-South`)
- `SAM-Search-` for search radar groups (e.g., `SAM-Search-SA10`, `SAM-Search-Hawk`)
- `SAM-Track-` for tracking/engagement groups (e.g., `SAM-Track-SA10`, `SAM-Track-SA11`)

```lua
-- IADS Configuration
local IADS = {
    -- Group name prefixes
    ewrPrefix = "EWR-",
    searchPrefix = "SAM-Search-",
    trackPrefix = "SAM-Track-",
    
    -- Detection ranges (meters)
    searchActivationRange = 80000,  -- 80 km - activate search radars
    trackActivationRange = 40000,   -- 40 km - activate track radars
    
    -- Timing (seconds)
    updateInterval = 10,            -- How often to check threats
    searchPulseOn = 15,             -- Search radar on duration
    searchPulseOff = 45,            -- Search radar off duration
    
    -- State tracking
    ewrGroups = {},
    searchGroups = {},
    trackGroups = {},
    searchRadarsOn = false,
    trackRadarsOn = false,
    lastSearchPulse = 0,
}

-- Initialize IADS groups
function IADS:init()
    -- Find all groups matching our prefixes
    for _, coalitionId in pairs({coalition.side.RED, coalition.side.BLUE}) do
        local groups = coalition.getGroups(coalitionId, Group.Category.GROUND)
        for _, group in ipairs(groups or {}) do
            if group:isExist() then
                local name = group:getName()
                if string.find(name, self.ewrPrefix) == 1 then
                    table.insert(self.ewrGroups, group)
                elseif string.find(name, self.searchPrefix) == 1 then
                    table.insert(self.searchGroups, group)
                elseif string.find(name, self.trackPrefix) == 1 then
                    table.insert(self.trackGroups, group)
                end
            end
        end
    end
    
    env.info(string.format("IADS initialized: %d EWR, %d Search, %d Track groups",
        #self.ewrGroups, #self.searchGroups, #self.trackGroups))
    
    -- EWRs always on
    self:setGroupsEmission(self.ewrGroups, true)
    
    -- SAMs start cold
    self:setGroupsEmission(self.searchGroups, false)
    self:setGroupsEmission(self.trackGroups, false)
    
    -- Set all SAMs to RED alert state (ready to fire when radar on)
    self:setGroupsAlarmState(self.searchGroups, AI.Option.Ground.val.ALARM_STATE.RED)
    self:setGroupsAlarmState(self.trackGroups, AI.Option.Ground.val.ALARM_STATE.RED)
end

-- Enable/disable emissions for a list of groups
function IADS:setGroupsEmission(groups, enable)
    for _, group in ipairs(groups) do
        if group:isExist() then
            group:enableEmission(enable)
        end
    end
end

-- Set alarm state for a list of groups
function IADS:setGroupsAlarmState(groups, state)
    for _, group in ipairs(groups) do
        if group:isExist() then
            local controller = group:getController()
            controller:setOption(AI.Option.Ground.id.ALARM_STATE, state)
        end
    end
end

-- Get closest hostile distance from EWR detections
function IADS:getClosestHostileRange()
    local closestRange = math.huge
    
    for _, ewrGroup in ipairs(self.ewrGroups) do
        if ewrGroup:isExist() then
            local controller = ewrGroup:getController()
            local targets = controller:getDetectedTargets(Controller.Detection.RADAR)
            
            for _, target in ipairs(targets or {}) do
                if target.object and target.object:isExist() then
                    -- Check if target is hostile (different coalition)
                    local targetCoalition = target.object:getCoalition()
                    local ewrCoalition = ewrGroup:getCoalition()
                    
                    if targetCoalition ~= ewrCoalition and targetCoalition ~= coalition.side.NEUTRAL then
                        -- Calculate distance from EWR to target
                        local ewrPos = ewrGroup:getUnit(1):getPoint()
                        local targetPos = target.object:getPoint()
                        local dx = targetPos.x - ewrPos.x
                        local dz = targetPos.z - ewrPos.z
                        local range = math.sqrt(dx * dx + dz * dz)
                        
                        if range < closestRange then
                            closestRange = range
                        end
                    end
                end
            end
        end
    end
    
    return closestRange
end

-- Main IADS update loop
function IADS:update(_, time)
    local closestHostile = self:getClosestHostileRange()
    
    -- Track radar control - activate when hostiles in engagement range
    if closestHostile <= self.trackActivationRange then
        if not self.trackRadarsOn then
            env.info("IADS: Track radars ACTIVE - hostile within " .. 
                math.floor(closestHostile / 1000) .. " km")
            self:setGroupsEmission(self.trackGroups, true)
            self.trackRadarsOn = true
        end
    else
        if self.trackRadarsOn then
            env.info("IADS: Track radars OFF - no immediate threat")
            self:setGroupsEmission(self.trackGroups, false)
            self.trackRadarsOn = false
        end
    end
    
    -- Search radar control - pulse when hostiles detected at medium range
    if closestHostile <= self.searchActivationRange then
        -- Hostiles in area - use pulsing pattern
        local timeSinceLastPulse = time - self.lastSearchPulse
        
        if self.searchRadarsOn then
            -- Currently on, check if time to turn off
            if timeSinceLastPulse >= self.searchPulseOn then
                env.info("IADS: Search radars pulsing OFF")
                self:setGroupsEmission(self.searchGroups, false)
                self.searchRadarsOn = false
                self.lastSearchPulse = time
            end
        else
            -- Currently off, check if time to turn on
            if timeSinceLastPulse >= self.searchPulseOff then
                env.info("IADS: Search radars pulsing ON - hostile at " .. 
                    math.floor(closestHostile / 1000) .. " km")
                self:setGroupsEmission(self.searchGroups, true)
                self.searchRadarsOn = true
                self.lastSearchPulse = time
            end
        end
    else
        -- No hostiles detected - ensure search radars are off
        if self.searchRadarsOn then
            env.info("IADS: Search radars OFF - area clear")
            self:setGroupsEmission(self.searchGroups, false)
            self.searchRadarsOn = false
        end
    end
    
    -- Reschedule next update
    return time + self.updateInterval
end

-- Start the IADS
IADS:init()
timer.scheduleFunction(function(_, time) return IADS:update(_, time) end, nil, timer.getTime() + 5)
```

**How it works:**

1. **EWR groups** (prefixed `EWR-`) remain active throughout the mission, providing continuous surveillance.

2. **Search radar groups** (prefixed `SAM-Search-`) pulse on/off when EWRs detect hostiles within 80 km. The default pattern is 15 seconds on, 45 seconds off. This reduces exposure to SEAD aircraft while maintaining situational awareness.

3. **Track radar groups** (prefixed `SAM-Track-`) activate when hostiles enter 40 km, providing fire control for engagements.

**Example group setup:**

| Group Name | Units | Role |
|------------|-------|------|
| `EWR-North` | 1L13 EWR | Always-on early warning |
| `EWR-South` | 55G6 EWR | Always-on early warning |
| `SAM-Search-SA10` | Big Bird (64N6E) | Pulsing search radar |
| `SAM-Track-SA10` | Clam Shell, Flap Lid, TELs | Engagement group |
| `SAM-Search-Hawk` | AN/MPQ-50 | Pulsing search radar |
| `SAM-Track-Hawk` | AN/MPQ-46, Launchers | Engagement group |

**Customization options:**

- Adjust `searchActivationRange` and `trackActivationRange` for different threat levels
- Modify `searchPulseOn` and `searchPulseOff` to change radar exposure time
- Add ARM evasion by enabling `EVASION_OF_ARM` option on track groups:

```lua
controller:setOption(AI.Option.Ground.id.EVASION_OF_ARM, true)
```

---

## Skill Levels

SAM effectiveness varies with skill level:

| Skill | Behavior |
|-------|----------|
| `"Average"` | Slower reaction, more likely to miss |
| `"Good"` | Standard performance |
| `"High"` | Fast reaction, accurate |
| `"Excellent"` | Near-perfect performance |

For challenging SEAD missions, use `"High"` or `"Excellent"`. For training scenarios, use `"Average"` or `"Good"`.

---

## Checklist

Before finalizing your SAM deployment:

- [ ] All required components present (launchers need radars)
- [ ] Radars and launchers in same group
- [ ] Components within operational range of each other
- [ ] Search radar present (if required by system)
- [ ] Command post present (if required by system)
- [ ] EWR offset from main battery
- [ ] SHORAD protecting long-range systems
- [ ] Radar oriented toward expected threat axis
- [ ] Terrain provides good radar horizon
- [ ] Unique `groupId` and `unitId` values
- [ ] Unique unit names

---

## Troubleshooting

### SAM Not Engaging Targets

- Verify all required components are present in the same group
- Check that tracking radar is present and functional
- Ensure targets are within engagement envelope (altitude, range)
- Verify group is not set to weapons hold (check ROE)

### SAM Destroyed Too Easily

- Spread units further apart
- Add SHORAD protection for long-range systems
- Relocate radars to less exposed positions
- Add decoy emitters if available

### Inconsistent Detection

- Add early warning radar to extend detection range
- Ensure radar has clear line of sight (no terrain masking)
- Check that search radar is properly linked

---

## See Also

- [Ground Units Reference](../units/ground.md) - Complete list of ground unit type strings
- [Mission File Schema](../mission/mission-file-schema.md) - Full mission file structure reference
- [Simulator Scripting Engine](../scripting/simulator-scripting-engine.md) - Dynamic SAM control via scripting
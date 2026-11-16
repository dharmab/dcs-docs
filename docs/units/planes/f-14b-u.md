# F-14B(U)

**Internal Name:** `F-14B(U)`

**Type ID:** `F-14BU`

**Playable:** Yes

## Background

The **(U) denotes Upgrade**: a late-service F-14B configuration reflecting the Tomcat's evolution from a Cold War maritime air-superiority fighter and fleet defender into a 2000s multirole aircraft. It retained its fleet-defense and air-superiority roles while taking on precision strike, reconnaissance, forward air control, and long-range combat operations. The upgrade is therefore more than an additional weapons option: it brings changes to cockpit displays, navigation, mission management, defensive systems, and flight controls.

Heatblur's DCS: F-14B(U) builds on its F-14A/B module with upgraded cockpits, an updated exterior representation, and additional avionics and weapons capabilities. DCS represents it as a separate aircraft from the baseline [F-14B](f-14b.md). Use `F-14BU` for the unit's `type` in mission files and scripting; `F-14B(U)` is the display name, not the type ID.

## Upgrade Systems

### Cockpit and Targeting

- **VDIG-R and modernized HUD:** Bring targeting data, navigation cues, radar-warning information, LANTIRN integration, JDAM delivery information, and multiple target-designation boxes into the pilot's field of view.
- **PTID:** Replaces the rear cockpit's classic TID with a larger, more capable display for the Radar Intercept Officer (RIO), supporting sensor, navigation, targeting, and precision-strike work.
- **ECMD with MFD mode:** Adds TID repeat functionality and ALR-67 integration, improving the crew's ability to monitor threats and manage tactical information.

### Navigation, Mission Management, and Weapons

- **EGI and GPS:** Upgrade the aircraft's navigation capability.
- **CDNU and Mission Data Loader support:** Provide updated navigation and mission-data management tools.
- **Fast Tactical Imaging System (FTI):** Allows images to be shared between Tomcats.
- **JDAM integration:** Adds GPS-guided precision-strike capability, including GBU-31. The DCS aircraft definition also lists GBU-38; see the station and CLSID tables below for supported stores.

### Defensive Systems and Flight Controls

- **ALE-47:** Provides programmable, mission-configurable chaff and flare dispensing integrated with the aircraft's defensive systems.
- **Digital Flight Control System (DFCS):** Replaces the analog AFCS, improving departure resistance, high-angle-of-attack handling, roll response, spin resistance, and carrier-approach characteristics. DFCS does **not** turn the Tomcat into a modern fly-by-wire aircraft; it refines the existing aircraft's handling rather than replacing its fundamental control characteristics.

## Tasks

- CAP
- Escort
- Fighter Sweep
- Intercept
- Reconnaissance
- Ground Attack
- Runway Attack
- Pinpoint Strike
- Anti-ship Strike
- CAS
- AFAC
- SEAD

## Pylons

DCS payload indices differ from the station labels shown in the Mission Editor. The table summarizes major compatible stores, not every rack or training-store option. Stores on neighboring stations can impose additional restrictions; a store appearing on two stations does not guarantee that both can carry it simultaneously.

| Payload index | Station | Major compatible stores                                                                                                      |
| ------------- | ------- | ---------------------------------------------------------------------------------------------------------------------------- |
| 1             | 1A      | AIM-9L/M on LAU-7 or LAU-138; ACMI/training and smoke stores                                                                 |
| 2             | 1B      | AIM-54A/C (Mk 47/60), AIM-7E/F/M/MH/P, AIM-9L/M; unguided bombs, practice bombs and Zuni rocket racks                        |
| 3             | 2       | 300-gallon external fuel tank (full or empty)                                                                                |
| 4             | 3       | AIM-54A/C, AIM-7E/F/M/MH/P; unguided bombs; GBU-10/12/16/24/24E; GBU-38 and GBU-31(V)2/B or (V)4/B; ECA adapter              |
| 5             | 4       | AIM-54A/C, AIM-7E/F/M/MH/P; unguided bombs; GBU-12/16; GBU-38 and GBU-31(V)2/B or (V)4/B                                     |
| 6             | 5       | AIM-54A/C, AIM-7E/F/M/MH/P; unguided bombs; GBU-12/16/24/24E; GBU-38 and GBU-31(V)2/B or (V)4/B; TARPS                       |
| 7             | 6       | AIM-54A/C, AIM-7E/F/M/MH/P; unguided bombs; GBU-10/12/16; GBU-38 and GBU-31(V)2/B or (V)4/B; AN/ALQ-167 pod                  |
| 8             | 7       | 300-gallon external fuel tank (full or empty)                                                                                |
| 9             | 8B      | AIM-54A/C (Mk 47/60), AIM-7E/F/M/MH/P, AIM-9L/M; unguided bombs, practice bombs and Zuni rocket racks; LANTIRN targeting pod |
| 10            | 8A      | AIM-9L/M on LAU-7 or LAU-138; ACMI/training and smoke stores                                                                 |

### Precision-strike CLSIDs

Use these exact launcher identifiers in `payload.pylons[index].CLSID`:

| Store             | CLSID                  | Station labels (payload indices) |
| ----------------- | ---------------------- | -------------------------------- |
| GBU-38 JDAM       | `{BRU-32 GBU-38}`      | 3, 4, 5, 6 (4, 5, 6, 7)          |
| GBU-31(V)2/B JDAM | `{BRU-32 GBU_31_V_2B}` | 3, 4, 5, 6 (4, 5, 6, 7)          |
| GBU-31(V)4/B JDAM | `{BRU-32 GBU_31_V_4B}` | 3, 4, 5, 6 (4, 5, 6, 7)          |
| GBU-24E           | `{BRU-32 GBU-24E}`     | 3, 5 (4, 6)                      |
| LANTIRN           | `{F14-LANTIRN-TP}`     | 8B (9)                           |

For example, this payload entry mounts a GBU-38 on station 3 (payload index 4):

```lua
[4] = {
    ["CLSID"] = "{BRU-32 GBU-38}",
},
```

## Mission Design Notes

- Select `F-14BU` explicitly when creating upgraded Tomcat slots or AI units. Changing the unit name or livery of an `F-14B` does not select this variant.
- Use the upgrade for late-service, 2000s multirole Tomcat scenarios, including long-range precision strike, reconnaissance, and forward air control as well as fleet defense.
- Use the upgrade for JDAM-equipped strike flights; do not assume its additional stores are supported by the baseline F-14B.
- LANTIRN occupies station 8B, so that station cannot simultaneously carry a missile or bomb rack.
- Validate complete loadouts in the Mission Editor, especially large belly-mounted bombs and mixed missile/bomb configurations. The datamine includes cross-station restrictions.
- A listed task or pod does not by itself establish a working weapon capability; for example, a SEAD task listing does not imply anti-radiation missile compatibility.

## Sources

- User-provided Heatblur F-14B Upgrade overview: late-service role, cockpit displays, navigation and mission-management systems, defensive suite, FTI, JDAM integration, and DFCS description.
- [Quaggles' DCS Lua Datamine — F-14BU aircraft definition](https://github.com/Quaggles/dcs-lua-datamine/blob/72ea893c452c728267d78a3bd481ca59501ce709/_G/db/Units/Planes/Plane/F-14BU.lua): aircraft identity, playable cockpit, tasks, station numbering, stores and launcher CLSIDs.
- [DCS World changelog](https://www.digitalcombatsimulator.com/en/news/changelog/): F-14B(U) introduction in DCS 2.9.28.26283 (22 July 2026).

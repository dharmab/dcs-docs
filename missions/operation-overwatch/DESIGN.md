# Operation Overwatch - Design

Status: draft

A close air support (CAS) mission on the Afghanistan terrain, set during the War in Afghanistan. Players take off from a hand-built Kandahar Airfield or forward arming and refueling points (FARPs). When a flight checks in on station, the mission generates a CAS tasking: friendly ground forces in contact with insurgents, controlled by a JTAC.

## Goals

- CAS is the core activity: find the friendlies, find the enemy, get cleared by the JTAC, and attack without fratricide.
- Each check-in produces a fresh tasking, so repeat sessions differ.
- Fixed-wing and rotary-wing flights get tasks suited to their speed, sensors, and weapons.
- Hand-built bases give a stable, believable home: Kandahar and the FARPs do not change between sessions.

## Non-Goals

- SEAD/DEAD and air-to-air. The enemy has no aircraft and no radar SAMs.
- Strategic campaign state. Taskings are independent.
- Night operations.
- Difficulty settings.

## Setting

Historical War in Afghanistan. Coalition (blue) aircraft operate from Kandahar Airfield in support of coalition ground forces. The enemy (red) is insurgent forces: infantry, technicals, mortars, and light AAA.

Date: 23 September 2010, daytime, during Operation Dragon Strike. The 101st Airborne launched Dragon Strike on 15 September 2010 to clear Zhari district, west of Kandahar City. Friendly vehicles of the period include MRAPs, M-ATVs, and Strykers.

Reasons for the date:

- 2010 was the peak year for enemy-initiated attacks, and insurgents favored direct fire over IEDs that year. Direct fire declined in 2011 as IED use rose. Kandahar and Helmand had over 60% of the violence in late 2010.
- Late September is still in the June-September fighting season and is cooler than mid-September, which helps helicopter performance at Kandahar's elevation.

## Player Aircraft

| Base     | Aircraft                                                       |
| -------- | -------------------------------------------------------------- |
| Kandahar | A-10C, AV-8B, F-16C, F/A-18C, F-15E, F-14B(U), M-2000C, CH-47F |
| FARPs    | AH-64D, OH-58D                                                 |

The M-2000C stands in for the French Mirage 2000D detachment at Kandahar. Slots favor the spirit of the setting over exact basing. USMC AV-8Bs left Kandahar in May 2010 and returned in 2011. The F-14 retired in 2006 but flew CAS over Afghanistan from carriers earlier in the war.

The CH-47F flies from Kandahar, where US, Canadian, and RAF Chinooks were based.

Following `docs/wisdom.md`, fixed-wing and rotary-wing flights get separate taskings with their own threat levels and distances.

## Bases

### Kandahar Airfield

Hand-built. Player slots use Dynamic Spawn for every player type at Kandahar and the FARPs, following `docs/recipes/player-slots.md`.

Static aircraft represent as many of the September 2010 Kandahar units as DCS has types for:

| Unit                               | Static type                     |
| ---------------------------------- | ------------------------------- |
| RAF Tornado detachment             | `Tornado GR4`                   |
| USAF 81st/354th EFS                | `A-10C`                         |
| Belgian and Dutch F-16 detachments | `F-16A MLU`                     |
| French Mirage 2000D detachment     | `M-2000C`                       |
| USMC VMFA-122                      | `F/A-18C`                       |
| USMC Harriers                      | `AV-8B N/A`                     |
| RAF No. 39 Sqn and USAF UAVs       | `MQ-9 Reaper`, `MQ-1A Predator` |
| RAF and USAF airlift               | `C-130`, `C-130J-30`, `C-17A`   |
| Contract airlift                   | `IL-76MD`, `Mi-8MTV2`           |
| US Army 101st CAB                  | `CH-47F`, `UH-60A`, `AH-64D`    |
| Canadian Air Wing, RAF 1310 Flight | `CH-47D`                        |

No DCS types exist for the MC-12W, CU-170 Heron, or CH-146 Griffon.

Static aircraft must not occupy parking stands that Dynamic Spawn needs. Place them on stands reserved for decoration or off-stand on aprons. Vehicles and structures (fuel trucks, hardened shelters, C-RAM) fill out the base. `docs/wisdom.md` warns that heavy airbase decoration hurts multiplayer performance, so measure frame rate and server load as the count grows.

### FARPs

Two hand-built FARPs with fuel, ammo, and ground crew:

- **FARP Pasab** at FOB Pasab (formerly FOB Wilson) on Highway 1 in Zhari district, Kandahar province: `x = -262650`, `z = -68950`.
- **FARP Gereshk**, 9 km west of Gereshk on Highway 1, Helmand province: `x = -237350`, `z = -160450`. Sangin, Gereshk, Lashkar Gah, and Nad-e Ali are within 20 nm.

Both positions are open ground with no fields or compounds within 300 m in the land cover export.

## CAS Tasking Flow

1. Players take off from Kandahar. Helicopters take off from Kandahar or a FARP.
2. Optionally, players refuel from a tanker.
3. Players fly toward the briefed check-in point and check in with the F10 Check In command. The command is added to the flight's group menu after takeoff (`S_EVENT_TAKEOFF`) and works anywhere while airborne, so a flight can request another tasking right after finishing one.
4. The mission generates a CAS tasking: a friendly element in contact with an enemy force, controlled by a JTAC (`docs/recipes/jtac-setup.md`) who gives the situation, target description, and marks (smoke, laser).
5. The players attack. The tasking succeeds when every key unit is destroyed or 70% of the enemy force is destroyed. Key units are the ones the JTAC names in the brief, such as technicals and ZU-23s. The JTAC then calls the enemy broken, and the remaining enemy units are removed.
6. Players RTB or request another tasking.

There is one check-in point, shared by all aircraft, on Highway 1 halfway between Kandahar Airfield and Camp Bastion (`x = -257475`, `z = -108266`). It is a briefed starting point, not a requirement.

### Tasking Placement

Fixed-wing taskings are placed on any tasking site in the area of operations, Kandahar and Helmand provinces, independent of the flight's position and the check-in point. Transit and fuel management across the area are part of the gameplay. Sites are chosen at runtime from a generated site mask rather than a hand-picked list, so taskings repeat less.

A tasking site is open ground or farmland with compounds within 1 km, outside cities, at least 5 km from airfields, on flat ground. These rules select the green zones along the Helmand and Arghandab rivers, where the 2010 fighting was, and leave out the open desert, which has no compounds for the enemy to fire from. `generate_terrain_data.py` builds the mask from the terrain export.

Helicopter taskings (AH-64D, OH-58D) are placed within 20 nm of a FARP, so rotary-wing flights get transits suited to their speed and range.

### Multiplayer

Up to 8 players. Up to 4 taskings run at once, so players can work one tasking together or fly separate ones. Each airborne flight's F10 menu has two items:

- **Check In:** generates a new tasking for the flight. When 4 taskings are active, Check In tells the flight to use Join Tasking instead.
- **Join Tasking:** a submenu listing all active taskings, most recent first. Each entry shows the tasking's name, type, and location. Selecting one assigns the flight to that tasking and sends it the JTAC's check-in brief. The submenu is rebuilt for every flight when a tasking starts or ends. With at most 4 entries, the F10 page limit does not matter.

The enemy force does not scale with the number of flights. A tasking also ends, and all its units are removed, 10 minutes after its last assigned flight lands, dies, or disconnects.

### Scenario Types

The first version has one scenario type: troops in contact (firefight). The others are candidates for later versions. The scenarios favor drama over realism: enemies are more numerous and more exposed than real insurgents were, and timelines are compressed.

"Rotary" and "Fixed" mark which flights a scenario suits.

#### Troops in Contact: Firefight

Rotary, Fixed. A friendly patrol is pinned by insurgents in a compound or treeline. The two sides trade fire with AI-controlled tracers and RPGs, so the fight is visible from altitude. The success rule is the default (key units or 70% of the enemy).

The enemy is 400-900 m from the friendlies, spread over about 150 m. Afghanistan firefights were long range: about half of engagements were beyond 300 m, and insurgents often fired from 500 m or more off high ground, where troops could not see who was shooting at them (Ehrhart, "Increasing Small Arms Lethality in Afghanistan: Taking Back the Infantry Half-Kilometer", 2009). The JTAC's brief reflects this: the enemy count and range are estimates, the friendlies cannot see the shooters, and the smoke marks the approximate enemy position. Finding the enemy is part of the task.

#### Troops in Contact: Convoy Ambush

Rotary, Fixed. A friendly convoy is stopped on a road after an IED disables the lead vehicle. The enemy is on high ground or in compounds along the road (`docs/recipes/convoy-route.md`). After the tasking succeeds, the convoy resumes its route, and the tasking ends when the convoy reaches its destination. Variant: the ambush starts after check-in, and the flight is already overhead escorting the convoy.

#### Show of Force

Rotary, Fixed. A crowd or a group of fighting-age males is massing near a friendly patrol, and the JTAC wants them to disperse without anyone firing. The JTAC names a point, a run-in heading, and a maximum height. The pass counts when an aircraft crosses within a set distance of the point, below the height, and within 30° of the heading. On a good pass the enemy group drives or walks away and the tasking succeeds. A pass that is too high or from the wrong direction draws "negative effect, make another pass." Releasing weapons fails the tasking. Flares on the pass are a crowd-pleaser and could count as a bonus.

#### Cache Destruction

Rotary, Fixed. Friendlies have found a weapons cache in a compound and cannot carry it out. The JTAC holds the flight until the friendly element withdraws past a safe distance, then clears the attack. Destroying the cache static triggers a chain of secondary explosions with `trigger.action.explosion`. An attack before the clearance, or one that hits the friendlies, fails the tasking.

#### Mortar or Rocket Team

Fixed, Rotary. A FOB is under indirect fire. Counter-battery radar gives the point of origin as a grid, and the JTAC gives an area, not a precise target. The flight searches for the team, which fires a salvo every few minutes and packs up to move if not found in time. Mortar impacts on the FOB give the scenario a clock.

#### Squirters

Rotary, Fixed. Insurgents break contact from a fight in technicals and light vehicles. The JTAC keeps eyes on with the Reaper and calls the vehicles' movement. The flight must strike them before they reach a village, where the JTAC calls them "off limits" and the tasking fails.

#### IED Emplacers

Rotary. Two or three men are digging in on a route that a convoy will use within the hour. The JTAC can't clear the attack until the men show hostile intent, such as uncoiling wire or retrieving a weapon. The rules are tight, so this scenario fits the slower, sensor-heavy OH-58D and AH-64D.

#### Raid Support

Rotary, Fixed. Friendly special forces raid a compound to capture a commander. The flight arrives before the raid and watches the compound. When the raid starts, the flight strikes enemy reinforcements and squirters. The friendlies are inside the compound throughout, so every attack is danger close.

### Tasking Modifiers

A modifier changes the rules of a scenario. A tasking draws zero or one modifier, chosen to fit the scenario:

- **Danger close:** friendlies are within 100 m of the target. The JTAC requires the flight to acknowledge, and any friendly loss fails the tasking.
- **Collateral concern:** civilians or a mosque are near the target. The JTAC restricts weapons, such as guns or rockets only, or no bombs heavier than 500 lb.
- **Final attack heading:** the JTAC restricts the run-in heading to keep the effects away from the friendlies.
- **Time on target:** the attack must happen within a short window, timed to a friendly maneuver.

### Enemy Composition

Each tasking rolls its enemy force from a pool, so players do not know what they will face until they arrive. Unit types are in `docs/units/ground.md`.

| Element        | Types                                      | Fixed-wing | Rotary-wing | Count |
| -------------- | ------------------------------------------ | ---------- | ----------- | ----- |
| Riflemen       | `Infantry AK Ins`                          | Always     | Always      | 6-12  |
| RPG gunners    | `Soldier RPG`                              | Always     | Always      | 1-3   |
| Technicals     | `HL_DSHK`, `HL_KORD`, `tt_DSHK`, `tt_KORD` | 70%        | 70%         | 1-3   |
| Light vehicles | `UAZ-469`, `VAZ Car`                       | 50%        | 50%         | 1-2   |
| ZU-23          | `HL_ZU-23`, `tt_ZU-23`, `ZU-23 Insurgent`  | 25%        | 15%         | 1     |
| MANPADS        | `Igla manpad INS`                          | 15%        | 10%         | 1     |

Light vehicles are unarmed. They carry fighters to the fight and drive away when the enemy breaks.

Skill is randomized per unit among the upper tiers, following `docs/wisdom.md`.

Scenario adjustments:

- **Show of Force:** riflemen and light vehicles only, holding fire, plus the MANPADS roll. If the MANPADS launches, the enemy opens fire and the tasking becomes a firefight.
- **Cache Destruction:** half the usual counts. The enemy probes the friendlies while they withdraw.
- **Mortar or Rocket Team:** adds a `2B11 mortar` or a rocket technical (`HL_B8M1`, `tt_B8M1`) as the key unit. No ZU-23.
- **Squirters:** technicals and light vehicles always, 2-4 of each. No ZU-23.
- **IED Emplacers:** 2-3 riflemen and one light vehicle. No other rolls.

### MANPADS

The MANPADS is a surprise. The JTAC never names it as a key unit, and it is placed 1-2 km from the main enemy, on high ground or in a compound, so the threat comes from an unexpected direction.

The JTAC's brief may include "reports of a SAM team in the area." The warning is a hint, not a guarantee: it is given for 50% of taskings with a MANPADS and 20% of taskings without one. After a launch, the JTAC calls "SAM launch" with a bearing from the friendlies, and the MANPADS becomes a key unit.

### Threats

Low to medium. Small arms and RPGs in every tasking, technicals in most, and a ZU-23 or MANPADS in some.

## Stretch Goal: CH-47 Transport Taskings

Dynamically generated transport taskings for the CH-47F, using the same check-in flow as CAS: move troops or cargo between Kandahar, the FARPs, and FOBs. Details wait until CAS taskings work.

## Support Assets

- Tankers: one boom and one basket track over the Registan desert south of the green zones, between Kandahar and Helmand (`docs/recipes/tanker-setup.md`). The boom track runs east-west at `x = -310000` from `z = -130000` to `z = -60000`. The basket track runs east-west at `x = -330000` from `z = -140000` to `z = -70000`. Both legs are 70 km, and the nearest tasking site is 24 km from the boom track and 14 km from the basket track.
- AWACS: datalink only. Voice GCI from SkyEye (`docs/recipes/awacs-setup.md`).
- JTAC: one MQ-9 Reaper per tasking, orbiting overhead. No ground JTACs; `docs/recipes/jtac-setup.md` rates UAVs as the most reliable.

## Communications

Follow `docs/recipes/comm-plan.md`, except for JTACs. Each of the 4 tasking slots has a fixed JTAC frequency on UHF AM (256.1, 256.3, 256.5, 256.7), preset in every player aircraft. The recipe puts JTACs on FM, which the M-2000C cannot tune, and fixed-wing CAS check-ins of the period were on UHF. The tasking's check-in brief names its frequency.

## Technical Notes

- `TerrainData.lua` is generated from `docs/data/terrains/Afghanistan/` by `generate_terrain_data.py`. It contains the area of operations polygon and the tasking site mask.
- Candidate reuse from Operation Infinity: `Logging`, `Units`, `Spatial`, `Terrain`, `Formations`, `Virtualization`, and the offline test harness.

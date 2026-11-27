# Operation Overwatch - Agent Notes

CAS mission on the Afghanistan terrain. Tunables live in `OperationOverwatch.config` in `src/l10n/DEFAULT/OperationOverwatch.lua`.

## Status

The mission file is hand-written and has not been opened in DCS. Pack it with `uv run pack_mission.py`. Values that need a DCS install are marked `TODO(dcs)` (`grep -rn "TODO(dcs)" src`):

- Kandahar's airdromeId (placeholder `9999` in `mission` and `warehouses`) and a parking stand for each Kandahar template. The Mission Editor also writes every other Afghanistan airport into `warehouses`.
- `wsType` for `AV8BNA`, `CH-47Fbl1`, `AH-64D_BLK_II`, and `OH-58D` (placeholders end in `0`). A wrong `wsType` shows the type greyed out with `(0)` in the spawn dialog.
- `country.id.INSURGENTS` (`17` in `coalitions` and the red country).
- The AV-8B radio layout, and radio presets for the helicopters, which have none.
- Kandahar elevation (`alt = 1017`) and FARP heights.

Mission contents: dynamic spawn templates at Kandahar for every fixed-wing type and the CH-47F, AH-64D and OH-58D templates at each FARP, FARP statics with fuel and ammo trucks, the Texaco and Arco tankers, the Overlord AWACS, and the script load trigger. Main radio presets follow the comm card in `dictionary`.

`TerrainData.lua` is generated; do not edit it. It contains the area of operations polygon (Kandahar and Helmand provinces) and a 200 m mask of tasking sites, built from `docs/data/terrains/Afghanistan/`. Regenerate with `uv run python generate_terrain_data.py` after a terrain re-export or a change to the site rules. The generator's docstring and constants define a site.

`kandahar-layout.md` describes Kandahar's aprons and stand rows, for placing statics. `kandahar-parking.csv` lists every stand at Kandahar and Kandahar Heliport, from `airbase:getParking()` logged in game.

The FARP positions and check-in point in the config were chosen from the export: open ground with no fields or compounds within 300 m. Check them in the Mission Editor before building the FARPs.

## Scripts

Load order:

1. `Logging.lua`, `Units.lua`, `Spatial.lua` (copied unchanged from Operation Infinity)
2. `TerrainData.lua` - generated area of operations and site mask
3. `EnemyForce.lua` - rolls the insurgent force from weighted pools
4. `Sites.lua` - picks tasking locations and nearby points
5. `Firefight.lua` - spawns the friendly patrol, enemy groups, and MQ-9 JTAC
6. `Tasking.lua` - tasking lifecycle, success and abandonment, JTAC calls, laser
7. `OperationOverwatch.lua` - config, events, per-flight F10 menus

When adding a script, update `Harness.scripts` in `tests/harness.lua`, the load trigger (`trigrules` and `trig.actions`) in `mission`, `mapResource`, and both lists in `pack_mission.py`. `tests/script_list_test.lua` fails if any of them disagree. `tests/mission_test.lua` checks that the mission's FARPs, helicopter templates, and JTAC presets match the config.

Style follows Operation Infinity: `array[#array + 1] = value`, named constants for magic numbers, verbose logging.

## Tests

`luajit tests/run.lua tests/*_test.lua` from this directory, or `make test`. `tests/dcs_mock.lua` is Operation Infinity's mock with flat open land, no airbases or roads, and a fake coordinate projection. `harness.load()` replaces the area of operations, FARPs, and site grid with placeholders around the origin (`Harness.testArea`, `Harness.testFarps`, `Harness.testGrid`). Pass `realTerrain = true` to keep the generated data, or `noArea = true` to leave them unset. `harness.takeOff()` adds an airborne player and fires `S_EVENT_TAKEOFF`.

## Design Decisions

- Flights are player groups, keyed by group name. Check In appears after `S_EVENT_TAKEOFF` and is removed on land, crash, eject, death, or leaving the unit.
- Fixed-wing flights get `fixed` taskings on any site in the area, each site cell equally likely. Helicopters in `rotaryCasTypes` get `rotary` taskings on a site near a FARP, found by rejection sampling inside the FARP radius.
- Sites are open ground or farmland with compounds within 1 km, outside cities, at least 5 km from airfields, on flat ground. These are the green zones along the Helmand and Arghandab rivers. The open desert has no sites. Other helicopters (CH-47F) get no menu.
- The enemy is 400-900 m from the friendlies. Afghanistan engagements were long range and troops often could not see the shooters, so the brief gives an estimated count and range and smoke marks the approximate position.
- Every ground group is invisible to AI, so the two sides cannot kill each other while FireAtPoint runs. Friendlies are also immortal. Players see and attack the enemy normally.
- AI sensors cannot see invisible groups, so the MQ-9's `FAC_EngageGroup` task may never find its target. The script lasers the first living key unit from the MQ-9 itself (`Spot.createLaser`, code `laserCode`) and pops smoke on each check-in brief.
- Success is checked every 5 s by polling unit life, not by events.
- JTACs are on UHF AM 256.1-256.7, not the FM JTAC block in `docs/recipes/comm-plan.md`, so every player aircraft can tune them (the M-2000C has no FM radio). Do not change the recipe for this mission.

## Untested in DCS

Nothing has run on a server yet. Check these first:

- Whether the AFAC MQ-9 talks on the radio menu with invisible targets.
- `country.id.INSURGENTS` for red. The mission file's coalition setup must include it.
- `CHAP_MATV` and `M30_CC` spawn and behave as expected.
- Whether RPG and DShK FireAtPoint at 400-900 m keeps firing; RPG-7 range is short of the far end.

## Not Implemented

Scenario types other than Firefight, tasking modifiers, light vehicles driving away when the enemy breaks, failure on friendly loss (hits only draw a cease-fire call), base decoration, helicopter radio presets, and CH-47 transport taskings.

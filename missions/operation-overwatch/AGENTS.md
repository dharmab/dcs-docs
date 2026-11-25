# Operation Overwatch - Agent Notes

CAS mission on the Afghanistan terrain. Tunables live in `OperationOverwatch.config` in `src/l10n/DEFAULT/OperationOverwatch.lua`.

## Status

Scripts and offline tests only. The mission file (`src/mission`, `theatre`, `warehouses`, `options`, `dictionary`, `mapResource`) and `pack_mission.py` wait for the Afghanistan terrain export, so `make check-missions` skips this mission until `src/mission` exists.

Config values marked `TODO(terrain)` wait for the export: `areaOfOperations`, `farps`, and `checkInPoint`. `Sites:isValidPoint` only checks the surface type until the export gives land cover, slope, towns, and roads.

## Scripts

Load order:

1. `Logging.lua`, `Units.lua`, `Spatial.lua` (copied unchanged from Operation Infinity)
2. `EnemyForce.lua` - rolls the insurgent force from weighted pools
3. `Sites.lua` - picks tasking locations and nearby points
4. `Firefight.lua` - spawns the friendly patrol, enemy groups, and MQ-9 JTAC
5. `Tasking.lua` - tasking lifecycle, success and abandonment, JTAC calls, laser
6. `OperationOverwatch.lua` - config, events, per-flight F10 menus

When adding a script, update `Harness.scripts` in `tests/harness.lua`. `tests/script_list_test.lua` fails if it disagrees with `l10n/DEFAULT`. Once the mission file exists, also update the load trigger, `mapResource`, and `pack_mission.py`, and extend the test as in Operation Infinity.

Style follows Operation Infinity: `array[#array + 1] = value`, named constants for magic numbers, verbose logging.

## Tests

`luajit tests/run.lua tests/*_test.lua` from this directory, or `make test`. `tests/dcs_mock.lua` is Operation Infinity's mock with flat open land, no airbases or roads, and a fake coordinate projection. `harness.load()` sets a placeholder area of operations and FARP (`Harness.testArea`, `Harness.testFarps`); pass `noArea = true` to leave them unset. `harness.takeOff()` adds an airborne player and fires `S_EVENT_TAKEOFF`.

## Design Decisions

- Flights are player groups, keyed by group name. Check In appears after `S_EVENT_TAKEOFF` and is removed on land, crash, eject, death, or leaving the unit.
- Fixed-wing flights get `fixed` taskings anywhere in the area. Helicopters in `rotaryCasTypes` get `rotary` taskings near a FARP. Other helicopters (CH-47F) get no menu.
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

Scenario types other than Firefight, tasking modifiers, light vehicles driving away when the enemy breaks, failure on friendly loss (hits only draw a cease-fire call), tankers, AWACS, base decoration, and CH-47 transport taskings.

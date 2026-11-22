# Operation Infinity - Agent Notes

Player-facing overview is in `README.md`. Tunables (regions, SAM counts, support aircraft, durations) live in `OperationInfinity.config` in `src/l10n/DEFAULT/OperationInfinity.lua`; read the code for numbers rather than trusting docs.

## Scripts

Load order (dependencies):

1. `Logging.lua`
2. `Units.lua`
3. `Spatial.lua`
4. `BatchScheduler.lua`
5. `TerrainData.lua`
6. `Terrain.lua`
7. `UnitTemplates.lua`
8. `Formations.lua`
9. `Virtualization.lua`
10. `IADS.lua`
11. `AirIntercept.lua`
12. `BattlefieldGeneration.lua`
13. `CarrierOps.lua`
14. `OperationInfinity.lua`

When adding a script, update all five places: `Harness.scripts` in `tests/harness.lua`, the "Load Mission Scripts" trigger (`trigrules` and `trig.actions` in `src/mission`), `src/l10n/DEFAULT/mapResource`, and both file lists in `pack_mission.py`. `tests/script_list_test.lua` fails if they disagree.

Style:

- `array[#array + 1] = value`, not `table.insert()`
- Name all magic numbers except -1, 0, and 1 as constants
- Verbose logging is intentional; DCS has little observability. IADS state changes log with an `[IADS]` prefix.
- Use `Logging`, `Units`, and `Spatial` for shared functionality

## Tests

`tests/` runs the scripts offline under LuaJIT (Lua 5.1, like DCS): `make test`, or `luajit tests/run.lua tests/*_test.lua` from this directory. `harness.load()` gives each test a fresh `dcs_mock.lua` environment with the mission file's groups and all 14 scripts loaded; `env.advance(seconds)` runs scheduled functions. `generation_test.lua` runs seeds 1-3 for every region, playtime, and difficulty; set `GENERATION_SEEDS=N` to run seeds 1-N (about 0.6 s per seed).

Scripts run in their own global table without `io`, `lfs`, `os`, `require`, `loadlib`, and `package`, as in DCS. Test code keeps the full standard library and reads script globals through `_G`.

The mock has no AI. Units only move when a test moves them. Enum values come from `docs/scripting/reference`. The generation tests fail if a script calls an API the mock lacks; add it to `dcs_mock.lua` with behavior checked against the docs.

`tests/terrain_model.lua` answers `land.getSurfaceType`, `land.getClosestPointOnRoads`, and `coord.LOtoLL`/`LLtoLO`/`LLtoMGRS` from the terrain export. Surface types come from the 100 m land cover; ROAD is within 5 m of a road line. Height is flat because the export has no elevation. The roads are the Mission Editor map overlay, which has fewer roads than the 3D terrain, so road placement fails more often offline than in DCS. Only the `roads` network exists.

## Terrain Data

`TerrainData.lua` is generated; do not edit it. It is a 200 m mask of forest, water, and off-mesh ground built from `docs/data/terrains/Caucasus/landcover.tif`. Regenerate with `uv run python generate_terrain_data.py` after a terrain re-export or a change to the mission area. The generator also writes `tests/mock_terrain.lua`, the test mock's terrain, which the mission does not load.

`Terrain:isValidTerrainForUnits` checks the mask first, then surface type, slope, roughness, and road distance, then scenery (buildings, bridges, pylons) within `sceneryClearance`. The land cover `town` class is too loose to reject on, so buildings are only checked at runtime. That check covers only one point, so groups are placed with `Terrain:findValidLayout`, which builds the units at each candidate center and also checks every unit's position against the mask and surface type (`isValidUnitPosition`). Convoys use `Terrain:findRoadLayout` instead: snapped onto a road, laid out as a column along it, and exempt from the scenery check. The generation tests fail if any spawned ground unit is on blocked ground. Airfield positions are read from the airbases at init and support racetracks are offsets from Krymsk.

## Player Slots

Dynamic spawn at Krymsk (airdromeId 15) and on the Stennis (ship warehouse keyed by unitId 20, carrier types only). Templates only apply when the warehouse stock entry links them with `linkDynTempl`, so both bases stock each type explicitly (`unlimitedAircrafts = false`, per-type `unlimited = true`). Krymsk templates are groups 1-14, 29, and 31-33; Stennis templates are 25-28.

`F-14BU` is a real type string (Quaggles' datamine, `F-14BU.lua`, display name "F-14B(U)").

## Comms Plan

Follow `docs/recipes/comm-plan.md`. Mission-specific rules:

- Main radio: every channel means the same thing in every aircraft except ch3-6 (home block, by spawn base) and ch7-8 (tankers, by boom or probe). 18 channels so the F-4E fits.
- V/UHF second radios: ch1 SkyEye VHF, ch2-20 = main ch1-19.
- A-10 ARC-210 preset names go in `channelsNames` beside `channels`; it is the only radio with editable names.
- FC3 aircraft get no presets.
- The in-game AWACS has `communication = false` (datalink only). Voice GCI is SkyEye.
- The comms card exists in two places that must match: `displayCommsPlan` in `OperationInfinity.lua` and the shared briefing (`DictKey_descriptionText_1`) in `dictionary`. `comms/*.md` are per-aircraft preset cards generated from the mission by `luajit tests/comms_cards.lua`; regenerate after changing presets, tankers, or carrier systems. `tests/comms_plan_test.lua` fails if they are stale.

## Factions

- ISAF: `docs/factions/isaf-2004.md` or `isaf-2005.md`
- Erusea: `docs/factions/erusea-2004.md` for Easy/Normal, `erusea-2005.md` for Hard

## Gotchas

- Interceptors read their spawn point from the airbase at runtime. A route point off the airdrome makes DCS air-start the group.
- Interceptor removal can fire DEAD, CRASH, UNIT_LOST, and LAND for one aircraft; removals are de-duplicated by unit name.
- The S-3B recovery tanker (`Arco 2`) shares the Arco callsign because DCS has only three tanker callsigns. It is not in `supportAircraft`; it starts at mission load with its tasks on waypoint 1, and `getSupportAssetText` lists it with a hardcoded line.
- `supportAircraft` stores altitude in feet and IAS in knots; Orbit TAS is computed at runtime.
- `CarrierOps.lua` starts at mission load, independent of F10 settings. Carrier radio/TACAN/ICLS/Link 4 are set on waypoint 1 and must be re-applied after every route change.
- Per-group F10 items (Comms Plan, Mission Info) are added by the late-joiner loop and reply only to that group. Settings items are coalition-wide.

## Not Implemented

Do not assume these exist: enemy helicopters, Very Easy immortal/hold-fire targets, virtualized air assets, EPLRS membership for late joiners. `UnitTemplates.AAA` is defined but unused. The Maykop region has no enemy fighters (no intercept zone covers it).

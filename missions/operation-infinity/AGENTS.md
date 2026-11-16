# Operation Infinity - Agent Notes

Player-facing overview is in `README.md`. Tunables (regions, SAM counts, support aircraft, durations) live in `OperationInfinity.config` in `src/l10n/DEFAULT/OperationInfinity.lua`; read the code for numbers rather than trusting docs.

## Scripts

Load order (dependencies):

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

Style:

- `array[#array + 1] = value`, not `table.insert()`
- Name all magic numbers except -1, 0, and 1 as constants
- Verbose logging is intentional; DCS has little observability. IADS state changes log with an `[IADS]` prefix.
- Use `Logging`, `Units`, and `Spatial` for shared functionality

## Player Slots

Dynamic spawn at Krymsk (airdromeId 15) and on the Stennis (ship warehouse keyed by unitId 20, carrier types only). Templates only apply when the warehouse stock entry links them with `linkDynTempl`, so both bases stock each type explicitly (`unlimitedAircrafts = false`, per-type `unlimited = true`). Krymsk templates are groups 1-14 and 29; Stennis templates are 25-28.

`F-14BU` is a real type string (Quaggles' datamine, `F-14BU.lua`, display name "F-14B(U)").

## Comms Plan

Follow `docs/recipes/comm-plan.md`. Mission-specific rules:

- Main radio: every channel means the same thing in every aircraft except ch3-6 (home block, by spawn base) and ch7-8 (tankers, by boom or probe). 18 channels so the F-4E fits.
- V/UHF second radios: ch1 SkyEye VHF, ch2-20 = main ch1-19.
- A-10 ARC-210 preset names go in `channelsNames` beside `channels`; it is the only radio with editable names.
- FC3 aircraft get no presets.
- The in-game AWACS has `communication = false` (datalink only). Voice GCI is SkyEye.
- The comms card exists in three places that must match: `displayCommsPlan` in `OperationInfinity.lua`, the blue-task briefing in `dictionary`, and `README.md`.

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

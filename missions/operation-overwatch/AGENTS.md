# Operation Overwatch - Agent Notes

CAS mission on the Afghanistan terrain. Tunables live in `OperationOverwatch.config` in `src/l10n/DEFAULT/OperationOverwatch.lua`.

## Status

The mission file is hand-written and has not been opened in DCS. Pack it with `uv run pack_mission.py`. Values that need a DCS install are marked `TODO(dcs)` (`grep -rn "TODO(dcs)" src`):

- A parking stand for the CH-47F template at Kandahar. It still uses stand `1`, which is the M-2000C template's. No ME label is known for any Kandahar helicopter stand.
- The AV-8B radio layout, and radio presets for the helicopters, which have none.
- FARP heights. The helicopter templates use `alt = 0` `RADIO`. The 1 km elevation export is too coarse to give the ground height.

Values taken from the DCS install:

- Kandahar is airdrome `7` (`airfield7` in `Mods/terrains/Afghanistan/beacons.lua`). Camp Bastion is airdrome `10` (`airfield10`, `Camp_Bastion`), Camp Bastion Heliport `13` (`airfield13`, `Camp_Bastion_Heli`), and Kandahar Heliport `15` (`airfield15`, `Kandahar_Heli`), all in `radio.lua`. `warehouses` lists these four airbases and FARP Pasab, all blue. Camp Bastion and Kandahar Heliport have no Dynamic Spawn but unlimited fuel and munitions.
- Camp Bastion Heliport template stands, from the installed `IA-Afgham-AH64D-*` missions, which park AH-64Ds there: AH-64D stand `16` `TRJ04-H`, OH-58D stand `24` `TRJ03-H`, `alt = 886`. The UH-1H uses stand `33` `TRJ02-H`, from `IA-Afgham-F18C-Cold Start.miz` and `IA-Afgham-A10C-Cold Start.miz`, which park an AH-64D there. None of the three stands has been checked for fit. UH-1H `wsType` `{ 1, 2, 6, 166 }`, loadout CLSIDs (`XM158_M151`, `M134_SIDE_L`, `M134_SIDE_R`), and the `US NAVY` livery come from installed missions. The Mission Editor also writes every other Afghanistan airport.
- `country.id.INSURGENTS` is `17`. `Scripts/Database/db_countries.lua` numbers countries in order from 0 and skips 14.
- `wsType` values come from the most common value in the ME-saved `.miz` files that ship with the install. The fourth number can change when modules are added, so values in old saves vary.
- Fixed-wing template stands, by `term_index` (`kandahar-parking.csv`) and ME label: A-10C `297` J01, AV-8B `203` J03, F-16C `28` W01, F/A-18C `16` W02, F-15E `174` S04, F-14B(U) `258` T02, M-2000C `1` Y01 (a `Term_Type` 72 stand). Each label pair comes from an installed Afghanistan mission and matches the runway side given in `kandahar-layout.md`. Position and `alt` are the stand's from the CSV. None of the stands has a decoration static, but whether each one is big enough for its type has not been checked.

Mission contents: dynamic spawn templates at Kandahar for every fixed-wing type and the CH-47F, plus AH-64D, OH-58D, and UH-1H templates at FARP Pasab and Camp Bastion Heliport, the FARP Pasab static with fuel and ammo trucks, 535 decoration statics (aircraft, vehicles, and ground support equipment) at Kandahar and Kandahar Heliport, 255 at Camp Bastion and Camp Bastion Heliport, 22 at the FARP Pasab flight line, the Texaco and Arco tankers, the Overlord AWACS, and the script load trigger. Main radio presets follow the comm card in `dictionary`.

`TerrainData.lua` is generated; do not edit it. It contains the area of operations polygon (Kandahar and Helmand provinces) and a 200 m mask of tasking sites, built from `docs/data/terrains/Afghanistan/`. Regenerate with `uv run python generate_terrain_data.py` after a terrain re-export or a change to the site rules. The generator's docstring and constants define a site.

`kandahar-layout.md` describes Kandahar's aprons and stand rows, for placing statics. `kandahar-parking.csv` lists every stand at Kandahar and Kandahar Heliport, from `airbase:getParking()` logged in game. `bastion-layout.md` and `bastion-parking.csv` do the same for Camp Bastion and its heliport. That CSV comes from the terrain's `AirfieldsTaxiways/*.rn5` files, which also give each stand's ME label and heading; `bastion-layout.md` describes the format.

The check-in point was chosen from the export: open ground with no fields or compounds within 300 m. FARP Pasab is an Invisible FARP (`Invisible FARP`, shape `invisiblefarp`, one pad) on the old airstrip north of FOB Pasab, which the map models. The strip ends were measured with the Mission Editor ruler: x -262291, y -68906 to x -262218, y -68492, heading 080. Pad markers sit on the strip centreline at 50 m spacing, and the support area is 30 m north of it, because FOB buildings start within 30 m south of the centreline.

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
- `CHAP_MATV` and `M30_CC` spawn and behave as expected.
- Kandahar decoration: each static sits on its stand, faces a sensible way (headings are estimates from the stand pattern), and gets its country's default livery (no `livery_id` is set). Blue includes UK, France, Canada, The Netherlands, Belgium, and Ukraine for these statics. Contract airlift (IL-76MD, An-26, Yak-40) is under Ukraine with an explicit `livery_id`, because those types have no USA livery. The contract Mi-8s stay under USA, which has the `USA_AFG` livery. Dynamic Spawn still finds free stands for every type, including the F-14 and F-15E. The Massun92 ground equipment (power carts, tugs, light carts, cargo pallets) shows up and sits clear of the aircraft. The 812 decoration statics (535 at Kandahar, 255 at Camp Bastion, 22 at FARP Pasab) do not hurt load time or frame rate on the server. The statics are `hidden` on the F10 map. The Mission Editor also leaves `hidden` groups off its own map until Show Hidden is ticked in the units list panel.
- Camp Bastion decoration: aircraft sit on their stands and face the taxiway (headings from the `.rn5` stand matrices, not checked in game). The `livery_id` values (`ch-47_green uk`, `ah-64_d_green uk`, `Royal Air Force`, `RAF 47 Sqn, RAF Brize Norton`, `USA Marines`, `US NAVY`) apply. Ground equipment sits clear of taxiways and of buildings, which the `.rn5` files do not include. Players still spawn on the heliport's `TRJ` row, and Dynamic Spawn finds free heliport stands with 13 of 32 taken.
- Template loadouts (2004-2010 CAS, GBU-54 included) prefill the spawn dialog. Whether the AV-8B's flare-only `EWDispenser*` and the F-14B(U)'s `ALE39Loadout = 0` from the template's `AddPropAircraft` apply to the spawned aircraft. Other types start with their default chaff and flares; players move the slider.
- FARP Pasab: helicopters spawn on the Invisible FARP and can rearm and refuel there. Only one helicopter can spawn at a time, because the FARP has one pad. The tyres sit on the strip and the tents and trucks just north of it, clear of FOB buildings. Positions come from a screenshot ruler, so each could be off by up to 10 m.
- Camp Bastion, Kandahar Heliport, and Camp Bastion Heliport show blue on the F10 map, and helicopters can rearm and refuel at all three.
- Camp Bastion Heliport: the AH-64D, OH-58D, and UH-1H spawn there. The UH-1H also spawns at FARP Pasab, gets rotary CAS taskings, and its livery and loadout prefill the spawn dialog.
- Whether RPG and DShK FireAtPoint at 400-900 m keeps firing; RPG-7 range is short of the far end.

## To Do

- Set the other coalition airbases to blue. Kandahar, Kandahar Heliport, Camp Bastion, and Camp Bastion Heliport are done.

## Not Implemented

Scenario types other than Firefight, tasking modifiers, light vehicles driving away when the enemy breaks, failure on friendly loss (hits only draw a cease-fire call), FARP and structure decoration (tents, HESCO, hangars), helicopter radio presets, and CH-47 transport taskings.

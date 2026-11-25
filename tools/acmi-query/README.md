# acmi-query

Tacview records DCS sessions as ACMI files. An ACMI file shows what AI units and spawn scripts actually did: when groups spawned and despawned, where aircraft flew, who fired what, and what died. `acmi-query` indexes and queries these recordings. This page also covers the quirks of DCS recordings and the file format.

Upstream spec: [ACMI flight recordings 2.2](https://raia-software-inc.gitbook.io/tacview/technical-documentation/acmi-telemetry-file-format).

## Usage

Recordings are too large for an AI agent's context window. A multi-hour multiplayer session can be hundreds of megabytes zipped. The first query against a recording builds a SQLite cache in the system temp directory. This can take a while for a long session. Later queries are fast. Caches unused for a day are deleted automatically.

The tool strips control characters and terminal escape codes from names and messages, and rejects zipped recordings that decompress to more than 4 GiB.

You must use [uv](https://docs.astral.sh/uv/) to run this tool, not
`python acmi_query.py`.

```bash
# Show the mission, DCS version, duration, and object counts
uv run acmi-query summary Tacview-example.zip.acmi
# Show when each group spawned and how many units it lost
uv run acmi-query groups Tacview-example.zip.acmi
# Show missile and bomb launches by one group
uv run acmi-query shots Tacview-example.zip.acmi --launcher "SA-11 Site 1"
# Rebuild the cache
uv run acmi-query index Tacview-example.zip.acmi --force
```

### Commands

| Command               | Use it to answer                                                                                                                                                      |
| --------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `summary`             | What mission, DCS version, duration, and object counts by type and color?                                                                                             |
| `groups`              | When did each group spawn, how many units, how many were removed?                                                                                                     |
| `objects`             | Which units existed, with spawn and removal times and spawn position in mission x/y? `--alive-at T` shows a snapshot. `--kind weapon\|ephemeral\|all` widens the set. |
| `timeline`            | What happened in order? Unit spawns, removals, weapon launches, and `Event=` lines.                                                                                   |
| `track OBJ`           | Where did a unit go? Lat/lon, mission x/y, altitude, heading, ground speed, vertical speed, roll, and pitch every `--interval` seconds.                               |
| `near OBJ --range NM` | What came within range of a unit, when, and how close?                                                                                                                |
| `shots`               | Who launched each missile or bomb, how long it flew, which unit was nearest when it ended, and whether that unit was removed soon after.                              |
| `removals`            | Why did each unit disappear? Lists the nearest weapon that ended within `--radius` meters and `--window` seconds.                                                     |
| `guns`                | Which units fired guns, cannons, or AAA, how many recorded rounds, and when.                                                                                          |

`OBJ` is a hex object ID, a unit name, or a group name. Unit names repeat when a script respawns a group; the tool lists the matches with spawn times, and `--from`/`--to` picks the right one.

Common filters:

- `--type Air+FixedWing` matches whole tags, all of which must be present. `--type Air` matches aircraft but not `AntiAircraft`.
- `--name SA-11` is a substring of the model name, `--group` a substring of the group name, and `--unit` a substring of the unit name.
- `--color Red|Blue|Grey|Violet`.
- `--from`/`--to` accept seconds from recording start or mission clock `HH:MM[:SS]`, the clock Tacview displays.
- `--json` for machine-readable output, `--limit N` for row count (default 500).

### Debugging Recipes

**Spawn script did not spawn, or spawned too much.** Run `groups --group <prefix>` to see spawn times and counts per group. Run `timeline --group <prefix> --no-weapons` for the per-unit order. Groups that spawn and vanish within seconds show up as short `life_s` in `objects`.

**AI did not engage.** Run `near <target> --range 20 --type Air` to confirm the AI was in range. Then run `shots --launcher <ai group>` to see whether it fired. Use `track` to see whether it turned toward the target.

**SAM or AAA did not fire.** Run `shots --group <sam group>` and `guns --group <sam group>`. If there are no launches while `near` shows targets in range, check emission control, ROE, and alarm state in the script.

**Unit disappeared.** Run `removals --unit <name>`. `no weapon nearby` with `gs_kt` 0 on the ground usually means a script despawn or a landing and shutdown. In flight it means a crash, a player disconnect, or a script `destroy()`.

## DCS Recording Quirks

These come from a DCS 2.9 recording made with DCS2ACMI 1.8.7.

- **Red is `Allies`.** DCS red units have `Color=Red` with `Coalition=Allies`, and blue units have `Color=Blue` with `Coalition=Enemies`. This dates back to DCS's origin in the 1990s Su-27 Flanker games, where Russia (red) was the player's side. Filter on Color to avoid confusion.
- **No events, launchers, or locks.** The recording has no `Event=` lines, no `Parent`, and no speed properties. DCS never exports `LockedTarget`; other sims do. `acmi-query` infers launchers by finding the nearest unit within 900 m when a weapon spawns, preferring the same color. It infers hits from proximity when a weapon is removed. Treat both as strong guesses. Nearby units of the same color, such as a SAM battery, can make the launcher wrong within a group.
- **Unit names match the mission.** `Pilot` is the DCS unit name and `Group` is the group name, for ground units as well as aircraft. They match `Unit.getName()` and `Group.getName()` in scripts and the names in the mission file. Player aircraft show `<unit name> | <player name>`.
- **Flight data in singleplayer only.** Singleplayer recordings may include per-frame properties such as `IAS`, `Mach`, `AOA`, `Throttle`, `LandingGear`, and `FuelWeight`. Server-side multiplayer recordings omit them. When present, `track` adds `f_` columns (speeds in knots, fuel in kg, others as recorded).
- **AGL.** Newer Tacview builds export `AGL` (meters above ground). When present, `track` and `removals` show `agl_ft`, which separates landings and ground despawns from in-flight removals. Older recordings leave it blank.
- **Dead units freeze before removal.** A destroyed unit stops moving several frames before it is removed. `removals` skips the frozen samples when it computes speed.
- **Not every round is recorded.** Only some gun rounds (mostly tracers) appear as `Projectile+Shell`, so `guns` round counts are low. Use them to tell whether a unit fired and when, not how much.
- **Mission coordinates.** DCS recordings fill `u` with mission `y` (east) and `v` with mission `x` (north), in meters. These match `Unit.getPoint()` (`x` and `z`) and the `x`/`y` fields in the mission file, so spawn positions can be compared directly with trigger zones and scripted spawn points. `acmi-query` shows them as `x` and `y`.
- **Time.** `ReferenceTime` is the mission date and start time. `RecordingTime` is the real-world UTC start, which helps match a recording to `dcs.log`.

## File Format

ACMI 2.2 is UTF-8 text, often zipped (`.zip.acmi` holds one `.txt.acmi`). Each line is one of these:

| Line                                            | Meaning                                                                                                  |
| ----------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `FileType=text/acmi/tacview`, `FileVersion=2.2` | Header                                                                                                   |
| `0,Key=Value`                                   | Global property (`ReferenceTime`, `ReferenceLatitude`, `ReferenceLongitude`, `Title`, `DataSource`, ...) |
| `#123.45`                                       | Time frame in seconds after `ReferenceTime`. Applies to the lines that follow.                           |
| `a02,T=...,Type=...,Name=...`                   | Object update. The ID is hex. Properties are sticky: omitted ones keep their last value.                 |
| `-a02`                                          | Object removed                                                                                           |
| `0,Event=Type\|id\|...\|text`                   | Event (`Destroyed`, `TakenOff`, `Landed`, `Message`, `Bookmark`, ...)                                    |
| `// ...`                                        | Comment                                                                                                  |

Text values escape commas as `\,`. A line ending in `\` continues on the next line. Continuation lines can start with `-`, so join them before treating a line as a removal.

### Transform (`T=`)

`T` has 3, 5, 6, or 9 `|`-separated fields. An empty field means unchanged.

| Fields | Layout                                           |
| ------ | ------------------------------------------------ |
| 3      | `lon\|lat\|alt`                                  |
| 5      | `lon\|lat\|alt\|u\|v`                            |
| 6      | `lon\|lat\|alt\|roll\|pitch\|yaw`                |
| 9      | `lon\|lat\|alt\|roll\|pitch\|yaw\|u\|v\|heading` |

Longitude and latitude are degree offsets from `ReferenceLongitude` and `ReferenceLatitude`. Altitude is meters MSL. Angles are degrees, and yaw and heading are clockwise from true north. `u` and `v` are the simulator's native flat-world coordinates in meters.

### Type Tags

`Type` joins tags with `+`. Tags seen in DCS recordings:

- Aircraft: `Air+FixedWing`, `Air+Rotorcraft`
- Ground: `Ground+AntiAircraft`, `Ground+Vehicle`, `Ground+Heavy+Armor+Vehicle+Tank`, `Ground+Light+Human+Infantry`, `Ground+Light+Human+Air+Parachutist`, `Ground+Static+Building`, `Ground+Static+Aerodrome`
- Sea: `Sea+Watercraft`, `Sea+Watercraft+Warship`, `Sea+Watercraft+AircraftCarrier`
- Weapons: `Weapon+Missile`, `Weapon+Bomb`
- Short-lived: `Projectile+Shell`, `Misc+Decoy+Chaff`, `Misc+Decoy+Flare`, `Misc+Shrapnel`, `Misc+Container`
- `Navaid+Static+Bullseye`

`acmi-query` stores units at 1 Hz, weapons at full rate, and short-lived objects as spawn and removal points only.

## Development

```bash
# Install the tool and the dev dependencies (ruff, ty)
uv sync --group dev
# Lint the code
uv run ruff check .
# Type check the code
uv run ty check
```

# MIZ File Format

A MIZ file is a DCS World mission. It is a ZIP archive containing the files that define the mission.

## Archive Contents

### mission

A Lua table containing the main mission data. See [Mission File Schema](mission-file-schema.md).

The mission file defines:

- **Date and time**: The mission date (`date`) and start time
- **Weather**: Wind speeds and directions at multiple altitudes, cloud coverage and presets, fog, visibility, temperature, and atmospheric conditions
- **Theatre**: The map name (also stored separately in the `theatre` file)
- **Coalitions**: The `coalition` table contains the blue (typically NATO/Western) and red (typically OPFOR) sides, each with their own countries and units
- **Countries**: Within each coalition, countries contain groups of units organized by category (plane, helicopter, vehicle, ship, static)
- **Groups and units**: Each group contains one or more units with properties like position, type, skill level, loadout, callsign, and waypoints
- **Triggers**: A trigger system with conditions and actions that drive mission scripting. Triggers reference dictionary keys and resource keys for text and embedded files
- **Navigation points**: Named waypoints that can be referenced by units and triggers
- **Ground control**: Settings for Combined Arms roles like artillery commander and forward observer

Trigger actions can embed Lua scripts.

### theatre

A plain text file containing the map (theatre) name, such as "Caucasus", "Nevada", "PersianGulf", or "Syria". The top-level `theatre` key in the [`mission`](mission-file-schema.md) table has the same value. The `theatre` file is optional. DCS loads the terrain named by `mission.theatre` and does not read the `theatre` file.[^optional-files]

### warehouses

A Lua table containing the supply levels for each warehouse. Warehouses are airbases, FARPs, and other points where aircraft rearm and refuel. Each entry sets quantities of fuel, ammunition, weapons, and other supplies. The structure varies by theatre, since maps have different default airbases and warehouses.

Key fields for each airbase entry include `coalition`, `unlimitedAircrafts`, `unlimitedFuel`, `unlimitedMunitions`, `dynamicSpawn` (enables dynamic spawn at the airfield), `allowHotStart` (permits players to choose hot or cold start), `speed`, `periodicity`, `size`, `suppliers`, `dynamicCargo`, `aircrafts` (aircraft inventory), and `weapons`.

### options

A Lua table containing mission difficulty settings that can override the player's options. It also contains leftover global options from whoever last saved the mission, including graphics settings and username. DCS ignores most of this extra data. The `options` file is optional.[^optional-files]

### l10n Directory

The `l10n` directory contains localized resources. Most missions have one language and only a `DEFAULT` subdirectory.

#### l10n/DEFAULT/dictionary

A Lua table that maps dictionary keys to their actual text values. Keys follow naming conventions like `DictKey_ActionText_112` or `DictKey_descriptionBlueTask_3`. The mission file references these keys, and DCS resolves them at runtime. The dictionary contains briefing text, radio transmissions, trigger messages, and other localized strings.

#### l10n/DEFAULT/mapResource

A Lua table that maps resource keys to filenames of embedded assets. Keys follow naming conventions like `ResKey_Action_6` or `ResKey_ImageBriefing_428`. These are referenced in triggers via `getValueResourceByKey()`. Resources include:

- Lua script files (community frameworks like MIST and MOOSE)
- Audio files (OGG format for radio transmissions, ATIS recordings, etc.)
- Image files (JPG/PNG for briefing images, kneeboard pages, mission patches)

#### Embedded Assets

Audio, image, and script files are stored directly in the `l10n/DEFAULT` directory. When referenced from Lua scripts, paths may include virtual directories (e.g., `AUDIO/ELT.ogg`) that DCS maps to the actual file locations at runtime. <!-- TODO: MISSING - Document the complete mapping of virtual directory paths to actual file locations within the MIZ archive -->

Common asset types include:

- **Audio files (OGG)**: Radio transmissions, ATIS recordings, ambient sounds
- **Images (JPG/PNG)**: Briefing images, kneeboard pages, mission patches, UI elements
- **Lua scripts**: Community frameworks (MIST, MOOSE) and custom mission scripts

## Working with MIZ Files

MIZ files can be extracted and repacked with standard archive tools, so programs can edit mission data without the Mission Editor.

When repacking a MIZ file, ensure that:

1. All files are at the correct directory level (mission, theatre, warehouses, and options at root level)
2. The l10n directory structure is preserved
3. No additional compression metadata is added that could confuse DCS

<!-- TODO: QA - Verify specific compression settings required when repacking MIZ files (compression level, method, store vs deflate) -->

[^optional-files]: The mission loader in `MissionEditor/modules/me_mission.lua` calls `TheatreOfWarData.selectTheatreOfWar(env.mission.theatre)` and never opens the `theatre` file. It reads `options` only when `unzLocateFile('options')` finds it. 376 of the missions bundled with DCS World have no `theatre` file, and 7 have no `options` file.

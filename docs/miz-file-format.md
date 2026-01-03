# MIZ File Format

A MIZ file is the mission file format used by DCS World. It is a standard ZIP archive containing several files that together define a complete mission.

## Archive Contents

### mission

A Lua table containing the primary mission data. This is the core of the mission file. See [Mission File Schema](mission-file-schema.md) for complete documentation of every key and data structure.

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

The mission file also contains embedded Lua scripts within trigger actions. Complex missions frequently embed community scripting frameworks like MIST and MOOSE to enable advanced mission logic.

### theatre

A plain text file containing the name of the map (theatre) the mission is designed for. Examples include "Caucasus", "Nevada", "PersianGulf", "Syria", and other DCS World maps. This value also appears within the mission Lua table.

### warehouses

A Lua table defining the supply levels for each warehouse in the mission. Warehouses represent airbases, FARPs, and other logistics points where aircraft can rearm and refuel. Each airbase entry specifies quantities of fuel, ammunition, weapons, and other supplies. The exact structure of this file varies depending on the theatre, as different maps have different default airbase and warehouse configurations.

### options

A Lua table containing mission-specific difficulty settings that may override the player's global difficulty options when the mission is loaded. This file also contains residual data from the global options of the player who last saved the mission in the Mission Editor, including graphics settings and the player's username. Most of this extra data is not used when loading the mission and can be considered noise.

### l10n Directory

The `l10n` directory contains localized resources for the mission. While the system supports multiple languages, most missions are created for a single language and contain only a `DEFAULT` subdirectory.

#### l10n/DEFAULT/dictionary

A Lua table that maps dictionary keys to their actual text values. Keys follow naming conventions like `DictKey_ActionText_112` or `DictKey_descriptionBlueTask_3`. These keys are referenced throughout the mission file and resolved at runtime. The dictionary contains mission briefing text, radio transmissions, trigger messages, and other localized strings.

#### l10n/DEFAULT/mapResource

A Lua table that maps resource keys to filenames of embedded assets. Keys follow naming conventions like `ResKey_Action_6` or `ResKey_ImageBriefing_428`. These are referenced in triggers via `getValueResourceByKey()`. Resources include:

- Lua script files (community frameworks like MIST and MOOSE)
- Audio files (OGG format for radio transmissions, ATIS recordings, etc.)
- Image files (JPG/PNG for briefing images, kneeboard pages, mission patches)

#### Embedded Assets

Audio, image, and script files are stored directly in the `l10n/DEFAULT` directory. When referenced from Lua scripts, paths may include virtual directories (e.g., `AUDIO/ELT.ogg`) that DCS maps to the actual file locations at runtime.

Common asset types include:

- **Audio files (OGG)**: Radio transmissions, ATIS recordings, ambient sounds
- **Images (JPG/PNG)**: Briefing images, kneeboard pages, mission patches, UI elements
- **Lua scripts**: Community frameworks (MIST, MOOSE) and custom mission scripts

## Working with MIZ Files

Since MIZ files are ZIP archives, they can be extracted and repacked using standard archive utilities. This allows for programmatic manipulation of mission data outside of the DCS Mission Editor.

When repacking a MIZ file, ensure that:

1. All files are at the correct directory level (mission, theatre, warehouses, and options at root level)
2. The l10n directory structure is preserved
3. No additional compression metadata is added that could confuse DCS

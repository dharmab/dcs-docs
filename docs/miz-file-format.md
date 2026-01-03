# MIZ File Format

A MIZ file is the mission file format used by DCS World. It is a standard ZIP archive containing several files that together define a complete mission.

## Archive Contents

### mission

A Lua table containing the primary mission data. This file defines all mission elements including units, triggers, zones, weather, and objectives. The structure must conform to the DCS mission schema.

### theatre

A plain text file containing the name of the map (theatre) the mission is designed for. Examples include "Caucasus", "Nevada", "PersianGulf", "Syria", and other DCS World maps.

### warehouses

A Lua table defining the supply levels for each warehouse in the mission. Warehouses represent airbases, FARPs, and other logistics points where aircraft can rearm and refuel. The exact structure of this file varies depending on the theatre, as different maps have different default airbase and warehouse configurations.

### options

A Lua table containing mission-specific difficulty settings that may override the player's global difficulty options when the mission is loaded. This file also contains residual data from the global options of the player who last saved the mission in the Mission Editor, including graphics settings and the player's username. Most of this extra data is not used when loading the mission and can be considered noise.

## Working with MIZ Files

Since MIZ files are ZIP archives, they can be extracted and repacked using standard archive utilities. This allows for programmatic manipulation of mission data outside of the DCS Mission Editor.

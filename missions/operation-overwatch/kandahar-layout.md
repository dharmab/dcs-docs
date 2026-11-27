# Kandahar Airbase Layout Notes

Notes for decorating Kandahar with statics in Operation Overwatch. They come from four Mission Editor screenshots (satellite view, north up). Stand names are read off the map labels. Small or overlapping labels are marked _(unclear)_.

## Overview

- Location: about 31.50° N, 65.85° E (from the ME cursor readouts), on the Afghanistan map.
- One runway, oriented SW–NE (05/23), with a full-length parallel taxiway on each side.
- There are two airbase objects:
  - **Kandahar**: the fixed-wing field, with aprons along both sides of the runway.
  - **Kandahar Heliport**: a separate airbase north-west of the runway, with helicopter-only stands.
- Stands whose names end in `-H` are helicopter-only.
- Terrain around the field:
  - North and north-west: irrigated farmland and villages.
  - South-east: the built-up camp (a dense grid of buildings and tents), a quartered circular reservoir, and a small pond on the east edge.
  - East: a highway running NNW–SSE past the NE end of the runway, with a canal to the north-east.
  - South-west and west: open desert, plus a large empty paved area west of the SW threshold.

## South-East Side (Main Apron)

The apron is one continuous strip along the SE taxiway. From the SW threshold to the NE end:

| Area    | Stands                                               | Notes                                                 |
| ------- | ---------------------------------------------------- | ----------------------------------------------------- |
| SW tip  | small cluster of `-H` stands _(unclear)_             | at the far SW corner of the apron                     |
| O row   | `O01`–`O08`, plus `D1`/`D2`-style labels _(unclear)_ | a short spur just NE of the SW tip                    |
| OS row  | `OS01`–`OS11` _(unclear prefix)_                     | a diagonal row of shelters along the apron edge       |
| N block | `N01`–`N04`, `N17`–`N25`                             | `N17`–`N25` are packed tightly together               |
| M block | `M01`–`M07`, `M10`–`M12`, `M16`–`M20`                | widely spaced on the open apron; suits large aircraft |
| L row   | `L12-H`–`L16-H`                                      | helicopter stands near the K row                      |
| K row   | `K01`–`K06`                                          | small spur at the NE end of the M block               |
| J row   | `J01`… _(unclear)_                                   |                                                       |
| I row   | `I01`–`I08`                                          |                                                       |
| H row   | `H01`–`H20`                                          | about midfield                                        |
| G row   | `G01`–`G10`                                          |                                                       |
| PAN row | `PAN01`–`PAN15`                                      | dense diagonal stands                                 |
| AAF row | `AAF01`–`AAF15`                                      | the NE end of the SE side                             |

There is also a lone stand near the SW threshold whose label looks like `24AS01` _(unclear)_.

Behind the apron, toward the camp, there is room for revetments, tents, containers, and fuel or ammo dumps. The camp's building grid starts right behind the M, N, and O rows.

## North-West Side

From the SW end to the NE end:

| Area         | Stands                     | Notes                                                  |
| ------------ | -------------------------- | ------------------------------------------------------ |
| S row        | `S01`–`S15`                | in front of large hangars (dark roofs)                 |
| Z / Y blocks | `Z01`–`Z24`, `Y01`–`Y24`   | a large apron in diagonal rows                         |
| X block      | `X01`–`X19`                | next to the Y/Z blocks                                 |
| UAE row      | `UAE01`–`UAE12`            | in front of two hangars                                |
| W row        | `W01`–`W12` _(approx.)_    | beside large dark hangars and shelters                 |
| V / U rows   | `V01`…, `U01`… _(unclear)_ | between the W and T rows                               |
| T row        | `T01`–`T13`                | the north-easternmost NW stands, close to the heliport |

There is also a dense cluster of stands north of the AAF row, across the NE end of the runway. They were too crowded to read.

## Kandahar Heliport

- The heliport lies north-west of the T/U/V rows and north of the S row. The ME shows it as its own airbase.
- It has two pads:
  - West pad: `MST59-H`–`MST66-H`.
  - Centre pad: `MST67-H`–`MST89-H`.
- A large square grid apron to the south-west holds many more `MST…-H` stands, too dense to read.
- The heliport is bordered by farmland to the north and west, which makes a natural perimeter for a fence, HESCO, or guard posts.

## Existing Objects

White map icons appear at several places:

- The open ground south of the runway at midfield, behind the H/I rows.
- Near the AAF row.
- In the compound north-east of the field, by the highway.
- Next to the heliport.

The screenshots were taken in an empty new mission, so these icons belong to the map, not to statics placed by a mission. Leave room around them. There is also a navaid symbol south of the runway near the J row.

## Parking Dump

[`kandahar-parking.csv`](kandahar-parking.csv) lists every stand from `airbase:getParking()`, logged in game: 406 stands in total. Positions are map `x`/`z` with `y` as altitude, plus latitude and longitude. The Mission Editor stand labels (`X01`, `MST62-H`) are not in the dump.

| Airbase           | ID  | Reference point (x, z) | Runway              | Stands by `Term_Type`               |
| ----------------- | --- | ---------------------- | ------------------- | ----------------------------------- |
| Kandahar          | 7   | -269628.5, -28470.8    | `23`, 2981 m × 60 m | 257 × 104, 25 × 72, 34 × 40, 2 × 16 |
| Kandahar Heliport | 15  | -268791.7, -29800.1    | `23`, 219 m × 45 m  | 86 × 40, 2 × 16                     |

`Term_Type` values, per the Hoggit wiki:

- `104`: open-air stand
- `72`: open-air stand or shelter
- `40`: helicopter only
- `16`: runway spawn point

Every stand had `Term_Index_0` = -1 and `TO_AC` = false. `fDistToRW` is the distance to the runway in metres.

## Decoration in the Mission

The mission's static groups are named `KAF <type> #NN`, and a comment above each one gives its stand (`term_index` in the CSV). Statics sit on stand positions. Aircraft face the runway or down the runway axis (toward the SW), depending on the row. The stand groups below are by position along the runway, from the CSV, not by ME label.

| Area                                     | Stands (`term_index`)                             | Statics                                    |
| ---------------------------------------- | ------------------------------------------------- | ------------------------------------------ |
| SE, paved area 900 m SW of the threshold | 13, 31, 216, 24                                   | Motor pool: MaxxPro, Stryker, HMMWV, HEMTT |
| SE, helicopter row at the SW end         | 187, 6                                            | UH-60A                                     |
| SE, dense block (N rows)                 | 163, 301, 286, 251, 55, 122, 304, 48              | Belgian and Dutch F-16A MLU, HEMTT, HMMWV  |
| SE, widely spaced block (M rows)         | 170, 206, 108, 119, 89, 255                       | C-17A, RAF and USAF C-130, IL-76MD         |
| SE, helicopter block (L-H)               | 125, 66, 21, 148, 191, 111                        | Canadian and RAF CH-47D, Mi-8              |
| SE, K row                                | 309, 107, 299, 260, 194                           | MQ-9, MQ-1, Predator ground station        |
| SE, flight line parallel to the runway   | 146, 110, 269, 182, 209, 79, 181, 41, 172         | A-10C, F/A-18C, HEMTT, M939                |
| SE, PAN row                              | 15, 115, 68, 222                                  | AV-8B                                      |
| SE, AAF row and shelters at the NE end   | 175, 128, 279, 272, 29                            | Mirage 2000, HMMWV, C-RAM                  |
| NW, middle block                         | 84, 166, 254, 219, 226, 22                        | Tornado GR4, RAF crash tender, M939        |
| Kandahar Heliport                        | 50, 59, 71, 30, 36, 11, 67, 64, 68, 37, 6, 20, 15 | AH-64D, UH-60A, CH-47F, HEMTT, M939, C-RAM |

The NW big stands near midfield, the NW shelters, and most of the NE blocks are left free for Dynamic Spawn.

### Second Pass

Statics with group IDs 401 and up were added by a one-off script, by these rules:

- Each zone continues the theme above. It fills a share of its free stands, with the type mix set by weights. A stand goes to the first zone in the table that matches it:

  | Zone (along the runway from the SW threshold)     | Share | Types                                                                   |
  | ------------------------------------------------- | ----- | ----------------------------------------------------------------------- |
  | J ramp by the terminal (stands 296, 240, 183, 76) | 100%  | Yak-40, An-26 (Ukraine)                                                 |
  | Any stand 45 m or more from its nearest stand     | 85%   | C-17A, IL-76MD (Ukraine), C-130 (USAF, RAF), C-130J (USAF, RAF, Canada) |
  | NW, 1450 to 1800 m (Y and Z blocks)               | 40%   | An-26, Yak-40 (Ukraine)                                                 |
  | SE, -1100 to -250 m (N rows)                      | 55%   | Belgian and Dutch F-16A MLU                                             |
  | SE, -250 to 450 m (M rows)                        | 50%   | C-130 (USAF, RAF), C-17A, A-10C                                         |
  | SE, 450 to 1000 m (K row)                         | 50%   | MQ-9, MQ-1                                                              |
  | SE, 1000 to 2200 m (flight line)                  | 55%   | A-10C, F/A-18C                                                          |
  | SE, 2200 to 2700 m (PAN row)                      | 55%   | AV-8B, F/A-18C                                                          |
  | SE, 2700 to 3400 m (AAF row)                      | 45%   | Mirage 2000, Mi-8                                                       |
  | NW, 2000 to 2500 m (middle block)                 | 45%   | Tornado GR4                                                             |
  | NW, 2500 to 3400 m (NE blocks)                    | 25%   | Dutch F-16A MLU, A-10C, Tornado GR4                                     |
  | Kandahar Heliport                                 | 65%   | AH-64D, UH-60A, OH-58D, CH-47F, RAF and Canadian CH-47D                 |

- A type goes only on a stand whose nearest other stand is far enough away for it. For example, 18 m for fighters, 30 m for Chinooks, and 55 m for the C-17. The biggest types get the widest stands first.
- Never filled: Kandahar's `Term_Type` 40 helicopter stands (the CH-47F spawns there), the seven template stands, and the NW midfield except its wide stands and the Y and Z blocks. Kandahar keeps 133 free fixed-wing stands and 26 free helicopter stands. Kandahar Heliport has no Dynamic Spawn, so it is filled more heavily.
- At Kandahar, a new aircraft takes the heading of the nearest earlier static aircraft within 150 m. Otherwise it faces the runway. At Kandahar Heliport, helicopters face square to their row of stands. Rows across the runway axis face down it, toward the SW, like the hand-placed helicopters. The single column of stands on the west edge faces the apron (143.7°).
- About three in four aircraft get one or two pieces of ground equipment by the nose. For helicopters it goes ahead of the nose, clear of the rotor disc. Fighters get Massun92 power carts, air conditioners, bomb loaders, light carts, and tugs. Heavies get tugs and fuel trucks. The J ramp's civil aircraft get buses, Land Rovers, tugs, and fuel trucks. Helicopters get HEMTTs, HMMWVs, and power carts. No equipment is within 18 m of a free Kandahar stand, or within 11 m of another occupied stand.
- Cargo aircraft (C-17A, IL-76MD, C-130, C-130J, An-26) also get a row of two to four Massun92 pallets, containers, and cargo loaders beside the rear fuselage, behind the wing.
- The equipment's comment reads `Kandahar stand N ground equipment` (or `Heliport stand N ground equipment`), for the stand of the aircraft it serves.

## Decorating Tips

- Don't place statics on stands that players or AI spawn on. Look up which stands the mission's groups use (`parking` / `parking_id`; see the [player slots recipe](../../docs/recipes/player-slots.md)).
- The ME labels give no exact coordinates. To get exact stand positions, run a one-off mission that logs [`airbase:getParking()`](../../docs/scripting/reference/classes/airbase.md#airbasegetparking) for both airbases:

```lua
for _, name in ipairs({ "Kandahar", "Kandahar Heliport" }) do
    local ab = Airbase.getByName(name)
    for _, s in ipairs(ab:getParking()) do
        env.info(string.format("%s %s type=%s x=%.1f z=%.1f", name, s.Term_Index, s.Term_Type, s.vTerminalPos.x, s.vTerminalPos.z))
    end
end
```

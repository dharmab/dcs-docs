# Camp Bastion Layout Notes

Notes on the Camp Bastion decoration in Operation Overwatch. Camp Bastion (airdrome `10`) and Camp Bastion Heliport (airdrome `13`) are separate airbases on the Afghanistan map. The heliport lies west of the main airfield's stands.

## Stand Data

[`bastion-parking.csv`](bastion-parking.csv) lists every stand at both airbases: 156 at Camp Bastion and 32 at Camp Bastion Heliport. Each row gives the Mission Editor label, the map `x` and `z`, the heading an aircraft faces on the stand, and the distance to the nearest other stand.

The data comes from the terrain's taxiway files, `Mods/terrains/Afghanistan/AirfieldsTaxiways/Camp_Bastion.rn5` and `Camp_Bastion_Heli.rn5`. Each stand record in an `.rn5` file is two 4×4 matrices of doubles, then the stand's ME label as a length-prefixed string. The first matrix is the stand's transform in map coordinates: the translation (elements 12–14) is the stand position and the first row is a unit vector along the stand's row. The taxiway lead-in leaves each stand 90° to the left of that vector, so aircraft face that way, nose toward the taxiway. The same parse of `Kandahar.rn5` matches every stand in `kandahar-parking.csv` (from `airbase:getParking()` in game) to within 0.1 m, and the labels match the installed missions' stand names, such as `Y01` and `W02`.

The `term_index` numbers DCS gives these stands are not in the files, and at the heliport they do not follow file order. Look stands up by label.

## Rows

| Airbase   | Rows                    | Stands | Spacing  | Notes                                        |
| --------- | ----------------------- | ------ | -------- | -------------------------------------------- |
| Bastion   | `A`, `B`, `NA`, `SA`    | 7      | 86–110 m | Widely spaced heavy stands                   |
| Bastion   | `C`, `D`                | 17     | 45–102 m | Two loops of cargo stands                    |
| Bastion   | `E`, `G`, `H`, `H-H`    | 26     | 30–62 m  | Medium stands at the south end               |
| Bastion   | `J`                     | 29     | 34–91 m  | Long medium row, a few wide stands           |
| Bastion   | `K-H`                   | 28     | 23 m     | Helicopter-only block                        |
| Bastion   | `L`                     | 49     | 25–34 m  | The largest block, two double rows           |
| Heliport  | `ARN-H`                 | 14     | 26–35 m  | Two facing columns on the west side          |
| Heliport  | `PGS-H`                 | 10     | 29–31 m  | Two rows on the east side                    |
| Heliport  | `TRJ-H`                 | 8      | 36–72 m  | One row; holds the AH-64D and OH-58D templates (`TRJ04-H`, `TRJ03-H`) |

## Decoration in the Mission

The statics were placed by a one-off script. Their groups are named `BSN <type> #NN` at Camp Bastion and `BSN Heli <type> #NN` at the heliport, with group IDs from 1001. A comment above each gives its airbase and stand label.

| Zone                         | Share | Types                                      |
| ---------------------------- | ----- | ------------------------------------------ |
| Bastion `A`, `B`, `C`, `D`, `NA`, `SA` | 85%   | RAF C-130 and C-130J, USMC KC-130J, two C-17A on the widest stands |
| Bastion `J`                  | 60%   | USMC CH-53E, KC-130J on the wide stands    |
| Bastion `K-H`                | 55%   | USMC AH-1W, UH-1H (for the UH-1N/Y)        |
| Bastion `L`                  | 60%   | UK AH-64D and CH-47D                       |
| Bastion `E`, `G`, `H`, `H-H` | 60%   | UK CH-47D, USMC CH-53E                     |
| Heliport `ARN-H`, `PGS-H`    | 55%   | UK AH-64D and CH-47D                       |
| Heliport `TRJ-H`             | 0%    | Left free for Dynamic Spawn                |

- A type goes only on a stand whose nearest other stand is far enough away for it: 55 m for the C-17A, 45 m for the Hercules types, 30 m for the CH-47D and CH-53E, and 18 m for the attack helicopters.
- Aircraft face the heading in `bastion-parking.csv`.
- UK statics set `livery_id`: `ch-47_green uk`, `ah-64_d_green uk`, `Royal Air Force` (C-130), and `RAF 47 Sqn, RAF Brize Norton` (C-130J). The AH-1W uses `USA Marines` and the UH-1H `US NAVY`, the grey scheme closest to USMC Hueys. On `K-H`, 6 of the 15 helicopters are UH-1Hs, alternating with AH-1Ws down the row.
- About three in four aircraft get one or two pieces of ground equipment ahead of the nose, 4.5 or 7.5 m off the centreline: tugs, fuel trucks, power carts, and a Land Rover (UK) or HMMWV (USA) for cargo aircraft; power carts, fire extinguishers, trucks, and a Land Rover or HMMWV for helicopters. Cargo aircraft also get two to four pallets, containers, or cargo loaders beside the rear fuselage.
- Equipment stays 9 m from any taxiway point except the stand's own lead-in, 11 m from any other stand at Camp Bastion, and 18 m from a free stand at the heliport.
- Result: 110 aircraft and 145 pieces of equipment. Camp Bastion keeps 59 free stands and the heliport 19.

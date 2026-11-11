## Fixed (needs playtest)

- interceptors rapidly spawning without enough cooldown
  - DEAD/CRASH/UNIT_LOST all decremented the airborne count for one kill; now de-duplicated per unit
  - group lookup matched by substring (`-1` matched `-12`); now exact
  - added a 180 s global cooldown across all airfields
- interceptors air spawning instead of runway spawning
  - spawn point now read from the airbase by airdromeId instead of hardcoded coords
- tankers have wrong airspeeds
- tankers need more altitude distribution
  - Magic 30k/280 KIAS, Texaco 25k/280, Arco 21k/250, Shell 15k/200; TAS computed at runtime
  - removed the +500 m per-index offset that broke the precomputed TAS and bunched tankers at ~19-20k
- comms plan needs to be in briefing (added carrier, AWACS, Shell, tanker altitudes)
- comms plan F10 option (already existed as F10 > Comms Plan; added AWACS + Shell)
- mission info should tell players support asset callsigns and frequencies
- Shell moved 270.0 -> 270.7 (Heavy Boom per comm plan)
- Gudauta battlefield needs more regular enemies and closer to player airbase
  - approach-route targets now start ~60 nm from Krymsk (was ~140 nm), 7 waypoints, denser

- comms plan needs to be in radio presets
  - presets on all 14 non-FC3 templates (Krymsk 1-14, Stennis 25-28); layout in mission CLAUDE.md
  - FC3 jets (F-15C, MiG-29A, Su-25, Su-25T) can't take mission presets; tune in SRS
- Krymsk warehouse now links each type to its template (linkDynTempl). Before this, no Krymsk
  template (loadout or presets) was linked; possibly the cause of "dynamic slots are broken"
- hot starts disabled on the Stennis (allowHotStart = false); cold start only everywhere

## Open

- dynamic slots are broken (retest after the linkDynTempl fix; need symptoms if still broken)
- jeff slot is not playable (need symptoms)

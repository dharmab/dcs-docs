# Standardized Communications Plan

This document defines a standardized frequency allocation for DCS World missions. All frequencies are in the UHF military band (225.0-399.975 MHz AM) to ensure compatibility with aircraft that have limited radio tuning ranges, such as the F-4E Phantom II (225.0-399.95 MHz primary, 265.0-284.9 MHz auxiliary) and F-16C Viper (225.0-399.975 MHz on COM1).

## Frequency Allocation Table

| Purpose | Frequency (MHz) | Notes |
|---------|-----------------|-------|
| **ATC & Navigation** |||
| Tower | 254.1 | Tower and traffic pattern control |
| Ground | 254.3 | Taxi and ground movement (optional, for multiple controllers) |
| Radar | 254.5 | Departure, approach, and flight following (optional, for multiple controllers) |
| Carrier | 254.7 | Marshal, approach, and LSO |
| **Strike Coordination** |||
| Strike | 255.1 | Package-wide coordination |
| **Flight Tactical** |||
| Red 1 | 260.1 | Flight internal |
| Red 2 | 260.3 | Flight internal |
| Red 3 | 260.5 | Flight internal |
| Red 4 | 260.7 | Flight internal |
| Red 5 | 260.9 | Flight internal |
| Blue 1 | 261.1 | Flight internal |
| Blue 2 | 261.3 | Flight internal |
| Blue 3 | 261.5 | Flight internal |
| Blue 4 | 261.7 | Flight internal |
| Blue 5 | 261.9 | Flight internal |
| Green 1 | 262.1 | Flight internal |
| Green 2 | 262.3 | Flight internal |
| Green 3 | 262.5 | Flight internal |
| Green 4 | 262.7 | Flight internal |
| Green 5 | 262.9 | Flight internal |
| **Flight Tactical (FM)** ||| *A-10, helicopters* |
| Yellow 1 | 30.1 FM | Flight internal |
| Yellow 2 | 30.3 FM | Flight internal |
| Yellow 3 | 30.5 FM | Flight internal |
| Yellow 4 | 30.7 FM | Flight internal |
| Yellow 5 | 30.9 FM | Flight internal |
| Orange 1 | 31.1 FM | Flight internal |
| Orange 2 | 31.3 FM | Flight internal |
| Orange 3 | 31.5 FM | Flight internal |
| Orange 4 | 31.7 FM | Flight internal |
| Orange 5 | 31.9 FM | Flight internal |
| **Tanker Operations** |||
| Basket | 270.1 | KC-135 MPRS probe & drogue |
| Recovery | 270.3 | S-3B carrier tanker |
| Fighter Boom | 270.5 | KC-135 boom for fighters |
| Heavy Boom | 270.7 | KC-135 boom for heavy or slow receivers |
| **GCI / AWACS** |||
| GCI UHF | 255.3 | Primary GCI frequency |
| GCI VHF | 124.1 VHF | VHF alternate |
| GCI FM | 32.1 FM | FM alternate |
| In-Game AWACS | 255.5 | Reserved. DCS AI AWACS radio calls are poor; keep AI AWACS for datalink only (`communication = false`) and don't preset this |
| **JTAC** |||
| JTAC 1 | 32.3 FM | Forward air controller |
| JTAC 2 | 32.5 FM | Forward air controller |
| JTAC 3 | 32.7 FM | Forward air controller |
| JTAC 4 | 32.9 FM | Forward air controller |
| **Reserved** |||
| Military Guard | 243.0 | Military emergency frequency |
| Civil Guard | 121.5 VHF | International emergency frequency |
| Aux Reserved | 265.0-284.9 | Compatible with F-4E aux radio |

## Design Rationale

The frequency plan uses whole and half MHz values for easy memorization and radio tuning. Frequencies are grouped by function with gaps between groups to allow expansion.

ATC frequencies are grouped in the 254 MHz range. Strike and GCI frequencies use the 255 MHz range. Fighter flight tactical frequencies use the 260-263 MHz range. Tanker frequencies use the 270 MHz range. The 265.0-284.9 MHz range is reserved for future expansion.

FM frequencies (30-88 MHz) are allocated for A-10 and helicopter flights. These aircraft have three radios including FM capability, so using FM for internal flight comms leaves their UHF radio free for strike coordination, JTAC, and package-level traffic. Aircraft with only UHF radios cannot monitor FM, so mixed packages should coordinate on UHF frequencies.

All operational frequencies avoid the guard frequencies (243.0 MHz military, 121.5 MHz civil) and stay well within the 225-400 MHz UHF band supported by all military aircraft in DCS. The 250-252 MHz range is avoided because it is heavily used by airfield ATC frequencies on the Syria, Caucasus, Nevada, and other maps.

## Aircraft Radio Compatibility

Ranges and preset counts below come from each type's `panelRadio` table in Quaggles' DCS Lua Datamine (`_G/db/Units/Planes/Plane/<type>.lua`). The `Radio` table in a mission unit is indexed in `panelRadio` order, which is the "Mission index" column. Each `Radio[n]` entry has parallel `channels` (MHz) and `modulations` (0 = AM, 1 = FM) arrays.

| Aircraft (type) | Mission index: radio, range, presets |
|-----------------|--------------------------------------|
| F-4E-45MC | [1] ARC-164 UHF 225-399.95, **18**; [2] aux receiver 265-284.9, 20 |
| F-16C_50 | [1] COMM1 ARC-164 UHF 225-399.975, 20; [2] COMM2 ARC-222 VHF AM 116-155.975 + FM 30-87.975 (no UHF), 20 |
| FA-18C_hornet | [1] COMM1 ARC-210 30-399.975, 20; [2] COMM2 ARC-210 30-399.975, 20 |
| F-15ESE | [1] UHF Radio 1 225-399.975, 20; [2] V/UHF Radio 2 30-399.975, 40 |
| F-14A-135-GR / F-14B / F-14BU | [1] ARC-159 UHF 225-399.975 (pilot), 20; [2] ARC-182 V/UHF 30-399.975 (RIO), 30 |
| A-10C_2 | [1] ARC-210 30-399.975, 25; [2] ARC-164 UHF 225-399.975, 20; [3] ARC-186 FM 30-87.995, 20 |
| M-2000C | [1] UHF 225-400, 20; [2] V/UHF 118-400, 20 |
| Mirage-F1CE | [1] TRAP-136 V/UHF 118-399.975, 20; [2] TRAP-137B UHF 225-399.975, 20 |
| JF-17 | [1] one 20-preset list shared by COMM1 and COMM2, both 30-399.975 |
| F-15C, MiG-29A, Su-25, Su-25T (FC3) | No `panelRadio`; mission presets are not possible. With SRS, players tune UHF/VHF/FM radios in the SRS overlay. |

Not yet verified against the datamine:

| Aircraft | Radio 1 | Radio 2 | Radio 3 |
|----------|---------|---------|---------|
| AV-8B Harrier | 225.0-399.975 AM | 225.0-399.975 AM | — |
| AH-64D Apache | 225.0-399.975 AM | 116.0-151.975 VHF AM | 30.0-87.975 FM |
| UH-1H Huey | 225.0-399.975 AM | 30.0-75.975 FM | — |
| Mi-24P Hind | 100.0-399.9 AM | 20.0-59.975 FM | — |
| Ka-50 Black Shark | 100.0-399.9 AM | 20.0-59.9 FM | — |

Every jet above except the FC3 types has at least one 225-400 MHz radio, so an all-UHF main preset list works everywhere. The constraints are the second radios: F-16 COMM2 and the A-10's ARC-186 cannot tune UHF, which is why SkyEye also listens on 124.1 VHF and 32.1 FM.

## Radio Presets

Use one main-radio list in every aircraft, capped at 18 channels for the F-4E. Fill it in priority order: Strike, SkyEye GCI, the ATC frequencies (Tower, Ground, Radar; they're used by human controllers on SRS), Carrier, tankers, then flight tactical with whatever slots remain. Drop interflight channels before anything above them. Don't preset an in-game AI AWACS voice frequency; it is kept only for datalink, and voice GCI is SkyEye.

Use the second radio for SkyEye ("radio 1 to talk, radio 2 on GCI"): put SkyEye VHF 124.1 on channel 1 of every second radio that can tune VHF, followed by the main list. For VHF/FM-only radios, add 32.1 FM and the FM flight tactical channels. Dynamic spawn templates only apply their presets at a base whose warehouse stock links the template with `linkDynTempl` (see [player-slots.md](player-slots.md)).

Operation Infinity (`missions/operation-infinity/CLAUDE.md`) has a complete worked layout.

A-10 and helicopter flights should use FM frequencies for internal flight communications, leaving UHF free for strike coordination, JTAC, and other package-level traffic.

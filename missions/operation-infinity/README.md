# Operation Infinity

A dynamic mission generator for DCS World supporting 1-12 players.

## Overview

Operation Infinity is a sandbox mission that generates a fresh battlefield every time you play. Pick your difficulty and how long you want to fly, and the mission builds a warzone with frontline firefights, air defenses, convoys, and enemy fighters tailored to your selections. Even with the same settings, exact enemy positions stay unpredictable.

Enemy positions, SAM placements, and patrol routes shift each session, so you can't memorize the threats. The number of enemy fighters also scales with player count and aircraft type.

No briefings to sit through, no rigid objectives. Just pick an aircraft, get your coordinates, and go hunting.

## Setting

You're flying for ISAF against Erusean forces. ISAF holds the northwest corner of the Caucasus map (Anapa/Krymsk), while Erusea controls Tbilisi, Mozdok, and various military airfields throughout the region. ISAF is launching air support, interdiction, and SEAD missions in support of ongoing ground operations.

## Available Aircraft

The following aircraft are available via Dynamic Spawn at Krymsk:

- F-4E Phantom II
- F-16C Viper
- F-15E Strike Eagle
- F-15C Eagle
- MiG-29A Fulcrum
- F/A-18C Hornet
- A-10C Warthog
- Mirage 2000C
- Mirage F1
- F-14A Tomcat
- F-14B Tomcat

The warehouse is configured for unlimited weapons.

## Radio Frequencies

| Purpose | Frequency |
|---------|-----------|
| Tower | 254.1 MHz AM |
| Ground | 254.3 MHz AM |
| Radar | 254.5 MHz AM |
| Strike | 255.1 MHz AM |
| GCI UHF | 255.3 MHz AM |
| GCI VHF | 124.1 MHz VHF |
| GCI FM | 32.1 MHz FM |
| In-Game AWACS | 255.5 MHz AM |
| Red 1 | 260.1 MHz AM |
| Red 2 | 260.3 MHz AM |
| Red 3 | 260.5 MHz AM |
| Red 4 | 260.7 MHz AM |
| Red 5 | 260.9 MHz AM |
| Blue 1 | 261.1 MHz AM |
| Blue 2 | 261.3 MHz AM |
| Blue 3 | 261.5 MHz AM |
| Blue 4 | 261.7 MHz AM |
| Blue 5 | 261.9 MHz AM |
| Green 1 | 262.1 MHz AM |
| Green 2 | 262.3 MHz AM |
| Green 3 | 262.5 MHz AM |
| Green 4 | 262.7 MHz AM |
| Green 5 | 262.9 MHz AM |
| Yellow 1 | 30.1 MHz FM |
| Yellow 2 | 30.3 MHz FM |
| Yellow 3 | 30.5 MHz FM |
| Yellow 4 | 30.7 MHz FM |
| Yellow 5 | 30.9 MHz FM |
| Orange 1 | 31.1 MHz FM |
| Orange 2 | 31.3 MHz FM |
| Orange 3 | 31.5 MHz FM |
| Orange 4 | 31.7 MHz FM |
| Orange 5 | 31.9 MHz FM |
| Basket Tanker | 270.1 MHz AM |
| Boom Tanker | 270.5 MHz AM |
| Military Guard | 243.0 MHz AM |
| Civil Guard | 121.5 MHz VHF |

## Difficulty Levels

**Very Easy (Training):** Ground targets only. Nothing shoots back. Good for learning aircraft systems.

**Easy:** Erusea 2004 equipment. Light defenses including AAA, MANPADS, and a few standalone SAMs. Enemy fighters carry IR missiles only.

**Normal:** Erusea 2004/2005 mix. Proper air defense network with EWRs, SA-2, SA-3, SA-6, and SHORAD systems. Enemy fighters carry semi-active radar missiles.

**Hard:** Erusea 2005 equipment. Layered IADS with SA-10, SA-11, and coordinated radar coverage. Enemy fighters carry active radar missiles.

## Mission Duration Options

**45 Minutes (CAS):** Short transit, quick action.

**90 Minutes (Interdiction):** Medium transit time.

**180 Minutes (Deep Strike):** Long transit, tanker support recommended.

## Support Assets

Two tankers orbit near Anapa:
- **KC-135 "Texaco"** (boom) at 25,000 ft, 270.5 MHz, TACAN 100X
- **KC-135MPRS "Arco"** (basket) at 22,000 ft, 270.1 MHz, TACAN 101X

An E-3A AWACS "Overlord" orbits northwest of Krymsk at 30,000 ft with EPLRS enabled. For actual GCI, use SkyEye on 255.3 MHz rather than the in-game AWACS radio.

## Multiplayer Notes

- First player to select settings locks them for everyone
- Unlimited respawns
- Late joiners receive target coordinates automatically
- No AI wingmen (ground forces only)

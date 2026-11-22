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
- MiG-29A Fulcrum (FC)
- MiG-29S Fulcrum
- MiG-29G Fulcrum
- F/A-18C Hornet
- A-10C Warthog
- Mirage 2000C
- Mirage F1
- F-14A Tomcat
- F-14B Tomcat
- F-14B(U) Tomcat
- JF-17 Thunder
- Su-25 Frogfoot
- Su-25T Frogfoot

The following aircraft can also spawn on the carrier CVN-74 John C. Stennis:

- F/A-18C Hornet
- F-14A Tomcat
- F-14B Tomcat
- F-14B(U) Tomcat

The warehouse is configured for unlimited weapons.

## Communications Plan

The comms card is in the mission briefing and in F10 > Comms Plan. Per-aircraft preset cards:

- [F-4E Phantom II](comms/f-4e.md)
- [F-16C Viper](comms/f-16c.md)
- [F-15E Strike Eagle](comms/f-15e.md)
- [F-15C Eagle](comms/f-15c.md)
- [MiG-29A Fulcrum](comms/mig-29-fulcrum.md)
- [MiG-29A Fulcrum (FC)](comms/mig-29a.md)
- [MiG-29S Fulcrum](comms/mig-29s.md)
- [MiG-29G Fulcrum](comms/mig-29g.md)
- F/A-18C Hornet: [Shore](comms/fa-18c-shore.md), [Carrier](comms/fa-18c-carrier.md)
- [A-10C Warthog](comms/a-10c.md)
- [Mirage 2000C](comms/m-2000c.md)
- [Mirage F1](comms/mirage-f1.md)
- F-14A Tomcat: [Shore](comms/f-14a-shore.md), [Carrier](comms/f-14a-carrier.md)
- F-14B Tomcat: [Shore](comms/f-14b-shore.md), [Carrier](comms/f-14b-carrier.md)
- F-14B(U) Tomcat: [Shore](comms/f-14bu-shore.md), [Carrier](comms/f-14bu-carrier.md)
- [JF-17 Thunder](comms/jf-17.md)
- [Su-25 Frogfoot](comms/su-25.md)
- [Su-25T Frogfoot](comms/su-25t.md)

## Difficulty Levels

**Very Easy (Training):** Ground targets only. Nothing shoots back. Good for learning aircraft systems.

**Easy:** Erusea 2004 equipment. Light defenses including AAA, MANPADS, and a few standalone SAMs. Enemy fighters carry IR missiles only.

**Normal:** Erusea 2004/2005 mix. Proper air defense network with EWRs, SA-2, SA-3, SA-6, and SHORAD systems. Enemy fighters carry semi-active radar missiles.

**Hard:** Erusea 2005 equipment. Layered IADS with SA-10, SA-11, and coordinated radar coverage. Enemy fighters carry active radar missiles.

## Mission Duration Options

**45 Minutes (Western Caucasus):** Short transit, quick action.

**90 Minutes (Central Caucasus):** Medium transit time.

**180 Minutes (Eastern Caucasus):** Long transit, tanker support recommended.

## Map Hints

The F10 map marks each target aerodrome, the FEBA, and red circles around artillery batteries, supply depots, and fuel storage. Each circle has its target somewhere inside it, but not at the center, and is removed once the target is destroyed. Patrols, convoys, and air defenses are not marked.

## Support Assets

Three tankers orbit on a racetrack between Krymsk and the target area:

- **KC-135 "Texaco"** (boom) at 20,000 ft, 270.5 MHz, TACAN 100X
- **KC-135MPRS "Arco"** (basket) at 18,000 ft, 270.1 MHz, TACAN 101X
- **KC-135 "Shell"** (slow boom for A-10s) at 15,000 ft, 270.7 MHz, TACAN 102X

Two Patriot batteries, each with a pair of Avengers for close-in defense, guard Krymsk from 8-9 km east of the field, their radars facing the Erusean side.

A carrier strike group operates in the Black Sea about 50 nm southwest of Krymsk: CVN-74 John C. Stennis with a Ticonderoga-class cruiser, two Arleigh Burke-class destroyers, and an Oliver Hazard Perry-class frigate. The carrier steams into the wind for about 25 knots over the deck, turning back downwind when it reaches the edge of its operating area. An SH-60B plane guard helicopter flies off the carrier's starboard side.

- **Carrier:** 254.7 MHz AM, TACAN 74X (STN), ICLS 4, Link 4 336.0 MHz, ACLS
- **S-3B "Arco 2-1"** (basket recovery tanker): orbits over the carrier's operating area at 8,000 ft, 270.3 MHz, TACAN 103X

Aircraft that spawn on the Stennis have the carrier on preset 3 and Krymsk on presets 4-6. Krymsk aircraft have Krymsk on 3-5 and the carrier on 6. Presets 7-8 hold the tankers your aircraft can refuel from.

An E-3A AWACS "Magic" orbits northwest of Krymsk at 30,000 ft with EPLRS datalink enabled. It is datalink only, with no voice. SkyEye GCI also uses the callsign Magic and has voice on 255.3 MHz, 124.1 VHF, and 32.1 FM.

## Multiplayer Notes

- First player to select settings locks them for everyone
- Unlimited respawns
- Late joiners receive target coordinates automatically
- No AI wingmen (ground forces only)

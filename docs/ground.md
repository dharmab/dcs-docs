# DCS World Ground Units

This document provides comprehensive information about ground units in DCS World, including identification, real-world context, and operational requirements.

## Table of Contents

- [Categories](#categories)
- [SAM System Compositions](#sam-system-compositions)
- [Support & Logistics](#support--logistics)
- [Air Defence](#air-defence)
- [Armor](#armor)
- [Artillery](#artillery)
- [Infantry](#infantry)
- [Unarmed](#unarmed)
- [Fortification](#fortification)
- [Surface-to-Surface Missiles](#surface-to-surface-missiles)
- [Trains](#trains)

## Categories

DCS World organizes ground units into the following categories:

| Category | Count | Description |
|----------|-------|-------------|
| Air Defence | 74 | SAM systems, AAA, radars, MANPADS |
| Armor | 88 | Tanks, IFVs, APCs, tank destroyers, scout vehicles |
| Artillery | 29 | Self-propelled artillery, multiple rocket launchers, mortars |
| Infantry | 15 | Soldiers with various weapons |
| Unarmed | 70 | Trucks, support vehicles, fuel trucks, civilian vehicles |
| Fortification | 12 | Bunkers, outposts, defensive positions |
| MissilesSS | 9 | Surface-to-surface missiles |
| Carriage/Locomotive | 16 | Train cars and locomotives |

## SAM System Compositions

Many SAM systems in DCS require multiple vehicles to function properly. The launcher typically requires a tracking radar, and the radar may require a command post or search radar. Understanding these dependencies is critical for mission designers.

### S-300PS (SA-10 Grumble)

The S-300PS represents the road-mobile variant of the Soviet Union's premier long-range air defense system. First deployed in 1978, the S-300 family was developed as a successor to the S-75 and S-200 systems, designed from the outset to engage multiple targets simultaneously and resist the increasingly sophisticated electronic countermeasures employed by Western aircraft. The "PS" designation indicates the self-propelled (mobile) version optimized for field deployment with ground forces, as opposed to fixed-site variants protecting strategic installations.

The system's development was driven by the Soviet military's recognition that earlier single-target SAM systems were vulnerable to saturation attacks—NATO doctrine called for overwhelming Soviet air defenses with multiple simultaneous strikes. The S-300's phased array radar and vertical launch system allowed engagement of up to six targets simultaneously, a revolutionary capability in the 1970s. The 5V55 missile family achieves speeds exceeding Mach 6 with range out to 75-90 km depending on variant, capable of engaging targets from treetop level to above 25,000 meters altitude.

The S-300 family has been exported to numerous nations including China, Iran, Syria, Greece, and others. Syrian S-300PM systems were delivered in 2018 following the downing of a Russian Il-20 reconnaissance aircraft during Israeli strikes, though their combat effectiveness remains unclear given continued Israeli operations in Syrian airspace. The system's reputation as a formidable threat has influenced air campaign planning worldwide, with NATO and Israeli planners developing specific tactics, standoff weapons, and electronic warfare capabilities to counter S-300 batteries.

| Component | Type ID | Role |
|-----------|---------|------|
| 5P85C TEL | `S-300PS 5P85C ln` | Launcher (4 missiles, truck-mounted) |
| 5P85D TEL | `S-300PS 5P85D ln` | Launcher (4 missiles, trailer-mounted) |
| 30N6 (Flap Lid) | `S-300PS 5H63C 30H6_tr` | Tracking radar |
| 40B6M | `S-300PS 40B6M tr` | Tracking radar (alternate) |
| 40B6MD (Clam Shell) | `S-300PS 40B6MD sr` | Search radar |
| 40B6MD with 19J6 | `S-300PS 40B6MD sr_19J6` | Search radar (with 19J6) |
| 64H6E (Big Bird) | `S-300PS 64H6E sr` | Search radar (alternate) |
| 54K6 | `S-300PS 54K6 cp` | Command post |

**Required for operation:** Launchers require either the 30N6 or 40B6M tracking radar. The command post requires a search radar (40B6MD or 64H6E).

### MIM-104 Patriot

The MIM-104 Patriot represents the U.S. Army's primary surface-to-air missile system for medium and long-range air defense. Development began in 1969 as the SAM-D program, with the system entering service in 1981. The name "Patriot" derives from the radar component designation: "Phased Array Tracking Radar to Intercept on Target." The system was designed to replace both the MIM-14 Nike Hercules strategic SAM and the MIM-23 Hawk tactical SAM, consolidating air defense into a single highly capable platform.

The Patriot's phased array radar represented a significant technological leap, capable of searching for, detecting, tracking, and guiding missiles to multiple targets simultaneously without mechanically rotating the antenna. This electronic beam steering allows the system to react to rapidly changing tactical situations and engage targets from any direction within its coverage arc. Early versions could engage aircraft out to approximately 70 km, with later PAC-3 variants extending this range and adding true ballistic missile defense capability through hit-to-kill interceptors.

The system gained worldwide fame during the 1991 Gulf War when Patriot batteries engaged Iraqi Al-Hussein ballistic missiles (extended-range Scuds) targeting Saudi Arabia and Israel. Initial claims of near-perfect intercept rates were later revised downward as post-war analysis revealed many missiles either missed or hit the wrong portion of the incoming warhead. Nevertheless, the Patriot's psychological and political value was significant, and the lessons learned drove the PAC-2 GEM and PAC-3 upgrades that dramatically improved anti-ballistic missile performance. During the 2003 invasion of Iraq, Patriot systems achieved confirmed kills against Iraqi tactical ballistic missiles, though two friendly fire incidents resulted in the downing of a British Tornado GR4 and an American F/A-18C, highlighting the challenges of integrating air defense with friendly air operations. More recently, Patriot batteries provided to Ukraine have proven highly effective against Russian cruise missiles, ballistic missiles, and aircraft, including the reported shoot-down of multiple Su-34 and Su-35 fighters at extended range.

| Component | Type ID | Role |
|-----------|---------|------|
| M901 Launcher | `Patriot ln` | Launcher (4 missiles) |
| AN/MPQ-53 STR | `Patriot str` | Search/track radar (phased array) |
| ECS | `Patriot ECS` | Engagement Control Station |
| EPP-III | `Patriot EPP` | Electric Power Plant |
| ICC | `Patriot cp` | Information Coordination Central |
| AMG AN/MRC-137 | `Patriot AMG` | Communications relay |

**Required for operation:** Launcher requires STR. STR requires ECS.

### MIM-23 Hawk

The MIM-23 Hawk entered service with the U.S. Army in 1959 as the first mobile, medium-range SAM designed specifically to counter low-to-medium altitude aircraft. Its name is a backronym: "Homing All the Way Killer," reflecting the semi-active radar homing guidance that tracks targets continuously from launch to impact. Unlike earlier command-guided missiles, the Hawk's seeker head homes on radar energy reflected from the target, providing superior accuracy against maneuvering aircraft.

The system was designed to fill the gap between short-range gun defenses and high-altitude Nike systems. A standard Hawk battery consists of multiple launchers, each carrying three missiles on a towed or self-propelled mount, supported by search radars for detection and high-power illuminator radars for target tracking and missile guidance. The separation of search and tracking functions allows the battery to engage one target while continuing to scan for others. The MIM-23B Improved Hawk, introduced in 1972, featured upgraded electronics and missiles with range extended to approximately 40 km.

The Hawk saw extensive combat service with numerous operators. Israeli Hawk batteries claimed multiple kills during the 1973 Yom Kippur War, demonstrating effectiveness against Egyptian and Syrian aircraft conducting low-level attacks. Iranian Hawks engaged Iraqi aircraft during the Iran-Iraq War, with some batteries reportedly operating using locally-maintained electronics after U.S. support was cut off following the 1979 revolution. Kuwait's Hawk batteries attempted to engage Iraqi forces during the 1990 invasion, and Saudi Hawks participated in the defense against Iraqi Scud missiles during Desert Storm—though the system was not designed for anti-ballistic missile work. The system has been largely replaced by Patriot in U.S. service but remains operational with numerous export customers including Egypt, Jordan, and Taiwan.

| Component | Type ID | Role |
|-----------|---------|------|
| M192 Launcher | `Hawk ln` | Launcher (3 missiles) |
| AN/MPQ-46 TR | `Hawk tr` | High Power Illuminator (tracking radar) |
| AN/MPQ-50 SR | `Hawk sr` | Pulse Acquisition Radar (search) |
| AN/MPQ-55 CWAR | `Hawk cwar` | Continuous Wave Acquisition Radar |
| PCP | `Hawk pcp` | Platoon Command Post |

**Required for operation:** Launcher requires TR. TR requires PCP. PCP requires SR, CWAR, or both.

### SA-11 Buk (Gadfly)

The 9K37 Buk (NATO reporting name SA-11 "Gadfly") entered Soviet service in 1980 as a replacement for the 2K12 Kub (SA-6). The system was designed to provide divisional-level air defense against aircraft, cruise missiles, and precision-guided munitions flying at altitudes from 15 meters to 22 kilometers, with engagement ranges out to approximately 35 km. The name "Buk" means "beech tree" in Russian.

The Buk's most distinctive feature is the TELAR (Transporter Erector Launcher And Radar) concept: each launcher vehicle carries its own fire control radar, allowing independent engagement without requiring a separate tracking radar vehicle. This provides significant tactical flexibility and redundancy—a Buk battery can disperse its TELARs across a wide area, each capable of autonomous operation, or concentrate them under centralized command post control for coordinated defense. The 9M38 missile uses semi-active radar homing, with the TELAR's radar illuminating the target throughout the missile's flight.

The Buk family has seen extensive combat use and has proven devastatingly effective. During the 2008 Russo-Georgian War, Georgian Buk-M1 systems shot down multiple Russian aircraft including Su-25 attack aircraft and a Tu-22M3 bomber. The system gained international notoriety on 17 July 2014 when Malaysia Airlines Flight 17 was shot down over eastern Ukraine by a Buk missile, killing all 298 people aboard. International investigators determined the missile was fired from territory controlled by Russian-backed separatists using a Buk system transported from Russia. During Russia's 2022 invasion of Ukraine, both sides have employed Buk systems extensively, with Ukrainian Buks claiming numerous Russian aircraft while Russian systems have engaged Ukrainian jets and helicopters.

| Component | Type ID | Role |
|-----------|---------|------|
| 9A310M1 TELAR | `SA-11 Buk LN 9A310M1` | Launcher with onboard radar (4 missiles) |
| 9S470M1 | `SA-11 Buk CC 9S470M1` | Command post |
| 9S18M1 Snow Drift | `SA-11 Buk SR 9S18M1` | Search radar |

**Required for operation:** TELAR can operate independently using its own radar or can be directed by the command post.

### SA-6 Kub (Gainful)

The 2K12 Kub (NATO reporting name SA-6 "Gainful") entered Soviet service in 1967 and represented a generational leap in mobile air defense capability. Designed to provide medium-range air defense for armored divisions on the move, the Kub combined a tracked launcher carrying three 3M9 missiles with the 1S91 "Straight Flush" combined search and tracking radar on a similar tracked chassis. The system could engage targets at ranges out to 24 km and altitudes from 50 meters to 14 kilometers.

The Kub's 3M9 missile featured a distinctive design with four ramjet intakes surrounding the body, providing sustained thrust throughout the flight envelope rather than the boost-coast profile of solid-fuel missiles. This gave the missile excellent maneuverability at the end of its flight when intercepting targets at maximum range—precisely when most solid-fuel missiles are losing energy. The semi-active radar homing guidance required the 1S91 to illuminate the target continuously, meaning each radar could engage only one target at a time.

The Kub achieved devastating effectiveness during the 1973 Yom Kippur War, where Egyptian and Syrian batteries destroyed numerous Israeli aircraft during the opening days of the conflict. The Israeli Air Force, accustomed to dominating Arab air defenses, suffered unprecedented losses to the Kub's combination of mobility, low-altitude capability, and resistance to the jamming techniques effective against older SA-2 systems. The shock of these losses drove urgent development of new tactics, electronic warfare systems, and anti-radiation missiles. The Kub saw additional combat service during the 1982 Lebanon War, where Israeli forces employed new countermeasures and destroyed Syrian SAM batteries in the Bekaa Valley, and during various other conflicts in Africa and the Middle East. The system was eventually replaced in Soviet service by the Buk but remains operational with some export customers.

| Component | Type ID | Role |
|-----------|---------|------|
| 2P25 TEL | `Kub 2P25 ln` | Launcher (3 missiles) |
| 1S91 Straight Flush | `Kub 1S91 str` | Combined search/track radar |

**Required for operation:** TEL requires the 1S91 radar.

### S-125 Neva (SA-3 Goa)

The S-125 Neva (NATO reporting name SA-3 "Goa") entered Soviet service in 1961 as a low-to-medium altitude complement to the high-altitude S-75. While the S-75 was designed to engage high-flying bombers and reconnaissance aircraft, the S-125 was optimized for the low-altitude regime where terrain masking and ground clutter complicated radar detection. The system uses command guidance with the SNR-125 "Low Blow" tracking radar transmitting steering commands to the missile throughout its flight, requiring the radar to track both target and missile simultaneously.

The S-125 uses a two-stage solid-fuel missile, eliminating the dangerous liquid propellants of the S-75 and reducing logistics complexity. Engagement range extends to approximately 25 km with altitude capability from 20 meters to 18 kilometers, though effectiveness decreases at both extremes. The launcher carries four missiles on a rotating mount, allowing rapid reengagement. Early versions were fixed-site, but later Pechora variants introduced road-mobile capability.

The S-125 has seen extensive combat service over six decades. North Vietnamese forces employed the system against American aircraft during the Vietnam War, though the S-75 was the primary SAM threat. Egyptian and Syrian S-125 batteries participated in the 1973 war, contributing to the integrated air defense network. The system achieved its most famous kill on 27 March 1999 when a Yugoslav 3rd Battery, 250th Missile Brigade S-125 shot down USAF F-117A "Nighthawk" serial 82-0806 during Operation Allied Force—the only stealth aircraft ever lost to enemy fire. The battery commander, Colonel Zoltán Dani, reportedly modified his radar operating procedures to detect the aircraft's brief radar signature during weapons bay opening, demonstrating that skilled operators can exploit even small vulnerabilities. The system remains in service with numerous countries including Egypt, Syria, and North Korea, with various upgrade programs extending its relevance.

| Component | Type ID | Role |
|-----------|---------|------|
| 5P73 Launcher | `5p73 s-125 ln` | Launcher (4 missiles) |
| SNR-125 Low Blow | `snr s-125 tr` | Tracking radar |
| P-19 Flat Face | `p-19 s-125 sr` | Search radar |

**Required for operation:** Launcher requires the SNR-125 tracking radar.

### S-75 Dvina (SA-2 Guideline)

The S-75 Dvina (NATO reporting name SA-2 "Guideline") entered Soviet service in 1957 as the world's first effective high-altitude surface-to-air missile system, designed specifically to counter the American strategic bombers and reconnaissance aircraft that Soviet interceptors struggled to reach. The system's massive V-750 missile could engage targets at altitudes exceeding 25 kilometers and ranges out to 45 km, creating a lethal envelope that forced fundamental changes in Western air tactics.

The S-75 announced its capabilities dramatically on 1 May 1960 when a battery near Sverdlovsk shot down CIA pilot Francis Gary Powers flying a U-2 at 70,000 feet—an altitude previously considered immune to interception. The incident caused an international crisis, ended summit talks between Eisenhower and Khrushchev, and proved that high-altitude flight was no longer a guarantee of safety. The system uses radio command guidance with the distinctive SNR-75 "Fan Song" radar tracking both target and missile, computing an intercept solution, and transmitting steering commands to the missile in flight.

The S-75 became the most widely deployed SAM system in history and saw extensive combat during the Vietnam War, where it formed the backbone of North Vietnamese air defenses around Hanoi and Haiphong. American aircrew called the missiles "flying telephone poles" for their size and visual signature. The system shot down numerous American aircraft including F-105s, F-4s, and B-52s, though electronic countermeasures, Wild Weasel SEAD missions, and improved tactics progressively reduced its effectiveness. Egyptian and Syrian S-75 batteries engaged Israeli aircraft during the War of Attrition and 1973 war. The missile's liquid propellant—requiring toxic fuming red nitric acid oxidizer—made handling dangerous and logistics complex, but the system's proven lethality ensured continued deployment. The S-75 remains in limited service with a few operators including North Korea.

| Component | Type ID | Role |
|-----------|---------|------|
| SM-90 Launcher | `S_75M_Volhov` | Launcher (1 missile) |
| SNR-75 Fan Song | `SNR_75V` | Tracking radar |
| RD-75 Amazonka | `RD_75` | Radio direction finding (optional) |
| ZIL-131 Tractor | `S_75_ZIL` | Transport vehicle |

**Required for operation:** Launcher requires the SNR-75 tracking radar.

### S-200 Angara (SA-5 Gammon)

The S-200 Angara (NATO reporting name SA-5 "Gammon") entered Soviet service in 1967 as a long-range, high-altitude system designed to engage strategic targets such as American B-52 bombers, SR-71 reconnaissance aircraft, and airborne early warning platforms that the shorter-range S-75 and S-125 could not reach. The massive 5V21 missile—nearly 11 meters long and weighing over 7,000 kg—uses a liquid-fuel sustainer rocket after solid-fuel boosters accelerate it to high speed, achieving engagement ranges out to 300 km and altitudes exceeding 40 kilometers.

The S-200 employs semi-active radar homing, with the 5N62V "Square Pair" tracking radar illuminating the target throughout the missile's flight. This very high-power radar has a distinctive large parabolic antenna and can burn through all but the most powerful jamming. The system's semi-active guidance at extreme range requires continuous target illumination for an extended period, making the radar vulnerable to anti-radiation missiles. The launcher holds a single missile and requires significant time to reload, limiting sustained engagement capability.

The S-200 has seen limited combat use but remains relevant. Syrian S-200 batteries have engaged Israeli aircraft on numerous occasions, with Israel claiming electronic jamming has caused the missiles to miss while Syrian and Russian sources have occasionally claimed hits. In February 2018, an Israeli F-16I was shot down during strikes on Syria—the first Israeli combat aircraft lost since 1982—though Israel attributed the loss to an SA-5 or SA-17. On 10 February 2018, the wreckage of the F-16 fell in Israeli territory. The system has also been involved in tragic incidents: a Ukrainian S-200 accidentally shot down Siberia Airlines Flight 1812 over the Black Sea in 2001, killing all 78 aboard, when the missile acquired the airliner instead of a target drone during exercises. Despite its age, the S-200's exceptional range means it remains a factor in air operations planning, particularly against high-value assets like tankers and AWACS operating in what might otherwise be safe standoff positions.

| Component | Type ID | Role |
|-----------|---------|------|
| 5P72 Launcher | `S-200_Launcher` | Launcher (1 large missile) |
| RPC 5N62V Square Pair | `RPC_5N62V` | Tracking radar |
| P-14 Tall King | `P14_SR` | Search radar |
| 19J6 | `RLS_19J6` | Search radar (alternate) |

**Required for operation:** Tracking radar requires a search radar (P-14 or 19J6).

### NASAMS

The Norwegian Advanced Surface-to-Air Missile System (NASAMS) represents a joint Norwegian-American development that entered service in 1994, pioneering the concept of adapting proven air-to-air missiles for ground-based air defense. The system fires AIM-120 AMRAAM missiles from a truck-mounted launcher, leveraging decades of development and massive production quantities of this mature air-to-air weapon while eliminating the need for separate missile development programs.

The NASAMS employs a distributed architecture with networked launchers, radars, and command centers that can be separated by kilometers, reducing vulnerability to attack and allowing flexible deployment. Each Launcher Container Rack (LCHR) carries six AIM-120s in sealed canisters that serve as both storage and launch tubes. The AIM-120's active radar homing guidance is fully autonomous—once launched, the missile guides itself to the target without requiring continuous radar illumination, enabling simultaneous engagement of multiple targets. Range exceeds 25 km depending on engagement geometry and missile variant.

NASAMS has been exported to numerous NATO and partner nations including the United States (protecting the Washington, D.C. area), Finland, Netherlands, Lithuania, and others. The system gained significant attention when provided to Ukraine beginning in 2022, where it has demonstrated high effectiveness against Russian cruise missiles, drones, and aircraft. Ukrainian operators have reported intercept rates exceeding 90% against Russian missiles, with NASAMS proving particularly valuable for defense of critical infrastructure. The combination of proven missile technology, network-centric architecture, and relative affordability has made NASAMS one of the most successful modern short-to-medium range SAM systems.

| Component | Type ID | Role |
|-----------|---------|------|
| LCHR (AIM-120B) | `NASAMS_LN_B` | Launcher with AIM-120B |
| LCHR (AIM-120C) | `NASAMS_LN_C` | Launcher with AIM-120C |
| AN/MPQ-64F1 | `NASAMS_Radar_MPQ64F1` | Sentinel search radar |
| FDC | `NASAMS_Command_Post` | Fire Distribution Center |

**Required for operation:** Launchers require the Command Post. Command Post requires the radar.

### Rapier

The Rapier short-range air defense system entered British Army service in 1971 as a replacement for the towed Bofors 40mm guns that had provided low-level air defense since World War II. Developed by British Aircraft Corporation, Rapier was designed from the outset for mobility and accuracy, capable of engaging fast, low-flying aircraft with a hit probability that conventional guns could not match. The system's name, according to BAC, stood for "Rapid Anti-aircraft Projected Interception of Enemy Radar-visible aircraft."

The original Rapier used optical tracking with command line-of-sight guidance: an operator tracked the target through a magnified sight while the system automatically tracked the missile and computed steering commands to bring missile and target together. This simple but effective approach achieved remarkable accuracy—reportedly better than 70% hit probability—but was limited to clear weather and daytime operations. The Blindfire radar, added to form the Field Standard A (FSA) configuration, provided all-weather capability by replacing the optical tracker with radar tracking for both target and missile.

Rapier saw combat during the 1982 Falklands War, where systems deployed with the Royal Artillery and RAF Regiment engaged Argentine aircraft attacking the task force and ground forces. Rapier batteries claimed at least 14 aircraft destroyed, though some claims remain disputed. The system experienced maintenance challenges in the harsh South Atlantic conditions, and the optical system was degraded by the frequent fog, rain, and low cloud. The Blindfire-equipped units provided essential all-weather coverage. Rapier was also deployed during the Gulf War and has been exported to numerous countries including Switzerland, Iran, Turkey, and several others. The system remained in British service until replacement by Sky Sabre (Land Ceptor) in the 2020s.

| Component | Type ID | Role |
|-----------|---------|------|
| Launcher | `rapier_fsa_launcher` | Launcher (4 missiles) |
| Blindfire TR | `rapier_fsa_blindfire_radar` | Tracking radar (all-weather) |
| Optical Tracker | `rapier_fsa_optical_tracker_unit` | Optical tracking unit |

**Required for operation:** Launcher requires the Blindfire radar for all-weather operation.

### IRIS-T SLM

The IRIS-T SLM (Surface Launched Medium Range) represents Germany's premier modern short-to-medium range air defense system, entering service in 2022. The system adapts the proven IRIS-T infrared-guided air-to-air missile—developed as a Sidewinder replacement for the German Luftwaffe and numerous export customers—to a ground-launched configuration. The "SLM" variant features an extended-range motor providing engagement capability out to approximately 40 km.

The system architecture consists of networked vertical launchers, each carrying eight missiles in sealed canisters, connected to the CEAFAR-2 multi-function radar and IBCS command posts. The IRIS-T missile uses an imaging infrared seeker with exceptional off-boresight capability, allowing it to engage targets across a wide angle and providing inherent resistance to radar-based countermeasures. The missile's thrust-vectoring nozzle provides extreme maneuverability, essential for intercepting agile targets or cruise missiles executing terminal evasive maneuvers.

Germany provided IRIS-T SLM to Ukraine as one of the first deliveries of modern Western air defense systems in October 2022, and the system quickly demonstrated exceptional effectiveness against Russian cruise missiles, drones, and aircraft. Ukrainian operators have reported intercept rates near 100% against engaged targets, with the system credited with protecting Kyiv and other cities from Russian missile and drone attacks. The combination of an advanced infrared seeker immune to radar jamming, extreme missile agility, and modern network-centric command and control has validated the IRIS-T SLM concept. Egypt, Sweden, and other nations have ordered the system.

| Component | Type ID | Role |
|-----------|---------|------|
| Launcher | `CHAP_IRISTSLM_LN` | Launcher |
| STR | `CHAP_IRISTSLM_STR` | Search/track radar |
| C2 | `CHAP_IRISTSLM_CP` | Command post |

**Required for operation:** Launcher requires the STR.

### HQ-7 (FM-80/90)

The HQ-7 (Hóngqí-7, "Red Banner 7") is China's first domestically produced short-range air defense system, entering service in 1988. The system is based on the French Crotale, which China obtained samples of through Pakistan in the 1980s. The export designations FM-80 and FM-90 refer to progressively improved variants with enhanced missiles and fire control systems. The HQ-7 represented a significant step forward for Chinese air defense, providing mobile, low-altitude coverage that older systems could not match.

The system consists of a tracked TELAR (Transporter Erector Launcher And Radar) carrying four missiles on a rotating turret with integrated search and tracking radar, allowing independent operation without external support vehicles. Engagement range is approximately 12 km with altitude coverage from 15 meters to 6 kilometers—optimized for defending ground forces against low-flying aircraft, helicopters, and cruise missiles. The FM-90 features an improved missile with greater range, better seeker performance, and enhanced resistance to countermeasures.

The HQ-7 has been exported to Pakistan, Bangladesh, and Iran, with Iranian systems reportedly deployed against Iraqi aircraft during the final phase of the Iran-Iraq War. The system saw service during the 1991 Gulf War when Kuwaiti batteries attempted to engage Iraqi aircraft during the invasion. Chinese forces deploy the HQ-7 to protect mechanized divisions and high-value installations. While superseded by more capable systems like the HQ-16 and HQ-9 for frontline use, the HQ-7 remains in service for point defense and with export customers.

| Component | Type ID | Role |
|-----------|---------|------|
| TELAR | `HQ-7_LN_SP` | Launcher with onboard radar |
| TELAR (Player) | `HQ-7_LN_P` | Player-controllable version |
| SR | `HQ-7_STR_SP` | Search radar (optional) |

**Required for operation:** TELAR can operate independently.

### Self-Propelled SAM Systems (Single Vehicle)

These systems combine radar, launcher, and fire control into a single vehicle, providing highly mobile short-range air defense that can keep pace with armored formations.

**2S6 Tunguska (SA-19 "Grison")** (`2S6 Tunguska`) - The 2S6 Tunguska entered Soviet service in 1982 as the world's first combined gun-missile air defense system, merging the short-range killing power of automatic cannon with the extended reach of guided missiles. Armed with twin 30mm autocannons providing 5,000 rounds per minute combined fire rate and eight 9M311 missiles with 8 km range, the Tunguska can engage helicopters and aircraft out to missile range, then destroy any that penetrate with its guns. The tracked chassis provides cross-country mobility to accompany tank units. The system saw action during the 2008 Russo-Georgian War and the Russian intervention in Syria.

**9A33 Osa (SA-8 "Gecko")** (`Osa 9A33 ln`) - The 9K33 Osa entered service in 1972 as the first fully mobile, all-in-one Soviet SAM system with radar and missiles on the same amphibious vehicle. The distinctive rotating turret carries six 9M33 missiles with 10 km range, while the "Land Roll" radar provides both search and tracking capability. The Osa was designed to protect motorized rifle divisions against low-flying aircraft that larger SAMs like the Kub could not engage effectively. The system was widely exported and saw combat in Angola, Libya, Syria during the 1982 Lebanon War, and the Iran-Iraq War.

**9A331 Tor (SA-15 "Gauntlet")** (`Tor 9A331`) - The Tor entered Soviet service in 1986 as a replacement for the Osa, designed specifically to counter precision-guided munitions, cruise missiles, and smart bombs as well as aircraft. The vertically-launched 9M330 missile achieved engagement ranges out to 12 km with extremely fast reaction time—essential against fast-closing threats. The system's phased array radar provides multiple target tracking and engagement. Tor systems have been extensively employed in Syria, where Russian batteries have engaged Israeli missiles and drones, and in Ukraine where both sides operate variants of the system.

**Tor-M2** (`CHAP_TorM2`) - The Tor-M2 represents the latest evolution of the Tor system, featuring improved missiles with 16 km range, enhanced radar, and the ability to engage four targets simultaneously. The system has demonstrated effectiveness against rocket artillery, drones, and cruise missiles, making it particularly valuable against modern threats.

**Pantsir-S1 (SA-22 "Greyhound")** (`CHAP_PantsirS1`) - The Pantsir-S1 entered Russian service in 2012 as a replacement for the Tunguska, combining twin 30mm autocannons with twelve 57E6 missiles providing 20 km engagement range. Mounted on a truck chassis for strategic mobility, the Pantsir is deployed to protect S-300 and S-400 batteries against cruise missiles and aircraft that penetrate the outer defense layers. The system has seen extensive combat in Syria, where Israeli forces have claimed destruction of multiple Pantsir units during strikes, including video of missiles hitting Pantsir vehicles before they could engage.

**Roland ADS** (`Roland ADS`) - The Roland was a Franco-German short-range SAM system entering service in 1977, designed to provide mobile air defense for European NATO forces. The system carried two ready missiles with eight more stored, engaging targets at ranges out to 6 km. Roland served with French, German, and American forces—the U.S. developed a version on an M109 chassis. The system saw combat during the 1991 Gulf War when Iraqi Rolands engaged coalition aircraft, reportedly damaging at least one F-16. Now retired from most users.

**9K35 Strela-10 (SA-13 "Gopher")** (`Strela-10M3`) - The Strela-10 entered Soviet service in 1976 as a replacement for the Strela-1, providing passive infrared homing guidance with enhanced resistance to countermeasures. Mounted on an MT-LB tracked chassis with four ready missiles, the system can engage helicopters and low-flying aircraft at ranges up to 5 km without emitting radar, making it difficult to detect and counter. The system remains in widespread service and has been used extensively in the Ukraine conflict by both sides.

**9P31 Strela-1 (SA-9 "Gaskin")** (`Strela-1 9P31`) - The Strela-1 entered Soviet service in 1968 as a mobile, vehicle-mounted version of the Strela-2 (SA-7) MANPADS concept. Mounted on a BRDM-2 scout car with four ready missiles, the system provided regimental air defense against low-flying threats. The infrared homing missiles required no radar emission but were limited by early seeker technology and countermeasures vulnerability. Widely exported and used in numerous conflicts.

**M48 Chaparral** (`M48 Chaparral`) - The M48 Chaparral entered U.S. Army service in 1969 as an interim short-range air defense system using the AIM-9 Sidewinder air-to-air missile in a ground-launched configuration. The tracked vehicle carries four ready missiles with an optical sight for target tracking. The system was effective against slow, non-maneuvering targets but struggled against modern jets. Replaced by Avenger and Stinger in U.S. service but remains in use with some export customers.

**M1097 Avenger** (`M1097 Avenger`) - The Avenger entered U.S. Army service in 1990, mounting two Stinger missile pods and a .50 caliber machine gun on a HMMWV. This highly mobile system provides short-range air defense for maneuver forces, engaging helicopters, aircraft, and drones at ranges up to 8 km. Avenger batteries have deployed to numerous contingencies and continue providing forward air defense for U.S. ground forces.

**M6 Linebacker** (`M6 Linebacker`) - The M6 Linebacker combines the M2 Bradley IFV with four ready Stinger missiles, providing air defense that can keep pace with armored formations without requiring dedicated vehicles. The Bradley's 25mm cannon provides secondary anti-air capability against helicopters, while the Stingers engage fixed-wing threats. The Linebacker concept was retired from U.S. service as the Army focused on network-centric air defense but demonstrated the value of integrating air defense into combat vehicle fleets.

## Support & Logistics

### Fuel Trucks

These vehicles automatically refuel nearby ground units when positioned close to them:

| Name | Type ID | Origin |
|------|---------|--------|
| Refueler ATZ-5 | `ATZ-5` | Soviet/Russian |
| Refueler ATZ-5 civil | `ural_atz5_civil` | Soviet/Russian (civilian) |
| Refueler ATZ-10 | `ATZ-10` | Soviet/Russian |
| Refueler ATMZ-5 | `ATMZ-5` | Soviet/Russian |
| Refueler ATZ-60 Tractor | `ATZ-60_Maz` | Soviet/Russian |
| Refueler TZ-22 Tractor | `TZ-22_KrAZ` | Soviet/Russian |
| Refueler M978 HEMTT | `M978 HEMTT Tanker` | USA |

### Ammunition Carriers

These vehicles automatically reload nearby units when positioned close to them:

| Name | Type ID | Description |
|------|---------|-------------|
| Ammo M30 Cargo Carrier | `M30_CC` | WWII-era American ammunition carrier based on the M3 halftrack chassis |

## Air Defence

### Anti-Aircraft Artillery (AAA)

Anti-aircraft artillery remains a significant threat to low-flying aircraft and helicopters despite the proliferation of guided missiles. While lacking the range and accuracy of SAMs, AAA provides high-volume fire that requires no lock-on or guidance, making it effective against maneuvering targets and resistant to electronic countermeasures. The psychological impact of heavy AAA fire should not be underestimated—even experienced pilots will alter tactics to avoid the streams of tracer fire from concentrated anti-aircraft positions.

#### Modern AAA

**ZU-23-2** - The Soviet ZU-23-2 twin 23mm autocannon entered service in 1960 and remains one of the world's most widely deployed anti-aircraft weapons. The air-cooled, gas-operated guns can fire 2,000 rounds per minute combined, engaging aircraft at slant ranges up to 2,500 meters. The system's simplicity, reliability, and effectiveness have made it ubiquitous—from Soviet motor rifle divisions to Afghan mujahideen, Syrian rebels, and technicals across Africa and the Middle East. The weapon is commonly mounted on trucks for mobility or emplaced in fixed positions for point defense.

**S-60 57mm** (`S-60_Type59_Artillery`) - The Soviet S-60 57mm automatic cannon entered service in 1950 as a medium-caliber anti-aircraft gun capable of engaging targets at altitudes and ranges beyond the reach of lighter weapons. When directed by the SON-9 "Fire Can" radar, the S-60 provided reasonably accurate fire against aircraft at ranges up to 6,000 meters. The high-explosive fragmentation rounds create a lethal burst radius that compensates for aiming errors. North Vietnamese S-60 batteries contributed to the dense air defense network around Hanoi that claimed numerous American aircraft.

**KS-19 100mm** (`KS-19`) - The Soviet KS-19 100mm anti-aircraft gun entered service in 1948 as a heavy AAA system for engaging high-altitude targets beyond the reach of lighter weapons. Capable of reaching altitudes up to 15,000 meters with its powerful cartridge, the KS-19 filled the gap between medium AAA and early SAM systems. When radar-directed, the gun could place shells with reasonable accuracy against bombers at extreme range. The system was widely exported and saw service in numerous conflicts including Vietnam, where it formed part of the integrated air defense network.

**ZSU-23-4 Shilka** (`ZSU-23-4 Shilka`) - The ZSU-23-4 "Shilka" entered Soviet service in 1965 and became the iconic self-propelled anti-aircraft gun of the Cold War era. Mounting four 23mm autocannons with a combined rate of fire approaching 3,400 rounds per minute, the Shilka creates a dense cone of fire that is lethal to any aircraft or helicopter within its 2,500-meter effective range. The "Gun Dish" radar provides autonomous target tracking, though the system can also engage optically. The Shilka proved devastating against Israeli aircraft during the 1973 Yom Kippur War, particularly when integrated with SAM systems—pilots diving to escape SAMs descended into Shilka engagement envelopes. The system has been used in virtually every conflict involving Soviet-equipped forces and remains in widespread service.

**ZSU-57-2** (`ZSU_57_2`) - The ZSU-57-2 entered Soviet service in 1955, mounting twin 57mm autocannons on a T-54 tank chassis. While theoretically capable of engaging aircraft, the slow rate of fire and lack of fire control radar made it marginally effective against fast jets. However, the powerful 57mm rounds proved devastating against ground targets, and the ZSU-57-2 found its greatest utility as a fire support vehicle for infantry. North Vietnamese forces used the vehicle in this role during the Vietnam War.

**Gepard** (`Gepard`) - The Flugabwehrkanonenpanzer Gepard entered German Army service in 1976 as one of the most capable SPAAGs ever built. Mounting twin Oerlikon KDA 35mm autocannons with sophisticated tracking radar, the Gepard can engage aircraft at ranges up to 5,500 meters with high probability of kill. The pulse-Doppler radar distinguishes moving targets from ground clutter, while the large-caliber ammunition carries proximity fuzes for enhanced lethality. Germany provided Gepard systems to Ukraine in 2022, where they have proven highly effective against Russian drones and cruise missiles, reportedly destroying hundreds of Iranian-supplied Shahed drones threatening Ukrainian infrastructure.

**M163 Vulcan** (`Vulcan`) - The M163 Vulcan Air Defense System entered U.S. Army service in 1969, mounting the M61 Vulcan 20mm rotary cannon on an M113 armored personnel carrier chassis. The six-barrel gatling gun fires up to 3,000 rounds per minute, creating a devastating stream of fire effective against helicopters and low-flying aircraft within 1,200 meters. The M163 provided mobile air defense for armored formations through the 1980s before replacement by Avenger and Stinger systems. The system remains in service with numerous export customers.

**C-RAM Phalanx** (`HEMTT_C-RAM_Phalanx`) - The Counter-Rocket, Artillery, and Mortar (C-RAM) system adapts the naval Phalanx CIWS for land-based defense of forward operating bases against indirect fire. The 20mm M61 Vulcan cannon, guided by Ku-band radar, automatically tracks and engages incoming rockets, artillery shells, and mortar rounds, destroying them in flight before they can impact friendly positions. C-RAM systems were deployed extensively in Iraq and Afghanistan, where they protected bases against insurgent rocket and mortar attacks.

| Name | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| AAA ZU-23 Emplacement | `ZU-23 Emplacement` | 23mm | Soviet twin-barrel autocannon, towed |
| AAA ZU-23 Closed Emplacement | `ZU-23 Emplacement Closed` | 23mm | Protected version |
| AAA ZU-23 on Ural-4320 | `Ural-375 ZU-23` | 23mm | Truck-mounted for mobility |
| AAA ZU-23 on Ural Insurgent | `Ural-375 ZU-23 Insurgent` | 23mm | Insurgent version |
| AAA ZU-23 Insurgent Emplacement | `ZU-23 Insurgent` | 23mm | Insurgent towed |
| AAA ZU-23 Insurgent Closed | `ZU-23 Closed Insurgent` | 23mm | Insurgent protected |
| AAA S-60 57mm | `S-60_Type59_Artillery` | 57mm | Soviet heavy AAA, radar-directed with SON-9 |
| AAA KS-19 100mm | `KS-19` | 100mm | Soviet heavy AAA, radar-directed with SON-9 |
| SPAAA ZSU-23-4 Shilka | `ZSU-23-4 Shilka` | 23mm | Iconic Soviet radar-guided SPAAG |
| SPAAA ZSU-57-2 | `ZSU_57_2` | 57mm | Soviet twin 57mm SPAAG |
| SPAAA Gepard | `Gepard` | 35mm | German twin 35mm SPAAG |
| SPAAA Vulcan M163 | `Vulcan` | 20mm | American M61 Vulcan on M113 chassis |
| SPAAA HL with ZU-23 | `HL_ZU-23` | 23mm | Technical with ZU-23 |
| SPAAA LC with ZU-23 | `tt_ZU-23` | 23mm | Technical with ZU-23 |
| LPWS C-RAM | `HEMTT_C-RAM_Phalanx` | 20mm | Counter-rocket/artillery/mortar system |
| AAA Bofors 40mm | `bofors40` | 40mm | Swedish-designed, widely used in WWII and after |

#### WWII-Era AAA

**8.8cm Flak 18/36/37 "Eighty-Eight"** - The German 88mm Flak became the most famous anti-aircraft gun of World War II and arguably the most versatile artillery piece of the war. Entering service in 1933, the 88 combined exceptional muzzle velocity, effective ceiling of 9,900 meters, and lethal bursting charge to create a weapon that devastated Allied bomber formations. The gun proved equally effective against tanks, leading to its deployment in anti-tank and field artillery roles—the Tiger I tank's main armament was derived from the Flak 41. Allied bomber crews learned to fear the dense box barrages of 88mm fire over German cities, where batteries directed by radar and optical predictors could place shells with deadly accuracy. The Flak 36 improved transportability with a two-wheel carriage, while the Flak 37 added enhanced fire control data transmission.

**Flak 38 20mm** - The German Flak 38 (and earlier Flak 30) 20mm autocannon served as the primary light anti-aircraft weapon of the Wehrmacht. The single-barrel version provided 220 rounds per minute against low-flying aircraft, while the Flakvierling 38 quad mount increased firepower to nearly 800 rounds per minute. These weapons equipped virtually every German position, from airfields to naval vessels to infantry units. The 20mm was particularly effective against low-flying fighter-bombers conducting strafing runs.

**Bofors 40mm** (`bofors40`) - The Swedish-designed Bofors 40mm became the most widely used medium anti-aircraft gun of World War II, adopted by virtually every Allied nation and several Axis powers. Entering production in 1934, the Bofors combined high rate of fire (120 rounds per minute), effective range (over 3,800 meters), and lethal shell weight. American and British forces deployed the Bofors extensively on ships and in field batteries, where it proved devastating against kamikaze attacks and low-level bombing. The gun remains in limited service today, seven decades after its introduction.

**QF 3.7-inch** (`QF_37_AA`) - The British 3.7-inch (94mm) anti-aircraft gun served as the backbone of the United Kingdom's air defense throughout World War II. Comparable to the German 88mm in capability, the 3.7-inch could engage bombers at altitudes up to 9,000 meters. Batteries of 3.7-inch guns, directed by primitive radar and predictor systems, defended British cities during the Blitz and protected the fleet from aerial attack. Unlike the German 88, the 3.7-inch was rarely employed in the anti-tank role despite its theoretical capability.

| Name | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| AAA 8,8cm Flak 18 | `flak18` | 88mm | German, the famous "Eighty-Eight" |
| AAA 8,8cm Flak 36 | `flak36` | 88mm | Improved Flak 18 |
| AAA 8,8cm Flak 37 | `flak37` | 88mm | Flak 36 with improved data transmission |
| AAA 8,8cm Flak 41 | `flak41` | 88mm | High-velocity version |
| AAA Flak 38 20mm | `flak30` | 20mm | German light AAA |
| AAA Flak-Vierling 38 | `flak38` | 20mm | Quad 20mm mount |
| AAA M1 37mm | `M1_37mm` | 37mm | American medium AAA |
| AAA M45 Quadmount | `M45_Quadmount` | 12.7mm | American quad .50 cal |
| AAA 25mm x 2 Type 94 Truck | `Type_94_25mm_AA_Truck` | 25mm | Japanese truck-mounted |
| AAA 25mm x 2 Type 96 | `Type_96_25mm_AA` | 25mm | Japanese towed |
| AAA 75mm Type 88 | `Type_88_75mm_AA` | 75mm | Japanese heavy AAA |
| AAA 80mm Type 3 | `Type_3_80mm_AA` | 80mm | Japanese heavy AAA |
| AAA QF 3.7 | `QF_37_AA` | 94mm | British heavy AAA |

#### Fire Control and Radars

| Name | Type ID | Role |
|------|---------|------|
| AAA Fire Can SON-9 | `SON_9` | Fire control radar for S-60 and KS-19 |
| AAA Kdo.G.40 | `KDO_Mod40` | German optical fire director for 88mm guns |
| Allies Rangefinder (DRT) | `Allies_Director` | Allied optical fire director |
| SL Flakscheinwerfer 37 | `Flakscheinwerfer_37` | German searchlight |
| Maschinensatz 33 | `Maschinensatz_33` | German generator for AAA systems |
| Diesel Power Station 5I57A | `generator_5i57` | Soviet generator for SAM systems |

### MANPADS

Man-Portable Air Defense Systems represent one of the most significant threats to low-flying aircraft in modern warfare. These shoulder-launched missiles allow individual infantry soldiers to engage helicopters and aircraft without requiring vehicles, radars, or extensive training. The proliferation of MANPADS has fundamentally changed air warfare, forcing aircraft to fly higher, use countermeasures, and avoid areas where infantry might be concealed.

**FIM-92 Stinger** - The FIM-92 Stinger entered U.S. Army service in 1981 as a replacement for the earlier Redeye missile. The Stinger's proportional navigation guidance and all-aspect engagement capability—able to attack aircraft from any angle rather than only from behind—represented a major improvement over first-generation MANPADS. The missile uses an infrared/ultraviolet dual-detector seeker that helps discriminate aircraft from countermeasure flares. Stingers provided by the CIA to Afghan mujahideen during the Soviet-Afghan War proved devastatingly effective against Soviet helicopters and aircraft, contributing to the Soviet withdrawal. The missile has since seen action in numerous conflicts and remains the primary American MANPADS. Stingers provided to Ukraine have claimed numerous Russian helicopters and aircraft.

**9K38 Igla (SA-18 "Grouse")** - The 9K38 Igla entered Soviet service in 1983 as a successor to the Strela-2 (SA-7). The Igla improved significantly on earlier Soviet MANPADS with better seeker sensitivity, enhanced resistance to countermeasures, and all-aspect engagement capability. The missile achieved approximately 5 km range against typical targets. The Igla has been widely exported and used in numerous conflicts, with Iraqi systems downing American helicopters during the 2003 invasion and various operators employing the weapon in Syria, Libya, and Ukraine. The improved 9K338 Igla-S (SA-24 "Grinch") introduced an enhanced seeker, greater range, and improved proximity fuze.

MANPADS pose particular risks because of their small size and portability. Unlike vehicle-mounted SAMs that can be tracked and targeted, a soldier with a MANPADS can hide almost anywhere and engage aircraft with little warning. The concern over MANPADS proliferation to terrorist groups has led to extensive international efforts to control their spread and secure existing stockpiles.

| Name | Type ID | Missile | Notes |
|------|---------|---------|-------|
| MANPADS Stinger | `Soldier stinger` | FIM-92 | American IR-guided |
| MANPADS Stinger C2 | `Stinger comm` | FIM-92 | With communication equipment |
| MANPADS Stinger C2 Desert | `Stinger comm dsr` | FIM-92 | Desert camouflage |
| SA-18 Igla | `SA-18 Igla manpad` | 9K38 | Soviet/Russian IR-guided |
| SA-18 Igla-S | `SA-18 Igla-S manpad` | 9K338 | Improved Igla |
| SA-18 Igla C2 | `SA-18 Igla comm` | 9K38 | With communication |
| SA-18 Igla-S C2 | `SA-18 Igla-S comm` | 9K338 | Improved with comms |
| Igla INS | `Igla manpad INS` | 9K38 | Insurgent version |

### Early Warning Radars

Long-range surveillance radars for detecting aircraft:

| Name | Type ID | Range | Notes |
|------|---------|-------|-------|
| EWR 1L13 | `1L13 EWR` | ~300km | Soviet VHF radar |
| EWR 55G6 | `55G6 EWR` | ~400km | Soviet UHF radar |
| EWR AN/FPS-117 | `FPS-117` | ~450km | American 3D radar |
| EWR AN/FPS-117 (domed) | `FPS-117 Dome` | ~450km | Protected version |
| EWR AN/FPS-117 ECS | `FPS-117 ECS` | N/A | Equipment Control Shelter |
| EWR Dog Ear (9S80M1) | `Dog Ear radar` | ~80km | Soviet mobile radar |
| EWR FuMG-401 Freya LZ | `FuMG-401` | ~200km | WWII German radar |
| EWR FuSe-65 Würzburg-Riese | `FuSe-65` | ~80km | WWII German fire control radar |

## Armor

### Main Battle Tanks (MBTs)

The main battle tank remains the dominant ground combat vehicle, combining firepower, protection, and mobility in a single platform capable of decisive action on the battlefield. Modern MBTs mount powerful 120mm or 125mm guns capable of defeating any armored vehicle, composite and reactive armor providing protection against anti-tank weapons, and engines producing 1,000-1,500 horsepower for cross-country mobility.

#### Western MBTs

**M1A2 Abrams** (`M-1 Abrams`) - The M1 Abrams entered U.S. Army service in 1980 and has become the most combat-proven Western tank of the modern era. The M1A2 variant introduced the Commander's Independent Thermal Viewer for hunter-killer capability, allowing the commander to search for targets while the gunner engages. The 120mm M256 smoothbore gun fires a variety of rounds including depleted uranium APFSDS capable of penetrating any known armor. Chobham composite armor provides exceptional protection, particularly against HEAT warheads. The gas turbine engine produces 1,500 horsepower, giving the 70-ton tank surprising speed and acceleration. Abrams tanks devastated Iraqi armored forces during the 1991 Gulf War and 2003 invasion, often destroying T-72s at ranges exceeding 3,000 meters without suffering return hits. The M1A2C SEP v3 variant adds improved electronics, Trophy active protection system integration, and enhanced armor.

**M60A3 Patton** (`M-60`) - The M60 entered U.S. Army service in 1960 as the primary battle tank of the Cold War era before the Abrams. Armed with the 105mm M68 rifled gun (the American version of the British L7), the M60 served through Vietnam and the Yom Kippur War, where Israeli Magach 6 variants (M60s) fought Egyptian and Syrian armor. The M60A3 introduced thermal sights and laser rangefinder for improved accuracy. While replaced by the Abrams in U.S. service, M60 variants remain in use with numerous allies including Egypt, Turkey, and Israel.

**Challenger 2** (`Challenger2`) - The Challenger 2 entered British Army service in 1998 as the successor to Challenger 1. The tank mounts the 120mm L30A1 rifled gun, the last rifled tank gun in NATO service, chosen to maintain compatibility with HESH (High Explosive Squash Head) ammunition favored for urban warfare. Dorchester composite armor provides excellent protection; during the 2003 Iraq War, a Challenger 2 survived 70 RPG hits and one MILAN missile strike without penetration. The tank has seen action in Iraq and remains in British service.

**Chieftain Mk.3** (`Chieftain_mk3`) - The Chieftain entered British Army service in 1967 as the most powerfully armed and armored tank in the Western world. The 120mm L11 rifled gun set a new standard for tank armament, while the heavily sloped armor provided unprecedented protection for its era. The tank's Leyland engine proved underpowered and unreliable, limiting mobility. Iran and Jordan operated Chieftains extensively, with Iranian Chieftains fighting Iraqi T-62s during the Iran-Iraq War.

**Leopard 1A3** (`Leopard1A3`) - The Leopard 1 entered West German service in 1965 as the Bundeswehr's first indigenous tank design since World War II. German designers prioritized mobility and firepower over armor, calculating that any tank would be vulnerable to modern anti-tank weapons. The 105mm L7 gun provided excellent firepower, while the MTU diesel engine gave high speed. The Leopard 1 was widely exported and saw combat with numerous operators.

**Leopard 2** (`leopard-2A4`, `Leopard-2A5`, `Leopard-2`) - The Leopard 2 entered German service in 1979 and became one of the most successful tank designs in history. The 120mm Rheinmetall L/44 smoothbore gun (later the longer L/55) can defeat any known armor, while advanced composite armor and later variants' wedge-shaped turret add-ons provide excellent protection. Over 3,600 have been built for 19 operators. The Leopard 2A4 was widely exported and has seen combat with Turkish forces in Syria. Germany, along with several European allies, provided Leopard 2A4 and 2A6 tanks to Ukraine, where they have engaged Russian forces with mixed results—while effective in combat, several have been lost to mines, artillery, and anti-tank missiles.

**Leclerc** (`Leclerc`) - The Leclerc entered French Army service in 1992, featuring an autoloader that reduces crew to three and increases rate of fire. The 120mm CN120-26 gun and advanced fire control system provide excellent accuracy. The Leclerc served in Kosovo and Lebanon but has not seen major armor-on-armor combat.

**Merkava Mk.4** (`Merkava_Mk4`) - The Merkava ("Chariot") entered Israeli service in 1979 with a revolutionary design placing the engine in front to provide additional crew protection. This arrangement also created a rear compartment capable of carrying infantry or evacuating casualties—unique among main battle tanks. The Merkava was designed specifically for Israel's requirements: fighting in close terrain against anti-tank missiles, with crew survival as the highest priority. The Mk.4 variant mounts the 120mm MG253 smoothbore gun and Trophy active protection system. Merkavas have seen extensive combat in Lebanon and Gaza.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| MBT M1A2 Abrams | `M-1 Abrams` | USA | 120mm smoothbore, gas turbine |
| MBT M1A2C SEP v3 Abrams | `M1A2C_SEP_V3` | USA | Latest Abrams variant |
| MBT M60A3 Patton | `M-60` | USA | 105mm rifled gun |
| MBT Challenger II | `Challenger2` | UK | 120mm rifled gun, Chobham armor |
| MBT Chieftain Mk.3 | `Chieftain_mk3` | UK | 120mm rifled gun, 1960s design |
| MBT Leopard 1A3 | `Leopard1A3` | Germany | 105mm, first West German MBT |
| MBT Leopard-2A4 | `leopard-2A4` | Germany | 120mm, widely exported |
| MBT Leopard-2A4 Trs | `leopard-2A4_trs` | Germany | Training variant |
| MBT Leopard-2A5 | `Leopard-2A5` | Germany | Arrow-shaped turret armor |
| MBT Leopard-2A6M | `Leopard-2` | Germany | L55 longer barrel |
| MBT Leclerc | `Leclerc` | France | 120mm, autoloader |
| MBT Merkava IV | `Merkava_Mk4` | Israel | Front-mounted engine, troop compartment |

#### Eastern MBTs

**T-55** (`T-55`) - The T-55 entered Soviet service in 1958 and became the most-produced tank in history, with estimates exceeding 100,000 vehicles including licensed variants. The T-55's simple design, 100mm D-10T rifled gun, and robust construction made it easy to manufacture and maintain. The tank served as the backbone of Soviet and Warsaw Pact armored forces through the 1970s and was exported worldwide. T-55s have fought in virtually every conflict since 1960, from the Six-Day War through Vietnam, the Iran-Iraq War, and numerous African conflicts. The tank remains in service with many nations and has appeared in the Ukraine conflict.

**T-62** (`T62M`) - The T-62 entered Soviet service in 1961 as the first production tank with a smoothbore gun, the 115mm U-5TS. The smoothbore allowed firing APFSDS (Armor-Piercing Fin-Stabilized Discarding Sabot) rounds at higher velocities than rifled guns. The T-62 fought during the 1973 Yom Kippur War, where Syrian T-62s achieved initial successes before Israeli counterattacks. The tank's carousel-style spent case ejection and cramped interior limited crew efficiency. The T-62M variant added improved fire control and Kontakt-1 ERA.

**T-64** (`CHAP_T64BV`) - The T-64 entered Soviet service in 1966 as a revolutionary design featuring the first production autoloader, eliminating the loader and reducing crew to three. The 125mm 2A46 smoothbore gun became the standard Soviet tank armament. The T-64's sophisticated design and expensive components led to parallel development of the cheaper T-72 for export and mass production. The T-64BV variant added Kontakt-1 ERA. Large numbers of T-64s remained in Ukraine after the Soviet collapse and have seen extensive combat during the ongoing conflict with Russia.

**T-72** (`T-72B`, `T-72B3`) - The T-72 entered Soviet service in 1973 as a simplified, mass-production alternative to the sophisticated T-64. Armed with the same 125mm gun and autoloader, the T-72 was easier to manufacture and maintain. Over 25,000 were built, making it the most numerous Soviet tank of the Cold War era. The T-72's combat record has been mixed: Iraqi T-72s were easily destroyed by Coalition forces during the Gulf War, leading to debates about crew training versus vehicle capability. The T-72B variant added composite armor and Kontakt-5 ERA, while the T-72B3 is a Russian modernization program for remaining vehicles, adding improved fire control and the Relikt ERA. Both sides have lost hundreds of T-72 variants during the Ukraine conflict.

**T-80** (`T-80B`, `T-80UD`) - The T-80 entered Soviet service in 1976 as a high-performance tank featuring a gas turbine engine producing 1,100 horsepower. The turbine provided exceptional acceleration and cold-weather starting but consumed fuel at prodigious rates. The T-80U introduced the Shtora active protection system and improved armor. T-80s suffered badly during the First Chechen War when they entered Grozny in December 1994—Russian forces lost many tanks to Chechen fighters armed with RPGs in close urban combat. The T-80UD variant substituted a diesel engine for improved fuel efficiency.

**T-90** (`T-90`, `CHAP_T90M`) - The T-90 entered Russian service in 1992 as an evolution of the T-72B with improved fire control, Shtora active protection, and Kontakt-5 ERA. Originally designated T-72BU, the tank was renamed T-90 for marketing purposes following the T-72's poor showing in the Gulf War. The T-90A introduced a welded turret, while the T-90M "Proryv" adds the Relikt ERA, improved fire control, and remote weapon station. The T-90 has been widely exported to India, Algeria, and other nations. Russian T-90s have seen extensive combat in Ukraine, where they have proven capable but vulnerable to modern anti-tank weapons.

**T-84 Oplot-M** (`CHAP_T84OplotM`) - The T-84 Oplot represents Ukraine's indigenous development of the T-80UD, featuring an upgraded 125mm gun, explosive reactive armor, and Western-standard electronics. The Oplot-M variant offered for export includes improved fire control and the Ukrainian-developed "Knife" ERA. Thailand purchased Oplot-Ms, while Ukraine has deployed limited numbers during the ongoing conflict.

**Type 59** (`TYPE-59`) - The Type 59 is China's license-built copy of the Soviet T-54A, entering production in 1959 as the first Chinese-manufactured tank. The design was progressively upgraded with better fire control and ammunition but retained the basic 100mm gun. Pakistan operated Type 59s during the 1971 Indo-Pakistani War. The tank remains in service with numerous countries, often heavily modified.

**ZTZ-96B** (`ZTZ96B`) - The ZTZ-96 series represents China's domestically developed main battle tank, entering service in 1997. Armed with a 125mm smoothbore gun with autoloader similar to Soviet designs, the ZTZ-96B adds improved armor, fire control, and ERA. The tank has not seen combat but represents the bulk of PLA armored strength.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| MBT T-55 | `T-55` | USSR | 100mm, widely exported |
| MBT T-62M | `T62M` | USSR | First with 115mm smoothbore |
| MBT T-72B | `T-72B` | USSR | 125mm, autoloader, ERA |
| MBT T-72B3 | `T-72B3` | Russia | Modernized T-72 |
| MBT T-80B | `T-80B` | USSR | Gas turbine engine |
| MBT T-80U | `T-80UD` | USSR | Diesel engine variant |
| MBT T-90A | `T-90` | Russia | Evolution of T-72 |
| MBT T-90M | `CHAP_T90M` | Russia | Latest T-90 variant |
| MBT T-64BV | `CHAP_T64BV` | USSR | First with autoloader |
| MBT T-84 Oplot-M | `CHAP_T84OplotM` | Ukraine | Modern Ukrainian MBT |
| MT Type 59 | `TYPE-59` | China | Chinese T-54 derivative |
| ZTZ-96B | `ZTZ96B` | China | Modern Chinese MBT |

#### WWII Tanks

**M4 Sherman** (`M4_Sherman`) - The M4 Sherman entered U.S. service in 1942 and became the most important Allied tank of World War II, with nearly 50,000 produced. The Sherman's reliability, ease of production, and ability to be shipped in vast numbers gave Allied forces armored superiority through sheer quantity. The tank's 75mm gun could defeat most German armor at typical combat ranges, though it struggled against Panthers and Tigers. The Sherman's relatively thin armor made it vulnerable, earning grim nicknames from crews, but its mechanical reliability, standardized production, and crew survivability (including wet ammunition storage in later variants) meant more tanks stayed operational. Shermans fought from North Africa through Normandy to the heart of Germany, and with Soviet lend-lease forces on the Eastern Front.

**M4A4 Sherman Firefly** (`M4A4_Sherman_FF`) - The Sherman Firefly was a British conversion mounting the powerful 17-pounder anti-tank gun in a modified Sherman turret. The 17-pounder could penetrate the frontal armor of Panthers and Tigers at combat ranges, making the Firefly the only Allied tank capable of reliably defeating German heavy armor. British tank troops typically included one Firefly per troop of four Shermans. German crews learned to identify and prioritize Fireflies, leading some British units to disguise the distinctive long barrel. The Firefly played a crucial role in Normandy, where it provided the British Army's answer to German armor superiority.

**T-34-85** (`T-34-85`) - The T-34-85 was the definitive variant of the Soviet T-34, the tank that shocked German forces in 1941 with its sloped armor and 76mm gun. The T-34-85 variant, introduced in 1944, added an enlarged three-man turret mounting the 85mm ZiS-S-53 gun, which could defeat Panthers at reasonable combat ranges. The combination of firepower, armor, mobility, and mass production made the T-34 arguably the most influential tank design of the war. Over 80,000 T-34 variants were produced. The tank continued in service with numerous nations through the Korean War and beyond.

**Panther** (`Pz_V_Panther_G`) - The Panzerkampfwagen V Panther entered German service in 1943 as a direct response to the Soviet T-34. The Panther combined a high-velocity 75mm L/70 gun capable of defeating any Allied tank at extreme range, sloped armor providing excellent protection, and good mobility despite its 45-ton weight. Many historians consider the Panther the best tank design of the war in terms of the balance of firepower, protection, and mobility. The Panther's main weaknesses were mechanical unreliability—particularly the transmission and final drive—and the inability to traverse the turret when the engine was off. Panthers fought at Kursk, Normandy, and in the defense of Germany.

**Panzer IV** (`Pz_IV_H`) - The Panzerkampfwagen IV served as the backbone of German armored forces throughout World War II, the only German tank in continuous production from 1939 to 1945. Early variants mounted a short 75mm gun for infantry support, but the Ausf. F2 and later variants received the long 75mm KwK 40, transforming the tank into an effective tank destroyer. The Panzer IV H variant featured additional armor skirts (Schürzen) protecting against anti-tank rifles and shaped-charge weapons. Over 8,500 were produced. The Panzer IV fought on all fronts and remained effective throughout the war despite being outclassed by later Allied designs.

**Tiger I** (`Tiger_I`) - The Panzerkampfwagen VI Tiger I entered German service in 1942 as a heavy breakthrough tank. The Tiger's 88mm KwK 36 gun, derived from the legendary Flak 88, could destroy any Allied tank at ranges exceeding 2,000 meters. The thick, well-sloped armor was nearly impervious to Allied tank guns until the introduction of the 17-pounder and 76mm Sherman. The Tiger's reputation caused "Tiger fear" among Allied tankers, who often reported any German tank as a Tiger. However, the Tiger was expensive, mechanically unreliable, and difficult to recover when disabled. Only 1,347 were built. Tigers achieved remarkable kill ratios in skilled hands but could not change the war's outcome through quality when facing Allied quantity.

**Tiger II** (`Tiger_II_H`) - The Panzerkampfwagen VI Tiger II "Königstiger" (King Tiger) entered German service in 1944 as the most powerful tank of the war. The 88mm KwK 43 L/71 gun could destroy any Allied tank at any combat range, while the sloped armor was virtually immune to frontal penetration by any Allied weapon. At 70 tons, the Tiger II was underpowered and unreliable, consuming fuel at rates Germany could not sustain. Only 489 were built. The Tiger II represented the pinnacle of WWII tank design but arrived too late and in too few numbers to affect the war's outcome.

**Cromwell IV** (`Cromwell_IV`) - The Cromwell entered British service in 1944 as a cruiser tank emphasizing speed over armor. The Rolls-Royce Meteor engine (derived from the Merlin aircraft engine) gave the Cromwell excellent speed, reaching 40 mph on roads. The 75mm gun was adequate against most German armor but struggled against Panthers and Tigers. Cromwells served with British armoured divisions from Normandy through Germany, where their speed proved valuable for exploitation and pursuit.

**Churchill VII** (`Churchill_VII`) - The Churchill infantry tank entered British service in 1941, designed for the slow, methodical advance envisioned for future trench warfare. The Churchill's thick armor, low speed, and ability to traverse difficult terrain made it ideal for close infantry support. The Churchill VII variant mounted the 75mm gun in a larger turret with thicker armor. Churchills proved their worth at Dieppe (despite the disaster), Tunisia, Italy, and Northwest Europe, where their ability to climb steep slopes and cross obstacles exceeded all other tanks.

**PT-76** (`PT_76`) - The PT-76 amphibious light tank entered Soviet service in 1951, designed for reconnaissance and amphibious operations. The tank could swim across rivers and lakes using water jets, eliminating the need for bridging equipment. The 76mm gun provided limited anti-armor capability. PT-76s saw combat with North Vietnamese forces during the Vietnam War, including attacks on U.S. Special Forces camps. The tank remains in service with numerous nations.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| Tk M4 Sherman | `M4_Sherman` | USA | Medium tank, workhorse of Allied forces |
| Tk M4A4 Sherman Firefly | `M4A4_Sherman_FF` | UK | Sherman with 17-pounder |
| Tk T-34-85 | `T-34-85` | USSR | Upgraded T-34 with 85mm gun |
| Tk Panther G | `Pz_V_Panther_G` | Germany | 75mm L/70, sloped armor |
| Tk PzIV H | `Pz_IV_H` | Germany | Late-war version with long 75mm |
| Tk Tiger 1 | `Tiger_I` | Germany | Heavy tank, 88mm gun |
| Tk Tiger II | `Tiger_II_H` | Germany | King Tiger, 88mm L/71 |
| Tk Cromwell IV | `Cromwell_IV` | UK | Fast British cruiser tank |
| Tk Churchill VII | `Churchill_VII` | UK | Heavy infantry tank |
| Tk Centaur IV CS | `Centaur_IV` | UK | Close support variant |
| Tk Tetrach | `Tetrarch` | UK | Light airborne tank |
| Tk Type 89 I-Go | `Type_89_I_Go` | Japan | WWII medium tank |
| Tk Type 98 Ke-Ni | `Type_98_Ke_Ni` | Japan | WWII light tank |
| LT PT-76 | `PT_76` | USSR | Amphibious light tank |

### Infantry Fighting Vehicles (IFVs)

Infantry Fighting Vehicles combine the troop-carrying capability of APCs with sufficient firepower to support dismounted infantry and engage enemy armor. Unlike APCs, which prioritize transport, IFVs are designed to fight alongside tanks, providing suppressive fire, anti-armor capability, and protected transport.

**BMP-1** (`BMP-1`) - The BMP-1 entered Soviet service in 1966 as the world's first true infantry fighting vehicle, establishing the concept of a tracked vehicle combining troop transport with significant armament. The 73mm 2A28 "Grom" low-pressure gun fires shaped-charge rounds effective against light armor, while the 9M14 Malyutka (AT-3 Sagger) ATGM provides anti-tank capability. The squad of eight infantry can fire through ports while buttoned up. The BMP-1's aluminum armor provides protection against small arms and shell fragments but is vulnerable to heavy machine guns and autocannon. The BMP-1 saw extensive combat during the Yom Kippur War, Soviet-Afghan War, Iran-Iraq War, and numerous other conflicts. The thin armor and exposed fuel tanks make it vulnerable to RPGs and mines.

**BMP-2** (`BMP-2`) - The BMP-2 entered Soviet service in 1980 as an improved BMP addressing lessons from the Yom Kippur War. The 73mm gun was replaced by the 30mm 2A42 autocannon, providing sustained fire against infantry, light vehicles, and low-flying aircraft. The 9M113 Konkurs (AT-5 Spandrel) ATGM replaced the manually guided Sagger with a SACLOS wire-guided missile effective to 4,000 meters. The BMP-2 has seen combat in Afghanistan, both Chechen Wars, Syria, and extensively in Ukraine, where both Russian and Ukrainian forces operate the vehicle.

**BMP-3** (`BMP-3`) - The BMP-3 entered Soviet service in 1987 as the most heavily armed IFV ever built. The unusual armament combines a 100mm 2A70 gun/missile launcher (firing both conventional rounds and 9M117 Bastion ATGMs), a coaxial 30mm 2A72 autocannon, and three 7.62mm machine guns. The 100mm gun provides infantry support firepower approaching that of a tank, while the ATGM capability matches dedicated anti-tank vehicles. The BMP-3's amphibious capability and low silhouette continue BMP traditions. The vehicle has been exported to numerous countries and has seen combat in Syria and Ukraine.

**BMD-1** (`BMD-1`) - The BMD-1 entered Soviet Airborne Forces (VDV) service in 1969 as a light IFV designed for parachute delivery. The aluminum-hulled BMD carries the same armament as the BMP-1 in a smaller package weighing only 7.5 tons. The vehicle can be dropped by parachute with or without crew aboard. The thin armor provides minimal protection, and the cramped interior limits dismount squad size to four or five soldiers. BMD-1s have deployed with Russian airborne forces in every conflict since Afghanistan.

**BTR-82A** (`BTR-82A`) - The BTR-82A entered Russian service in 2013 as a modernization of the BTR-80 8x8 wheeled armored personnel carrier. The 30mm 2A72 autocannon in a stabilized turret provides firepower matching the BMP-2, while the wheeled configuration offers higher road speed and lower operating costs than tracked vehicles. The BTR-82A has seen extensive combat in Syria and Ukraine, where its vulnerability to ATGMs and mines has resulted in significant losses.

**M2A2 Bradley** (`M-2 Bradley`) - The M2 Bradley entered U.S. Army service in 1981 after a protracted development program. The Bradley mounts a 25mm M242 Bushmaster chain gun and twin TOW ATGM launchers, providing both suppressive fire and anti-tank capability. The vehicle carries a squad of six infantry (reduced from original requirements to accommodate ammunition). The Bradley has proven effective in combat: during the Gulf War, Bradleys destroyed more Iraqi armored vehicles than M1 Abrams tanks did, using their TOW missiles and 25mm cannon against T-55s and BMPs. The M2A2 variant added appliqué armor and improved fire control. Bradleys have served in Iraq and Afghanistan, and the U.S. has provided Bradleys to Ukraine.

**LAV-25** (`LAV-25`) - The LAV-25 (Light Armored Vehicle) entered U.S. Marine Corps service in 1983 as a wheeled reconnaissance and security vehicle. The 8x8 vehicle mounts a 25mm M242 Bushmaster in a two-man turret, identical to the Bradley's armament. The LAV-25's wheeled configuration provides 62 mph road speed for rapid deployment and strategic mobility, though off-road capability is inferior to tracked vehicles. LAV-25s have deployed with Marine forces in Panama, the Gulf War, Somalia, Iraq, and Afghanistan.

**Stryker** (`M1126 Stryker ICV`) - The M1126 Stryker Infantry Carrier Vehicle entered U.S. Army service in 2002 as the core of the medium-weight Stryker Brigade Combat Teams. The 8x8 wheeled vehicle carries a nine-man infantry squad with .50 caliber machine gun or Mk 19 grenade launcher armament. The Stryker family includes numerous variants: command vehicles, mortar carriers, reconnaissance vehicles, and the M1128 Mobile Gun System with 105mm cannon. Stryker brigades deployed extensively to Iraq, where the vehicles' rapid movement and C-130 transportability proved valuable, though vulnerability to IEDs led to the addition of slat armor and eventually the "Double-V" hull.

**Marder** (`Marder`) - The Marder entered West German service in 1971 as one of the first purpose-built IFVs. The 20mm Rh 202 autocannon provides anti-personnel and light anti-armor fire, while the MILAN ATGM launcher (on later variants) adds anti-tank capability. The Marder carries seven dismounts in reasonable comfort for its era. Germany has provided Marders to Ukraine, where they have seen combat.

**Warrior** (`MCV-80`) - The FV510 Warrior entered British Army service in 1987, replacing the FV432 APC. The 30mm L21A1 RARDEN cannon fires accurate semi-automatic bursts effective against light armor and fortifications. The Warrior carries seven infantry and has deployed to the Gulf War, Bosnia, Iraq, and Afghanistan. The vehicle's relatively heavy armor provides good protection against 14.5mm fire.

**ZBD-04A** (`ZBD04A`) - The ZBD-04 is China's indigenous infantry fighting vehicle, entering service in the 2000s. The vehicle combines a 100mm gun/missile launcher (similar to the BMP-3), 30mm autocannon, and modern fire control systems. The ZBD-04A improved variant adds enhanced armor and electronics. The vehicle has not seen combat but equips PLA mechanized units.

**BMPT Terminator** (`CHAP_BMPT`) - The BMPT "Terminator" entered Russian service in 2017 as a specialized tank support combat vehicle designed to protect tanks in urban combat and against dismounted anti-tank teams. Armed with twin 30mm autocannons, four 9M120 Ataka ATGMs, and two automatic grenade launchers, the BMPT provides overwhelming firepower against infantry and light vehicles. The concept arose from Russian experiences in Grozny, where tanks without infantry support suffered severe losses to RPG teams. The BMPT has seen combat in Syria and Ukraine.

| Name | Type ID | Country | Armament | Notes |
|------|---------|---------|----------|-------|
| IFV BMP-1 | `BMP-1` | USSR | 73mm gun, AT-3 | First true IFV |
| IFV BMP-2 | `BMP-2` | USSR | 30mm autocannon, AT-5 | Improved BMP |
| IFV BMP-3 | `BMP-3` | USSR/Russia | 100mm gun, 30mm, AT-10 | Heavily armed |
| IFV BMD-1 | `BMD-1` | USSR | 73mm | Airborne IFV |
| IFV BTR-82A | `BTR-82A` | Russia | 30mm | Wheeled IFV |
| IFV M2A2 Bradley | `M-2 Bradley` | USA | 25mm, TOW | American IFV |
| IFV LAV-25 | `LAV-25` | USA | 25mm | Marine wheeled IFV |
| IFV Stryker ICV | `M1126 Stryker ICV` | USA | 12.7mm | Wheeled APC/IFV |
| IFV M1130 Stryker CV | `CHAP_M1130` | USA | Command | Command variant |
| IFV Marder | `Marder` | Germany | 20mm, Milan | German IFV |
| IFV Warrior | `MCV-80` | UK | 30mm | British IFV |
| ZBD-04A | `ZBD04A` | China | 100mm, 30mm | Chinese IFV |
| IFV BMPT Terminator | `CHAP_BMPT` | Russia | 2x30mm, ATGMs | Tank support vehicle |

### Armored Personnel Carriers (APCs)

Armored Personnel Carriers prioritize protected transport of infantry over fighting capability. While armed with machine guns or light autocannon for self-defense, APCs are designed to deliver troops to the edge of the battlefield rather than fight alongside tanks. The distinction between APCs and IFVs has blurred as vehicles like the BTR-82A gain heavier armament.

**BTR-60/70/80** (`BTR-60`, `BTR-70`, `BTR-80`) - The BTR (Bronetransportyor - "armored transporter") series has served as the Soviet and Russian standard wheeled APC since 1960. The BTR-60 introduced the 8x8 configuration with boat-shaped hull for amphibious capability. Each axle has independent suspension and power, allowing continued movement with several wheels disabled. The BTR-60 mounted only a 14.5mm machine gun turret, providing limited firepower. The BTR-70 (1972) improved the powertrain, while the BTR-80 (1986) added side doors (crews previously had to exit through roof hatches or small side ports) and a more powerful diesel engine. BTR series vehicles have seen combat in every Soviet and Russian conflict, as well as numerous export conflicts. The thin armor provides protection only against small arms and shell fragments.

**M113** (`M-113`) - The M113 entered U.S. Army service in 1960 and became the most widely used armored personnel carrier in history, with over 80,000 produced. The aluminum hull provided protection against small arms while keeping weight low enough for amphibious operation and helicopter transport. The M113 served as the U.S. Army's primary troop carrier through Vietnam, where its ability to traverse rice paddies earned it the nickname "ACAV" (Armored Cavalry Assault Vehicle) when fitted with additional weapons and gun shields. Though replaced in front-line service by Bradley IFVs, M113 variants continue serving in command, medical, mortar carrier, and other roles. Numerous countries continue operating M113s.

**AAV-7** (`AAV7`) - The AAV-7 (Assault Amphibious Vehicle) entered U.S. Marine Corps service in 1972 for ship-to-shore movement during amphibious operations. The tracked vehicle can launch from ships, transit to shore through heavy surf, and then serve as an APC on land. The AAV-7 carries 25 Marines and their equipment from amphibious ships up to 25 miles from shore. Armed with a 12.7mm machine gun and 40mm grenade launcher. The vehicle saw action during the Gulf War, where AAV-7s transported Marines across Kuwait. Age and vulnerability have led to development of the ACV (Amphibious Combat Vehicle) replacement.

**MT-LB** (`MTLB`) - The MT-LB (Mnogotselevoy Tyagach Legky Bronirovanny - "multi-purpose light armored tractor") entered Soviet service in 1964 as a general-purpose tracked vehicle. The MT-LB serves as an artillery tractor, APC, command vehicle, ambulance, and platform for numerous weapon systems from mortars to SAMs. The low ground pressure makes the MT-LB effective in snow and swamps. The vehicle's versatility has kept it in production for decades, with both Russia and Ukraine continuing to use large numbers.

**TPz Fuchs** (`TPZ`) - The Transportpanzer 1 Fuchs ("Fox") entered West German service in 1979 as a 6x6 wheeled armored transport. The Fuchs serves primarily in NBC reconnaissance, engineer, and command roles rather than as a front-line APC. The German Army deployed Fuchs vehicles to Afghanistan and other peacekeeping missions.

**M2A1 Halftrack** (`M2A1_halftrack`) - The M2 Half-Track entered U.S. service in 1941, combining a truck front end with tracked rear for improved cross-country mobility. The vehicle became the standard American infantry carrier of World War II, transporting rifle squads across North Africa, Italy, and Northwest Europe. The open-top design left occupants vulnerable to artillery and air attack but allowed rapid dismounting and 360-degree fire with mounted machine guns. Over 40,000 halftracks of all variants were produced.

**Sd.Kfz.251** (`Sd_Kfz_251`) - The Sonderkraftfahrzeug 251 was the German halftrack that carried Panzergrenadiers alongside tanks during World War II blitzkrieg operations. The vehicle mounted various armaments from machine guns to flamethrowers to anti-aircraft guns, with over 20 variants produced. The 251's armor protected against small arms fire, enabling mechanized infantry to keep pace with tanks. Over 15,000 were built, and the vehicle served on all German fronts from 1939 to 1945.

**MRAP Vehicles** (`CHAP_MATV`, `MaxxPro_MRAP`) - Mine-Resistant Ambush Protected (MRAP) vehicles emerged from U.S. experience with IED attacks in Iraq and Afghanistan. The M-ATV (MRAP All-Terrain Vehicle) and MaxxPro feature V-shaped hulls that deflect blast energy away from the crew compartment, dramatically improving survivability against roadside bombs. These vehicles replaced HMMWVs in patrol and convoy roles where the threat of mines and IEDs exceeded small arms. MRAPs have been provided to Ukraine, where they serve in similar roles against Russian forces.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| APC BTR-60 | `BTR-60` | USSR | 8x8 wheeled |
| APC BTR-70 | `BTR-70` | USSR | Improved BTR-60 |
| APC BTR-80 | `BTR-80` | USSR | Modern wheeled APC |
| APC M113 | `M-113` | USA | Aluminum hull, ubiquitous |
| APC AAV-7 | `AAV7` | USA | Amphibious assault vehicle |
| APC MTLB | `MTLB` | USSR | Multi-purpose tracked |
| APC TPz Fuchs | `TPZ` | Germany | 6x6 wheeled |
| APC M2A1 Halftrack | `M2A1_halftrack` | USA | WWII halftrack |
| APC Sd.Kfz.251 | `Sd_Kfz_251` | Germany | WWII halftrack |
| APC MRAP M-ATV | `CHAP_MATV` | USA | Modern MRAP |
| APC MRAP MaxxPro | `MaxxPro_MRAP` | USA | Mine-resistant vehicle |
| APC Type 98 So-Da | `Type_98_So_Da` | Japan | WWII APC |
| Tractor M4 High Speed | `M4_Tractor` | USA | Artillery tractor |
| LARC-V | `LARC-V` | USA | Amphibious cargo carrier |

### Tank Destroyers and Self-Propelled Guns

Tank destroyers and assault guns represent specialized armored vehicles optimized for specific roles—usually anti-tank warfare or infantry support—rather than the all-around capability of main battle tanks.

**M10 GMC** (`M10_GMC`) - The M10 Gun Motor Carriage entered U.S. service in 1942 as the first purpose-built American tank destroyer. The 3-inch M7 gun could defeat most German armor at typical combat ranges. The M10's open-topped turret reduced weight and improved crew visibility but left the crew vulnerable to artillery and air attack. American tank destroyer doctrine called for massing TD battalions against German armored thrusts rather than distributing them among infantry units—a doctrine that proved difficult to execute in practice.

**M1128 Stryker MGS** (`M1128 Stryker MGS`) - The M1128 Mobile Gun System mounted a 105mm M68A2 rifled gun on the Stryker chassis to provide direct fire support for Stryker brigade infantry. The automated turret allowed operation with a three-man crew. The MGS was intended to destroy bunkers, buildings, and light armor rather than engage main battle tanks. The system was retired from U.S. service in 2022 after reliability and capability concerns.

**Jagdpanther** (`Jagdpanther_G1`) - The Jagdpanther entered German service in 1944 as perhaps the best tank destroyer of World War II. Mounting the powerful 88mm Pak 43 gun in a low-profile casemate on the Panther chassis, the Jagdpanther combined excellent protection, firepower capable of defeating any Allied tank, and reasonable mobility. The lack of a turret required the entire vehicle to turn to engage targets, but the low silhouette made the Jagdpanther difficult to spot and hit. Only 415 were built—too few to affect the war's outcome.

**Jagdpanzer IV** (`JagdPz_IV`) - The Jagdpanzer IV was the production tank destroyer based on the Panzer IV chassis, entering German service in 1944. Early variants mounted the 75mm L/48 gun, while later versions received the longer L/70. The low silhouette made the Jagdpanzer IV an effective ambush vehicle. Over 2,000 were built, making it the most numerous German tank destroyer.

**StuG III** (`Stug_III`) - The Sturmgeschütz III (Assault Gun) was originally designed for infantry support, but mounting progressively longer 75mm guns transformed it into Germany's most successful tank killer of World War II. The StuG III's low silhouette, reasonable protection, and effective gun made it popular with crews, while its turretless design was cheaper and faster to produce than tanks. Over 10,000 StuG IIIs were built—more than any other German armored vehicle. The StuG III claimed more Allied tank kills than any other German vehicle.

**Elefant** (`Elefant_SdKfz_184`) - The Elefant (originally "Ferdinand") was a heavy tank destroyer built on hulls from the failed Porsche Tiger prototype. The 88mm Pak 43/2 gun could destroy any Allied tank at extreme range, while the thick armor was nearly impervious to enemy fire. However, the Elefant was underpowered, mechanically unreliable, and initially lacked any close-defense armament against infantry. At Kursk, Soviet infantry destroyed numerous Elefants with mines, grenades, and Molotov cocktails when the vehicles outran their own infantry support. Only 91 were built.

**Sturmpanzer IV Brummbär** (`SturmPzIV`) - The Sturmpanzer IV "Brummbär" ("Grouch") mounted a 150mm infantry gun for destroying fortifications and strongpoints in urban combat. The heavy howitzer could demolish buildings with direct fire. Over 300 were built from 1943 to 1945, seeing action in Italy and on the Eastern Front.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| SPG M10 GMC | `M10_GMC` | USA | WWII, 3-inch gun |
| SPG Stryker MGS | `M1128 Stryker MGS` | USA | 105mm gun on Stryker |
| SPG Jagdpanther | `Jagdpanther_G1` | Germany | 88mm, sloped armor |
| SPG Jagdpanzer IV | `JagdPz_IV` | Germany | 75mm L/48 or L/70 |
| SPG StuG III G | `Stug_III` | Germany | Assault gun, 75mm |
| SPG StuG IV | `Stug_IV` | Germany | StuG III on Pz IV chassis |
| SPG Elefant | `Elefant_SdKfz_184` | Germany | Heavy tank destroyer, 88mm |
| SPG Brummbaer | `SturmPzIV` | Germany | 150mm infantry gun |

### Scout and Reconnaissance Vehicles

Scout and reconnaissance vehicles trade protection for speed, silence, and low profile. Their mission is to find the enemy, report his location, and withdraw before being engaged—though many carry weapons for self-defense or to engage other scouts.

**BRDM-2** (`BRDM-2`) - The BRDM-2 (Boyevaya Razvedyvatelnaya Dozornaya Mashina - "Combat Reconnaissance Patrol Vehicle") entered Soviet service in 1962 and became the most widely used reconnaissance vehicle of the Cold War era. The 4x4 amphibious vehicle features belly wheels that can be lowered for crossing trenches, 14.5mm KPVT machine gun turret, and space for the scout crew. The BRDM-2 also served as the primary chassis for the 9P122 ATGM carrier and various command variants. The vehicle has seen combat worldwide and remains in widespread service.

**HMMWV** (`M1043 HMMWV Armament`) - The High Mobility Multipurpose Wheeled Vehicle entered U.S. Army service in 1984 as a replacement for the Jeep and other light vehicles. The HMMWV's wide stance and powerful engine provide excellent off-road mobility, while various armament configurations allow mounting of machine guns, grenade launchers, and TOW missiles. HMMWVs served extensively in the Gulf War, Iraq, and Afghanistan, though their vulnerability to IEDs led to the development of up-armored variants and eventual MRAP supplementation. The HMMWV remains in widespread service for roles where mine resistance is less critical.

**M8 Greyhound** (`M8_Greyhound`) - The M8 Light Armored Car entered U.S. service in 1943 as a 6x6 wheeled reconnaissance vehicle. The 37mm gun and machine guns provided adequate firepower against enemy scouts and soft targets. The Greyhound's speed made it effective for route reconnaissance, but its thin armor offered minimal protection. M8s served in Europe and the Pacific, often racing ahead of advancing forces to locate enemy positions.

**Sd.Kfz.234/2 Puma** (`Sd_Kfz_234_2_Puma`) - The Sd.Kfz.234/2 Puma was the premier German armored car of World War II, mounting a 50mm KwK 39 gun in a fully rotating turret on an 8x8 chassis. The Puma's speed, low silhouette, and effective armament made it excellent for reconnaissance and screening. The vehicle could function as a light tank destroyer when necessary. Only 101 were built due to late introduction and production difficulties.

**FV101 Scorpion** (`CHAP_FV101`) - The FV101 Scorpion entered British Army service in 1973 as the world's fastest tracked combat vehicle, capable of 50 mph. The aluminum-hulled light tank mounts a 76mm L23A1 gun for engaging light vehicles and structures. Scorpions deployed with British forces to the Falklands and Gulf War, where their speed proved valuable for reconnaissance and flank security.

**Technicals** (`HL_DSHK`, `HL_KORD`, `tt_DSHK`, `tt_KORD`) - "Technical" is the common term for civilian pickup trucks or SUVs mounting heavy weapons, named after the practice of NGOs in Somalia paying "technical assistance grants" for armed escort vehicles. Technicals have become ubiquitous in irregular warfare, providing mobility and firepower to insurgent and militia forces who lack access to purpose-built military vehicles. Common armaments include heavy machine guns (DShK, KORD, M2), recoilless rifles, anti-aircraft guns, and rocket launchers.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| Scout BRDM-2 | `BRDM-2` | USSR | Amphibious recon |
| Scout HMMWV | `M1043 HMMWV Armament` | USA | Armed Humvee |
| Scout Cobra | `Cobra` | Turkey | Armored recon |
| Scout M8 Greyhound | `M8_Greyhound` | USA | WWII armored car |
| Scout Puma AC | `Sd_Kfz_234_2_Puma` | Germany | WWII 8-wheel armored car |
| LT FV101 Scorpion | `CHAP_FV101` | UK | Light tank, 76mm |
| Scout FV107 Scimitar | `CHAP_FV107` | UK | 30mm autocannon |
| Scout Daimler AC | `Daimler_AC` | UK | WWII armored car |
| Scout HL with DSHK | `HL_DSHK` | USSR | Technical with 12.7mm |
| Scout HL with KORD | `HL_KORD` | Russia | Technical with 12.7mm |
| Scout LC with DSHK | `tt_DSHK` | USSR | Technical with 12.7mm |
| Scout LC with KORD | `tt_KORD` | Russia | Technical with 12.7mm |

### Anti-Tank Guided Missile Vehicles

Anti-tank guided missile vehicles provide infantry and mechanized forces with long-range anti-armor capability without the weight and signature of main battle tanks. These light vehicles carry potent missiles capable of destroying any tank from ranges exceeding direct-fire weapons.

**BRDM-2 with 9M14 Malyutka** (`BRDM-2_malyutka`) - The BRDM-2 served as the primary launch platform for the 9M14 Malyutka (AT-3 Sagger) wire-guided ATGM in Soviet service. The vehicle carries six missiles on a fold-down launcher. The Sagger achieved its greatest success during the 1973 Yom Kippur War, where Egyptian infantry destroyed numerous Israeli tanks during the Canal crossing. The missile's MCLOS (manual command line-of-sight) guidance required operators to fly the missile to the target using a joystick, demanding significant skill and steady nerves.

**M1045 HMMWV TOW** (`M1045 HMMWV TOW`) - The TOW (Tube-launched, Optically-tracked, Wire-guided) missile has been the primary American heavy anti-tank weapon since 1970. The HMMWV-mounted version provides mobility for TOW teams that previously had to move on foot or in M113s. The TOW's semi-automatic guidance requires only that the gunner keep the crosshairs on target while the missile automatically steers via wire commands. Current TOW 2B variants can defeat any known main battle tank. TOW-equipped HMMWVs have deployed extensively with U.S. forces and have been provided to numerous allies.

**M1134 Stryker ATGM** (`M1134 Stryker ATGM`) - The M1134 Stryker Anti-Tank Guided Missile Vehicle mounts twin TOW launchers on the Stryker chassis, providing Stryker Brigade Combat Teams with organic anti-armor capability. The vehicle carries ten TOW missiles and can engage tanks at ranges exceeding 3,750 meters.

**VAB Mephisto** (`VAB_Mephisto`) - The VAB Mephisto is a French anti-tank variant of the VAB armored personnel carrier, mounting four HOT (Haut subsonique Optiquement téléguidé Tiré d'un Tube) long-range ATGMs. The HOT missile can engage tanks at ranges up to 4,000 meters with semi-automatic guidance similar to TOW.

| Name | Type ID | Missile | Notes |
|------|---------|---------|-------|
| ATGM BRDM-2 Malyutka | `BRDM-2_malyutka` | AT-3 Sagger | Early ATGM carrier |
| ATGM HMMWV TOW | `M1045 HMMWV TOW` | TOW | American ATGM vehicle |
| ATGM Stryker | `M1134 Stryker ATGM` | TOW | Wheeled ATGM carrier |
| ATGM VAB Mephisto | `VAB_Mephisto` | HOT | French ATGM vehicle |
| APC BTR-RD | `BTR_D` | AT-5 Spandrel | Airborne ATGM carrier |

## Artillery

Artillery provides indirect fire support, delivering high explosives, illumination, smoke, and other munitions against targets beyond line of sight. Modern artillery systems combine long range, high accuracy, and rapid displacement capability to support maneuver forces while surviving counterbattery fire.

### Self-Propelled Howitzers

Self-propelled howitzers mount artillery pieces on armored, tracked chassis that provide mobility and protection for artillery crews. Unlike towed artillery, SPHs can shoot and displace rapidly to avoid counterbattery fire.

**M109 Paladin** (`M-109`) - The M109 entered U.S. Army service in 1963 and has become the most widely used Western self-propelled howitzer. The 155mm M126 howitzer fires standard NATO ammunition at ranges up to 24 km with conventional rounds, extending to 30+ km with rocket-assisted projectiles. The M109 served in Vietnam, the Gulf War, Iraq, and Afghanistan. The current M109A7 Paladin Integrated Management variant features improved automotive components and digital fire control. M109s have been provided to Ukraine, where they have proven effective in counter-battery and fire support roles.

**2S3 Akatsiya** (`SAU Akatsia`) - The 2S3 Akatsiya ("Acacia") entered Soviet service in 1971 as the standard divisional self-propelled howitzer. The 152mm 2A33 gun fires a heavier shell than NATO 155mm at similar ranges. The vehicle shares components with other Soviet tracked systems, simplifying logistics. The 2S3 has seen extensive combat in the Soviet-Afghan War, Chechen conflicts, and the ongoing Ukraine war.

**2S19 Msta** (`SAU Msta`) - The 2S19 Msta-S entered Soviet service in 1989 as a replacement for the 2S3, featuring improved range, rate of fire, and automation. The 152mm 2A64 gun can fire up to 8 rounds per minute at ranges exceeding 24 km. The Msta has seen combat in Chechnya, Syria, and extensively in Ukraine, where it serves as Russia's primary self-propelled artillery system.

**2S1 Gvozdika** (`SAU Gvozdika`) - The 2S1 Gvozdika ("Carnation") entered Soviet service in 1971 as a light, amphibious self-propelled howitzer for motorized rifle divisions. The 122mm 2A31 howitzer provides direct support at regimental level with range out to 15 km. The MT-LB-derived chassis is fully amphibious. The Gvozdika has been widely exported and sees extensive combat in Ukraine.

**ShKH Dana vz.77** (`SpGH_Dana`) - The ShKH Dana entered Czechoslovak service in 1981 as an innovative wheeled self-propelled howitzer. The 152mm gun mounted on a Tatra 8x8 chassis provides strategic mobility exceeding tracked SPHs while retaining respectable firepower. The wheeled configuration offered cost savings and simplified logistics for the Czechoslovak People's Army.

**T155 Firtina** (`T155_Firtina`) - The T155 Firtina ("Storm") is Turkey's license-built version of the South Korean K9 Thunder, entering service in 2004. The 155mm/52 caliber gun achieves NATO-standard performance with ranges exceeding 40 km using extended-range ammunition. The Firtina has seen combat during Turkish operations in Syria.

**PLZ-05** (`PLZ05`) - The PLZ-05 entered Chinese service in 2008 as an advanced 155mm self-propelled howitzer. The 52-caliber gun and automated loading system provide range and rate of fire matching or exceeding Western contemporaries. The PLZ-05 has not seen combat but equips front-line PLA artillery units.

**2S9 Nona** (`SAU 2-C9`) - The 2S9 Nona-S entered Soviet Airborne Forces service in 1981 as an air-droppable mortar/howitzer hybrid. The 120mm 2A51 gun/mortar can fire conventional mortar bombs, guided projectiles, or anti-tank rounds in direct fire. The vehicle's light weight allows parachute delivery, providing VDV units with organic artillery support.

| Name | Type ID | Caliber | Country | Notes |
|------|---------|---------|---------|-------|
| SPH M109 Paladin | `M-109` | 155mm | USA | Standard NATO SPH |
| SPH 2S3 Akatsia | `SAU Akatsia` | 152mm | USSR | Soviet equivalent |
| SPH 2S19 Msta | `SAU Msta` | 152mm | Russia | Modern SPH |
| SPH 2S1 Gvozdika | `SAU Gvozdika` | 122mm | USSR | Light amphibious SPH |
| SPH Dana vz77 | `SpGH_Dana` | 152mm | Czechoslovakia | 8x8 wheeled |
| SPH T155 Firtina | `T155_Firtina` | 155mm | Turkey | Korean K9 derivative |
| PLZ-05 | `PLZ05` | 155mm | China | Modern Chinese SPH |
| SPM 2S9 Nona | `SAU 2-C9` | 120mm | USSR | Airborne mortar/howitzer |
| SPH M12 GMC | `M12_GMC` | 155mm | USA | WWII self-propelled gun |
| SPH Wespe | `Wespe124` | 105mm | Germany | WWII SPH |

### Multiple Rocket Launchers (MRL)

Multiple rocket launchers deliver massive firepower across large areas in seconds, saturating targets with high explosives, submunitions, or specialized warheads. While less accurate than tube artillery, MRL systems compensate with volume of fire and psychological effect. Modern guided rockets have eliminated the accuracy disadvantage while retaining the firepower advantage.

**BM-21 Grad** (`Grad-URAL`) - The BM-21 Grad ("Hail") entered Soviet service in 1963 and has become the most widely deployed multiple rocket launcher in history. The truck-mounted system fires forty 122mm rockets in approximately 20 seconds, saturating a target area with 2,400 kg of high explosives. The Grad's simplicity, reliability, and devastating firepower have made it ubiquitous—virtually every Soviet-aligned or post-Soviet nation operates Grad systems, and they have seen combat in nearly every conflict since the 1960s. The Grad remains devastating against infantry in the open, soft vehicles, and unfortified positions.

**BM-27 Uragan** (`Uragan_BM-27`) - The BM-27 Uragan ("Hurricane") entered Soviet service in 1977 as a longer-range, heavier MRL. The sixteen 220mm rockets carry significantly more explosive than Grad rounds and can reach targets at 35 km. The Uragan fires cluster munitions, high explosives, or thermobaric warheads. The system has seen extensive combat in Afghanistan, Chechnya, and Ukraine.

**BM-30 Smerch** (`Smerch`, `Smerch_HE`) - The BM-30 Smerch ("Tornado") entered Soviet service in 1989 as the most powerful conventional rocket artillery system of its era. The twelve 300mm rockets can reach targets at 90 km while delivering cluster submunitions, high explosives, or fuel-air explosive warheads. The massive 280 kg warheads create devastating effects across wide areas. The Smerch has been used extensively in Ukraine by both Russian and Ukrainian forces.

**M270 MLRS** (`MLRS`) - The M270 Multiple Launch Rocket System entered U.S. Army service in 1983, providing NATO with long-range precision strike capability. The tracked launcher fires twelve 227mm rockets or two ATACMS tactical ballistic missiles. Original rockets used cluster munitions to saturate areas; the M30/M31 GMLRS (Guided MLRS) added GPS guidance for precision strike at 70+ km range. The M270 saw action in the Gulf War, where MLRS batteries devastated Iraqi positions with cluster munitions, earning the nickname "Steel Rain." MLRS systems have been provided to Ukraine with dramatic effect against Russian ammunition depots, command posts, and troop concentrations.

**M142 HIMARS** (`CHAP_M142_GMLRS_M30`, `CHAP_M142_GMLRS_M31`, `CHAP_M142_ATACMS_M39A1`, `CHAP_M142_ATACMS_M48`) - The M142 High Mobility Artillery Rocket System entered U.S. service in 2005 as a lighter, truck-mounted alternative to the tracked M270. HIMARS carries six GMLRS rockets or one ATACMS missile on a wheeled 5-ton truck chassis, providing strategic mobility and C-130 transportability that the heavier M270 lacks. HIMARS has achieved extraordinary prominence in Ukraine, where GPS-guided GMLRS rockets have systematically destroyed Russian ammunition depots, headquarters, and logistics nodes far behind front lines. The combination of 70+ km range, GPS precision, and shoot-and-scoot mobility has made HIMARS effectively invulnerable to Russian counterbattery fire while inflicting disproportionate damage.

**TOS-1A** (`CHAP_TOS1A`) - The TOS-1A "Solntsepyok" ("Blazing Sun") is a Russian thermobaric multiple rocket launcher based on a T-72 tank chassis. The 24-round launcher fires 220mm rockets containing fuel-air explosive warheads that create devastating overpressure effects, particularly lethal in enclosed spaces like fortifications, caves, and urban structures. The thermobaric effect creates a pressure wave followed by vacuum that can collapse structures and kill through lung damage even when personnel are behind cover. The TOS-1A has been used in Chechnya, Syria, and extensively in Ukraine, where its use against urban areas has drawn international condemnation.

| Name | Type ID | Caliber | Country | Notes |
|------|---------|---------|---------|-------|
| MLRS BM-21 Grad | `Grad-URAL` | 122mm | USSR | 40 rockets, widely exported |
| Grad FDDM (FC) | `Grad_FDDM` | N/A | USSR | Fire direction vehicle |
| MLRS BM-27 Uragan | `Uragan_BM-27` | 220mm | USSR | 16 rockets |
| MLRS BM-30 Smerch | `Smerch` | 300mm | Russia | 12 rockets, cluster munitions |
| MLRS BM-30 Smerch HE | `Smerch_HE` | 300mm | Russia | 12 rockets, HE warhead |
| MLRS M270 | `MLRS` | 227mm | USA | 12 rockets or 2 ATACMS |
| MLRS M270 FDDM (FC) | `MLRS FDDM` | N/A | USA | Fire direction vehicle |
| MLRS M142 HIMARS CM | `CHAP_M142_GMLRS_M30` | 227mm | USA | 6 GMLRS rockets (cluster) |
| MLRS M142 HIMARS HE | `CHAP_M142_GMLRS_M31` | 227mm | USA | 6 GMLRS rockets (HE) |
| MLRS M142 ATACMS M39A1 | `CHAP_M142_ATACMS_M39A1` | 610mm | USA | 1 ATACMS (cluster) |
| MLRS M142 ATACMS M48 | `CHAP_M142_ATACMS_M48` | 610mm | USA | 1 ATACMS (HE) |
| MLRS TOS-1A | `CHAP_TOS1A` | 220mm | Russia | Thermobaric rockets |
| MLRS HL with B8M1 | `HL_B8M1` | 80mm | USSR | Technical with rockets |
| MLRS LC with B8M1 | `tt_B8M1` | 80mm | USSR | Technical with rockets |

### Towed Artillery and Mortars

Towed artillery and mortars provide indirect fire support at lower cost than self-propelled systems, though with less mobility and protection. These weapons are easier to transport and deploy but require more time to move under fire.

**2B11 Mortar** (`2B11 mortar`) - The 2B11 is a Soviet 120mm heavy mortar providing battalion-level indirect fire support. The mortar can fire 12-15 rounds per minute at ranges up to 7 km, delivering HE, smoke, and illumination rounds. The 120mm mortar has been a standard infantry support weapon since World War II, offering firepower heavier than company mortars while remaining portable enough to accompany infantry.

**L118 Light Gun** (`L118_Unit`) - The L118 Light Gun entered British Army service in 1976 as a helicopter-transportable 105mm towed howitzer. The 1.8-ton gun can be lifted by Chinook or Puma helicopters, enabling rapid deployment to support airmobile and paratrooper operations. The L118 fires standard NATO 105mm ammunition at ranges up to 17 km. British L118s deployed to the Falklands, where they provided critical fire support during the mountain battles, and have served in Iraq and Afghanistan. The U.S. Army uses the M119, a license-built variant.

**M2A1 105mm Howitzer** (`M2A1-105`) - The M2A1 105mm howitzer served as the standard American divisional artillery piece of World War II. The reliable, accurate weapon provided responsive fire support from North Africa through the drive into Germany. The M2A1 remained in service through Korea and into Vietnam, where it was eventually replaced by the M102. The weapon's range of approximately 11 km was adequate for divisional support.

**Pak 40** (`Pak40`) - The 7.5 cm Pak 40 (Panzerabwehrkanone - "tank defense cannon") entered German service in 1942 as the standard anti-tank gun of the Wehrmacht. The powerful 75mm L/46 gun could defeat any Allied tank except the heaviest at normal combat ranges. Over 23,000 were produced, making it the most numerous German anti-tank gun. The Pak 40's effectiveness and availability made it feared by Allied tankers, though its weight made it difficult to maneuver in muddy conditions.

| Name | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| Mortar 2B11 | `2B11 mortar` | 120mm | Soviet heavy mortar |
| L118 Light Gun | `L118_Unit` | 105mm | British towed howitzer |
| FH M2A1 | `M2A1-105` | 105mm | WWII American howitzer |
| FH LeFH-18 | `LeFH_18-40-105` | 105mm | WWII German howitzer |
| FH Pak 40 | `Pak40` | 75mm | WWII German anti-tank gun |

## Infantry

Infantry remain the foundation of ground combat, capable of holding terrain, clearing buildings, and performing tasks that vehicles cannot. While vulnerable to air attack and artillery, dispersed infantry are difficult to detect and engage from the air, and infantry equipped with MANPADS and ATGMs pose lethal threats to aircraft and armor.

**Riflemen** - Standard infantry armed with assault rifles (AK-74, M4) provide the core of ground forces. Modern rifles offer effective range to 300-400 meters with select-fire capability. Russian soldiers typically carry the 5.45mm AK-74 or modernized AK-12, while Western and Western-aligned forces use 5.56mm NATO weapons including the M4 carbine.

**Machine Gunners** - Squad automatic weapons like the M249 SAW provide sustained suppressive fire, essential for fire and maneuver tactics. The M249 fires the same 5.56mm ammunition as riflemen but from belt-fed magazines allowing extended automatic fire.

**Anti-Tank Infantry** - Soldiers equipped with rocket-propelled grenades and anti-tank missiles provide organic anti-armor capability. The RPG-7 has been the most widely used infantry anti-tank weapon since the 1960s, firing a variety of shaped-charge and tandem warheads capable of defeating most armored vehicles when hitting side or rear armor. Paratroopers carry the RPG-16, a lighter weapon optimized for airborne forces.

**JTAC** - Joint Terminal Attack Controllers are specialized personnel trained to direct close air support. JTACs coordinate between ground forces and attacking aircraft, identifying targets, clearing airspace, and ensuring strikes hit enemy positions rather than friendly forces. In DCS, JTAC units can mark targets with smoke and provide laser designation for guided munitions.

| Name | Type ID | Weapon | Notes |
|------|---------|--------|-------|
| Infantry AK-74 | `Soldier AK` | AK-74 | Russian rifleman |
| Infantry AK-74 Rus ver1 | `Infantry AK` | AK-74 | Russian variant 1 |
| Infantry AK-74 Rus ver2 | `Infantry AK ver2` | AK-74 | Russian variant 2 |
| Infantry AK-74 Rus ver3 | `Infantry AK ver3` | AK-74 | Russian variant 3 |
| Infantry M4 | `Soldier M4` | M4 Carbine | American rifleman |
| Infantry M4 Georgia | `Soldier M4 GRG` | M4 Carbine | Georgian soldier |
| Infantry M249 | `Soldier M249` | M249 SAW | Machine gunner |
| Infantry RPG | `Soldier RPG` | RPG-7 | Anti-tank |
| Paratrooper AKS | `Paratrooper AKS-74` | AKS-74 | Folding stock variant |
| Paratrooper RPG-16 | `Paratrooper RPG-16` | RPG-16 | Airborne anti-tank |
| JTAC | `JTAC` | Radio | Joint Terminal Attack Controller |
| Insurgent AKM | `Infantry AK Ins` | AKM | Insurgent fighter |

### WWII Infantry

World War II infantry were primarily armed with bolt-action rifles except for American forces, who were the only nation to fully equip their infantry with semi-automatic rifles. The M1 Garand gave American soldiers a significant rate-of-fire advantage in infantry combat, while German and British soldiers relied on accurate but slower bolt-action rifles supplemented by submachine guns and machine guns.

| Name | Type ID | Weapon | Country |
|------|---------|--------|---------|
| Infantry M1 Garand | `soldier_wwii_us` | M1 Garand | USA |
| Infantry SMLE No.4 | `soldier_wwii_br_01` | Lee-Enfield | UK |
| Infantry Mauser 98 | `soldier_mauser98` | Kar98k | Germany |

## Unarmed

Unarmed vehicles provide logistics, transport, and support functions essential for military operations. While not directly participating in combat, these vehicles represent high-value targets whose destruction can cripple enemy operations.

### Trucks and Transport

Military operations depend on a constant flow of supplies—ammunition, fuel, food, spare parts—delivered by truck convoys. The destruction of logistics vehicles can paralyze an army more effectively than destroying combat units. Modern armies consume enormous quantities of material, and interdicting supply lines has been a primary mission of tactical aviation since World War II.

**Ural-4320** (`Ural-375`) - The Ural-4320 is the standard Soviet and Russian 6x6 military truck, capable of carrying 5 tons of cargo across rough terrain. The Ural has served as the chassis for numerous weapon systems including the BM-21 Grad rocket launcher and ZU-23 anti-aircraft guns. Hundreds of thousands have been produced since 1961.

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| Truck Ural-4320 | `Ural-375` | USSR | Standard Soviet truck |
| Truck KAMAZ 43101 | `KAMAZ Truck` | USSR | Heavy truck |
| Truck ZIL-135 | `ZIL-135` | USSR | 8x8 heavy truck |
| Truck M939 Heavy | `M 818` | USA | 6x6 cargo truck |
| Truck M1083 MTV | `CHAP_M1083` | USA | Modern cargo truck |
| Truck Bedford | `Bedford_MWD` | UK | WWII British truck |
| Truck Opel Blitz | `Blitz_36-6700A` | Germany | WWII German truck |
| Truck Type 94 | `Type_94_Truck` | Japan | WWII Japanese truck |
| Truck GAZ-66 | `GAZ-66` | USSR | Soviet utility truck |
| Truck GAZ-66 civil | `gaz-66_civil` | USSR | Civilian version |
| Truck GAZ-3307 | `GAZ-3307` | USSR | Soviet truck |
| Truck GAZ-3308 | `GAZ-3308` | Russia | Modern truck |
| Truck KrAZ-6322 | `KrAZ6322` | Ukraine | Heavy 6x6 truck |
| Truck Ural-4320-31 | `Ural-4320-31` | Russia | Armored variant |
| Truck Ural-4320T | `Ural-4320T` | Russia | Tractor variant |
| Truck Ural civil | `ural_4230_civil_b` | USSR | Civilian box truck |
| Truck Ural civil T | `ural_4230_civil_t` | USSR | Civilian tractor |
| Truck KAMAZ civil | `kamaz_tent_civil` | USSR | Civilian truck |
| Truck ZIL-131 civil | `zil-131_civil` | USSR | Civilian truck |
| Truck ZIL-4331 | `ZIL-4331` | Russia | Modern truck |
| Truck MAZ-6303 | `MAZ-6303` | Belarus | Heavy truck |
| Truck GMC CCKW-353 | `CCKW_353` | USA | WWII 6x6 truck |

### Light Utility Vehicles

| Name | Type ID | Country | Notes |
|------|---------|---------|-------|
| LUV HMMWV Jeep | `Hummer` | USA | Unarmed Humvee |
| LUV UAZ-469 Jeep | `UAZ-469` | USSR | Soviet jeep |
| LUV Tigr | `Tigr_233036` | Russia | Modern Russian vehicle |
| LUV Land Rover 109 | `Land_Rover_109_S3` | UK | British utility |
| Car Willys Jeep | `Willys_MB` | USA | WWII jeep |
| LUV Kubelwagen | `Kubelwagen_82` | Germany | WWII German jeep |
| LUV Horch 901 | `Horch_901_typ_40_kfz_21` | Germany | WWII German staff car |
| LUV Kettenrad | `Sd_Kfz_2` | Germany | WWII motorcycle halftrack |
| LUV Land Rover 101 FC | `Land_Rover_101_FC` | UK | British forward control |
| Tractor Sd.Kfz.7 | `Sd_Kfz_7` | Germany | WWII artillery tractor |

### Civilian Vehicles

| Name | Type ID | Notes |
|------|---------|-------|
| Bus IKARUS-280 | `IKARUS Bus` | Hungarian articulated bus |
| Bus LAZ-695 | `LAZ Bus` | Soviet bus |
| Bus LiAZ-677 | `LiAZ Bus` | Soviet bus |
| Car VAZ-2109 | `VAZ Car` | Soviet Lada |
| ZIU-9 Trolley | `Trolley bus` | Soviet trolleybus |
| Suidae | `Suidae` | Pig (scenery animal) |

### Airfield Equipment

| Name | Type ID | Notes |
|------|---------|-------|
| GPU APA-5D | `Ural-4320 APA-5D` | Ground power unit |
| GPU APA-80 | `ZiL-131 APA-80` | Ground power unit |
| GD-20 Lift Truck | `GD-20` | Cargo loader |
| Firefighter HEMMT TFFT | `HEMTT TFFT` | Fire truck |
| Firefighter Ural ATsP-6 | `Ural ATsP-6` | Fire truck |
| Firefighter RAF Rescue | `tacr2a` | RAF crash tender |
| Firefighter AA-7.2/60 | `AA8` | Soviet fire truck |
| M92 B600 drivable | `B600_drivable` | Ground support |
| M92 MJ-1 drivable | `MJ-1_drivable` | Weapons loader |
| M92 P20 drivable | `P20_drivable` | Power unit |
| M92 R11 Volvo drivable | `r11_volvo_drivable` | Fuel truck |
| M92 Tug Harlan drivable | `TugHarlan_drivable` | Aircraft tug |

### Command and Control

| Name | Type ID | Notes |
|------|---------|-------|
| Truck SKP-11 Mobile ATC | `SKP-11` | Mobile air traffic control |
| Truck Ural-4320 MCC | `Ural-375 PBU` | Mobile command post |
| Truck ZIL-131 (C2) | `ZIL-131 KUNG` | Command vehicle |
| MCC Predator UAV CP | `Predator GCS` | UAV ground control station |
| MCC Predator UAV CL | `Predator TrojanSpirit` | UAV communications link |

### GPS and Navigation

| Name | Type ID | Notes |
|------|---------|-------|
| GPS Spoofer NATO | `GPS_Spoofer_Blue` | GPS jamming/spoofing |
| GPS Spoofer RF | `GPS_Spoofer_Red` | GPS jamming/spoofing |
| PRMG Glidepath | `prmg_gp_beacon` | ILS glidepath beacon |
| PRMG Localizer | `prmg_loc_beacon` | ILS localizer beacon |
| RSBN car | `rsbn_beacon` | Soviet navigation beacon |

## Fortification

Defensive structures and buildings:

| Name | Type ID | Notes |
|------|---------|-------|
| Bunker 1 | `Sandbox` | Infantry fighting position |
| Bunker 2 | `Bunker` | Reinforced bunker |
| Bunker with Fire Control | `fire_control` | Observation bunker |
| Outpost | `outpost` | Guard post with weapon |
| Road outpost | `outpost_road` | Road checkpoint |
| Road outpost-L | `outpost_road_l` | Road checkpoint (left) |
| Road outpost-R | `outpost_road_r` | Road checkpoint (right) |
| Barracks armed | `house1arm` | Building with weapons |
| Building armed | `houseA_arm` | Generic armed building |
| Watch tower armed | `house2arm` | Armed observation tower |
| Gun 15cm SK C/28 | `SK_C_28_naval_gun` | Naval gun in bunker |
| TACAN Beacon | `TACAN_beacon` | Portable navigation aid |

## Surface-to-Surface Missiles

### Ballistic and Cruise Missiles

| Name | Type ID | Range | Notes |
|------|---------|-------|-------|
| SSM SS-1C Scud-B | `Scud_B` | ~300km | Soviet tactical ballistic missile |
| SRBM 9K720 Iskander | `CHAP_9K720_HE` | ~500km | Modern Russian SRBM |
| SRBM 9K720 Iskander CM | `CHAP_9K720_Cluster` | ~500km | Cluster munition variant |
| V-1 Launch Ramp | `v1_launcher` | ~250km | WWII German cruise missile |

### Anti-Ship Missiles

| Name | Type ID | Notes |
|------|---------|-------|
| AShM SS-N-2 Silkworm | `hy_launcher` | Chinese HY-2 coastal defense |
| AShM Silkworm SR | `Silkworm_SR` | Search radar for Silkworm |

### Payload/Loadout Vehicles

These units represent missiles or payload stored for transport or loading:

| Name | Type ID | Notes |
|------|---------|-------|
| Payload PL-5EII | `PL5EII Loadout` | Chinese AAM payload |
| Payload PL-8 | `PL8 Loadout` | Chinese AAM payload |
| Payload SD-10 | `SD10 Loadout` | Chinese AAM payload |

## Trains

### Locomotives

| Name | Type ID | Notes |
|------|---------|-------|
| Loco CHME3T | `Locomotive` | Soviet diesel shunter |
| Loco DRG Class 86 | `DRG_Class_86` | WWII German steam |
| Loco ES44AH | `ES44AH` | Modern American diesel |
| Loco VL80 Electric | `Electric locomotive` | Soviet electric |

### Rolling Stock

| Name | Type ID | Notes |
|------|---------|-------|
| Passenger Car | `Coach a passenger` | Passenger coach |
| Freight Van | `Coach cargo` | Enclosed cargo |
| Open Wagon | `Coach cargo open` | Open-top cargo |
| Flatcar | `Boxcartrinity` | Flat railcar |
| Tank Car blue | `Coach a tank blue` | Fuel tanker |
| Tank Car yellow | `Coach a tank yellow` | Fuel tanker |
| Coach Platform | `Coach a platform` | Flat platform |
| Well Car | `Wellcarnsc` | Container car |
| DR 50-ton flat wagon | `DR_50Ton_Flat_Wagon` | Heavy flat wagon |
| Wagon G10 (Germany) | `German_covered_wagon_G10` | WWII German boxcar |
| Tank Car (Germany) | `German_tank_wagon` | WWII German tanker |
| Tank Cartrinity | `Tankcartrinity` | Modern tank car |

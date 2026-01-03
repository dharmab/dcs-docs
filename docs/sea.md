# Sea Units

This document describes the naval units available in DCS World, organized by vessel class. Each entry includes the DCS display name, type ID for mission files, operational role, and real-world background.

## Data Location

Ship definitions are located in `_G/db/Units/Ships/Ship/*.lua`. Each file defines a Lua table with fields including `DisplayName`, `type`, `tags`, `Categories`, physical dimensions, sensors, and weapon systems.

## Ship Classifications

Naval vessels are classified by size, armament, and intended role. These classifications evolved over centuries and continue to adapt as technology changes warfare at sea. While modern navies sometimes blur these distinctions, the traditional hierarchy provides useful context for understanding a fleet's composition and capabilities.

**Aircraft Carriers** are the largest surface combatants, designed to launch and recover fixed-wing aircraft. Fleet carriers (designated CV or CVN for nuclear-powered) operate catapult-launched aircraft and form the centerpiece of a carrier strike group, projecting power across vast distances. Light carriers and amphibious assault ships (LHA/LHD) are smaller vessels that operate helicopters and short takeoff/vertical landing (STOVL) aircraft like the Harrier. Carriers themselves carry minimal offensive armament, relying instead on their air wings and escorting warships for protection.

**Battlecruisers** occupy an unusual position between cruisers and the now-obsolete battleships. Only Russia operates battlecruisers today, with the Kirov-class vessels displacing over 25,000 tons and carrying massive anti-ship missile batteries alongside extensive air defense systems. These ships are designed to hunt carrier battle groups or lead surface action groups, combining the firepower of a battleship with cruiser-like speed.

**Cruisers** are large, multi-mission surface combatants ranging from 9,000 to 12,000 tons. In modern navies, cruisers primarily serve as air defense coordinators, using powerful radar systems and long-range surface-to-air missiles to protect carrier strike groups or lead independent task forces. American Ticonderoga-class cruisers with the Aegis Combat System exemplify this role. Russian cruisers like the Slava class emphasize anti-ship missiles for striking at enemy fleets.

**Destroyers** evolved from small torpedo boats designed to "destroy" enemy torpedo craft and now serve as the backbone of most surface fleets. Modern destroyers range from 6,000 to 10,000 tons and perform multiple roles including anti-air, anti-submarine, and anti-surface warfare. The distinction between cruisers and destroyers has blurred considerably, with large destroyers like the Arleigh Burke class rivaling cruisers in capability. Destroyers typically operate as escorts for carrier groups or in independent surface action groups.

**Frigates** are smaller than destroyers, typically 3,000 to 4,500 tons, and were traditionally specialized for convoy escort and anti-submarine warfare. The frigate prioritizes endurance and seakeeping over raw combat power, making them economical platforms for patrol, presence, and protection of merchant shipping. Modern frigates increasingly carry area air defense systems, narrowing the gap with destroyers. Many navies that cannot afford destroyer fleets rely on frigates as their primary surface combatants.

**Corvettes** are the smallest ocean-going warships, typically 500 to 3,000 tons, designed for coastal defense and littoral operations. Corvettes sacrifice range and seakeeping for reduced cost, allowing navies to maintain larger numbers of hulls for patrol and presence missions. Despite their size, corvettes can carry potent anti-ship missiles, making them dangerous opponents in confined waters. Russia's Tarantul-class corvettes, armed with supersonic Moskit missiles, exemplify how small platforms can threaten much larger vessels.

**Fast Attack Craft** (FAC) are small, high-speed vessels under 500 tons designed for hit-and-run attacks with missiles or torpedoes. These boats trade protection and endurance for speed and concentrated firepower, attacking from coastal waters and retreating before escorts can respond. Fast attack craft are particularly effective in archipelagic waters, straits, and littorals where their small size and shallow draft provide tactical advantages.

**Submarines** operate beneath the surface, providing stealth capabilities unmatched by surface ships. Nuclear-powered attack submarines (SSN) can remain submerged indefinitely, hunting enemy submarines and surface ships or launching cruise missiles. Conventional diesel-electric submarines (SSK) are quieter when running on batteries but must periodically surface or snorkel to recharge, limiting their endurance. Both types are extremely difficult to detect and track, making anti-submarine warfare one of the most challenging naval disciplines.

**Amphibious Warfare Ships** are specialized vessels that transport ground forces and their equipment for landing operations. Landing Platform Docks (LPD) carry troops, vehicles, and landing craft in a well deck. Landing Ships Tank (LST) can beach themselves to discharge vehicles directly onto shore. Amphibious assault ships combine helicopter flight decks with well decks to deliver Marines by both air and sea. These vessels form the core of naval expeditionary capability, allowing ground forces to strike from the sea.

## Aircraft Carriers

### United States Navy

**CVN-70 Carl Vinson** (`VINSON`)

Nimitz-class nuclear-powered supercarrier commissioned in 1982 as the third of ten Nimitz-class carriers. Named after Congressman Carl Vinson, who served in the House of Representatives for over 50 years and championed naval expansion. The 332-meter ship displaces approximately 100,000 tons and serves as the centerpiece of a carrier strike group, projecting air power globally. Armed with RIM-7 Sea Sparrow surface-to-air missiles and Phalanx CIWS for self-defense. The ship served in operations ranging from Desert Storm to Operation Enduring Freedom. In DCS, the Vinson provides catapult-assisted takeoff and arrested recovery (CATOBAR) operations with four steam catapults, four arresting wires, TACAN and ICLS navigation aids.

**CVN-71 Theodore Roosevelt** (`CVN_71`)

Nimitz-class nuclear-powered supercarrier commissioned in 1986. Named after President Theodore Roosevelt, who championed American naval power and as President sent the Great White Fleet around the world. Nicknamed "The Big Stick" after Roosevelt's famous foreign policy maxim, the ship saw extensive combat operations during Desert Storm, launching the opening strikes of Operation Desert Storm in 1991, and subsequent conflicts in the Middle East. As part of a carrier strike group, Theodore Roosevelt provides offensive power projection and sea control. Armed with RIM-7 Sea Sparrow and RIM-116 Rolling Airframe Missiles for air defense, plus Phalanx CIWS for close-in protection. Features four steam catapults and four arresting wires for CATOBAR operations.

**CVN-72 Abraham Lincoln** (`CVN_72`)

Nimitz-class nuclear-powered supercarrier commissioned in 1989, the first U.S. Navy ship named after President Abraham Lincoln. Lincoln participated in Operation Desert Storm and Operations Southern Watch and Enduring Freedom. The ship was notably where President George W. Bush delivered the "Mission Accomplished" speech in 2003. Serving as the centerpiece of Carrier Strike Group Nine, Lincoln provides the Navy's primary forward-deployed power projection capability. Armed with Sea Sparrow and RAM surface-to-air missiles plus Phalanx CIWS. The ship underwent refueling and complex overhaul (RCOH) from 2013 to 2017.

**CVN-73 George Washington** (`CVN_73`)

Nimitz-class nuclear-powered supercarrier commissioned in 1992. Named after the first U.S. President, George Washington served as the forward-deployed carrier in Yokosuka, Japan from 2008 to 2015, replacing USS Kitty Hawk. The ship provides power projection capabilities in support of U.S. treaty obligations in the Western Pacific and serves as the cornerstone of the Seventh Fleet's striking power. Armed with NATO Sea Sparrow, Rolling Airframe Missiles, and Phalanx CIWS for self-defense. Features four C-13-2 steam catapults and four arresting wires.

**CVN-74 John C. Stennis** (`Stennis`)

Nimitz-class nuclear-powered supercarrier commissioned in 1995, named after Senator John C. Stennis of Mississippi who served 41 years in the Senate and chaired the Armed Services Committee. Stennis has deployed extensively to the Western Pacific and Persian Gulf, participating in Operations Enduring Freedom and Iraqi Freedom. The ship serves as flagship of Carrier Strike Group Three, providing independent forward presence and deterrence. Armed with Sea Sparrow and RAM missiles plus Phalanx CIWS. In DCS, Stennis provides CATOBAR operations with four steam catapults, four arresting wires, and TACAN/ICLS navigation aids.

**CVN-75 Harry S. Truman** (`CVN_75`)

Nimitz-class nuclear-powered supercarrier commissioned in 1998, named after President Harry S. Truman who unified the armed forces under the Department of Defense. Truman has conducted combat operations supporting Operation Enduring Freedom and Operation Inherent Resolve against ISIS, launching thousands of strike sorties. The ship serves as flagship of Carrier Strike Group Eight, providing the Atlantic Fleet's primary power projection platform. Armed with Evolved Sea Sparrow Missiles, Rolling Airframe Missiles, and Phalanx CIWS. Features four steam catapults and four arresting wires for CATOBAR operations.

**CV-59 Forrestal** (`Forrestal`)

Lead ship of the Forrestal class, commissioned in 1955 as the first supercarrier designed from the keel up to operate jet aircraft. At 1,067 feet (325 meters), Forrestal introduced the angled flight deck, steam catapults, and enclosed hurricane bow that became standard on subsequent American carriers. The ship served as the template for all subsequent U.S. supercarriers and could operate 80-90 aircraft, serving as the centerpiece of Cold War carrier task forces. Armed with RIM-7 Sea Sparrow missiles and Phalanx CIWS in later refits. The ship is tragically remembered for the 1967 fire that killed 134 sailors, including future Senator John McCain who narrowly survived. Forrestal served until 1993 and was scrapped in 2015.

**LHA-1 Tarawa** (`LHA_Tarawa`)

Lead ship of the Tarawa-class amphibious assault ships, commissioned in 1976 and named for the Battle of Tarawa in World War II. At 834 feet, these ships combined the functions of several amphibious ship types into a single hull, carrying a Marine battalion landing team of 1,900 troops with helicopters, AV-8B Harrier STOVL aircraft, landing craft, and armored vehicles. Tarawa serves as the command ship for amphibious ready groups, providing vertical envelopment and surface assault capabilities. Armed with two RAM launchers, two Phalanx CIWS, and various machine guns for self-defense. Features a well deck for LCUs and LCACs plus a 820-foot flight deck. Tarawa was decommissioned in 2009 and sunk as a target during RIMPAC 2024. In DCS, supports STOVL and helicopter operations.

**Essex Class Carrier 1944** (`Essex`)

Essex-class carriers formed the backbone of the U.S. Navy's fast carrier task forces in the Pacific during World War II. Entering service from 1942, the Essex class would eventually number 24 ships, with fourteen seeing combat during the war, making it the most numerous class of heavy fleet carriers ever built. At 872 feet and 27,000 tons, these carriers could operate 90-100 aircraft including F6F Hellcats, F4U Corsairs, SB2C Helldivers, and TBF Avengers. The Essex class served as the primary striking arm of the Third and Fifth Fleets, destroying Japanese naval aviation at battles including the Philippine Sea and Leyte Gulf. Armed with twelve 5-inch/38 dual-purpose guns, numerous 40mm Bofors and 20mm Oerlikon anti-aircraft mounts. Many served into the jet age, some converted to anti-submarine warfare (CVS) or amphibious assault (LPH) roles.

### Russian Navy

**CV 1143.5 Admiral Kuznetsov** (`KUZNECOW`)

Russia's only operational aircraft carrier, designated an aircraft-carrying cruiser to permit transit of the Turkish Straits under the Montreux Convention. Commissioned in 1990 as the Soviet Union collapsed, Kuznetsov operates Su-33 and MiG-29K fighters using a 12-degree ski-jump ramp rather than catapults (STOBAR configuration). At 305 meters, the ship serves as flagship of the Northern Fleet and Russia's sole blue-water aviation platform. Unlike Western carriers focused purely on aviation, Kuznetsov carries significant offensive armament: 12 P-700 Granit supersonic anti-ship missiles in vertical launch tubes, 192 3K95 Kinzhal (SA-N-9 Gauntlet) SAMs, and 8 Kashtan CIWS combining 30mm guns with 9M311 missiles. The ship deployed to the Mediterranean during the Syrian Civil War in 2016-2017, losing two aircraft to deck accidents.

**CV 1143.5 Admiral Kuznetsov (2017)** (`CV_1143_5`)

Updated model of Admiral Kuznetsov representing the ship's 2017 configuration during its Syrian deployment. This variant reflects the configuration used during Operation Kuznetsov, when the carrier conducted combat operations against Syrian opposition forces. The air wing during this deployment consisted of Su-33 and MiG-29KR fighters conducting strikes from the Mediterranean. Weapons and sensors as per the standard Kuznetsov configuration.

### Royal Navy

**HMS Invincible (R05)** (`hms_invincible`)

Lead ship of the Invincible-class light aircraft carriers, commissioned in 1980. At 209 meters and 22,000 tons full load, these ships were originally designed as through-deck cruisers for anti-submarine warfare but were reclassified as aircraft carriers. Invincible gained fame during the 1982 Falklands War as flagship of the British Task Force, where her Sea Harrier FRS.1 fighters achieved air superiority over Argentine forces, destroying 20 enemy aircraft without loss in air combat. The ship served as the centerpiece of a carrier battle group, providing fleet air defense and ASW helicopter operations. Armed with Sea Dart GWS 30 twin-arm launcher (22 missiles) for area air defense and Phalanx CIWS. Features a 7-degree ski-jump ramp for STOVL operations. Decommissioned in 2005 and scrapped in 2011. In DCS, supports Sea Harrier and helicopter operations for the South Atlantic terrain.

### Argentine Navy

**ARA Veinticinco de Mayo** (`ara_vdm`)

Colossus-class light carrier originally commissioned as HMS Venerable in 1945, later sold to the Netherlands as HNLMS Karel Doorman in 1948, and finally purchased by Argentina in 1968. Named after Argentina's May Revolution of 25 May 1810. At 212 meters, the ship served as flagship of the Argentine fleet and operated A-4Q Skyhawks and S-2 Trackers. During the Falklands War, Veinticinco de Mayo posed a significant threat to the British Task Force but was unable to launch her aircraft on 2 May 1982 due to insufficient wind over the deck; the threat from British nuclear submarines, particularly after the sinking of ARA General Belgrano, forced her withdrawal to coastal waters. Armed with ten 40mm Bofors anti-aircraft guns. The carrier was fitted with a steam catapult and arresting wires. Decommissioned in 1997 and scrapped in 2000. Part of the South Atlantic assets.

**SS Atlantic Conveyor** (`atconveyor`)

British container ship requisitioned as a Merchant Navy auxiliary and converted to an aircraft transport during the Falklands War. Atlantic Conveyor was modified with a flight deck and carried critical aviation assets to the South Atlantic: six Wessex and five Chinook helicopters plus Harrier GR.3s to reinforce the carrier air groups. On May 25, 1982, while operating as an aircraft ferry and stores ship for the task force, the vessel was struck by two AM39 Exocet anti-ship missiles fired by Argentine Navy Super Etendards (originally targeting the carriers), killing 12 crew members including her master, Captain Ian North. The loss of the Chinooks except one that had been transferred earlier significantly complicated British logistics ashore, forcing troops to march ("yomp") across East Falkland. The ship was unarmed. Part of the South Atlantic assets.

## Battlecruisers

### Russian Navy

**Battlecruiser 1144.2 Pyotr Velikiy** (`PIOTR`)

Kirov-class (Project 1144.2 Orlan) nuclear-powered battlecruiser, the largest and heaviest surface combatant in the world aside from aircraft carriers. At 252 meters and 28,000 tons full load, Pyotr Velikiy was commissioned in 1998 and named after Peter the Great. The ship serves as flagship of the Northern Fleet, designed to operate independently or lead surface action groups hunting NATO carrier battle groups. The battlecruiser carries formidable armament: 20 P-700 Granit (SS-N-19 Shipwreck) supersonic anti-ship missiles capable of Mach 2.5, 96 S-300F Fort (SA-N-6 Grumble) long-range SAMs in vertical launchers, 128 3K95 Kinzhal (SA-N-9 Gauntlet) point-defense missiles, 6 Kashtan CIWS combining 30mm gatling guns with 9M311 missiles, twin AK-130 130mm dual-purpose guns, RBU-1000 anti-submarine rockets, and torpedo tubes. With a detection range of 250 km and threat range of 190 km, Pyotr Velikiy represents one of the most dangerous surface combatants in DCS.

## Cruisers

### United States Navy

**CG Ticonderoga** (`TICONDEROG`)

Lead ship of the Ticonderoga class, the first surface combatants equipped with the Aegis Combat System. Commissioned in 1983, these 173-meter, 9,800-ton cruisers provide fleet air defense with their AN/SPY-1 phased array radar and Standard Missile armament. Ticonderoga-class ships serve as the primary air defense coordinators for carrier strike groups, controlling the battlespace and directing fighter aircraft. The class carries 122 Mk 41 Vertical Launch System cells loaded with SM-2 Standard surface-to-air missiles for air defense, Tomahawk cruise missiles for land attack, and ASROC for anti-submarine warfare. Additional armament includes two 5-inch Mk 45 guns, two Phalanx CIWS, Harpoon anti-ship missiles, and torpedo tubes. In DCS, the class has a 150 km detection range and 100 km threat range.

### Russian Navy

**Cruiser 1164 Moskva** (`MOSCOW`)

Lead ship of the Slava class (Project 1164 Atlant), commissioned in 1983 as Slava and renamed Moskva in 1995. At 186 meters and 12,000 tons, these cruisers are instantly recognizable by the sixteen P-500 Bazalt (SS-N-12 Sandbox) or upgraded P-1000 Vulkan supersonic anti-ship missiles in massive angled twin-tube launchers along the hull. Designed to hunt NATO carrier battle groups, the Slava class serves as fleet flagships and surface action group leaders. Air defense comprises 64 S-300F Fort (SA-N-6 Grumble) long-range SAMs in eight revolving vertical launchers and 40 Osa-M (SA-N-4 Gecko) short-range SAMs. Close-in defense includes six AK-630 30mm CIWS. Gun armament consists of a twin AK-130 130mm dual-purpose mount. Moskva served as flagship of the Black Sea Fleet until April 2022, when the ship sank after an explosion, with Ukraine claiming a Neptune missile strike. In DCS, represents the pre-2022 configuration with a 160 km detection range and 75 km threat range.

## Destroyers

### United States Navy

**DDG Arleigh Burke IIa** (`USS_Arleigh_Burke_IIa`)

Flight IIA variant of the Arleigh Burke class, the backbone of the U.S. Navy's surface fleet. Entering service from 2000, Flight IIA ships measure 155 meters and 9,200 tons, adding helicopter hangars for two MH-60R Seahawks to enhance organic anti-submarine capability. These multi-mission destroyers serve in carrier strike groups providing air defense, operate independently for ballistic missile defense, and conduct surface warfare and strike missions. Armed with 96 Mk 41 VLS cells carrying SM-2 and SM-6 Standard missiles for air defense, Tomahawk cruise missiles for land attack, and ESSM for close-range air defense. Gun armament includes one 5-inch Mk 45 gun and two Phalanx CIWS. The AN/SPY-1D(V) Aegis Combat System provides integrated air and missile defense. In DCS, has a 150 km detection range and 100 km threat range.

### People's Liberation Army Navy

**Type 052B Destroyer** (`Type_052B`)

Chinese guided missile destroyer (Guangzhou class) entering service in 2004. At 154 meters and 5,850 tons, only two ships of this class were built as development platforms for subsequent indigenous designs. These destroyers serve as multi-role escorts for PLAN surface action groups. Armed with two single-arm launchers for 48 Russian-origin SA-N-12 Grizzly (9M317/Shtil) medium-range surface-to-air missiles, 16 YJ-83 (C-803) anti-ship missiles in quad launchers, one 100mm dual-purpose gun, two Type 730 CIWS, and anti-submarine torpedoes. The class features a stealthy hull design with reduced radar cross-section.

**Type 052C Destroyer** (`Type_052C`)

Chinese guided missile destroyer (Lanzhou class) known as the "Chinese Aegis" for its four-panel Type 348 active phased array radar similar in concept to the American SPY-1. Entering service from 2005, these 155-meter, 7,000-ton destroyers provide area air defense for PLAN carrier strike groups and surface action groups. Armed with 48 HQ-9 long-range surface-to-air missiles in cold-launch VLS cells (range exceeding 100 km), 8 YJ-62 (C-602) anti-ship cruise missiles, one 100mm dual-purpose gun, two Type 730 CIWS, and anti-submarine weapons. Six ships were built before production shifted to the improved Type 052D.

## Frigates

### United States Navy

**FFG Oliver Hazard Perry** (`PERRY`)

Lead ship of the numerous Oliver Hazard Perry class, the last operational U.S. Navy frigates. Entering service from 1977, 71 ships were built for the U.S. Navy and allied navies, making it one of the largest warship classes of the Cold War era. At 136 meters and 4,100 tons, these frigates were designed as affordable escorts for convoy and amphibious group protection, with particular emphasis on anti-submarine warfare. Armed with a single-arm Mk 13 launcher carrying 40 SM-1 Standard missiles and Harpoon anti-ship missiles, one 76mm OTO Melara gun, Phalanx CIWS, and two triple Mk 32 torpedo tubes for ASW. The class carried two SH-60 Seahawk helicopters for extended ASW reach. The U.S. Navy decommissioned its last Perry-class frigate in 2015, though many continue service with allied nations including Turkey, Egypt, Taiwan, and Poland.

### Russian Navy

**Frigate 11540 Neustrashimy** (`NEUSTRASH`)

Lead ship of the Neustrashimy-class (Project 11540 Yastreb), designed as anti-submarine frigates for the Soviet Navy. At 129 meters and 4,250 tons, only two ships were completed due to the Soviet collapse, with Neustrashimy commissioned in 1993. These frigates serve as escorts for the Baltic Fleet, specialized in ASW operations. Armed with 32 3K95 Kinzhal (SA-N-9 Gauntlet) SAMs in vertical launchers for point defense, 16 Kh-35 Uran (SS-N-25 Switchblade) anti-ship missiles, one 100mm gun, two Kashtan CIWS combining 30mm guns with 9M311 missiles, 533mm torpedo tubes, and RBU-6000 anti-submarine rockets. The class features the MGK-365 Zvezda-M1 sonar system for submarine detection and can operate one Ka-27 Helix helicopter.

**Frigate 1135M Rezky** (`REZKY`)

Krivak II-class frigate (Project 1135M Burevestnik), one of the workhorses of the Soviet Navy's anti-submarine forces. Entering service from 1970, at 123 meters and 3,200 tons, the Krivak class was designed to counter NATO submarines in the Atlantic approaches and Barents Sea. Armed with four SS-N-14 Silex anti-submarine missiles with nuclear or torpedo warheads, two twin 76mm guns, four 533mm torpedo tubes, and two RBU-6000 anti-submarine rocket launchers. Air defense comprises 40 4K33 Osa-M (SA-N-4 Gecko) short-range SAMs in a twin retractable launcher. The 1135M variant features enhanced sensors including the MGK-345 Bronza sonar. Many ships were transferred to the Border Guard as Nerei-class patrol vessels in the 1990s.

### People's Liberation Army Navy

**Type 054A Frigate** (`Type_054A`)

Chinese guided missile frigate (Jiangkai II class) entering service from 2008, with over 40 hulls built making it the most numerous modern frigate class in the world. At 134 meters and 4,050 tons, the Type 054A provides area air defense with 32 HQ-16 medium-range SAMs (derived from the Russian Shtil/Buk system, range 40+ km) in vertical launch cells. Also armed with 8 YJ-83 (C-803) anti-ship missiles, one 76mm gun, two Type 730 CIWS, and two triple torpedo tubes. These frigates form the backbone of the PLAN's escort forces, accompanying carrier strike groups and surface action groups. The class frequently deploys on anti-piracy patrols in the Gulf of Aden and shows the flag worldwide.

### Royal Navy

**HMS Achilles (F12)** (`leander-gun-achilles`)

Leander-class frigate commissioned in 1970, part of the final Batch 3 construction. At 113 meters and 2,860 tons, the Leander class was the most successful British frigate design of the Cold War, with 26 ships built for the Royal Navy. Named after the Greek hero Achilles, the ship served in the Royal Navy until 1990. These general-purpose frigates were designed for convoy escort, patrol, and anti-submarine duties. Armed with two 4.5-inch guns in a twin turret, Seacat short-range SAMs, torpedo tubes, and Limbo anti-submarine mortars. The class carried a Wasp or Lynx helicopter. Part of the South Atlantic assets representing the Falklands War era.

**HMS Andromeda (F57)** (`leander-gun-andromeda`)

Leander-class frigate commissioned in 1968, named after the constellation and mythological princess. Andromeda participated in the Falklands War as part of the British task force, providing escort and ASW duties in the Total Exclusion Zone. Armed with the standard Leander configuration of twin 4.5-inch guns, Seacat SAMs, and anti-submarine weapons. The ship was sold to India in 1995 as INS Krishna and served until 2012.

**HMS Ariadne (F72)** (`leander-gun-ariadne`)

Leander-class frigate commissioned in 1973, named after the mythological daughter of King Minos who helped Theseus escape the labyrinth. Ariadne served in the Falklands campaign as part of the task force providing escort duties. Armed with the standard Leander configuration. Decommissioned in 1992 and later sold to Chile.

### Chilean Navy

**CNS Almirante Condell (PFG-06)** (`leander-gun-condell`)

Former HMS Ariadne, purchased by Chile in 1992 and renamed after Carlos Condell, Chilean naval hero of the War of the Pacific who commanded the corvette Covadonga at the Battle of Punta Gruesa. The ship served as a patrol frigate in the Chilean Navy, conducting sovereignty patrols along Chile's extensive coastline. Retained the Leander-class armament of 4.5-inch guns, Seacat SAMs, and anti-submarine weapons. Retired in 2007 after 34 years of combined British and Chilean service.

**CNS Almirante Lynch (PFG-07)** (`leander-gun-lynch`)

Former HMS Achilles, purchased by Chile in 1990 and renamed after Patricio Lynch, a Chilean naval commander during the War of the Pacific who led the successful Expedition to Lima. The ship served alongside her sister Condell in the Chilean Navy's patrol and escort role. Armed with the standard Leander-class weapons fit. Decommissioned in 2003 after over 33 years of combined British and Chilean service.

## Corvettes and Patrol Vessels

### Russian Navy

**Corvette 1241.1 Molniya** (`MOLNIYA`)

Tarantul-class missile corvette (Project 1241.1 Molniya), a fast attack craft entering service from 1979. At 56 meters and 455 tons, these vessels are small but carry outsized firepower: four P-270 Moskit (SS-N-22 Sunburn) supersonic anti-ship missiles capable of Mach 3 and carrying 300kg warheads. Over 50 were built for the Soviet Navy and export customers including India, Poland, and Vietnam. The class serves in coastal defense and anti-surface strike roles, posing significant threats to larger warships in littoral waters. Additional armament includes one 76mm gun, Igla SAM launchers, and one AK-630 CIWS. The high speed of 42+ knots allows rapid attack runs and evasion.

**Corvette 1124M Grisha** (`ALBATROS`)

Grisha-class small anti-submarine ship (Project 1124 Albatros), entering service from 1970. At 72 meters and 1,200 tons, these corvettes were designed for coastal anti-submarine warfare in the Baltic, Black Sea, and Pacific approaches. The class serves as the primary ASW patrol vessel for Russian coastal waters. Armed with 20 4K33 Osa-M (SA-N-4 Gecko) SAMs in a twin retractable launcher, one 76mm gun, two twin 533mm torpedo tubes, two RBU-6000 anti-submarine rocket launchers, and depth charges. The 1124M variant (Grisha III) features an improved sonar suite with bow-mounted and dipping sonars. Over 60 were built for the Soviet Navy.

**Patrol Ship 22160 Vasily Bykov** (`CHAP_Project22160`)

Project 22160 patrol ship (Bykov class), a new class of Russian patrol vessels entering service from 2018. At 94 meters and 1,700 tons, the class was designed for patrol, presence, and constabulary missions with modular weapon and mission bays allowing adaptation to different roles. Named after Soviet Hero Vasily Bykov, these ships conduct sovereignty patrols in the Black Sea, Mediterranean, and Arctic. Armed with one 76mm gun, eight Kalibr cruise missile cells (optional modular installation), and Igla SAMs. Can embark one Ka-27 helicopter. Six ships are planned for Black Sea Fleet service.

**Patrol Ship 22160 with Tor M2KM** (`CHAP_Project22160_TorM2KM`)

Variant of the Project 22160 patrol ship fitted with a containerized Tor-M2KM short-range air defense system, demonstrating the modular weapons concept envisioned for this class. The Tor-M2KM provides 16 9M338 SAMs with 12 km range and simultaneous engagement of four targets, significantly enhancing self-defense capability against aircraft, cruise missiles, and precision-guided munitions. This configuration shows how the modular mission bay can rapidly transform a patrol vessel into an air defense platform.

### Royal Navy

**Castle Class** (`CastleClass_01`)

Castle-class offshore patrol vessel, commissioned in 1981 for the Royal Navy. At 81 meters and 1,450 tons, HMS Leeds Castle and HMS Dumbarton Castle were designed for fishery protection, oil rig patrol, and sovereignty duties around the British Isles, Falkland Islands, and overseas territories. During the Falklands War, both ships served in the Total Exclusion Zone. These lightly armed vessels were intended for constabulary rather than combat roles, armed with one 30mm gun and capable of embarking Royal Marines or carrying a Lynx helicopter on the flight deck. Both ships served until 2005 and 2007 respectively. Part of the South Atlantic assets.

## Fast Attack Craft

### French Navy / Export

**FAC La Combattante IIa** (`La_Combattante_II`)

La Combattante II-class fast attack craft, French-designed missile boats built by CMN Cherbourg and exported to numerous navies beginning in 1970. At 47 meters and 265 tons, these vessels serve as coastal defense platforms carrying significant anti-ship firepower. Armed with four MM38 or MM40 Exocet anti-ship missiles (40 km range), one 76mm OTO Melara gun, and two 40mm guns. The Hellenic Navy operates several La Combattante II and IIIa variants which have seen combat during the 1974 Cyprus crisis and Imia crisis. Exported to Greece, Iran, Libya, Malaysia, and other nations. Speed of 36+ knots allows hit-and-run tactics.

### People's Liberation Army Navy

**Type 021-1 Missile Boat** (`Type_021_1`)

Chinese-built missile boat (Huangfeng class) based on the Soviet Osa-class design, entering service from 1966. At 38 meters and 175 tons, these small craft provide coastal defense and anti-surface strike capability in Chinese littoral waters. Armed with four SY-1 (C-201/CSS-N-1 Silkworm) or later HY-2 (C-201/CSS-N-2 Safflower) anti-ship missiles with 40-95 km range depending on variant. Additional armament includes two twin 25mm guns. Over 100 were built for the PLAN and the class was widely exported to North Korea, Pakistan, Bangladesh, and other nations. Maximum speed exceeds 35 knots.

### German Navy (WWII)

**Schnellboot Type S130** (`Schnellboot_type_S130`)

German E-boat (Schnellboot) of World War II, fast torpedo boats that raided Allied convoys in the English Channel and North Sea. Entering service from 1943, the S130-class measured 35 meters and reached speeds over 42 knots on three Daimler-Benz diesel engines. These wooden-hulled boats served as the Kriegsmarine's primary offensive surface combatants in coastal waters, attacking convoys under cover of darkness. Armed with two 533mm torpedo tubes, mines, one 37mm or 40mm cannon, and various 20mm automatic weapons. The S130 type represents late-war production with enhanced anti-aircraft armament to counter increasing RAF patrols. E-boats sank numerous Allied vessels and remained a significant threat until war's end.

### Generic

**Boat Armed Hi-speed** (`speedboat`)

Generic armed speedboat representing small craft used by irregular forces, coast guards, smugglers, or naval patrol units. These fast open boats typically measure 8-12 meters and can exceed 40 knots. Armed with light weapons including machine guns and RPGs, suitable for harassment attacks, asymmetric swarming tactics, boarding operations, or maritime interdiction. In DCS, represents the type of fast attack craft employed by Iranian Revolutionary Guard Corps Navy, Somali pirates, and similar non-state or irregular naval forces.

## Submarines

### Russian Navy

**SSK 877V Kilo** (`KILO`)

Project 877 Paltus diesel-electric submarine (NATO: Kilo class), entering service from 1980. At 74 meters and 3,100 tons submerged, the Kilo is known for extremely quiet operation when running on electric motors, earning the nickname "black hole" from U.S. intelligence for its low acoustic signature. The class serves as Russia's primary conventional submarine for anti-submarine and anti-surface warfare in littoral waters and chokepoints. Armed with six 533mm torpedo tubes carrying 18 torpedoes or 24 mines, with capability to launch 3M-54 Klub (SS-N-27 Sizzler) cruise missiles from torpedo tubes. Maximum depth is 300 meters with 45-day endurance. Widely exported to India, China, Iran, Algeria, Vietnam, and other nations, with over 50 built.

**SSK 636 Improved Kilo** (`IMPROVED_KILO`)

Project 636 Varshavyanka (Improved Kilo), an advanced version of the Kilo class entering service from 1997. At 74 meters and 3,950 tons submerged, this variant features significantly reduced noise levels through improved propulsion isolation, extended range of 7,500 nm at 7 knots, and enhanced combat systems. The class serves as Russia's frontline conventional attack submarine. Armed with six 533mm torpedo tubes for torpedoes, mines, or 3M-54 Kalibr (SS-N-27 Sizzler) cruise missiles providing land-attack and anti-ship strike capability to 1,500+ km. The improved Kilo remains in production for Russia and export customers including China, Vietnam, and Algeria. Project 636.3 boats of the Black Sea Fleet conducted the first combat cruise missile strikes from submarines in the Syrian conflict.

**SSK 641B Tango** (`SOM`)

Project 641B Som diesel-electric submarine (NATO: Tango class), entering service from 1973. At 91 meters and 3,900 tons submerged, these were the largest conventional submarines built by the Soviet Union, designed for extended ocean patrols tracking NATO carrier battle groups in the Atlantic and Mediterranean. The class served as the Soviet Navy's primary conventional attack submarine before the Kilo class. Armed with six 533mm torpedo tubes carrying 24 torpedoes with capability for both anti-submarine and anti-surface warfare. Maximum depth is 300 meters with 90-day endurance. Eighteen were built, all retired from Russian service by 1998.

### People's Liberation Army Navy

**Type 093 Attack Submarine** (`Type_093`)

Chinese nuclear-powered attack submarine (SSN, Shang class), entering service from 2006. At approximately 107 meters and 7,000 tons submerged, the Type 093 represents China's second-generation nuclear attack submarine and a significant improvement over the earlier Han class. The class serves multiple roles: protecting Type 094 ballistic missile submarines (SSBNs), attacking enemy surface ships and submarines, intelligence gathering, and potentially launching cruise missiles. Armed with six 533mm torpedo tubes for Yu-6 torpedoes and YJ-18 anti-ship cruise missiles. Later Type 093A/B variants feature improved quieting and enhanced weapons. Six to eight boats are believed to be in service or under construction, forming the backbone of the PLAN's nuclear attack submarine force.

### German Navy (WWII)

**U-boat VIIC U-flak** (`Uboat_VIIC`)

Type VIIC U-boat, the most common German submarine of World War II with over 568 built from 1940-1945. At 67 meters and 871 tons submerged, the Type VIIC formed the backbone of the Kriegsmarine's submarine campaign against Allied shipping in the Battle of the Atlantic. Armed with five 533mm torpedo tubes (four bow, one stern) carrying 14 torpedoes, one 88mm deck gun, and anti-aircraft weapons. The "U-flak" designation indicates enhanced anti-aircraft armament (quadruple 20mm and 37mm cannon) added to counter increasing RAF Coastal Command patrol aircraft in the Bay of Biscay transit routes. Type VIIC boats sank millions of tons of Allied shipping but suffered heavy losses, particularly after Allied adoption of improved sonar, radar, and hunter-killer groups.

### Argentine Navy

**ARA Santa Fe (S-21)** (`santafe`)

Former USS Catfish (SS-339), a Balao-class submarine commissioned in 1945 and transferred to Argentina in 1971. At 95 meters and 2,415 tons submerged, the Balao class was the primary American fleet submarine of late World War II. During the Falklands War, Santa Fe was tasked with reinforcing Argentine forces on South Georgia, landing troops and supplies. On April 25, 1982, while surfaced near Grytviken, the submarine was attacked by Royal Navy Wessex and Lynx helicopters firing AS.12 missiles and depth charges. Disabled and unable to dive, Santa Fe was beached and her crew captured, providing the British with their first significant victory of the campaign. Armed with ten 533mm torpedo tubes. Part of the South Atlantic assets.

## Amphibious Warfare Ships

### Russian Navy

**LS Ropucha** (`BDK-775`)

Ropucha-class large landing ship (Project 775), entering service from 1975. At 113 meters and 4,080 tons full load, these ships were designed to deliver tanks, armored vehicles, and troops directly onto beaches in amphibious assault operations. Capable of carrying 10 main battle tanks and 340 troops or 24 APCs with 170 troops, the Ropucha class can beach itself and open bow doors to allow vehicles to drive directly ashore. Over 28 were built for the Soviet Navy, and the class remains active in the Russian Navy's Black Sea, Baltic, and Northern Fleets for amphibious assault and logistics missions. Armed with two 57mm guns, two AK-630 CIWS, and Strela-3 SAM launchers. Several ships of this class participated in the 2022 invasion of Ukraine; Saratov was destroyed in Berdyansk and Caesar Kunikov was sunk by naval drones.

### People's Liberation Army Navy

**Type 071 Amphibious Transport Dock** (`Type_071`)

Chinese amphibious transport dock (LPD, Yuzhao class), entering service from 2007. At 210 meters and 25,000 tons full load, these are among the largest amphibious warships outside the U.S. Navy. The Type 071 serves as the command ship for PLAN amphibious ready groups, designed to project power across the Taiwan Strait and into the South China Sea. Capable of transporting up to 800 troops, armored vehicles, and four LCAC-type air-cushion landing craft in a well deck. The flight deck accommodates four Z-8 or Z-18 helicopters. Armed with one 76mm gun, four Type 630 CIWS, and HQ-10 SAM launchers. Eight ships serve with the PLAN, forming the core of China's amphibious assault capability alongside the newer Type 075 LHD.

### United States Navy (WWII)

**LST Mk.II** (`LST_Mk2`)

Landing Ship, Tank (LST) of World War II, entering service from 1942. At 100 meters and 4,000 tons loaded, the LST was designed to land tanks and heavy vehicles directly on beaches during amphibious assaults without requiring port facilities. LSTs could beach themselves on a 1:50 gradient, open bow doors, lower a ramp, and discharge 20 Sherman tanks or 2,100 tons of cargo directly onto the beach. Over 1,051 were built by U.S. shipyards, supporting every major Allied amphibious operation from Sicily and Normandy to Iwo Jima and Okinawa. Armed with multiple 40mm Bofors and 20mm Oerlikon anti-aircraft guns. The LST was essential for the "ship-to-shore" logistics that sustained amphibious campaigns. Many surplus LSTs served with Allied navies for decades postwar.

**LS Samuel Chase** (`USS_Samuel_Chase`)

USS Samuel Chase (APA-26), a Bayfield-class attack transport (APA) commissioned in 1942. At 150 meters and 16,000 tons full load, attack transports were designed to carry assault troops and their landing craft to amphibious objectives. Named after Samuel Chase, a signer of the Declaration of Independence, the ship participated in the North African landings, Sicily, Salerno, and Normandy invasions. Attack transports carried approximately 1,500 troops and lowered up to 30 LCVPs for the initial assault waves. Armed with one 5-inch gun, four 3-inch guns, and numerous 40mm and 20mm anti-aircraft weapons. The APA concept—combining transport, boat davits, and combat loading—was essential to the U.S. Navy's amphibious doctrine. Chase was decommissioned in 1946.

### Generic (WWII)

**Boat LCVP Higgins** (`Higgins_boat`)

Landing Craft, Vehicle, Personnel (LCVP), the iconic Higgins boat that carried troops ashore during World War II amphibious landings. Designed by Andrew Higgins in New Orleans, these 11-meter plywood boats with a distinctive bow ramp could carry 36 troops, a jeep with 12 men, or 3,600 pounds of cargo and land directly on beaches. The bow ramp dropped forward to allow rapid disembarkation under fire. Over 23,000 were built, with the Higgins boat becoming the primary first-wave assault craft for the U.S. Navy, used at every major landing from North Africa to Okinawa. Armed with two .30 caliber machine guns. General Eisenhower credited Higgins as "the man who won the war for us," as the LCVP solved the fundamental problem of ship-to-shore assault against defended beaches.

## Civilian and Support Vessels

### Tankers

**Tanker Seawise Giant** (`Seawise_Giant`)

The largest ship ever built, originally launched as Seawise Giant in 1979 at 458 meters long with a deadweight of 564,763 tonnes—so large she could not transit the English Channel, Suez Canal, or Panama Canal fully loaded. The ultra-large crude carrier (ULCC) represented the peak of supertanker development, designed to transport crude oil economically between the Persian Gulf and consuming nations. During the Iran-Iraq War "Tanker War" phase, while anchored off Iran's Larak Island loaded with crude oil, the ship was struck by Iraqi bombs in 1988, causing fires that spread to leaked oil and blazed out of control. Though declared a total loss, the ship did not sink and was later salvaged and rebuilt as Happy Giant, then Jahre Viking, and finally Knock Nevis, serving as a floating storage unit. Scrapped in 2010. In DCS, serves as a large civilian target or scenario element representing strategic petroleum infrastructure.

**Tanker Elnya 160** (`ELNYA`)

Soviet Type 160 coastal tanker, a common design built from the 1970s and used throughout the USSR and successor states. At approximately 100 meters and 4,000 deadweight tons, these medium-sized tankers transport refined petroleum products, fuel oil, and diesel along coastal shipping routes, between ports, and to naval anchorages for fleet resupply. The Type 160 represents typical Soviet merchant fleet construction, with simple and rugged design emphasizing reliability over efficiency. In DCS, serves as civilian maritime traffic or logistics target representing coastal petroleum distribution.

### Cargo Ships

**Bulker Yakushev** (`Dry-cargo ship-1`)

Soviet-style dry cargo vessel representing common bulk carriers operating in coastal and international trade. At approximately 140 meters and 10,000 deadweight tons, this general cargo/bulk carrier transports grain, coal, ore, fertilizer, and other bulk commodities between major ports. The design reflects typical Soviet merchant fleet construction of the 1970s-1980s, with multiple cargo holds served by deck cranes. In DCS, represents commercial shipping traffic or potential targets in maritime strike scenarios.

**Cargo Ivanov** (`Dry-cargo ship-2`)

Soviet-era general cargo ship, a smaller coaster used for coastal trade and supplying remote ports inaccessible to larger vessels. At approximately 80 meters and 2,000 deadweight tons, these ships carry general cargo, containerized goods, and break-bulk freight to secondary ports throughout the Soviet coastal network from the Baltic to the Pacific. In DCS, represents coastal shipping traffic or resupply vessels for isolated garrisons and naval facilities.

**Bulker Handy Wind** (`HandyWind`)

Handysize bulk carrier, a common class of modern commercial vessel sized (under 35,000 DWT) to enter most ports worldwide without draft restrictions. At approximately 180 meters and 28,000 deadweight tons, Handysize bulkers are the workhorses of global dry bulk trade, carrying grain, coal, ore, cement, and steel between regional ports. Equipped with deck cranes allowing cargo operations at ports lacking shore facilities. In DCS, represents modern commercial shipping operating in or transiting conflict zones, potentially subject to maritime interdiction, inspection, or collateral risk.

**Supply Ship MV Tilde** (`Ship_Tilde_Supply`)

Commercial offshore supply vessel (OSV), representing the type of platform support vessel used for offshore oil and gas logistics and resupply missions. At approximately 70 meters, these vessels transport drilling supplies, pipes, chemicals, and provisions to offshore rigs and platforms. During the Falklands War, similar vessels were requisitioned as "ships taken up from trade" (STUFT) to support the British Task Force. In DCS, represents civilian maritime support operations or potential auxiliary vessels in amphibious scenarios. Part of the South Atlantic assets.

### Support Craft

**Harbor Tug** (`HarborTug`)

Small harbor tug boat, typically 20-30 meters with powerful engines for its size, used for maneuvering larger vessels in confined harbor waters, assisting with docking operations, and providing emergency towing. Harbor tugs are essential port infrastructure, pushing and pulling cargo ships, tankers, and warships that cannot maneuver safely in restricted waters under their own power. In DCS, represents port operations and maritime infrastructure. Part of the South Atlantic assets.

**Boat Zvezdny type** (`ZWEZDNY`)

Soviet-designed Zvezdny-class small patrol or utility boat, a versatile craft approximately 26 meters in length used for harbor patrol, coastal transport, personnel transfer, and port security duties. These boats served throughout the Soviet naval establishment and civilian maritime organizations, providing local transport and patrol capability at naval bases and commercial ports. Armed lightly if at all, with capacity for small arms. In DCS, represents miscellaneous small craft for harbor and coastal scenarios.


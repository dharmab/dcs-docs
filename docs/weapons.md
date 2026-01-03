# DCS World Weapons

This document provides comprehensive information about weapons in DCS World, including air-to-air missiles, air-to-ground missiles, guided and unguided bombs, and rockets.

## Table of Contents

- [Overview](#overview)
- [Data Locations](#data-locations)
- [Air-to-Air Missiles](#air-to-air-missiles)
  - [AIM-9 Sidewinder Family](#aim-9-sidewinder-family)
  - [AIM-7 Sparrow Family](#aim-7-sparrow-family)
  - [AIM-120 AMRAAM](#aim-120-amraam)
  - [AIM-54 Phoenix](#aim-54-phoenix)
  - [R-73 (AA-11 Archer)](#r-73-aa-11-archer)
  - [R-27 Family](#r-27-family)
  - [R-77 (AA-12 Adder)](#r-77-aa-12-adder)
  - [R-60 (AA-8 Aphid)](#r-60-aa-8-aphid)
  - [Other Western AAMs](#other-western-aams)
  - [Other Eastern Bloc AAMs](#other-eastern-bloc-aams)
- [Air-to-Ground Missiles](#air-to-ground-missiles)
  - [AGM-65 Maverick Family](#agm-65-maverick-family)
  - [Anti-Radiation Missiles](#anti-radiation-missiles)
  - [Anti-Ship Missiles](#anti-ship-missiles)
  - [Stand-Off Weapons](#stand-off-weapons)
  - [Soviet/Russian AGMs](#sovietrussian-agms)
  - [Helicopter-Launched Weapons](#helicopter-launched-weapons)
- [Guided Bombs](#guided-bombs)
  - [Paveway Laser-Guided Bombs](#paveway-laser-guided-bombs)
  - [JDAM Family](#jdam-family)
  - [GBU-39 Small Diameter Bomb](#gbu-39-small-diameter-bomb)
  - [Electro-Optical Guided Bombs](#electro-optical-guided-bombs)
  - [Soviet/Russian Guided Bombs](#sovietrussian-guided-bombs)
- [Unguided Bombs](#unguided-bombs)
  - [Mk-80 Series](#mk-80-series)
  - [Soviet/Russian FAB Series](#sovietrussian-fab-series)
  - [Cluster Munitions](#cluster-munitions)
  - [Penetrators](#penetrators)
  - [WWII Ordnance](#wwii-ordnance)
- [Unguided Rockets](#unguided-rockets)
  - [Hydra 70 Family](#hydra-70-family)
  - [Zuni](#zuni)
  - [S-Series Rockets](#s-series-rockets)
- [Technical Reference](#technical-reference)
  - [Guidance Types](#guidance-types)
  - [Seeker Generations](#seeker-generations)

## Overview

DCS World models hundreds of weapons across several categories. The datamine contains detailed specifications for each weapon including range, speed, guidance characteristics, and warhead data. This documentation organizes weapons by type and provides both historical context and technical specifications.

## Data Locations

| Category | Location | Description |
|----------|----------|-------------|
| Missiles | `_G/rockets/*.lua` | Air-to-air and air-to-ground missiles |
| Bombs | `_G/bombs/*.lua` | Guided and unguided bombs |
| Warheads | `_G/warheads/*.lua` | Warhead specifications |
| Unguided Rockets | `_G/weapons_table/weapons/nurs/*.lua` | Unguided rocket pods |

## Air-to-Air Missiles

### AIM-9 Sidewinder Family

The AIM-9 Sidewinder entered service in 1956 as the world's first successful infrared-guided air-to-air missile. Its simplicity, reliability, and effectiveness made it history's most widely produced guided missile, with over 110,000 built across dozens of variants. The basic design—an infrared seeker in the nose, a fragmentation warhead, a solid rocket motor, and canard control surfaces—has remained fundamentally unchanged for seven decades while the internal components have been continuously upgraded.

Early Sidewinders like the AIM-9B used uncooled lead sulfide seekers that could only track high-contrast heat sources from directly behind the target aircraft. The seeker had to be pointed almost directly at the engine exhaust, limiting engagement geometry severely. These missiles also struggled with countermeasures—simple flares could deceive the primitive seeker. Combat experience in Vietnam revealed these limitations when AIM-9Bs achieved kill rates well below 20%.

The AIM-9L, introduced in 1977, represented a generational leap. Its cooled indium antimonide seeker could detect the aerodynamic heating of an aircraft's skin, enabling all-aspect engagements including head-on shots. The AIM-9L achieved spectacular success in the 1982 Falklands War, where British Harriers scored 16 kills with 17 missiles fired. The AIM-9M improved flare rejection through better signal processing, while the AIM-9X incorporated imaging infrared technology and thrust vectoring for extreme off-boresight capability.

| Variant | Display Name | Range (m) | Speed (Mach) | Seeker Gen | Cooled | Warhead (kg) |
|---------|--------------|-----------|--------------|------------|--------|--------------|
| AIM-9E | AIM-9E | 14,000 | 2.5 | 2 | Yes | 11.0 |
| AIM-9J | AIM-9J | 14,000 | 2.5 | 2 | Yes | 11.0 |
| AIM-9JULI | AIM-9JULI | 14,000 | 2.5 | 3 | Yes | 11.0 |
| AIM-9L | AIM-9L | 14,000 | 2.7 | 3 | Yes | 11.0 |
| AIM-9M | AIM-9M | 14,000 | 2.7 | 3 | Yes | 9.4 |
| AIM-9P | AIM-9P | 11,000 | 2.2 | 2 | Yes | 11.0 |
| AIM-9P-3 | AIM-9P-3 | 11,000 | 2.2 | 2 | Yes | 11.0 |
| AIM-9P-5 | AIM-9P-5 | 11,000 | 2.2 | 3 | Yes | 11.0 |
| AIM-9X | AIM-9X | 14,000 | 2.7 | 4 | Yes | 9.4 |

### AIM-7 Sparrow Family

The AIM-7 Sparrow began development in 1946 as one of the first radar-guided air-to-air missiles. Unlike infrared missiles that passively track heat, the Sparrow uses semi-active radar homing (SARH)—the launching aircraft's radar illuminates the target, and the missile homes on the reflected energy. This guidance method provides longer range and all-aspect capability but requires the launching aircraft to maintain radar lock throughout the missile's flight, making evasive maneuvering dangerous.

Vietnam War performance disappointed planners who expected radar missiles to dominate beyond visual range. AIM-7E kill rates hovered around 10%, victims of unreliable electronics, restrictive rules of engagement requiring visual identification, and the challenges of distinguishing friend from foe. Many pilots reverted to Sidewinders and guns. The AIM-7F introduced solid-state electronics and a larger warhead, improving reliability substantially. The AIM-7M added look-down/shoot-down capability against targets below the horizon, a crucial advancement for engaging low-flying attackers.

The Sparrow saw extensive combat service in the Gulf War, where improved variants achieved significantly better kill rates. AIM-7s accounted for most of the coalition's air-to-air victories, validating decades of refinement. The missile remained in U.S. service until replaced by the AIM-120 AMRAAM, though export variants continue with several air forces.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance | Warhead (kg) |
|---------|--------------|-----------|--------------|----------|--------------|
| AIM-7E | AIM-7E | 50,000 | 3.2 | SARH | 29.5 |
| AIM-7E-2 | AIM-7E-2 (Dogfight Sparrow) | 50,000 | 3.2 | SARH | 29.5 |
| AIM-7F | AIM-7F | 50,000 | 3.2 | SARH | 39.0 |
| AIM-7M | AIM-7M | 50,000 | 3.2 | SARH | 39.0 |
| AIM-7MH | AIM-7MH | 50,000 | 3.2 | SARH | 39.0 |
| AIM-7P | AIM-7P | 50,000 | 3.2 | SARH | 39.0 |

### AIM-120 AMRAAM

The AIM-120 Advanced Medium-Range Air-to-Air Missile represented a fundamental shift in air combat when it entered service in 1991. Unlike the semi-active Sparrow, the AMRAAM uses active radar homing—the missile carries its own radar transmitter and can guide itself to the target without continuous support from the launching aircraft. This "fire and forget" capability allows the pilot to break lock and maneuver defensively after launch, dramatically improving survivability in multiple-target engagements.

Development began in 1975 as a joint Air Force and Navy program to replace both the Sparrow and the Navy's AIM-54 Phoenix. The resulting missile combines medium range with compact dimensions, allowing fighters to carry more missiles than the bulky Sparrow. The AIM-120A proved its capabilities in December 1992 when a USAF F-16 shot down an Iraqi MiG-25 over the southern no-fly zone—the first AMRAAM combat kill.

The AIM-120C introduced clipped fins for internal carriage in the F-22's weapons bays, while later variants extended range and improved electronic counter-countermeasures. The missile has been exported to numerous NATO allies and partner nations, becoming the de facto standard Western BVR missile.

| Variant | Display Name | Range (m) | Speed (Mach) | Seeker Gen | Warhead (kg) |
|---------|--------------|-----------|--------------|------------|--------------|
| AIM-120B | AIM-120B AMRAAM | 57,000 | 4.0 | 4 | 18.7 |
| AIM-120C | AIM-120C AMRAAM | 61,000 | 4.0 | 4 | 18.7 |

### AIM-54 Phoenix

The AIM-54 Phoenix was designed specifically for the F-14 Tomcat's fleet defense mission. No other missile in history matched its combination of range, speed, and the ability to engage multiple targets simultaneously. The AWG-9 radar and Phoenix system could track 24 targets and guide missiles to six of them at once, allowing a single F-14 to defend the carrier against massed Soviet bomber attacks.

The Phoenix used a two-stage guidance approach: inertial navigation with radar command updates during the long cruise phase, transitioning to active radar homing for terminal guidance. This allowed engagements at ranges exceeding 100 nautical miles—distances where the target would be below the radar horizon for a launch aircraft at typical combat altitudes. The missile's massive size (over 13 feet long and nearly 1,000 pounds) limited the Tomcat to six rounds maximum.

Despite its impressive specifications, the Phoenix saw limited combat use. U.S. Navy Tomcats never fired one in anger. Iranian F-14s employed Phoenix missiles against Iraqi aircraft during the Iran-Iraq War, claiming numerous kills, though exact figures remain disputed. The missile was retired with the F-14 in 2006.

| Variant | Display Name | Range (m) | Speed (Mach) | Warhead (kg) |
|---------|--------------|-----------|--------------|--------------|
| AIM-54A Mk.47 | AIM-54A Mk.47 Phoenix | 180,000 | 4.0 | 60.75 |
| AIM-54A Mk.60 | AIM-54A Mk.60 Phoenix | 180,000 | 4.0 | 60.75 |
| AIM-54C Mk.47 | AIM-54C Mk.47 Phoenix | 180,000 | 4.0 | 60.75 |
| AIM-54C | AIM-54C Phoenix | 140,000 | 4.5 | 60.75 |

### R-73 (AA-11 Archer)

The R-73 stunned Western intelligence when its capabilities became known after German reunification. Soviet pilots had been practicing helmet-mounted sight engagements for years, allowing off-boresight shots at targets up to 45 degrees off the nose—a capability NATO fighters wouldn't match until the AIM-9X entered service over a decade later. The missile's thrust-vectoring control surfaces provided exceptional maneuverability in the terminal phase.

Designed to replace the R-60, the R-73 entered service in 1984 with fourth-generation Soviet fighters. Its cooled infrared seeker could acquire targets in any aspect, while the Shchel-3UM helmet-mounted sight allowed the pilot to lock targets simply by looking at them. This combination gave Soviet fighters a decisive advantage in close-range combat, driving NATO to accelerate high off-boresight missile programs.

The R-73 has been widely exported and remains in production. It has seen combat service in numerous conflicts, including extensive use by both sides in the ongoing war in Ukraine.

| Variant | Display Name | Range (m) | Speed (Mach) | Seeker Gen | Cooled | Warhead |
|---------|--------------|-----------|--------------|------------|--------|---------|
| R-73 | R-73 (AA-11 Archer) | 12,000 | 2.8 | 3 | Yes | 7.4 kg |

### R-27 Family

The R-27 (NATO reporting name AA-10 "Alamo") serves as the primary medium-range missile for MiG-29 and Su-27 family aircraft. Unlike Western practice where different missiles handle infrared and radar guidance, the R-27 uses a modular design with interchangeable seeker heads. The R-27R uses semi-active radar homing while the R-27T uses infrared guidance, sharing common airframe and propulsion components.

Extended-range variants (R-27ER and R-27ET) use larger rocket motors for engagements out to approximately 80 km. The R-27 family saw combat during the Ethiopian-Eritrean War and has been employed in various other conflicts. While capable, the R-27's semi-active radar guidance requires the launching aircraft to maintain lock—a significant tactical limitation compared to active radar missiles like the R-77.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance | Warhead |
|---------|--------------|-----------|--------------|----------|---------|
| R-27R | R-27R (AA-10 Alamo-A) | 35,000 | 4.5 | SARH | 15.6 kg |
| R-27ER | R-27ER (AA-10 Alamo-C) | 60,000 | 4.0 | SARH | 15.6 kg |
| R-27T | R-27T (AA-10 Alamo-B) | 25,000 | 3.2 | IR | 15.6 kg |
| R-27ET | R-27ET (AA-10 Alamo-D) | 54,000 | 4.0 | IR | 15.6 kg |

### R-77 (AA-12 Adder)

The R-77 represents Russia's answer to the AIM-120 AMRAAM. Featuring active radar homing and distinctive lattice-fin control surfaces, the R-77 provides fire-and-forget capability for Russian fighters. The unusual grid fins fold flat for carriage and deploy after launch, providing exceptional control authority at the cost of increased drag compared to conventional fins.

Development began in the 1980s to counter the AMRAAM threat. The R-77 entered service in the 1990s but availability was limited due to post-Soviet economic difficulties. More advanced variants with improved seekers and extended range have been developed, though export versions may have reduced capabilities.

| Variant | Display Name | Range (m) | Speed (Mach) | Seeker Gen | Warhead |
|---------|--------------|-----------|--------------|------------|---------|
| R-77 | R-77 (AA-12 Adder) | 50,000 | 4.0 | 4 | 22 kg |

### R-60 (AA-8 Aphid)

The R-60 was designed as a lightweight, highly maneuverable short-range missile for close combat. At only 43 kg, it was among the lightest AAMs ever deployed, allowing fighters to carry large quantities. MiG-23s could carry six R-60s in addition to medium-range R-23s, providing substantial close-range firepower.

The small size came at the cost of a tiny 3.5 kg warhead, limiting effectiveness against larger aircraft. The uncooled seeker also restricted engagement geometry to rear-hemisphere shots. The R-60M variant improved seeker sensitivity somewhat but remained limited compared to Western all-aspect missiles like the AIM-9L.

| Variant | Display Name | Range (m) | Speed (Mach) | Seeker Gen | Warhead |
|---------|--------------|-----------|--------------|------------|---------|
| R-60 | R-60 (AA-8 Aphid) | 8,000 | 2.7 | 2 | 3.5 kg |
| R-60M | R-60M (AA-8 Aphid-B) | 8,000 | 2.7 | 2 | 3.5 kg |

### Other Western AAMs

#### MICA (France)

The MICA (Missile d'Interception, de Combat et d'Autodéfense) is France's dual-role missile, available in both infrared (MICA IR) and active radar (MICA EM) variants. Like the R-27 family, both variants share common airframe components, simplifying logistics.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance |
|---------|--------------|-----------|--------------|----------|
| MICA IR | MICA IR | 60,000 | 4 | IR |
| MICA EM | MICA EM | 60,000 | 4 | Active Radar |

#### Super 530 (France)

The Super 530 was France's primary beyond-visual-range missile before the MICA. Using semi-active radar homing, it served on Mirage 2000 and Mirage F1 aircraft.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance |
|---------|--------------|-----------|--------------|----------|
| Super 530D | Super 530D | 40,000 | 4.6 | SARH |
| Super 530F | Super 530F | 35,000 | 4.6 | SARH |

#### Magic (France)

The R.550 Magic served as France's short-range infrared missile, analogous to the Sidewinder. The Magic 2 improved all-aspect capability and flare rejection.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance |
|---------|--------------|-----------|--------------|----------|
| Magic II | R.550 Magic 2 | 15,000 | 2.7 | IR |

### Other Eastern Bloc AAMs

#### PL-Series (China)

China developed indigenous missiles based on Russian designs and later domestic developments. The PL-5 derived from the R-60, the PL-8 from the Python 3, and the PL-12 represents an indigenous active radar missile.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance |
|---------|--------------|-----------|--------------|----------|
| PL-5E II | PL-5E II | 16,000 | 2.2 | IR |
| PL-8A | PL-8A | 15,000 | 2.5 | IR |
| PL-8B | PL-8B | 15,000 | 2.5 | IR |
| PL-12 | SD-10 (PL-12) | 70,000 | 4 | Active Radar |

## Air-to-Ground Missiles

### AGM-65 Maverick Family

The AGM-65 Maverick became the workhorse precision-guided missile for Western tactical aircraft. First deployed in 1972, the Maverick pioneered the concept of a "fire and forget" air-to-ground missile—once the pilot locked the seeker onto a target and launched, the missile guided itself without further input. This allowed the pilot to immediately begin attacking another target or evading threats.

The Maverick family demonstrates an evolutionary approach to guidance technology. The original AGM-65A used an electro-optical television seeker requiring the pilot to visually identify and lock the target through a cockpit display. The AGM-65B improved the TV seeker's zoom capability for longer-range lock-on. The AGM-65D introduced imaging infrared (IIR) guidance, providing night and adverse weather capability—the IIR seeker detects heat differences rather than visible light contrast.

Warhead options split the family further. Early variants (A/B/D) used a 57 kg shaped-charge warhead optimized against armor. The AGM-65E (laser-guided, for Marine Corps use) and AGM-65F (Navy IIR) introduced a 136 kg penetrating blast-fragmentation warhead for larger targets like ships and bunkers. The AGM-65G combined the IIR seeker with the heavy warhead for Air Force use.

The Maverick proved devastating in the Gulf War, where over 5,000 rounds were fired with reported hit rates exceeding 80%. Targets included tanks, bunkers, vehicles, radar sites, and patrol boats.

| Variant | Display Name | Range (m) | Speed (Mach) | Guidance | Warhead (kg) |
|---------|--------------|-----------|--------------|----------|--------------|
| AGM-65A | AGM-65A | 24,076 | 1.2 | TV | 56 shaped charge |
| AGM-65B | AGM-65B | 24,076 | 1.2 | TV (scene mag) | 56 shaped charge |
| AGM-65D | AGM-65D | 24,076 | 1.2 | IIR | 56 shaped charge |
| AGM-65E | AGM-65E | 24,076 | 1.2 | Laser | 136 penetrator |
| AGM-65F | AGM-65F | 24,076 | 1.2 | IIR | 136 penetrator |
| AGM-65G | AGM-65G | 24,076 | 1.2 | IIR | 136 penetrator |
| AGM-65H | AGM-65H | 24,076 | 1.2 | CCD TV | 56 shaped charge |
| AGM-65K | AGM-65K | 24,076 | 1.2 | CCD TV | 136 penetrator |
| AGM-65L | AGM-65L | 24,076 | 1.2 | Laser | 136 penetrator |

### Anti-Radiation Missiles

Anti-radiation missiles (ARMs) home on enemy radar emissions, designed to destroy surface-to-air missile guidance radars and early warning systems. The concept emerged from Wild Weasel operations during the Vietnam War, where specialized crews deliberately attracted SAM radar attention to pinpoint and destroy the sites.

#### AGM-45 Shrike

The AGM-45 Shrike was the first American anti-radiation missile, developed from the AIM-7 Sparrow airframe. Each Shrike variant was tuned to specific radar frequency bands, requiring pilots to carry mixed loads when threat radars were uncertain. If the radar shut down, the missile lost guidance—a limitation operators quickly learned to exploit.

#### AGM-88 HARM

The AGM-88 High-speed Anti-Radiation Missile addressed Shrike's limitations. Its broadband seeker covered most threat radar frequencies without requiring variant selection, and it could memorize a target's location if the radar shut down. The AGM-88's speed (Mach 2+) and range (over 80 km) allowed standoff launches beyond SAM engagement envelopes.

| Weapon | Display Name | Range (m) | Speed (Mach) | Notes |
|--------|--------------|-----------|--------------|-------|
| AGM-45A | AGM-45A Shrike | 16,000 | 2.0 | Early ARM |
| AGM-45B | AGM-45B Shrike | 25,000 | 2.0 | Improved |
| AGM-88C | AGM-88C HARM | 80,000 | 3.0 | Standard NATO ARM |

#### ALARM (UK)

The British ALARM (Air Launched Anti-Radiation Missile) features a unique loiter mode. If no suitable radar is detected, the missile climbs, deploys a parachute, and descends slowly while searching. When a radar activates, ALARM jettisons the chute and attacks—a clever counter to the tactic of shutting radars down during ARM attacks.

### Anti-Ship Missiles

#### AGM-84 Harpoon

The AGM-84 Harpoon is the Western standard anti-ship missile, capable of launch from aircraft, ships, and submarines. The missile uses active radar homing in the terminal phase after cruising to the target area at low altitude using inertial navigation. Sea-skimming flight makes it difficult for ship defenses to detect and engage.

#### AGM-84E SLAM / AGM-84H SLAM-ER

The SLAM (Standoff Land Attack Missile) adapted the Harpoon airframe for precision land attack using GPS/INS navigation and an infrared terminal seeker with data link for operator-in-the-loop guidance. SLAM-ER extended range and added an improved warhead.

| Weapon | Display Name | Range (m) | Speed (Mach) | Guidance | Target |
|--------|--------------|-----------|--------------|----------|--------|
| AGM-84A | AGM-84A Harpoon | 124,000 | 0.85 | Active Radar | Ship |
| AGM-84D | AGM-84D Harpoon | 220,000 | 0.85 | Active Radar | Ship |
| AGM-84E | AGM-84E SLAM | 110,000 | 0.85 | GPS/IR | Land |
| AGM-84H | AGM-84H SLAM-ER | 270,000 | 0.85 | GPS/IR | Land |

### Stand-Off Weapons

#### AGM-154 JSOW

The Joint Stand-Off Weapon is an unpowered glide weapon with folding wings, capable of ranges exceeding 100 km when released from high altitude. Multiple variants exist: the AGM-154A carries BLU-97 combined effects bomblets, the AGM-154B carries BLU-108 sensor-fuzed anti-armor submunitions, and the AGM-154C has a unitary penetrating warhead with infrared terminal guidance.

| Variant | Display Name | Range (m) | Warhead |
|---------|--------------|-----------|---------|
| AGM-154A | AGM-154A JSOW | 130,000+ | BLU-97 cluster |
| AGM-154B | AGM-154B JSOW | 130,000+ | BLU-108 SFW |
| AGM-154C | AGM-154C JSOW | 130,000+ | Unitary penetrator |

### Soviet/Russian AGMs

#### Kh-29 (AS-14 Kedge)

The Kh-29 is Russia's equivalent to the Maverick, available in TV-guided (Kh-29T) and laser-guided (Kh-29L) variants. Considerably larger than the Maverick, it carries a 320 kg warhead capable of destroying hardened targets.

#### Kh-25 (AS-10 Karen)

The Kh-25 is a lighter tactical missile available in multiple guidance variants including laser (Kh-25ML), passive radar homing (Kh-25MP), and TV (Kh-25MT).

#### Kh-31 (AS-17 Krypton)

The Kh-31 is a supersonic missile available in anti-radiation (Kh-31P) and anti-ship (Kh-31A) variants. Its ramjet propulsion provides speeds exceeding Mach 3, making it difficult for ship defenses to intercept.

#### Kh-58 (AS-11 Kilter)

The Kh-58 is a large anti-radiation missile designed to destroy long-range SAM radars like the S-300. Its size limits carriage to larger aircraft.

### Helicopter-Launched Weapons

#### AGM-114 Hellfire

The AGM-114 Hellfire (Helicopter Launched Fire and Forget) was designed for the AH-64 Apache to destroy tanks at standoff range. Early variants used semi-active laser homing, requiring the launching helicopter or a ground designator to illuminate the target. Later variants introduced radar and imaging infrared guidance for true fire-and-forget capability.

| Variant | Display Name | Range (m) | Guidance | Warhead |
|---------|--------------|-----------|----------|---------|
| AGM-114 | AGM-114 Hellfire | 8,000 | Laser | Shaped charge |
| AGM-114K | AGM-114K Hellfire II | 8,000 | Laser | Tandem HEAT |

#### 9M120 Ataka

The Russian 9M120 Ataka is a supersonic anti-tank missile carried by Ka-50, Mi-28, and other rotorcraft. It uses radio command guidance with optional laser beam-riding.

#### HOT

The Franco-German HOT (Haute subsonique Optiquement téléguidé Tiré d'un Tube) is a wire-guided anti-tank missile used on Gazelle and other helicopters.

## Guided Bombs

### Paveway Laser-Guided Bombs

The Paveway series revolutionized air-to-ground warfare by providing affordable precision guidance. Rather than developing entirely new weapons, Paveway adds a guidance kit to existing "dumb" bombs—a seeker head in front and movable fins at the rear. This modular approach allowed rapid fielding and meant that any bomb in inventory could be upgraded.

The original Paveway I (GBU-10/12 designations) used a fixed-geometry seeker. Paveway II improved the seeker's tracking and added folding fins for carriage efficiency. Paveway III (GBU-24/27) introduced proportional navigation for shallow-angle attacks and better performance against moving targets. Paveway IV (not yet in DCS) adds GPS/INS backup and programmable fuzing.

Employment requires a laser designator—either from the launching aircraft, another aircraft, or ground forces—to illuminate the target. The bomb detects the reflected laser energy and steers toward the brightest spot. Cloud cover, rain, smoke, and dust can disrupt the laser beam, limiting effectiveness in adverse conditions.

| Weapon | Display Name | Bomb Body | Mass (kg) | Warhead (kg) |
|--------|--------------|-----------|-----------|--------------|
| GBU-10 | GBU-10 | Mk-84 2000 lb | 943 | 429 |
| GBU-11 | GBU-11 | Mk-84 2000 lb | 943 | 429 |
| GBU-12 | GBU-12 | Mk-82 500 lb | 277 | 89 |
| GBU-16 | GBU-16 | Mk-83 1000 lb | 500 | 202 |
| GBU-24 | GBU-24 | Mk-84 / BLU-109 | 1000+ | 429 / penetrator |
| GBU-27 | GBU-27 | BLU-109 | 900 | Penetrator |
| GBU-28 | GBU-28 | 4700 lb | 2268 | Deep penetrator |

### JDAM Family

The Joint Direct Attack Munition transformed the U.S. military's precision strike capability by providing GPS/INS guidance at a fraction of laser-guided bomb cost. Unlike Paveway, JDAM works in any weather without a designator—the pilot simply enters target coordinates, and the bomb navigates autonomously.

JDAM kits attach to existing bombs, similar to the Paveway concept. The GBU-31 uses the Mk-84 2000 lb bomb, the GBU-32 uses the Mk-83 1000 lb, and the GBU-38 uses the Mk-82 500 lb. The GBU-54 Laser JDAM adds a laser seeker for engaging moving targets, combining GPS accuracy with laser terminal guidance.

Accuracy depends on the quality of target coordinates. Against fixed targets with surveyed coordinates, JDAM achieves near-laser accuracy. Against targets located by less precise means, circular error probable increases accordingly.

| Weapon | Display Name | Bomb Body | Mass (kg) | Guidance |
|--------|--------------|-----------|-----------|----------|
| GBU-31 | GBU-31 | Mk-84 | 943 | GPS/INS |
| GBU-31(V)2/B | GBU-31(V)2/B | BLU-109 | 943 | GPS/INS |
| GBU-31(V)3/B | GBU-31(V)3/B | Mk-84 | 943 | GPS/INS |
| GBU-31(V)4/B | GBU-31(V)4/B | BLU-109 | 943 | GPS/INS |
| GBU-32 | GBU-32 | Mk-83 | 500 | GPS/INS |
| GBU-38 | GBU-38 | Mk-82 | 277 | GPS/INS |
| GBU-54 | GBU-54(V)1/B | Mk-82 | 277 | GPS/INS + Laser |

### GBU-39 Small Diameter Bomb

The GBU-39 Small Diameter Bomb (SDB) packs GPS/INS guidance into a 113 kg package, allowing fighters to carry far more precision weapons than with larger bombs. An F-15E can carry 28 SDBs versus four GBU-31s. The SDB uses deployable wings to achieve glide ranges exceeding 100 km from high altitude, providing standoff capability against defended targets.

The weapon uses a penetrating warhead with focused blast for reduced collateral damage—critical in urban environments and when engaging targets near friendly forces or civilians.

### Electro-Optical Guided Bombs

#### GBU-15

The GBU-15 uses either TV or imaging infrared guidance with a data link allowing the weapon systems officer to guide the bomb to impact. This provides precision against targets that might be difficult to designate with a laser, at the cost of requiring the launching aircraft to remain within data link range.

#### AGM-62 Walleye

The AGM-62 Walleye pioneered TV-guided glide weapons in the Vietnam War. The pilot locked the TV seeker onto a contrasting target feature before release, and the weapon guided autonomously. Walleye's accuracy demonstrated the potential of precision-guided munitions, helping drive development of the entire PGM family that followed.

### Soviet/Russian Guided Bombs

#### KAB-500 Series

The KAB-500 provides laser (KAB-500L) or TV (KAB-500Kr) guidance on a 500 kg bomb body. Soviet doctrine emphasized these weapons for high-value targets where precision justified the expense.

#### KAB-1500 Series

The KAB-1500 is a massive guided bomb weighing approximately 1500 kg, available with laser or TV guidance. The penetrating version can defeat hardened bunkers.

## Unguided Bombs

### Mk-80 Series

The Mk-80 series general-purpose bombs form the foundation of Western air-delivered ordnance. Developed in the 1950s, these low-drag bombs remain in production and serve as the basis for virtually all American precision-guided munitions. Each bomb consists of a steel case filled with Tritonal explosive, with nose and tail fuze wells.

The series follows a logical progression: Mk-81 (250 lb), Mk-82 (500 lb), Mk-83 (1000 lb), and Mk-84 (2000 lb). The Mk-82 and Mk-84 are by far the most common, with the Mk-81 rarely used due to limited effectiveness and the Mk-83 reserved for specific applications.

Retarded variants use high-drag devices to slow the bomb's fall, allowing low-altitude release without the aircraft being caught in its own bomb blast. The Snakeye uses folding metal fins, while AIR (Air Inflatable Retarder) variants deploy ballute-type drag devices.

| Weapon | Display Name | Mass (kg) | Explosive (kg) |
|--------|--------------|-----------|----------------|
| Mk-81 | Mk-81 | 113.4 | 45.4 |
| Mk-82 | Mk-82 | 228 | 87.1 |
| Mk-82 Snakeye | Mk-82 Snakeye | 249.5 | 87.1 |
| Mk-82 AIR | Mk-82 AIR | 242 | 87.1 |
| Mk-82Y | Mk-82Y (Chute Retarded) | 232 | 87.1 |
| Mk-83 | Mk-83 | 454 | 201.9 |
| Mk-83 AIR | Mk-83 AIR | 476.3 | 201.9 |
| Mk-83CT | Mk-83CT (Conical Tail) | 454 | 201.9 |
| Mk-84 | Mk-84 | 894 | 428.7 |
| Mk-84 AIR | Mk-84 AIR | 911.7 | 428.7 |

### Soviet/Russian FAB Series

The FAB (Fugasnaya Aviabomba, "high-explosive aircraft bomb") series serves the same role as the Mk-80 family. Soviet naming indicates the nominal mass: FAB-100 is approximately 100 kg, FAB-250 is 250 kg, FAB-500 is 500 kg, and FAB-1500 is 1500 kg.

Soviet bombs generally contain a higher proportion of explosive filler than Western equivalents, trading case strength for blast effect. Various suffixes indicate variants: "M" typically indicates modernized, "SL" indicates low-drag fins, and specific designations identify fuzing and construction differences.

| Weapon | Display Name | Mass (kg) | Explosive (kg) |
|--------|--------------|-----------|----------------|
| FAB-100 | FAB-100 | 100 | 45 |
| FAB-250 | OFAB-250-270 | 250 | 80 |
| FAB-500 | FAB-500M-62 | 500 | 200 |
| FAB-1500 | FAB-1500 | 1500 | 675 |

### Cluster Munitions

Cluster munitions dispense numerous submunitions over a wide area, effective against dispersed soft targets like vehicles, troops, and equipment. They are controversial due to unexploded submunitions that persist as de facto landmines.

#### CBU-87 Combined Effects Munition

The CBU-87 disperses 202 BLU-97 submunitions, each combining shaped charge, fragmentation, and incendiary effects. It was the most common U.S. cluster bomb during Desert Storm.

#### CBU-97 Sensor Fuzed Weapon

The CBU-97 contains 10 BLU-108 submunitions, each carrying four Skeet projectiles. Each Skeet uses infrared sensors to detect armored vehicles and fires an explosively formed penetrator at the target's vulnerable top armor. A single CBU-97 can theoretically kill 40 tanks.

#### CBU-103/105

Wind-corrected dispensers add GPS guidance to CBU-87 (creating CBU-103) and CBU-97 (creating CBU-105), improving accuracy and allowing release from higher altitude.

### Penetrators

#### BetAB-500

The BetAB-500 is a Soviet runway-penetrating bomb. The BetAB-500ShP version uses a rocket motor to accelerate the bomb after impact, driving it deeper into concrete before detonation.

#### Durandal

The French Durandal is specifically designed to crater runways. After release, a parachute orients the bomb nose-down, then a rocket motor accelerates it into the concrete.

### WWII Ordnance

DCS includes period ordnance for its WWII-era aircraft. American AN-M series bombs, British GP (General Purpose) and MC (Medium Capacity) bombs, and German SC (Sprengbombe Cylindrisch) series weapons are available for period-appropriate combat scenarios.

## Unguided Rockets

### Hydra 70 Family

The Hydra 70 (formally FFAR, Folding-Fin Aerial Rocket) is the standard 2.75-inch unguided rocket for U.S. fixed and rotary-wing aircraft. Descended from the WWII-era FFAR, the Hydra system uses a common motor with interchangeable warheads for different missions.

The M151 high-explosive warhead is the most common for general use. The M156 white phosphorus produces smoke for marking. The M274 practice warhead provides an inert training round. The M257 illumination round provides battlefield lighting. The M247 provides shaped-charge penetration for point targets.

Hydra rockets are carried in pods: the LAU-68 holds 7 rockets, the LAU-61 holds 19, and the LAU-130 holds 19.

### Zuni

The Zuni is a larger 5-inch (127mm) rocket providing greater range and warhead effect than the Hydra. The LAU-10 pod carries four Zunis. Originally developed for air-to-air use against bombers, the Zuni found its niche as a ground attack weapon, particularly against hardened targets where the larger warhead proved valuable.

### S-Series Rockets

Soviet/Russian aircraft use the S-series rockets. The S-5 (57mm) provides light suppression fire. The S-8 (80mm) is the rough equivalent of the Hydra 70, carried in B-8 pods of 20 rockets each. The S-13 (122mm) provides heavier punch for armored targets. The S-24 and S-25 are large single rockets rather than pod-carried weapons, delivering massive warheads at the cost of reduced capacity.

| Rocket | Caliber | Pod | Capacity | Warhead |
|--------|---------|-----|----------|---------|
| S-5 | 57mm | UB-16/32 | 16/32 | Various |
| S-8 | 80mm | B-8M1 | 20 | Various |
| S-13 | 122mm | B-13L | 5 | HE/penetrator |
| S-24 | 240mm | Single | 1 | 123 kg HE |
| S-25 | 340mm | Single | 1 | Heavy HE |

## Technical Reference

### Guidance Types

| Code | Type | Description |
|------|------|-------------|
| IR | Infrared | Homes on heat signature |
| SARH | Semi-Active Radar Homing | Homes on radar energy reflected from target |
| ARH | Active Radar Homing | Carries own radar, fire-and-forget |
| TV | Television/Electro-Optical | Tracks visible contrast |
| IIR | Imaging Infrared | Tracks thermal image |
| Laser | Laser Guidance | Follows reflected laser energy |
| GPS/INS | Satellite/Inertial | Navigates to coordinates |
| ARM | Anti-Radiation | Homes on radar emissions |

### Seeker Generations

For infrared missiles, the SeekerGen field indicates technology level:

| Generation | Characteristics |
|------------|-----------------|
| 1 | Uncooled PbS, rear-aspect only, poor flare rejection |
| 2 | Improved PbS, limited all-aspect, basic IRCCM |
| 3 | Cooled InSb, full all-aspect, good flare rejection |
| 4 | Imaging IR, high off-boresight, advanced IRCCM |

Higher seeker generation indicates more capable guidance, better flare rejection, and typically higher off-boresight tracking capability.

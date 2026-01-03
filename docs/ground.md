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

Long-range strategic SAM system. First deployed by the Soviet Union in 1978, the S-300 family remains one of the most capable air defense systems in the world.

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

American long-range SAM system. Entered service in 1981 and has been continuously upgraded. Used extensively in the Gulf War and subsequent conflicts.

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

American medium-range SAM system. First deployed in 1960 and widely exported. Being phased out but still in service with some nations.

| Component | Type ID | Role |
|-----------|---------|------|
| M192 Launcher | `Hawk ln` | Launcher (3 missiles) |
| AN/MPQ-46 TR | `Hawk tr` | High Power Illuminator (tracking radar) |
| AN/MPQ-50 SR | `Hawk sr` | Pulse Acquisition Radar (search) |
| AN/MPQ-55 CWAR | `Hawk cwar` | Continuous Wave Acquisition Radar |
| PCP | `Hawk pcp` | Platoon Command Post |

**Required for operation:** Launcher requires TR. TR requires PCP. PCP requires SR, CWAR, or both.

### SA-11 Buk (Gadfly)

Soviet/Russian medium-range SAM. Entered service in 1980. Highly mobile with the ability for TELARs to engage independently.

| Component | Type ID | Role |
|-----------|---------|------|
| 9A310M1 TELAR | `SA-11 Buk LN 9A310M1` | Launcher with onboard radar (4 missiles) |
| 9S470M1 | `SA-11 Buk CC 9S470M1` | Command post |
| 9S18M1 Snow Drift | `SA-11 Buk SR 9S18M1` | Search radar |

**Required for operation:** TELAR can operate independently using its own radar or can be directed by the command post.

### SA-6 Kub (Gainful)

Soviet medium-range SAM. Entered service in 1967. Famous for its effectiveness during the 1973 Yom Kippur War.

| Component | Type ID | Role |
|-----------|---------|------|
| 2P25 TEL | `Kub 2P25 ln` | Launcher (3 missiles) |
| 1S91 Straight Flush | `Kub 1S91 str` | Combined search/track radar |

**Required for operation:** TEL requires the 1S91 radar.

### S-125 Neva (SA-3 Goa)

Soviet medium-range SAM. Entered service in 1961. Widely exported and still in use. Shot down an F-117 during the Kosovo War in 1999.

| Component | Type ID | Role |
|-----------|---------|------|
| 5P73 Launcher | `5p73 s-125 ln` | Launcher (4 missiles) |
| SNR-125 Low Blow | `snr s-125 tr` | Tracking radar |
| P-19 Flat Face | `p-19 s-125 sr` | Search radar |

**Required for operation:** Launcher requires the SNR-125 tracking radar.

### S-75 Dvina (SA-2 Guideline)

Soviet high-altitude SAM. Entered service in 1957. One of the most widely deployed SAM systems in history, responsible for shooting down Gary Powers' U-2 in 1960.

| Component | Type ID | Role |
|-----------|---------|------|
| SM-90 Launcher | `S_75M_Volhov` | Launcher (1 missile) |
| SNR-75 Fan Song | `SNR_75V` | Tracking radar |
| RD-75 Amazonka | `RD_75` | Radio direction finding (optional) |
| ZIL-131 Tractor | `S_75_ZIL` | Transport vehicle |

**Required for operation:** Launcher requires the SNR-75 tracking radar.

### S-200 Angara (SA-5 Gammon)

Soviet long-range SAM. Entered service in 1967. Designed for high-altitude strategic targets like bombers and reconnaissance aircraft.

| Component | Type ID | Role |
|-----------|---------|------|
| 5P72 Launcher | `S-200_Launcher` | Launcher (1 large missile) |
| RPC 5N62V Square Pair | `RPC_5N62V` | Tracking radar |
| P-14 Tall King | `P14_SR` | Search radar |
| 19J6 | `RLS_19J6` | Search radar (alternate) |

**Required for operation:** Tracking radar requires a search radar (P-14 or 19J6).

### NASAMS

Norwegian/American medium-range SAM. Uses AIM-120 AMRAAM missiles. Highly mobile and effective against aircraft and cruise missiles.

| Component | Type ID | Role |
|-----------|---------|------|
| LCHR (AIM-120B) | `NASAMS_LN_B` | Launcher with AIM-120B |
| LCHR (AIM-120C) | `NASAMS_LN_C` | Launcher with AIM-120C |
| AN/MPQ-64F1 | `NASAMS_Radar_MPQ64F1` | Sentinel search radar |
| FDC | `NASAMS_Command_Post` | Fire Distribution Center |

**Required for operation:** Launchers require the Command Post. Command Post requires the radar.

### Rapier

British short-range SAM. Entered service in 1971. Known for accuracy and reliability.

| Component | Type ID | Role |
|-----------|---------|------|
| Launcher | `rapier_fsa_launcher` | Launcher (4 missiles) |
| Blindfire TR | `rapier_fsa_blindfire_radar` | Tracking radar (all-weather) |
| Optical Tracker | `rapier_fsa_optical_tracker_unit` | Optical tracking unit |

**Required for operation:** Launcher requires the Blindfire radar for all-weather operation.

### IRIS-T SLM

German short/medium-range SAM. Modern system using IRIS-T missiles.

| Component | Type ID | Role |
|-----------|---------|------|
| Launcher | `CHAP_IRISTSLM_LN` | Launcher |
| STR | `CHAP_IRISTSLM_STR` | Search/track radar |
| C2 | `CHAP_IRISTSLM_CP` | Command post |

**Required for operation:** Launcher requires the STR.

### HQ-7 (FM-80/90)

Chinese short-range SAM based on the French Crotale. Entered service in 1988.

| Component | Type ID | Role |
|-----------|---------|------|
| TELAR | `HQ-7_LN_SP` | Launcher with onboard radar |
| TELAR (Player) | `HQ-7_LN_P` | Player-controllable version |
| SR | `HQ-7_STR_SP` | Search radar (optional) |

**Required for operation:** TELAR can operate independently.

### Self-Propelled SAM Systems (Single Vehicle)

These systems combine radar, launcher, and fire control into a single vehicle:

| System | Type ID | Description |
|--------|---------|-------------|
| 2S6 Tunguska (SA-19) | `2S6 Tunguska` | Combined gun/missile SPAAG |
| 9A33 Osa (SA-8) | `Osa 9A33 ln` | Amphibious TELAR |
| 9A331 Tor (SA-15) | `Tor 9A331` | Modern short-range SAM |
| Tor-M2 | `CHAP_TorM2` | Upgraded Tor system |
| Pantsir-S1 | `CHAP_PantsirS1` | Combined gun/missile system |
| Roland ADS | `Roland ADS` | Franco-German SHORAD |
| Roland EWR | `Roland Radar` | Search radar for Roland |
| 9K35 Strela-10 (SA-13) | `Strela-10M3` | Optical-guided SAM |
| 9P31 Strela-1 (SA-9) | `Strela-1 9P31` | Vehicle-mounted SAM |
| M48 Chaparral | `M48 Chaparral` | American SHORAD |
| M1097 Avenger | `M1097 Avenger` | Humvee with Stingers |
| M6 Linebacker | `M6 Linebacker` | Bradley with Stingers |

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

Unguided anti-aircraft guns remain effective against low-flying aircraft and helicopters.

#### Modern AAA

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

Man-portable air defense systems carried by infantry:

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

Modern main battle tanks combining firepower, protection, and mobility:

#### Western MBTs

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

Armored vehicles designed to carry infantry and support them with firepower:

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

Vehicles primarily for transporting infantry with lighter armament:

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

Armored vehicles optimized for anti-tank warfare:

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

| Name | Type ID | Missile | Notes |
|------|---------|---------|-------|
| ATGM BRDM-2 Malyutka | `BRDM-2_malyutka` | AT-3 Sagger | Early ATGM carrier |
| ATGM HMMWV TOW | `M1045 HMMWV TOW` | TOW | American ATGM vehicle |
| ATGM Stryker | `M1134 Stryker ATGM` | TOW | Wheeled ATGM carrier |
| ATGM VAB Mephisto | `VAB_Mephisto` | HOT | French ATGM vehicle |
| APC BTR-RD | `BTR_D` | AT-5 Spandrel | Airborne ATGM carrier |

## Artillery

### Self-Propelled Howitzers

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

| Name | Type ID | Caliber | Notes |
|------|---------|---------|-------|
| Mortar 2B11 | `2B11 mortar` | 120mm | Soviet heavy mortar |
| L118 Light Gun | `L118_Unit` | 105mm | British towed howitzer |
| FH M2A1 | `M2A1-105` | 105mm | WWII American howitzer |
| FH LeFH-18 | `LeFH_18-40-105` | 105mm | WWII German howitzer |
| FH Pak 40 | `Pak40` | 75mm | WWII German anti-tank gun |

## Infantry

Infantry units in DCS represent soldiers with various weapons:

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

| Name | Type ID | Weapon | Country |
|------|---------|--------|---------|
| Infantry M1 Garand | `soldier_wwii_us` | M1 Garand | USA |
| Infantry SMLE No.4 | `soldier_wwii_br_01` | Lee-Enfield | UK |
| Infantry Mauser 98 | `soldier_mauser98` | Kar98k | Germany |

## Unarmed

### Trucks and Transport

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

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
| **JTAC** |||
| JTAC 1 | 32.3 FM | Forward air controller |
| JTAC 2 | 32.5 FM | Forward air controller |
| JTAC 3 | 32.7 FM | Forward air controller |
| JTAC 4 | 32.9 FM | Forward air controller |
| **Reserved** |||
| Guard | 243.0 | Emergency frequency (standard) |
| Aux Reserved | 265.0-284.9 | Compatible with F-4E aux radio |

## Design Rationale

The frequency plan uses whole and half MHz values for easy memorization and radio tuning. Frequencies are grouped by function with gaps between groups to allow expansion.

The 260-284 MHz range is used for fighter flight tactical frequencies because it falls within the F-4E's auxiliary radio range (265.0-284.9 MHz), allowing Phantom crews to monitor their flight frequency on the aux radio while using the primary for other communications.

FM frequencies (30-88 MHz) are allocated for A-10 and helicopter flights. These aircraft have three radios including FM capability, so using FM for internal flight comms leaves their UHF radio free for strike coordination, JTAC, and package-level traffic. Aircraft with only UHF radios cannot monitor FM, so mixed packages should coordinate on UHF frequencies.

All operational frequencies avoid the 243.0 MHz guard frequency and stay well within the 225-400 MHz UHF band supported by all military aircraft in DCS. The 250-252 MHz range is avoided because it is heavily used by airfield ATC frequencies on the Syria, Caucasus, Nevada, and other maps.

## Aircraft Radio Compatibility

| Aircraft | Radio 1 | Radio 2 | Radio 3 |
|----------|---------|---------|---------|
| F-4E Phantom II | 225.0-399.95 AM | 265.0-284.9 AM | — |
| F-16C Viper | 225.0-399.975 AM | 108.0-151.975 VHF | — |
| F/A-18C Hornet | 225.0-399.975 AM | 225.0-399.975 AM | — |
| F-15C/E Eagle | 225.0-399.975 AM | 225.0-399.975 AM | — |
| F-14A/B Tomcat | 225.0-399.975 AM | 225.0-399.975 AM | — |
| A-10C Warthog | 225.0-399.975 AM | 116.0-151.975 VHF AM | 30.0-87.975 FM |
| AV-8B Harrier | 225.0-399.975 AM | 225.0-399.975 AM | — |
| AH-64D Apache | 225.0-399.975 AM | 116.0-151.975 VHF AM | 30.0-87.975 FM |
| UH-1H Huey | 225.0-399.975 AM | 30.0-75.975 FM | — |
| Mi-24P Hind | 100.0-399.9 AM | 20.0-59.975 FM | — |
| Ka-50 Black Shark | 100.0-399.9 AM | 20.0-59.9 FM | — |

A-10 and helicopter flights should use FM frequencies for internal flight communications, leaving UHF free for strike coordination, JTAC, and other package-level traffic.

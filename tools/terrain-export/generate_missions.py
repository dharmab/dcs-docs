#!/usr/bin/env python3
"""
Generate MIZ mission files for terrain sampling.

Creates minimal mission files for each supported DCS theatre that will
run the terrain-sampler.lua script when executed.
"""

from __future__ import annotations

import zipfile
from pathlib import Path

import luadata


def load_terrain_sampler_script() -> str:
    """Load the terrain sampler Lua script from disk."""
    script_path = Path(__file__).parent / "terrain-sampler.lua"
    return script_path.read_text(encoding="utf-8")

# Theatre names as used in DCS
THEATRES = [
    "Caucasus",
    "Syria",
    "Nevada",
    "PersianGulf",
    "MarianaIslands",
    "Falklands",
    "Sinai",
    "Kola",
    "Afghanistan",
]


def serialize_lua(name: str, data: dict | list) -> str:
    """Serialize a Python dict/list to a Lua table assignment."""
    content = luadata.serialize(data, encoding="utf-8", indent="\t")
    return f"{name} =\n{content}\n"


def build_mission_data(theatre: str, script_content: str) -> dict:
    """Build the mission data structure for a given theatre."""
    return {
        "trig": {
            "actions": {},
            "events": {},
            "custom": {},
            "func": {},
            "flag": {},
            "conditions": {},
            "customStartup": {},
            "funcStartup": {},
            "activePart": {},
        },
        "result": {
            "total": 0,
            "offline": {
                "conditions": {},
                "actions": {},
                "func": {},
            },
            "blue": {
                "conditions": {},
                "actions": {},
                "func": {},
            },
            "red": {
                "conditions": {},
                "actions": {},
                "func": {},
            },
        },
        "goals": {},
        "weather": {
            "atmosphere_type": 0,
            "groundTurbulence": 0,
            "enable_fog": False,
            "wind": {
                "atGround": {
                    "speed": 0,
                    "dir": 0,
                },
                "at2000": {
                    "speed": 0,
                    "dir": 0,
                },
                "at8000": {
                    "speed": 0,
                    "dir": 0,
                },
            },
            "season": {
                "temperature": 20,
            },
            "type_weather": 0,
            "qnh": 760,
            "cyclones": {},
            "name": "Summer, clean sky",
            "fog": {
                "thickness": 0,
                "visibility": 0,
            },
            "visibility": {
                "distance": 80000,
            },
            "clouds": {
                "thickness": 200,
                "density": 0,
                "preset": "Preset1",
                "base": 2500,
                "iprecptns": 0,
            },
        },
        "requiredModules": {},
        "date": {
            "Day": 1,
            "Year": 2020,
            "Month": 6,
        },
        "coalitions": {
            "neutrals": {},
            "blue": {},
            "red": {},
        },
        "maxDictId": 0,
        "descriptionNeutralsTask": "",
        "groundControl": {
            "isPilotControlVehicles": False,
            "roles": {
                "artillery_commander": {
                    "neutrals": 0,
                    "blue": 0,
                    "red": 0,
                },
                "instructor": {
                    "neutrals": 0,
                    "blue": 0,
                    "red": 0,
                },
                "observer": {
                    "neutrals": 0,
                    "blue": 0,
                    "red": 0,
                },
                "forward_observer": {
                    "neutrals": 0,
                    "blue": 0,
                    "red": 0,
                },
            },
        },
        "descriptionText": f"Terrain export mission for {theatre}.",
        "pictureFileNameN": {},
        "descriptionBlueTask": "",
        "descriptionRedTask": "",
        "pictureFileNameR": {},
        "sortie": f"Terrain Export - {theatre}",
        "version": 22,
        "trigrules": {
            1: {
                "rules": {
                    1: {
                        "flag": 0,
                        "coalitionlist": "red",
                        "KeyDict_text": "",
                        "predicate": "c_time_after",
                        "zone": "",
                        "unitType": "",
                        "seconds": 30,
                        "meters": 1000,
                        "KeyDict_zone": "",
                        "readonly": False,
                        "text": "",
                        "unitObject": "",
                        "KeyDict_unitObject": "",
                        "target": "",
                        "KeyDict_target": "",
                    },
                },
                "comment": "Run terrain sampler",
                "eventlist": "",
                "predicate": "triggerOnce",
                "actions": {
                    1: {
                        "text": script_content,
                        "KeyDict_text": "",
                        "predicate": "a_do_script",
                        "KeyDict_file": "",
                        "ai_task": {},
                        "file": "",
                    },
                },
            },
        },
        "theatre": theatre,
        "triggers": {
            "zones": {},
        },
        "map": {
            "centerY": 0,
            "zoom": 1000000,
            "centerX": 0,
        },
        "coalition": {
            "neutrals": {
                "bullseye": {
                    "y": 0,
                    "x": 0,
                },
                "nav_points": {},
                "name": "neutrals",
                "country": {},
            },
            "blue": {
                "bullseye": {
                    "y": 0,
                    "x": 0,
                },
                "nav_points": {},
                "name": "blue",
                "country": {},
            },
            "red": {
                "bullseye": {
                    "y": 0,
                    "x": 0,
                },
                "nav_points": {},
                "name": "red",
                "country": {},
            },
        },
        "currentKey": 0,
        "start_time": 43200,
        "forcedOptions": {},
        "failures": {},
    }


def build_options_data() -> dict:
    """Build minimal options data structure."""
    return {
        "playerName": "Player",
        "miscellaneous": {
            "allow_ownship_export": True,
            "headmove": False,
            "TrackIR_external_views": True,
            "f11_free_camera": True,
            "f10_awacs": True,
            "Coordinate_Display": "Lat Long Decimal",
            "accidental_failures": False,
            "autologin": True,
            "show_pilot_body": False,
            "collect_stat": False,
            "chat_window_at_start": True,
            "synchronize_controls": False,
            "backup": False,
            "f5_nearest_ac": True,
        },
        "difficulty": {
            "fuel": False,
            "labels": 0,
            "easyRadar": False,
            "miniHUD": False,
            "optionsView": "optview_all",
            "setGlobal": True,
            "avionicsLanguage": "native",
            "cockpitVisualRM": False,
            "map": True,
            "spectatorExternalViews": True,
            "userSnapView": True,
            "iconsTheme": "nato",
            "weapons": False,
            "padlock": False,
            "birds": 0,
            "permitCrash": True,
            "immortal": False,
            "cockpitStatusBarAllowed": False,
            "wakeTurbulence": False,
            "easyFlight": False,
            "hideStick": False,
            "radio": False,
            "geffect": "realistic",
            "easyCommunication": True,
            "tips": True,
            "autoTrimmer": False,
            "externalViews": True,
            "RBDAI": True,
            "controlsIndicator": True,
            "units": "imperial",
            "unrestrictedSATNAV": False,
        },
        "VR": {},
        "graphics": {},
    }


def build_warehouses_data() -> dict:
    """Build minimal warehouses data structure."""
    return {}


def build_dictionary_data() -> dict:
    """Build localization dictionary data structure."""
    return {}


def build_map_resource_data() -> dict:
    """Build map resource data structure."""
    return {}


def create_miz(output_dir: Path, theatre: str, script_content: str) -> Path:
    """Create a MIZ file for the given theatre."""
    miz_path = output_dir / f"{theatre.lower()}-terrain-export.miz"

    with zipfile.ZipFile(miz_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # Main mission file
        zf.writestr(
            "mission", serialize_lua("mission", build_mission_data(theatre, script_content))
        )

        # Theatre identifier
        zf.writestr("theatre", theatre)

        # Options
        zf.writestr("options", serialize_lua("options", build_options_data()))

        # Warehouses
        zf.writestr("warehouses", serialize_lua("warehouses", build_warehouses_data()))

        # Localization
        zf.writestr(
            "l10n/DEFAULT/dictionary",
            serialize_lua("dictionary", build_dictionary_data()),
        )
        zf.writestr(
            "l10n/DEFAULT/mapResource",
            serialize_lua("mapResource", build_map_resource_data()),
        )

    return miz_path


def main() -> int:
    """Generate MIZ files for all supported theatres."""
    output_dir = Path(__file__).parent / "missions"
    output_dir.mkdir(exist_ok=True)

    # Load the terrain sampler script once
    script_content = load_terrain_sampler_script()
    print(f"Loaded terrain-sampler.lua ({len(script_content)} bytes)")

    print(f"Generating MIZ files in {output_dir}/")

    for theatre in THEATRES:
        miz_path = create_miz(output_dir, theatre, script_content)
        print(f"  Created: {miz_path.name}")

    print(f"\nGenerated {len(THEATRES)} mission files.")
    print("\nTo use:")
    print("1. Open any generated .miz file in DCS")
    print("2. Run the mission and wait for export completion")
    print("3. Find JSON output in Saved Games/DCS/TerrainExport/")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

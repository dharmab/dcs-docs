#!/usr/bin/env python3
"""
Generate MIZ mission files for terrain sampling.

Creates minimal mission files for each supported DCS theatre that will
run the terrain-sampler.lua script when executed.
"""

from __future__ import annotations

import zipfile
from pathlib import Path

# Theatre names as used in DCS (theatre file content) and display names
THEATRES = [
    ("Caucasus", "Caucasus"),
    ("Syria", "Syria"),
    ("Nevada", "Nevada"),
    ("PersianGulf", "PersianGulf"),
    ("MarianaIslands", "MarianaIslands"),
    ("Falklands", "Falklands"),
    ("Sinai", "Sinai"),
    ("Kola", "Kola"),
    ("Afghanistan", "Afghanistan"),
]


def generate_mission_lua(theatre: str) -> str:
    """Generate the mission Lua file content."""
    # The script uses dofile to load the terrain sampler from the Scripts folder.
    # This requires desanitized MissionScripting.lua (which is already required
    # for the terrain sampler to write files anyway).
    script_content = 'dofile(lfs.writedir() .. "Scripts/terrain-sampler.lua")'

    return f'''mission =
{{
    ["trig"] =
    {{
        ["actions"] =
        {{
            [1] = "a]do script({script_content}); ",
        }}, -- end of ["actions"]
        ["events"] =
        {{
        }}, -- end of ["events"]
        ["custom"] =
        {{
        }}, -- end of ["custom"]
        ["func"] =
        {{
        }}, -- end of ["func"]
        ["flag"] =
        {{
            [1] = true,
        }}, -- end of ["flag"]
        ["conditions"] =
        {{
            [1] = "return(c_time_after(5) )",
        }}, -- end of ["conditions"]
        ["customStartup"] =
        {{
        }}, -- end of ["customStartup"]
        ["funcStartup"] =
        {{
        }}, -- end of ["funcStartup"]
        ["activePart"] =
        {{
            [1] =
            {{
                [1] = 1,
            }}, -- end of [1]
        }}, -- end of ["activePart"]
    }}, -- end of ["trig"]
    ["requiredModules"] =
    {{
    }}, -- end of ["requiredModules"]
    ["date"] =
    {{
        ["Day"] = 1,
        ["Year"] = 2020,
        ["Month"] = 6,
    }}, -- end of ["date"]
    ["coalitions"] =
    {{
        ["neutrals"] =
        {{
        }}, -- end of ["neutrals"]
        ["blue"] =
        {{
        }}, -- end of ["blue"]
        ["red"] =
        {{
        }}, -- end of ["red"]
    }}, -- end of ["coalitions"]
    ["maxDictId"] = 0,
    ["descriptionNeutralsTask"] = "",
    ["groundControl"] =
    {{
        ["isPilotControlVehicles"] = false,
        ["roles"] =
        {{
            ["artillery_commander"] =
            {{
                ["neutrals"] = 0,
                ["blue"] = 0,
                ["red"] = 0,
            }}, -- end of ["artillery_commander"]
            ["instructor"] =
            {{
                ["neutrals"] = 0,
                ["blue"] = 0,
                ["red"] = 0,
            }}, -- end of ["instructor"]
            ["observer"] =
            {{
                ["neutrals"] = 0,
                ["blue"] = 0,
                ["red"] = 0,
            }}, -- end of ["observer"]
            ["forward_observer"] =
            {{
                ["neutrals"] = 0,
                ["blue"] = 0,
                ["red"] = 0,
            }}, -- end of ["forward_observer"]
        }}, -- end of ["roles"]
    }}, -- end of ["groundControl"]
    ["descriptionText"] = "Terrain export mission for {theatre}.",
    ["pictureFileNameN"] =
    {{
    }}, -- end of ["pictureFileNameN"]
    ["descriptionBlueTask"] = "",
    ["descriptionRedTask"] = "",
    ["pictureFileNameR"] =
    {{
    }}, -- end of ["pictureFileNameR"]
    ["sortie"] = "Terrain Export - {theatre}",
    ["version"] = 22,
    ["trigrules"] =
    {{
        [1] =
        {{
            ["rules"] =
            {{
                [1] =
                {{
                    ["flag"] = 0,
                    ["coalitionlist"] = "red",
                    ["KeyDict_text"] = "",
                    ["predicate"] = "c_time_after",
                    ["zone"] = "",
                    ["unitType"] = "",
                    ["seconds"] = 5,
                    ["meters"] = 1000,
                    ["KeyDict_zone"] = "",
                    ["readonly"] = false,
                    ["text"] = "",
                    ["unitObject"] = "",
                    ["KeyDict_unitObject"] = "",
                    ["target"] = "",
                    ["KeyDict_target"] = "",
                }}, -- end of [1]
            }}, -- end of ["rules"]
            ["comment"] = "Run terrain sampler",
            ["eventlist"] = "",
            ["predicate"] = "triggerOnce",
            ["actions"] =
            {{
                [1] =
                {{
                    ["text"] = "",
                    ["KeyDict_text"] = "",
                    ["predicate"] = "a]do script",
                    ["KeyDict_file"] = "",
                    ["ai_task"] =
                    {{
                    }}, -- end of ["ai_task"]
                    ["file"] = "Scripts/terrain-sampler.lua",
                }}, -- end of [1]
            }}, -- end of ["actions"]
        }}, -- end of [1]
    }}, -- end of ["trigrules"]
    ["theatre"] = "{theatre}",
    ["triggers"] =
    {{
        ["zones"] =
        {{
        }}, -- end of ["zones"]
    }}, -- end of ["triggers"]
    ["map"] =
    {{
        ["centerY"] = 0,
        ["zoom"] = 1000000,
        ["centerX"] = 0,
    }}, -- end of ["map"]
    ["coalition"] =
    {{
        ["neutrals"] =
        {{
            ["bullseye"] =
            {{
                ["y"] = 0,
                ["x"] = 0,
            }}, -- end of ["bullseye"]
            ["nav_points"] =
            {{
            }}, -- end of ["nav_points"]
            ["name"] = "neutrals",
            ["country"] =
            {{
            }}, -- end of ["country"]
        }}, -- end of ["neutrals"]
        ["blue"] =
        {{
            ["bullseye"] =
            {{
                ["y"] = 0,
                ["x"] = 0,
            }}, -- end of ["bullseye"]
            ["nav_points"] =
            {{
            }}, -- end of ["nav_points"]
            ["name"] = "blue",
            ["country"] =
            {{
            }}, -- end of ["country"]
        }}, -- end of ["blue"]
        ["red"] =
        {{
            ["bullseye"] =
            {{
                ["y"] = 0,
                ["x"] = 0,
            }}, -- end of ["bullseye"]
            ["nav_points"] =
            {{
            }}, -- end of ["nav_points"]
            ["name"] = "red",
            ["country"] =
            {{
            }}, -- end of ["country"]
        }}, -- end of ["red"]
    }}, -- end of ["coalition"]
    ["currentKey"] = 0,
    ["start_time"] = 43200,
    ["forcedOptions"] =
    {{
    }}, -- end of ["forcedOptions"]
    ["failures"] =
    {{
    }}, -- end of ["failures"]
}} -- end of mission
'''


def generate_options_lua() -> str:
    """Generate minimal options Lua file."""
    return '''options =
{
    ["playerName"] = "Player",
    ["miscellaneous"] =
    {
        ["allow_ownship_export"] = true,
        ["headmove"] = false,
        ["TrackIR_external_views"] = true,
        ["f11_free_camera"] = true,
        ["f10_awacs"] = true,
        ["Coordinate_Display"] = "Lat Long Decimal",
        ["accidental_failures"] = false,
        ["autologin"] = true,
        ["show_pilot_body"] = false,
        ["collect_stat"] = false,
        ["chat_window_at_start"] = true,
        ["synchronize_controls"] = false,
        ["backup"] = false,
        ["f5_nearest_ac"] = true,
    }, -- end of ["miscellaneous"]
    ["difficulty"] =
    {
        ["fuel"] = false,
        ["labels"] = 0,
        ["easyRadar"] = false,
        ["miniHUD"] = false,
        ["optionsView"] = "optview_all",
        ["setGlobal"] = true,
        ["avionicsLanguage"] = "native",
        ["cockpitVisualRM"] = false,
        ["map"] = true,
        ["spectatorExternalViews"] = true,
        ["userSnapView"] = true,
        ["iconsTheme"] = "nato",
        ["weapons"] = false,
        ["padlock"] = false,
        ["birds"] = 0,
        ["permitCrash"] = true,
        ["immortal"] = false,
        ["cockpitStatusBarAllowed"] = false,
        ["wakeTurbulence"] = false,
        ["easyFlight"] = false,
        ["hideStick"] = false,
        ["radio"] = false,
        ["geffect"] = "realistic",
        ["easyCommunication"] = true,
        ["tips"] = true,
        ["autoTrimmer"] = false,
        ["externalViews"] = true,
        ["RBDAI"] = true,
        ["controlsIndicator"] = true,
        ["units"] = "imperial",
        ["unrestrictedSATNAV"] = false,
    }, -- end of ["difficulty"]
    ["VR"] =
    {
    }, -- end of ["VR"]
    ["graphics"] =
    {
    }, -- end of ["graphics"]
} -- end of options
'''


def generate_warehouses_lua() -> str:
    """Generate minimal warehouses Lua file."""
    return '''warehouses =
{
} -- end of warehouses
'''


def generate_dictionary() -> str:
    """Generate localization dictionary."""
    return '''dictionary =
{
} -- end of dictionary
'''


def generate_map_resource() -> str:
    """Generate map resource file."""
    return '''mapResource =
{
} -- end of mapResource
'''


def create_miz(output_dir: Path, theatre_id: str, theatre_display: str) -> Path:
    """Create a MIZ file for the given theatre."""
    miz_path = output_dir / f"{theatre_id.lower()}-terrain-export.miz"

    with zipfile.ZipFile(miz_path, "w", zipfile.ZIP_DEFLATED) as zf:
        # Main mission file
        zf.writestr("mission", generate_mission_lua(theatre_id))

        # Theatre identifier
        zf.writestr("theatre", theatre_id)

        # Options
        zf.writestr("options", generate_options_lua())

        # Warehouses
        zf.writestr("warehouses", generate_warehouses_lua())

        # Localization
        zf.writestr("l10n/DEFAULT/dictionary", generate_dictionary())
        zf.writestr("l10n/DEFAULT/mapResource", generate_map_resource())

    return miz_path


def main() -> int:
    """Generate MIZ files for all supported theatres."""
    output_dir = Path(__file__).parent / "missions"
    output_dir.mkdir(exist_ok=True)

    print(f"Generating MIZ files in {output_dir}/")

    for theatre_id, theatre_display in THEATRES:
        miz_path = create_miz(output_dir, theatre_id, theatre_display)
        print(f"  Created: {miz_path.name}")

    print(f"\nGenerated {len(THEATRES)} mission files.")
    print("\nTo use:")
    print("1. Copy terrain-sampler.lua to Saved Games/DCS/Scripts/")
    print("2. Open any generated .miz file in DCS")
    print("3. Run the mission and wait for export completion")
    print("4. Find JSON output in Saved Games/DCS/TerrainExport/")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())

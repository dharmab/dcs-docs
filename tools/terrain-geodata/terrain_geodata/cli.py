"""Command line entry point."""

from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from . import export


def _dcs_path(arg: str | None) -> Path:
    value = arg or os.environ.get("DCS_PATH")
    if not value:
        sys.exit("pass --dcs-path or set DCS_PATH to the DCS World install folder")
    return Path(value)


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        prog="terrain-geodata",
        description="Export DCS World terrain data from the game install as GIS files.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser("list", help="List terrains found in the install")
    p_list.add_argument("--dcs-path", help="DCS World install folder (or DCS_PATH)")

    p_export = sub.add_parser("export", help="Export terrains")
    p_export.add_argument("--dcs-path", help="DCS World install folder (or DCS_PATH)")
    p_export.add_argument(
        "--out",
        type=Path,
        default=Path("docs/data/terrains"),
        help="Output root; each terrain gets a folder named by theatre id",
    )
    p_export.add_argument(
        "--terrain",
        action="append",
        help="Theatre id or terrain folder name; repeat for several (default: all)",
    )
    p_export.add_argument(
        "--resolution",
        type=float,
        default=100.0,
        help="Land cover pixel size in metres (default: 100)",
    )

    args = parser.parse_args(argv)
    dcs_path = _dcs_path(args.dcs_path)
    terrains = export.discover(dcs_path)

    if args.command == "list":
        for t in terrains:
            print(f"{t.theatre:22} {t.folder.name}")
        return

    if args.terrain:
        wanted = {w.casefold() for w in args.terrain}
        terrains = [
            t
            for t in terrains
            if t.theatre.casefold() in wanted or t.folder.name.casefold() in wanted
        ]
        if not terrains:
            sys.exit(f"no terrain matches {args.terrain}")
    version = export.dcs_version(dcs_path)
    for t in terrains:
        print(f"{t.theatre} ({t.folder.name})")
        export.export_terrain(t, args.out, args.resolution, version)


if __name__ == "__main__":
    main()

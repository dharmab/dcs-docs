"""Command line entry point."""

from __future__ import annotations

import argparse
import os
import sys
import time
from pathlib import Path

from . import export

# Registry values that hold the install folder: standalone (current and the
# retired OpenBeta branch), then Steam's uninstall entry for app 223750.
_REGISTRY_PATHS = (
    ("HKEY_CURRENT_USER", r"Software\Eagle Dynamics\DCS World", "Path"),
    ("HKEY_CURRENT_USER", r"Software\Eagle Dynamics\DCS World OpenBeta", "Path"),
    (
        "HKEY_LOCAL_MACHINE",
        r"SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 223750",
        "InstallLocation",
    ),
)


def _registry_dcs_path() -> Path | None:
    """First existing DCS World install folder recorded in the Windows registry."""
    if sys.platform != "win32":
        return None
    import winreg

    for hive, key, value in _REGISTRY_PATHS:
        try:
            with winreg.OpenKey(getattr(winreg, hive), key) as handle:
                folder, _ = winreg.QueryValueEx(handle, value)
        except OSError:
            continue
        path = Path(folder)
        if path.is_dir():
            return path
    return None


def _dcs_path(arg: str | None) -> Path:
    value = arg or os.environ.get("DCS_PATH")
    if value:
        return Path(value)
    path = _registry_dcs_path()
    if path is None:
        sys.exit("pass --dcs-path or set DCS_PATH to the DCS World install folder")
    print(f"using DCS World install at {path}", file=sys.stderr)
    return path


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        prog="terrain-geodata",
        description="Export DCS World terrain data from the game install as GIS files.",
    )
    sub = parser.add_subparsers(dest="command", required=True)

    p_list = sub.add_parser("list", help="List terrains found in the install")
    p_list.add_argument(
        "--dcs-path",
        help="DCS World install folder (default: DCS_PATH, then the registry)",
    )

    p_export = sub.add_parser("export", help="Export terrains")
    p_export.add_argument(
        "--dcs-path",
        help="DCS World install folder (default: DCS_PATH, then the registry)",
    )
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
    p_export.add_argument(
        "--elevation-resolution",
        type=float,
        default=1000.0,
        help="Elevation pixel size in metres (default: 1000)",
    )
    p_export.add_argument(
        "--jobs",
        type=int,
        default=os.process_cpu_count() or 1,
        help="Worker processes shared by all terrains (default: one per CPU)",
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
    started = time.monotonic()
    export.export_terrains(
        terrains,
        args.out,
        args.resolution,
        args.elevation_resolution,
        version,
        max(args.jobs, 1),
    )
    print(f"exported {len(terrains)} terrains in {time.monotonic() - started:.0f} s")


if __name__ == "__main__":
    main()

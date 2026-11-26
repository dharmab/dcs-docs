#!/usr/bin/env python3
# /// script
# requires-python = ">=3.12"
# dependencies = [
#     "humanize>=4.17.0",
#     "structlog>=26.1.0",
# ]
# ///
"""
Pack Operation Infinity mission source files into a .miz archive.

Usage:
    uv run pack_mission.py [--output OUTPUT_PATH]

The script reads from the src/ directory and produces a .miz file.
"""

import argparse
import sys
import zipfile
from pathlib import Path

import humanize
import structlog

log = structlog.get_logger()


def get_script_dir() -> Path:
    """Get the directory containing this script."""
    return Path(__file__).parent.resolve()


def validate_src_directory(src_dir: Path) -> list[str]:
    """
    Validate that all required source files exist.

    Returns:
        List of missing files (relative to src_dir).
    """
    required_files = [
        src_dir / "mission",
        src_dir / "theatre",
        src_dir / "warehouses",
        src_dir / "options",
        src_dir / "l10n" / "DEFAULT" / "dictionary",
        src_dir / "l10n" / "DEFAULT" / "mapResource",
        src_dir / "l10n" / "DEFAULT" / "Logging.lua",
        src_dir / "l10n" / "DEFAULT" / "Units.lua",
        src_dir / "l10n" / "DEFAULT" / "Spatial.lua",
        src_dir / "l10n" / "DEFAULT" / "BatchScheduler.lua",
        src_dir / "l10n" / "DEFAULT" / "TerrainData.lua",
        src_dir / "l10n" / "DEFAULT" / "Terrain.lua",
        src_dir / "l10n" / "DEFAULT" / "UnitTemplates.lua",
        src_dir / "l10n" / "DEFAULT" / "Formations.lua",
        src_dir / "l10n" / "DEFAULT" / "Virtualization.lua",
        src_dir / "l10n" / "DEFAULT" / "IADS.lua",
        src_dir / "l10n" / "DEFAULT" / "AirIntercept.lua",
        src_dir / "l10n" / "DEFAULT" / "BattlefieldGeneration.lua",
        src_dir / "l10n" / "DEFAULT" / "CarrierOps.lua",
        src_dir / "l10n" / "DEFAULT" / "OperationInfinity.lua",
    ]

    missing = []
    for path in required_files:
        if not path.exists():
            missing.append(str(path.relative_to(src_dir)))

    return missing


def pack_mission(output_path: Path | None = None) -> Path:
    """
    Pack mission source files into a MIZ archive.

    Args:
        output_path: Optional output path for the MIZ file.
                    Defaults to 'Operation Infinity.miz' in the script directory.

    Returns:
        Path to the created MIZ file.
    """
    script_dir = get_script_dir()
    src_dir = script_dir / "src"

    if output_path is None:
        output_path = script_dir / "Operation Infinity.miz"

    # Files at root level (relative to MIZ archive)
    root_files = [
        "mission",
        "theatre",
        "warehouses",
        "options",
    ]

    # l10n files (order matters for dependency loading)
    l10n_files = [
        "dictionary",
        "mapResource",
        "Logging.lua",
        "Units.lua",
        "Spatial.lua",
        "BatchScheduler.lua",
        "TerrainData.lua",
        "Terrain.lua",
        "UnitTemplates.lua",
        "Formations.lua",
        "Virtualization.lua",
        "IADS.lua",
        "AirIntercept.lua",
        "BattlefieldGeneration.lua",
        "CarrierOps.lua",
        "OperationInfinity.lua",
    ]

    log.info("packing mission", path=str(output_path))
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as miz:
        # Add root files
        for filename in root_files:
            src_path = src_dir / filename
            if src_path.exists():
                miz.write(src_path, filename)
            else:
                log.warning("skipping missing file", file=filename)

        # Add l10n files
        l10n_dir = src_dir / "l10n" / "DEFAULT"
        for filename in l10n_files:
            src_path = l10n_dir / filename
            archive_path = f"l10n/DEFAULT/{filename}"
            if src_path.exists():
                miz.write(src_path, archive_path)
            else:
                log.warning("skipping missing file", file=archive_path)

    log.info(
        "packed mission",
        path=str(output_path),
        size=humanize.naturalsize(output_path.stat().st_size),
    )
    return output_path


def list_contents(miz_path: Path) -> None:
    """List the contents of a MIZ file."""
    print(f"\nContents of {miz_path.name}:")
    print("-" * 40)
    with zipfile.ZipFile(miz_path, "r") as miz:
        for info in miz.infolist():
            compressed = info.compress_size
            uncompressed = info.file_size
            ratio = (1 - compressed / uncompressed) * 100 if uncompressed > 0 else 0
            print(
                f"  {info.filename:<40} {uncompressed:>8} bytes "
                f"({ratio:.0f}% compression)"
            )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Pack Operation Infinity mission files into a MIZ archive."
    )
    parser.add_argument(
        "--output",
        "-o",
        type=Path,
        help="Output path for the MIZ file (default: 'Operation Infinity.miz')",
    )
    parser.add_argument(
        "--validate",
        "-v",
        action="store_true",
        help="Validate source files without creating the archive",
    )
    parser.add_argument(
        "--list",
        "-l",
        action="store_true",
        help="List contents of the created archive",
    )

    args = parser.parse_args()

    script_dir = get_script_dir()
    src_dir = script_dir / "src"

    structlog.configure(logger_factory=structlog.PrintLoggerFactory(sys.stderr))

    if not src_dir.exists():
        log.error("source directory not found", path=str(src_dir))
        return 1

    log.info("validating source files", path=str(src_dir))
    missing = validate_src_directory(src_dir)

    if missing:
        log.warning("required files missing", files=missing)
        if args.validate:
            return 1
        log.info("packing available files despite missing files")
    else:
        log.info("all required files present")

    if args.validate:
        return 0

    try:
        output_path = pack_mission(args.output)
    except Exception:
        log.exception("packing failed")
        return 1

    if args.list:
        list_contents(output_path)
    return 0


if __name__ == "__main__":
    sys.exit(main())

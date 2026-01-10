#!/usr/bin/env python3
"""
Pack Operation Infinity mission source files into a .miz archive.

Usage:
    python pack_mission.py [--output OUTPUT_PATH]

The script reads from the src/ directory and produces a .miz file.
"""

import argparse
import os
import sys
import zipfile
from pathlib import Path


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
        src_dir / "l10n" / "DEFAULT" / "UnitTemplates.lua",
        src_dir / "l10n" / "DEFAULT" / "Virtualization.lua",
        src_dir / "l10n" / "DEFAULT" / "AirIntercept.lua",
        src_dir / "l10n" / "DEFAULT" / "IADS.lua",
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

    # l10n files
    l10n_files = [
        "dictionary",
        "mapResource",
        "UnitTemplates.lua",
        "Virtualization.lua",
        "AirIntercept.lua",
        "IADS.lua",
        "OperationInfinity.lua",
    ]

    # Create MIZ archive
    with zipfile.ZipFile(output_path, "w", zipfile.ZIP_DEFLATED) as miz:
        # Add root files
        for filename in root_files:
            src_path = src_dir / filename
            if src_path.exists():
                miz.write(src_path, filename)
                print(f"  Added: {filename}")
            else:
                print(f"  WARNING: Missing file: {filename}")

        # Add l10n files
        l10n_dir = src_dir / "l10n" / "DEFAULT"
        for filename in l10n_files:
            src_path = l10n_dir / filename
            archive_path = f"l10n/DEFAULT/{filename}"
            if src_path.exists():
                miz.write(src_path, archive_path)
                print(f"  Added: {archive_path}")
            else:
                print(f"  WARNING: Missing file: {archive_path}")

    print(f"\nCreated: {output_path}")
    print(f"Size: {output_path.stat().st_size / 1024:.1f} KB")
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
            print(f"  {info.filename:<40} {uncompressed:>8} bytes ({ratio:.0f}% compression)")


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

    print("Operation Infinity Mission Packer")
    print("=" * 40)

    # Validate source directory exists
    if not src_dir.exists():
        print(f"ERROR: Source directory not found: {src_dir}")
        return 1

    # Check for missing files
    missing = validate_src_directory(src_dir)

    if missing:
        print("\nMissing files:")
        for f in missing:
            print(f"  - {f}")

        if args.validate:
            return 1

        print("\nProceeding with available files...")
    else:
        print("All required files present.")

    if args.validate:
        print("\nValidation passed.")
        return 0

    print("\nPacking mission...")
    try:
        output_path = pack_mission(args.output)

        if args.list:
            list_contents(output_path)

        print("\nSuccess!")
        return 0
    except Exception as e:
        print(f"\nERROR: {e}")
        import traceback

        traceback.print_exc()
        return 1


if __name__ == "__main__":
    sys.exit(main())

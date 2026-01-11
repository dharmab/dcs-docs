"""Extract livery lists from DCS World installation.

Scans a DCS World installation directory for all aircraft liveries and generates
markdown documentation files listing available liveries for each aircraft type.
"""

import argparse
import re
import sys
from collections.abc import Generator
from dataclasses import dataclass, field
from pathlib import Path

# Windows-specific imports for registry access
if sys.platform == "win32":
    import winreg


@dataclass
class Livery:
    """Represents a single livery."""

    folder_name: str
    display_name: str | None
    path: Path


@dataclass
class LiveryEntry:
    """Liveries for a single livery entry (aircraft variant)."""

    name: str
    liveries: list[Livery] = field(default_factory=list)


def find_dcs_installation() -> Path | None:
    """Find DCS World installation directory.

    Checks Windows Registry first, then falls back to common installation paths.
    """
    # Try registry first (Windows only)
    if sys.platform == "win32":
        for key_path in [
            r"Software\Eagle Dynamics\DCS World",
            r"Software\Eagle Dynamics\DCS World OpenBeta",
        ]:
            try:
                with winreg.OpenKey(winreg.HKEY_CURRENT_USER, key_path) as key:
                    path_value, _ = winreg.QueryValueEx(key, "Path")
                    path = Path(path_value)
                    if path.exists():
                        return path
            except (FileNotFoundError, OSError):
                continue

    # Fall back to common paths
    common_paths = [
        Path("C:/Program Files/Eagle Dynamics/DCS World"),
        Path("C:/Program Files/Eagle Dynamics/DCS World OpenBeta"),
        Path("C:/DCS World"),
        Path("C:/DCS World OpenBeta"),
        Path("D:/DCS World"),
        Path("D:/DCS World OpenBeta"),
        Path("D:/Program Files/Eagle Dynamics/DCS World"),
        Path("D:/Program Files/Eagle Dynamics/DCS World OpenBeta"),
        Path("E:/DCS World"),
        Path("E:/DCS World OpenBeta"),
        Path("E:/Program Files/Eagle Dynamics/DCS World"),
        Path("E:/Program Files/Eagle Dynamics/DCS World OpenBeta"),
    ]

    for path in common_paths:
        if path.exists() and (path / "bin" / "DCS.exe").exists():
            return path

    return None


def find_livery_roots(dcs_root: Path) -> Generator[Path]:
    """Find all directories that contain livery folders.

    Yields paths like:
    - Bazar/Liveries/
    - CoreMods/aircraft/<module>/Liveries/
    - Mods/aircraft/<module>/Liveries/
    """
    # Bazar/Liveries
    bazar_liveries = dcs_root / "Bazar" / "Liveries"
    if bazar_liveries.exists():
        yield bazar_liveries

    # CoreMods/aircraft/*/Liveries
    coremods_aircraft = dcs_root / "CoreMods" / "aircraft"
    if coremods_aircraft.exists():
        for module_dir in coremods_aircraft.iterdir():
            if module_dir.is_dir():
                liveries_path = module_dir / "Liveries"
                if liveries_path.exists():
                    yield liveries_path

    # Mods/aircraft/*/Liveries
    mods_aircraft = dcs_root / "Mods" / "aircraft"
    if mods_aircraft.exists():
        for module_dir in mods_aircraft.iterdir():
            if module_dir.is_dir():
                liveries_path = module_dir / "Liveries"
                if liveries_path.exists():
                    yield liveries_path


def extract_livery_name(content: str) -> str | None:
    """Extract the name field from description.lua content."""
    # Match: name = "..." or name = '...'
    # Handle multiline and various whitespace
    match = re.search(r'^\s*name\s*=\s*["\'](.+?)["\']\s*$', content, re.MULTILINE)
    if match:
        return match.group(1)
    return None


def iter_liveries(livery_entry_dir: Path) -> Generator[Livery]:
    """Iterate over all liveries in a livery entry directory."""
    if not livery_entry_dir.exists():
        return

    for livery_dir in livery_entry_dir.iterdir():
        if not livery_dir.is_dir():
            continue

        description_file = livery_dir / "description.lua"
        display_name = None

        if description_file.exists():
            try:
                content = description_file.read_text(
                    encoding="utf-8", errors="replace"
                )
                display_name = extract_livery_name(content)
            except OSError:
                pass

        yield Livery(
            folder_name=livery_dir.name,
            display_name=display_name,
            path=livery_dir,
        )


def collect_all_liveries(dcs_root: Path) -> dict[str, LiveryEntry]:
    """Collect liveries for all aircraft from all livery locations.

    Returns a dict mapping livery entry name to LiveryEntry object.
    Liveries from multiple locations are merged.
    """
    entries: dict[str, LiveryEntry] = {}

    for livery_root in find_livery_roots(dcs_root):
        # Each subdirectory in a livery root is a livery entry (aircraft variant)
        for entry_dir in livery_root.iterdir():
            if not entry_dir.is_dir():
                continue

            entry_name = entry_dir.name

            if entry_name not in entries:
                entries[entry_name] = LiveryEntry(name=entry_name)

            # Add liveries from this location
            entry = entries[entry_name]
            existing_folders = {lv.folder_name for lv in entry.liveries}
            for livery in iter_liveries(entry_dir):
                # Avoid duplicates by folder name
                if livery.folder_name not in existing_folders:
                    entry.liveries.append(livery)
                    existing_folders.add(livery.folder_name)

    return entries


def generate_markdown_for_entry(entry: LiveryEntry) -> str:
    """Generate markdown content for a single livery entry."""
    lines = [
        f"# {entry.name} Liveries",
        "",
        "| Folder Name | Display Name |",
        "|-------------|--------------|",
    ]

    # Sort liveries by folder name
    sorted_liveries = sorted(entry.liveries, key=lambda lv: lv.folder_name.lower())

    for livery in sorted_liveries:
        display = livery.display_name if livery.display_name else ""
        # Escape pipe characters in names
        folder = livery.folder_name.replace("|", "\\|")
        display = display.replace("|", "\\|")
        lines.append(f"| {folder} | {display} |")

    lines.append("")
    return "\n".join(lines)


def generate_index_markdown(entries: dict[str, LiveryEntry]) -> str:
    """Generate markdown content for the index file."""
    lines = [
        "# DCS World Aircraft Liveries",
        "",
        "| Livery Entry | Livery Count |",
        "|--------------|--------------|",
    ]

    # Sort entries alphabetically
    for entry_name in sorted(entries.keys(), key=str.lower):
        entry = entries[entry_name]
        filename = entry_name.lower().replace(" ", "-") + ".md"
        lines.append(f"| [{entry_name}]({filename}) | {len(entry.liveries)} |")

    lines.append("")
    return "\n".join(lines)


def sanitize_filename(name: str) -> str:
    """Convert a livery entry name to a safe filename."""
    # Convert to lowercase and replace spaces with hyphens
    filename = name.lower().replace(" ", "-")
    # Remove or replace problematic characters
    filename = re.sub(r'[<>:"/\\|?*]', "", filename)
    return filename + ".md"


def write_output(entries: dict[str, LiveryEntry], output_dir: Path) -> None:
    """Write markdown files for all livery entries."""
    output_dir.mkdir(parents=True, exist_ok=True)

    # Write index
    index_content = generate_index_markdown(entries)
    (output_dir / "README.md").write_text(index_content, encoding="utf-8")
    print(f"Wrote index: {output_dir / 'README.md'}")

    # Write individual entry files
    for entry_name, entry in entries.items():
        if not entry.liveries:
            continue

        filename = sanitize_filename(entry_name)
        content = generate_markdown_for_entry(entry)
        filepath = output_dir / filename
        filepath.write_text(content, encoding="utf-8")
        print(f"Wrote: {filepath} ({len(entry.liveries)} liveries)")


def main() -> int:
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="Extract livery lists from DCS World installation"
    )
    parser.add_argument(
        "--dcs-root",
        type=Path,
        help="Path to DCS World installation (auto-detected if not specified)",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("docs/liveries"),
        help="Output directory for markdown files (default: docs/liveries)",
    )

    args = parser.parse_args()

    # Find DCS installation
    if args.dcs_root:
        dcs_root = args.dcs_root
        if not dcs_root.exists():
            print(f"Error: Specified DCS root does not exist: {dcs_root}")
            return 1
    else:
        dcs_root = find_dcs_installation()
        if dcs_root is None:
            print("Error: Could not find DCS World installation.")
            print("Please specify the path with --dcs-root")
            return 1

    print(f"DCS installation: {dcs_root}")

    # Collect all liveries
    entries = collect_all_liveries(dcs_root)
    print(f"Found {len(entries)} livery entries")

    # Write output
    write_output(entries, args.output_dir)

    print(f"\nDone! Generated {len(entries)} livery files in {args.output_dir}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

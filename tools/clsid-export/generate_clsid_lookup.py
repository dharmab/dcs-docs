"""Generate CLSID lookup table from DCS Lua datamine."""

import json
import re
import subprocess
import sys
import tempfile
from collections.abc import Generator
from datetime import UTC, datetime
from pathlib import Path

import luadata


def clone_datamine(temp_dir: Path) -> Path:
    """Clone the DCS Lua datamine repository into a temporary directory."""
    repo_url = "https://github.com/Quaggles/dcs-lua-datamine.git"
    repo_path = temp_dir / "dcs-lua-datamine"

    print(f"Cloning {repo_url}...")
    subprocess.run(
        ["git", "clone", "--depth", "1", repo_url, str(repo_path)],
        check=True,
        capture_output=True,
    )
    print("Clone complete.")
    return repo_path


def get_dcs_version(repo_path: Path) -> str | None:
    """Extract DCS version from the datamine."""
    version_file = repo_path / "_G" / "__DCS_VERSION__.lua"
    if not version_file.exists():
        return None

    # The file just contains the version number directly
    content = version_file.read_text().strip()
    return content if content else None


def iter_launcher_files(repo_path: Path) -> Generator[Path]:
    """Iterate over all launcher Lua files."""
    launcher_dir = repo_path / "_G" / "launcher"
    if not launcher_dir.exists():
        print(f"Warning: launcher directory not found at {launcher_dir}")
        return

    yield from launcher_dir.glob("*.lua")


def extract_table_from_assignment(content: str) -> str | None:
    """Extract the table portion from a Lua assignment statement.

    Given content like: _G["launcher"]["{CLSID}"] = { ... }
    Returns just the table: { ... }
    """
    # Find the first '=' which separates the assignment target from the value
    eq_idx = content.find("=")
    if eq_idx == -1:
        return None

    # Everything after the '=' is the table value
    table_part = content[eq_idx + 1 :].strip()
    return table_part if table_part else None


def preprocess_lua_content(content: str) -> str:
    """Preprocess Lua content to handle non-standard syntax.

    The datamine contains some patterns that luadata can't parse:
    1. Table reference markers like <1>, <2>, <table 1> - these are serialization
       artifacts and should be removed
    2. Scientific notation like 2e-05 or -1e-05 - replace with decimal

    Args:
        content: Raw Lua table content

    Returns:
        Preprocessed content that luadata can parse
    """
    # Remove table reference markers: <1>, <2>, <table 1>, etc.
    # These appear as: attribute = <1>{ ... } or wsTypeOfWeapon = <table 1>
    content = re.sub(r"<\d+>", "", content)
    content = re.sub(r"<table \d+>", "", content)

    # Convert scientific notation to decimal
    # Match patterns like 2e-05, -1e-05, 1.5e+10, 3e10
    # luadata doesn't parse scientific notation, so convert to decimal format
    def convert_scientific(match: re.Match[str]) -> str:
        try:
            val = float(match.group(0))
            # Use fixed-point notation to avoid scientific notation in output
            return f"{val:f}"
        except ValueError:
            return match.group(0)

    content = re.sub(r"-?\d+\.?\d*[eE][+-]?\d+", convert_scientific, content)

    return content


def parse_launcher_file(file_path: Path) -> dict | None:
    """Parse a launcher Lua file and extract weapon data.

    Returns a dict with CLSID, displayName, category, and origin fields,
    or None if parsing fails.
    """
    try:
        content = file_path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        print(f"Warning: Could not read {file_path}: {e}")
        return None

    # Extract just the table portion from the assignment
    table_str = extract_table_from_assignment(content)
    if table_str is None:
        return None

    # Preprocess to handle non-standard syntax
    table_str = preprocess_lua_content(table_str)

    # Parse the Lua table using luadata
    try:
        data = luadata.unserialize(table_str)
    except Exception as e:
        print(f"Warning: Could not parse {file_path.name}: {e}")
        return None

    if not isinstance(data, dict):
        return None

    # Extract the fields we need
    result: dict = {}

    clsid = data.get("CLSID")
    if not clsid:
        return None  # CLSID is required

    result["CLSID"] = clsid

    if "displayName" in data:
        result["displayName"] = data["displayName"]

    if "category" in data:
        result["category"] = data["category"]

    if "_origin" in data:
        result["origin"] = data["_origin"]

    return result


def build_lookup_data(repo_path: Path) -> dict:
    """Build the CLSID lookup data structure."""
    by_clsid: dict[str, dict] = {}
    by_display_name: dict[str, list[str]] = {}

    file_count = 0
    parsed_count = 0

    for lua_file in iter_launcher_files(repo_path):
        file_count += 1
        data = parse_launcher_file(lua_file)

        if data is None:
            continue

        parsed_count += 1
        clsid = data["CLSID"]

        # Build by_clsid entry
        entry: dict = {}
        if "displayName" in data:
            entry["displayName"] = data["displayName"]
        else:
            entry["displayName"] = None

        if "category" in data:
            entry["category"] = data["category"]
        else:
            entry["category"] = None

        if "origin" in data:
            entry["origin"] = data["origin"]

        by_clsid[clsid] = entry

        # Build by_display_name index (skip if no displayName)
        if "displayName" in data:
            display_name = data["displayName"]
            if display_name not in by_display_name:
                by_display_name[display_name] = []
            by_display_name[display_name].append(clsid)

    print(f"Processed {file_count} files, parsed {parsed_count} entries.")
    return {
        "by_clsid": by_clsid,
        "by_display_name": by_display_name,
    }


def main() -> int:
    """Main entry point."""
    # Determine output path
    script_dir = Path(__file__).parent
    output_dir = script_dir.parent.parent / "docs" / "data"
    output_file = output_dir / "clsid-lookup.json"

    # Create output directory if needed
    output_dir.mkdir(parents=True, exist_ok=True)

    with tempfile.TemporaryDirectory() as temp_dir:
        temp_path = Path(temp_dir)

        # Clone the datamine
        try:
            repo_path = clone_datamine(temp_path)
        except subprocess.CalledProcessError as e:
            print(f"Error cloning repository: {e}")
            return 1

        # Get DCS version
        dcs_version = get_dcs_version(repo_path)

        # Build lookup data
        lookup_data = build_lookup_data(repo_path)

    # Extract lookup tables
    by_clsid: dict[str, dict] = lookup_data["by_clsid"]
    by_display_name: dict[str, list[str]] = lookup_data["by_display_name"]

    # Add metadata
    output = {
        "version": "1.0.0",
        "dcs_version": dcs_version,
        "generated": datetime.now(UTC).isoformat(),
        "by_clsid": by_clsid,
        "by_display_name": by_display_name,
    }

    # Write output
    with open(output_file, "w", encoding="utf-8") as f:
        json.dump(output, f, indent=2, ensure_ascii=False)

    print(f"Wrote {len(by_clsid)} entries to {output_file}")
    return 0


if __name__ == "__main__":
    sys.exit(main())

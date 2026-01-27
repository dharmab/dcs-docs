#!/usr/bin/env python3
"""
Split planes.md into individual aircraft files.

This script parses the monolithic planes.md file and extracts each aircraft
section into its own markdown file in the planes/ directory.
"""

import re
from pathlib import Path


def build_filename_map(index_path: Path) -> dict[str, str]:
    """
    Build a mapping from aircraft name to filename by parsing index.md links.

    Returns dict like {"A-10A": "a-10a.md", "F/A-18C Lot 20": "fa-18c-lot-20.md"}
    """
    content = index_path.read_text()
    mapping = {}

    # Match patterns like [A-10A](a-10a.md) in table rows
    pattern = r'\[([^\]]+)\]\(([^)]+\.md)\)'
    for match in re.finditer(pattern, content):
        aircraft_name = match.group(1)
        filename = match.group(2)
        mapping[aircraft_name] = filename

    return mapping


def extract_aircraft_sections(planes_path: Path) -> dict[str, str]:
    """
    Parse planes.md and extract each aircraft section.

    Returns dict mapping aircraft name to its content (still with original heading levels).
    """
    content = planes_path.read_text()

    # Split on horizontal rules followed by aircraft headers
    # Each aircraft section starts with "## Aircraft Name"
    sections = {}

    # Find all aircraft section starts (## at start of line, not ### or ####)
    # Skip the TOC and intro (before first ---)

    # First, find where aircraft content begins (after TOC)
    toc_end = content.find("\n---\n")
    if toc_end == -1:
        print("Could not find TOC separator")
        return {}

    aircraft_content = content[toc_end + 5:]  # Skip past the first ---

    # Split into sections by finding ## headers (not ### or ####)
    # Use regex to split on "\n## " but keep the delimiter with the following section
    parts = re.split(r'\n(?=## [^#])', aircraft_content)

    for part in parts:
        part = part.strip()
        if not part:
            continue

        # Remove trailing --- separator if present
        if part.endswith("---"):
            part = part[:-3].rstrip()

        # Extract aircraft name from first line
        first_line = part.split('\n')[0]
        if first_line.startswith("## "):
            aircraft_name = first_line[3:].strip()
            sections[aircraft_name] = part

    return sections


def transform_headings(content: str) -> str:
    """
    Promote heading levels by one:
    - ## -> #
    - ### -> ##
    - #### -> ###
    """
    lines = content.split('\n')
    result = []

    for line in lines:
        if line.startswith("#### "):
            result.append("### " + line[5:])
        elif line.startswith("### "):
            result.append("## " + line[4:])
        elif line.startswith("## "):
            result.append("# " + line[3:])
        else:
            result.append(line)

    return '\n'.join(result)


def main():
    # Set up paths
    script_dir = Path(__file__).parent
    repo_root = script_dir.parent
    planes_md = repo_root / "docs" / "units" / "planes.md"
    planes_dir = repo_root / "docs" / "units" / "planes"
    index_md = planes_dir / "index.md"

    # Build filename mapping from index.md
    print("Reading index.md for filename mappings...")
    filename_map = build_filename_map(index_md)
    print(f"Found {len(filename_map)} aircraft in index")

    # Extract aircraft sections from planes.md
    print("Parsing planes.md...")
    sections = extract_aircraft_sections(planes_md)
    print(f"Found {len(sections)} aircraft sections")

    # Track already existing files to skip
    existing_files = {"a-10a.md", "a-50.md", "f-15c.md", "index.md"}

    # Process each aircraft
    created = 0
    skipped = 0
    errors = []

    for aircraft_name, content in sections.items():
        # Look up filename
        if aircraft_name not in filename_map:
            errors.append(f"No filename mapping for: {aircraft_name}")
            continue

        filename = filename_map[aircraft_name]

        # Skip already existing files
        if filename in existing_files:
            print(f"Skipping existing: {filename}")
            skipped += 1
            continue

        # Transform heading levels
        transformed = transform_headings(content)

        # Ensure trailing newline
        if not transformed.endswith('\n'):
            transformed += '\n'

        # Write file
        output_path = planes_dir / filename
        output_path.write_text(transformed)
        print(f"Created: {filename}")
        created += 1

    # Summary
    print(f"\nSummary:")
    print(f"  Created: {created}")
    print(f"  Skipped (existing): {skipped}")
    print(f"  Errors: {len(errors)}")

    if errors:
        print("\nErrors:")
        for error in errors:
            print(f"  - {error}")


if __name__ == "__main__":
    main()

# DCS World Agent Documentation

This repository contains documentation for AI agents to use as context when generating tools and content for the flight simulator "DCS World".

## Directory Structure

- `pdf/` - PDF manuals for older versions of DCS World. These should be only partially trusted as the simulator has changed significantly since these were created.
- `data/` - Outputs from dataminers. These can be more accurately trusted since they are regularly updated with new simulator versions.
- `docs/` - Generated markdown documentation. All documentation output should be placed here.

## Trust Hierarchy

When information conflicts between sources:

1. **Most trusted:** `data/` - Datamined information from current simulator versions
2. **Less trusted:** `pdf/` - Legacy PDF manuals that may contain outdated information

## Generating Documentation

When creating new documentation:

1. Place all generated markdown files in the `docs/` directory
2. Cross-reference datamined data in `data/` for accuracy
3. Use PDF manuals in `pdf/` as supplementary context, but verify against datamined sources when possible
4. Note any discrepancies between sources in the documentation

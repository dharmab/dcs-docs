# Documentation Roadmap

This roadmap tracks planned documentation improvements to better support AI-assisted mission generation.

## Phase 1: Map and Terrain Data

Create `docs/maps/` directory with theatre-specific documentation. Each file should include:

- Airfield locations with coordinates (lat/lon and DCS internal)
- Runway headings and lengths
- Parking positions and capacities
- Navigation aids (TACAN channels, ILS frequencies, NDB)
- Key geographic features and strategic locations
- Approximate map boundaries

### Files

- [ ] `docs/maps/caucasus.md`
- [ ] `docs/maps/nevada.md`
- [ ] `docs/maps/syria.md`
- [ ] `docs/maps/germany.md`

## Phase 2: Radio and Communications Reference

Create standard frequency allocation reference for AI to auto-configure radio presets.

### Content

- Standard frequency allocations (ATC, AWACS, tankers, JTAC)
- Preset channel conventions
- TACAN channel assignments for tankers and carriers
- IFF/datalink settings

### Files

- [ ] `docs/mission/radio-frequencies.md`

## Phase 3: Faction Naval Units

Expand faction files to include naval units for carrier operations and naval scenarios. Reference `docs/units/sea.md` for available ship types.

### Files to Modify

- [ ] `docs/factions/isaf-2004.md` - Add Naval Units section
- [ ] `docs/factions/erusea-2004.md` - Add Naval Units section
- [ ] `docs/factions/isaf-2005.md` - Add Naval Units section
- [ ] `docs/factions/erusea-2005.md` - Add Naval Units section
- [ ] `docs/factions/osea-2010.md` - Add Naval Units section
- [ ] `docs/factions/yuktobania-2010.md` - Add Naval Units section
- [ ] `docs/factions/belka-1995.md` - Add Naval Units section
- [ ] `docs/factions/allied-forces-1995.md` - Add Naval Units section

## Phase 4: Additional Recipes

Create new recipes covering both Lua file editing and SSE scripting approaches where applicable.

### Files

- [ ] `docs/recipes/cap-setup.md` - AI fighter patrol configuration with tasking and ROE
- [ ] `docs/recipes/jtac-setup.md` - Forward air controller placement and laser codes
- [ ] `docs/recipes/convoy-route.md` - Ground unit routes and waypoints
- [ ] `docs/recipes/weather-time.md` - Season, cloud layers, visibility settings
- [ ] `docs/recipes/trigger-patterns.md` - Common trigger patterns (zone entry, unit destruction, time-based)

## Phase 5: Route and Waypoint Patterns

Document standard route patterns for AI to generate realistic flight plans.

### Content

- Tanker orbit patterns (anchor points, racetrack dimensions)
- CAP racetrack parameters
- Standard ingress/egress profiles
- Holding patterns
- Attack profiles (pop-up, loft, dive)

### Files

- [ ] `docs/recipes/route-patterns.md`

## Phase 6: Livery Reference

Document available unit liveries for visual consistency within factions.

### Files

- [ ] `docs/units/liveries.md`

## Maintenance

After completing each phase, update `CLAUDE.md` to reflect new documentation in the Available Documentation section.

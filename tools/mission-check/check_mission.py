"""Validate a DCS mission directory or .miz file."""

from __future__ import annotations

import argparse
import os
import sys
import tempfile
import zipfile
from collections.abc import Generator
from pathlib import Path
from typing import Any

import luadata

# ---------------------------------------------------------------------------
# Diagnostic collector
# ---------------------------------------------------------------------------


class DiagnosticCollector:
    """Accumulates validation failures with logical path context."""

    def __init__(self) -> None:
        self.issues: list[tuple[str, str]] = []

    def fail(self, path: str, message: str) -> None:
        self.issues.append((path, message))

    def has_failures(self) -> bool:
        return len(self.issues) > 0

    def print_report(self) -> None:
        for path, message in self.issues:
            print(f"  {path}: {message}")
        count = len(self.issues)
        if count:
            print(f"\n{count} error{'s' if count != 1 else ''} found")
        else:
            print("No errors found")


# ---------------------------------------------------------------------------
# Lua parsing helpers
# ---------------------------------------------------------------------------


def parse_lua_assignment(content: str) -> dict[str, Any] | list[Any]:
    """Parse a DCS Lua file that uses assignment format (e.g. ``mission = { ... }``)."""
    idx = content.index("{")
    raw = content[idx:]
    return luadata.unserialize(raw)


# ---------------------------------------------------------------------------
# Edit-distance / suggestion helpers
# ---------------------------------------------------------------------------


def edit_distance(a: str, b: str) -> int:
    """Compute Levenshtein distance between two strings."""
    if len(a) < len(b):
        return edit_distance(b, a)
    if not b:
        return len(a)
    prev = list(range(len(b) + 1))
    for i, ca in enumerate(a):
        curr = [i + 1]
        for j, cb in enumerate(b):
            cost = 0 if ca == cb else 1
            curr.append(min(curr[j] + 1, prev[j + 1] + 1, prev[j] + cost))
        prev = curr
    return prev[-1]


def suggest_field(unknown: str, known: set[str]) -> str | None:
    """Return the closest known field name if edit distance is small enough."""
    best: str | None = None
    best_dist = float("inf")
    for k in sorted(known):
        d = edit_distance(unknown.lower(), k.lower())
        if d < best_dist:
            best_dist = d
            best = k
    threshold = max(3, len(unknown) // 3 + 1)
    if best is not None and best_dist <= threshold:
        return best
    return None


# ---------------------------------------------------------------------------
# Iteration helpers
# ---------------------------------------------------------------------------

UNIT_CATEGORIES = ("plane", "helicopter", "vehicle", "ship", "static")
AIRCRAFT_CATEGORIES = ("plane", "helicopter")


def _items(obj: Any) -> Generator[tuple[Any, Any]]:
    """Yield (key, value) pairs from a dict or (index, value) from a list."""
    if isinstance(obj, dict):
        yield from obj.items()
    elif isinstance(obj, list):
        yield from enumerate(obj)


def iter_groups(
    mission: dict[str, Any],
) -> Generator[tuple[str, str, int, int, str, dict[str, Any]]]:
    """Yield (side, category, country_idx, group_idx, path, group) for every group."""
    coalition = mission.get("coalition", {})
    for side in ("blue", "red", "neutrals"):
        side_data = coalition.get(side)
        if not isinstance(side_data, dict):
            continue
        countries = side_data.get("country")
        if countries is None:
            continue
        for ci, country in _items(countries):
            for category in UNIT_CATEGORIES:
                cat_data = country.get(category) if isinstance(country, dict) else None
                if not isinstance(cat_data, dict):
                    continue
                groups = cat_data.get("group")
                if groups is None:
                    continue
                for gi, group in _items(groups):
                    if not isinstance(group, dict):
                        continue
                    path = f"coalition.{side}.country[{ci}].{category}.group[{gi}]"
                    yield side, category, ci, gi, path, group


# ---------------------------------------------------------------------------
# 1. File existence and parseability
# ---------------------------------------------------------------------------

REQUIRED_FILES = [
    "mission",
    "warehouses",
    "options",
    "theatre",
    os.path.join("l10n", "DEFAULT", "dictionary"),
    os.path.join("l10n", "DEFAULT", "mapResource"),
]


def check_files(
    mission_dir: Path, diag: DiagnosticCollector
) -> dict[str, Any]:
    """Check required files exist and parse, returning parsed data keyed by filename."""
    parsed: dict[str, Any] = {}
    for rel in REQUIRED_FILES:
        fpath = mission_dir / rel
        if not fpath.is_file():
            diag.fail(rel, "required file is missing")
            continue
        content = fpath.read_text(encoding="utf-8", errors="replace")
        if rel == "theatre":
            parsed[rel] = content.strip()
            continue
        try:
            parsed[rel] = parse_lua_assignment(content)
        except Exception as exc:
            diag.fail(rel, f"failed to parse Lua: {exc}")
    return parsed


# ---------------------------------------------------------------------------
# 2. Mission top-level schema
# ---------------------------------------------------------------------------

MISSION_REQUIRED_KEYS = {
    "theatre",
    "version",
    "currentKey",
    "maxDictId",
    "start_time",
    "date",
    "sortie",
    "descriptionText",
    "descriptionBlueTask",
    "descriptionRedTask",
    "descriptionNeutralsTask",
    "map",
    "coalitions",
    "weather",
    "forcedOptions",
    "groundControl",
    "coalition",
}


def check_mission_schema(
    mission: dict[str, Any], theatre_text: str, diag: DiagnosticCollector
) -> None:
    for key in sorted(MISSION_REQUIRED_KEYS):
        if key not in mission:
            diag.fail("mission", f"missing required key '{key}'")

    date = mission.get("date")
    if isinstance(date, dict):
        for dk in ("Year", "Month", "Day"):
            if dk not in date:
                diag.fail("mission.date", f"missing required key '{dk}'")

    coalitions = mission.get("coalitions")
    if isinstance(coalitions, dict):
        for ck in ("blue", "red", "neutrals"):
            if ck not in coalitions:
                diag.fail("mission.coalitions", f"missing required key '{ck}'")

    coalition = mission.get("coalition")
    if isinstance(coalition, dict):
        for ck in ("blue", "red"):
            side = coalition.get(ck)
            if not isinstance(side, dict):
                diag.fail(f"mission.coalition.{ck}", "missing or not a table")
            elif "country" not in side:
                diag.fail(f"mission.coalition.{ck}", "missing 'country' table")

    mission_theatre = mission.get("theatre")
    if isinstance(mission_theatre, str) and mission_theatre != theatre_text:
        diag.fail(
            "mission.theatre",
            f"value '{mission_theatre}' does not match theatre file '{theatre_text}'",
        )


# ---------------------------------------------------------------------------
# 3. Warehouse schema
# ---------------------------------------------------------------------------

KNOWN_WAREHOUSE_FIELDS: set[str] = {
    "coalition",
    "dynamicSpawn",
    "allowHotStart",
    "supplier",
    "unlimitedAircrafts",
    "unlimitedFuel",
    "unlimitedMunitions",
    "OperatingLevel_Air",
    "OperatingLevel_Eqp",
    "OperatingLevel_Fuel",
    "speed",
    "periodicity",
    "size",
    "suppliers",
    "dynamicCargo",
    "aircrafts",
    "weapons",
    "gasoline",
    "methanol_mixture",
    "diesel",
    "jet_fuel",
}


def check_warehouse_schema(
    warehouses: dict[str, Any], diag: DiagnosticCollector
) -> set[int]:
    """Validate warehouse airports. Returns the set of known airport IDs."""
    airport_ids: set[int] = set()
    airports = warehouses.get("airports") if isinstance(warehouses, dict) else None
    if not isinstance(airports, dict):
        diag.fail("warehouses", "missing or invalid 'airports' table")
        return airport_ids

    for aid, airport in airports.items():
        if isinstance(aid, int):
            airport_ids.add(aid)
        path = f"warehouses.airports[{aid}]"
        if not isinstance(airport, dict):
            diag.fail(path, "airport entry is not a table")
            continue

        if "coalition" not in airport:
            diag.fail(path, "missing required field 'coalition'")

        for field in sorted(airport.keys()):
            if field not in KNOWN_WAREHOUSE_FIELDS:
                suggestion = suggest_field(field, KNOWN_WAREHOUSE_FIELDS)
                msg = f"unknown field '{field}'"
                if suggestion:
                    msg += f" (did you mean '{suggestion}'?)"
                diag.fail(path, msg)

    return airport_ids


# ---------------------------------------------------------------------------
# 4. Group and unit field validation
# ---------------------------------------------------------------------------

REQUIRED_GROUP_FIELDS = {"groupId", "name", "units", "route", "x", "y"}
AIRCRAFT_GROUP_FIELDS = {"task", "uncontrolled"}

REQUIRED_UNIT_FIELDS = {"unitId", "name", "type", "skill", "x", "y", "heading"}
AIRCRAFT_UNIT_FIELDS = {"alt", "alt_type", "speed", "psi", "payload"}


def check_groups_and_units(
    mission: dict[str, Any], diag: DiagnosticCollector
) -> None:
    for _side, category, _ci, _gi, path, group in iter_groups(mission):
        required = set(REQUIRED_GROUP_FIELDS)
        if category in AIRCRAFT_CATEGORIES:
            required |= AIRCRAFT_GROUP_FIELDS
        for field in sorted(required):
            if field not in group:
                diag.fail(path, f"missing required group field '{field}'")

        units = group.get("units")
        if units is None:
            continue
        for ui, unit in _items(units):
            if not isinstance(unit, dict):
                continue
            upath = f"{path}.units[{ui}]"
            ureq = set(REQUIRED_UNIT_FIELDS)
            if category in AIRCRAFT_CATEGORIES:
                ureq |= AIRCRAFT_UNIT_FIELDS
            for field in sorted(ureq):
                if field not in unit:
                    diag.fail(upath, f"missing required unit field '{field}'")


# ---------------------------------------------------------------------------
# 5. DynSpawnTemplate checks
# ---------------------------------------------------------------------------


def _coalition_label(side: str) -> str:
    """Map coalition side name to the label used in warehouse entries."""
    return side.upper()


def check_dyn_spawn_templates(
    mission: dict[str, Any],
    warehouses: dict[str, Any],
    diag: DiagnosticCollector,
) -> None:
    airports = (
        warehouses.get("airports")
        if isinstance(warehouses, dict)
        else None
    )
    if not isinstance(airports, dict):
        airports = {}

    for side, _category, _ci, _gi, path, group in iter_groups(mission):
        if not group.get("dynSpawnTemplate"):
            continue

        if not group.get("lateActivation"):
            diag.fail(path, "dynSpawnTemplate group must have lateActivation = true")

        units = group.get("units")
        if units is not None:
            for ui, unit in _items(units):
                if not isinstance(unit, dict):
                    continue
                if unit.get("skill") != "Client":
                    diag.fail(
                        f"{path}.units[{ui}]",
                        f"dynSpawnTemplate unit must have skill = 'Client', "
                        f"got '{unit.get('skill')}'",
                    )

        route = group.get("route")
        if not isinstance(route, dict):
            continue
        points = route.get("points")
        if not points:
            continue
        first_wp: dict[str, Any] | None = None
        for _, wp in _items(points):
            first_wp = wp if isinstance(wp, dict) else None
            break
        if first_wp is None:
            continue

        adrome_id = first_wp.get("airdromeId")
        if adrome_id is None:
            continue

        airport = airports.get(adrome_id)
        if airport is None:
            diag.fail(
                path,
                f"first waypoint airdromeId {adrome_id} not found in warehouses",
            )
            continue

        if not isinstance(airport, dict):
            continue

        if not airport.get("dynamicSpawn"):
            diag.fail(
                path,
                f"warehouse airport {adrome_id} must have dynamicSpawn = true "
                f"for dynSpawnTemplate group",
            )

        ap_coalition = airport.get("coalition", "")
        expected = _coalition_label(side)
        if isinstance(ap_coalition, str) and ap_coalition.upper() != expected:
            diag.fail(
                path,
                f"warehouse airport {adrome_id} coalition '{ap_coalition}' "
                f"does not match group coalition '{side}'",
            )


# ---------------------------------------------------------------------------
# 6. ID uniqueness
# ---------------------------------------------------------------------------


def check_id_uniqueness(
    mission: dict[str, Any], diag: DiagnosticCollector
) -> None:
    group_ids: dict[int, str] = {}
    unit_ids: dict[int, str] = {}
    group_names: dict[str, str] = {}
    unit_names: dict[str, str] = {}

    for _side, _cat, _ci, _gi, path, group in iter_groups(mission):
        gid = group.get("groupId")
        if isinstance(gid, int):
            if gid in group_ids:
                diag.fail(
                    path,
                    f"duplicate groupId {gid} (first seen at {group_ids[gid]})",
                )
            else:
                group_ids[gid] = path

        gname = group.get("name")
        if isinstance(gname, str):
            if gname in group_names:
                diag.fail(
                    path,
                    f"duplicate group name '{gname}' "
                    f"(first seen at {group_names[gname]})",
                )
            else:
                group_names[gname] = path

        units = group.get("units")
        if units is None:
            continue
        for ui, unit in _items(units):
            if not isinstance(unit, dict):
                continue
            upath = f"{path}.units[{ui}]"

            uid = unit.get("unitId")
            if isinstance(uid, int):
                if uid in unit_ids:
                    diag.fail(
                        upath,
                        f"duplicate unitId {uid} (first seen at {unit_ids[uid]})",
                    )
                else:
                    unit_ids[uid] = upath

            uname = unit.get("name")
            if isinstance(uname, str):
                if uname in unit_names:
                    diag.fail(
                        upath,
                        f"duplicate unit name '{uname}' "
                        f"(first seen at {unit_names[uname]})",
                    )
                else:
                    unit_names[uname] = upath


# ---------------------------------------------------------------------------
# 7. Airfield ID consistency
# ---------------------------------------------------------------------------


def check_airfield_consistency(
    mission: dict[str, Any],
    warehouse_ids: set[int],
    diag: DiagnosticCollector,
) -> None:
    for _side, _cat, _ci, _gi, path, group in iter_groups(mission):
        route = group.get("route")
        if not isinstance(route, dict):
            continue
        points = route.get("points")
        if not points:
            continue
        for wi, wp in _items(points):
            if not isinstance(wp, dict):
                continue
            adrome_id = wp.get("airdromeId")
            if adrome_id is not None and adrome_id not in warehouse_ids:
                diag.fail(
                    f"{path}.route.points[{wi}]",
                    f"airdromeId {adrome_id} not found in warehouse airports",
                )


# ---------------------------------------------------------------------------
# CLI entry point
# ---------------------------------------------------------------------------


def run_checks(mission_dir: Path) -> int:
    """Run all validation checks on the given mission directory. Returns exit code."""
    diag = DiagnosticCollector()

    parsed = check_files(mission_dir, diag)

    mission_data = parsed.get("mission")
    warehouses_data = parsed.get("warehouses")
    theatre_text = parsed.get("theatre", "")

    if isinstance(mission_data, dict):
        check_mission_schema(mission_data, theatre_text, diag)

    warehouse_ids: set[int] = set()
    if isinstance(warehouses_data, dict):
        warehouse_ids = check_warehouse_schema(warehouses_data, diag)

    if isinstance(mission_data, dict):
        check_groups_and_units(mission_data, diag)
        if isinstance(warehouses_data, dict):
            check_dyn_spawn_templates(mission_data, warehouses_data, diag)
        check_id_uniqueness(mission_data, diag)
        check_airfield_consistency(mission_data, warehouse_ids, diag)

    diag.print_report()
    return 1 if diag.has_failures() else 0


def main() -> int:
    parser = argparse.ArgumentParser(
        prog="check-mission",
        description="Validate a DCS mission directory or .miz file",
    )
    sub = parser.add_subparsers(dest="command")
    check_parser = sub.add_parser("check", help="Run validation checks")
    check_parser.add_argument(
        "path",
        type=Path,
        help="Path to a mission directory or .miz file",
    )
    args = parser.parse_args()

    if args.command != "check":
        parser.print_help()
        return 2

    target: Path = args.path
    if not target.exists():
        print(f"Error: path does not exist: {target}", file=sys.stderr)
        return 2

    if target.is_file() and target.suffix == ".miz":
        with tempfile.TemporaryDirectory() as tmpdir:
            with zipfile.ZipFile(target, "r") as zf:
                zf.extractall(tmpdir)
            return run_checks(Path(tmpdir))
    elif target.is_dir():
        return run_checks(target)
    else:
        print(
            f"Error: path must be a directory or .miz file: {target}",
            file=sys.stderr,
        )
        return 2


if __name__ == "__main__":
    raise SystemExit(main())

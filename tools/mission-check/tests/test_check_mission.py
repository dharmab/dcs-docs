"""Tests for check_mission."""

from __future__ import annotations

import copy
import sys
import zipfile
from pathlib import Path
from typing import Any

import luadata
import pytest

import check_mission as cm

# ---------------------------------------------------------------------------
# Fixture builders
# ---------------------------------------------------------------------------


def make_aircraft_unit(unit_id: int, name: str, **overrides: Any) -> dict[str, Any]:
    unit: dict[str, Any] = {
        "unitId": unit_id,
        "name": name,
        "type": "F-16C_50",
        "skill": "Client",
        "x": 0,
        "y": 0,
        "heading": 0,
        "alt": 100,
        "alt_type": "BARO",
        "speed": 0,
        "psi": 0,
        "payload": {"fuel": 3249},
    }
    unit.update(overrides)
    return unit


def make_aircraft_group(
    group_id: int, name: str, units: list[dict[str, Any]], **overrides: Any
) -> dict[str, Any]:
    group: dict[str, Any] = {
        "groupId": group_id,
        "name": name,
        "units": units,
        "route": {"points": [{"airdromeId": 15}]},
        "x": 0,
        "y": 0,
        "task": "CAP",
        "uncontrolled": False,
    }
    group.update(overrides)
    return group


def make_mission() -> dict[str, Any]:
    group = make_aircraft_group(1, "Viper", [make_aircraft_unit(1, "Viper-1")])
    return {
        "theatre": "Caucasus",
        "version": 23,
        "currentKey": 0,
        "maxDictId": 0,
        "start_time": 28800,
        "date": {"Year": 2026, "Month": 6, "Day": 1},
        "sortie": "DictKey_sortie",
        "descriptionText": "DictKey_descriptionText",
        "descriptionBlueTask": "DictKey_descriptionBlueTask",
        "descriptionRedTask": "DictKey_descriptionRedTask",
        "descriptionNeutralsTask": "DictKey_descriptionNeutralsTask",
        "map": {"centerX": 0, "centerY": 0, "zoom": 1},
        "coalitions": {"blue": [2], "red": [0], "neutrals": [70]},
        "weather": {"atmosphere_type": 0},
        "forcedOptions": {"labels": 0},
        "groundControl": {"isPilotControlVehicles": False},
        "goals": {},
        "result": {"total": 0},
        "trig": {"funcStartup": {}},
        "coalition": {
            "blue": {"country": [{"id": 2, "plane": {"group": [group]}}]},
            "red": {"country": [{"id": 0}]},
            "neutrals": {"country": [{"id": 70}]},
        },
    }


def make_warehouses() -> dict[str, Any]:
    return {
        "airports": {
            15: {"coalition": "BLUE", "dynamicSpawn": True},
            16: {"coalition": "RED", "dynamicSpawn": False},
        },
        "warehouses": {},
    }


def make_dictionary() -> dict[str, str]:
    keys = [
        "sortie",
        "descriptionText",
        "descriptionBlueTask",
        "descriptionRedTask",
        "descriptionNeutralsTask",
    ]
    return {f"DictKey_{key}": "" for key in keys}


def write_lua(path: Path, name: str, data: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(f"{name} = {luadata.serialize(data)}\n", encoding="utf-8")


def write_mission_dir(
    root: Path,
    mission: dict[str, Any] | None = None,
    warehouses: dict[str, Any] | None = None,
    theatre: str = "Caucasus",
) -> Path:
    write_lua(root / "mission", "mission", mission or make_mission())
    write_lua(root / "warehouses", "warehouses", warehouses or make_warehouses())
    write_lua(root / "options", "options", {"difficulty": {}})
    (root / "theatre").write_text(theatre, encoding="utf-8")
    l10n = root / "l10n" / "DEFAULT"
    write_lua(l10n / "dictionary", "dictionary", make_dictionary())
    write_lua(l10n / "mapResource", "mapResource", {"ResKey_Script": "Script.lua"})
    (l10n / "Script.lua").write_text("", encoding="utf-8")
    return root


def blue_group(mission: dict[str, Any]) -> dict[str, Any]:
    return mission["coalition"]["blue"]["country"][0]["plane"]["group"][0]


GROUP_PATH = "coalition.blue.country[0].plane.group[0]"


@pytest.fixture
def run(tmp_path: Path, capsys: pytest.CaptureFixture[str]):
    """Write a mission directory, run all checks, and return (exit code, output)."""

    def _run(
        mission: dict[str, Any] | None = None,
        warehouses: dict[str, Any] | None = None,
        theatre: str = "Caucasus",
    ) -> tuple[int, str]:
        mission_dir = write_mission_dir(tmp_path, mission, warehouses, theatre)
        code = cm.run_checks(mission_dir)
        return code, capsys.readouterr().out

    return _run


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("a", "b", "expected"),
    [
        ("", "", 0),
        ("abc", "", 3),
        ("", "abc", 3),
        ("kitten", "sitting", 3),
        ("coalition", "coalition", 0),
        ("dynamicSpwn", "dynamicSpawn", 1),
    ],
)
def test_edit_distance(a: str, b: str, expected: int) -> None:
    assert cm.edit_distance(a, b) == expected


def test_suggest_field_finds_close_match() -> None:
    assert cm.suggest_field("dynamicSpwn", cm.KNOWN_WAREHOUSE_FIELDS) == "dynamicSpawn"


def test_suggest_field_ignores_case() -> None:
    assert cm.suggest_field("COALITION", cm.KNOWN_WAREHOUSE_FIELDS) == "coalition"


def test_suggest_field_rejects_distant_name() -> None:
    assert cm.suggest_field("zzzzzzzzzzzzzzzz", {"planes", "helicopters"}) is None


def test_parse_lua_assignment() -> None:
    parsed = cm.parse_lua_assignment('mission = { ["a"] = 1, ["b"] = { 1, 2 } }')
    assert parsed == {"a": 1, "b": [1, 2]}


@pytest.mark.parametrize(
    ("lua", "expected"),
    [
        ("3.055902197933e-11", 3.055902197933e-11),
        ("1e5", 1e5),
        ("1E5", 1e5),
        ("-2.5e+3", -2.5e3),
        ("2.e-3", 2e-3),
        (".5e1", 5.0),
        ("1.7976931348623157e308", 1.7976931348623157e308),
    ],
)
def test_parse_lua_assignment_exponent(lua: str, expected: float) -> None:
    parsed = cm.parse_lua_assignment(f'mission = {{ ["heading"] = {lua}, }}')
    assert isinstance(parsed, dict)
    assert isinstance(parsed["heading"], float)
    assert parsed["heading"] == expected


def test_parse_lua_assignment_keeps_exponents_in_strings() -> None:
    lua = (
        'mission = { ["a"] = "x 1e5 \\" 2e3", ["b"] = \'3e2\', ["DictKey_1e5"] = 1e5 }'
    )
    parsed = cm.parse_lua_assignment(lua)
    assert parsed == {"a": 'x 1e5 " 2e3', "b": "3e2", "DictKey_1e5": 1e5}


def test_mission_with_exponent_passes(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    mission_dir = write_mission_dir(tmp_path)
    path = mission_dir / "mission"
    text = path.read_text(encoding="utf-8")
    path.write_text(
        text.replace("heading=0", "heading=3.055902197933e-11", 1),
        encoding="utf-8",
    )
    assert "3.055902197933e-11" in path.read_text(encoding="utf-8")
    assert cm.run_checks(mission_dir) == 0, capsys.readouterr().out


def test_iter_groups_paths_and_categories() -> None:
    mission = make_mission()
    vehicle = {"groupId": 2, "name": "Tanks", "units": []}
    mission["coalition"]["red"]["country"][0]["vehicle"] = {"group": [vehicle]}
    found = [(side, cat, path) for side, cat, _, _, path, _ in cm.iter_groups(mission)]
    assert found == [
        ("blue", "plane", GROUP_PATH),
        ("red", "vehicle", "coalition.red.country[0].vehicle.group[0]"),
    ]


# ---------------------------------------------------------------------------
# Full runs
# ---------------------------------------------------------------------------


def test_valid_mission_passes(run) -> None:
    code, out = run()
    assert code == 0
    assert "No errors found" in out


def test_repo_missions_pass(capsys: pytest.CaptureFixture[str]) -> None:
    missions_root = Path(__file__).resolve().parents[3] / "missions"
    mission_dirs = sorted(missions_root.glob("*/src"))
    if not mission_dirs:
        pytest.skip("no missions in repository")
    for mission_dir in mission_dirs:
        code = cm.run_checks(mission_dir)
        assert code == 0, f"{mission_dir}: {capsys.readouterr().out}"


def test_error_count_is_reported(run) -> None:
    mission = make_mission()
    del mission["sortie"]
    del mission["weather"]
    code, out = run(mission)
    assert code == 1
    assert "2 errors found" in out


# ---------------------------------------------------------------------------
# 1. Files
# ---------------------------------------------------------------------------


def test_missing_file(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    mission_dir = write_mission_dir(tmp_path)
    (mission_dir / "warehouses").unlink()
    assert cm.run_checks(mission_dir) == 1
    assert "warehouses: required file is missing" in capsys.readouterr().out


@pytest.mark.parametrize("name", ["options", "theatre"])
def test_optional_file_may_be_missing(
    tmp_path: Path, capsys: pytest.CaptureFixture[str], name: str
) -> None:
    mission_dir = write_mission_dir(tmp_path)
    (mission_dir / name).unlink()
    assert cm.run_checks(mission_dir) == 0, capsys.readouterr().out


def test_unparseable_lua(tmp_path: Path, capsys: pytest.CaptureFixture[str]) -> None:
    mission_dir = write_mission_dir(tmp_path)
    (mission_dir / "options").write_text("options = { [ }", encoding="utf-8")
    assert cm.run_checks(mission_dir) == 1
    assert "options: failed to parse Lua" in capsys.readouterr().out


# ---------------------------------------------------------------------------
# 2. Mission schema
# ---------------------------------------------------------------------------


def test_missing_mission_key(run) -> None:
    mission = make_mission()
    del mission["forcedOptions"]
    code, out = run(mission)
    assert code == 1
    assert "mission: missing required key 'forcedOptions'" in out


def test_missing_date_key(run) -> None:
    mission = make_mission()
    del mission["date"]["Day"]
    _, out = run(mission)
    assert "mission.date: missing required key 'Day'" in out


def test_missing_coalitions_key(run) -> None:
    mission = make_mission()
    del mission["coalitions"]["red"]
    _, out = run(mission)
    assert "mission.coalitions: missing required key 'red'" in out


def test_mission_without_neutrals_passes(run) -> None:
    mission = make_mission()
    del mission["descriptionNeutralsTask"]
    del mission["coalitions"]["neutrals"]
    code, out = run(mission)
    assert code == 0, out


def test_unassigned_country_is_neutral(run) -> None:
    mission = make_mission()
    mission["coalition"]["neutrals"]["country"].append({"id": 71})
    code, out = run(mission)
    assert code == 0, out


def test_red_country_placed_under_neutrals(run) -> None:
    mission = make_mission()
    mission["coalition"]["neutrals"]["country"].append({"id": 0})
    _, out = run(mission)
    assert (
        "coalition.neutrals.country[1]: country 0 is not in mission.coalitions.neutrals"
    ) in out


def test_missing_coalition_side(run) -> None:
    mission = make_mission()
    del mission["coalition"]["red"]
    _, out = run(mission)
    assert "mission.coalition.red: missing or not a table" in out


def test_coalition_side_without_country(run) -> None:
    mission = make_mission()
    mission["coalition"]["red"] = {"name": "red"}
    _, out = run(mission)
    assert "mission.coalition.red: missing 'country' table" in out


def test_theatre_mismatch(run) -> None:
    code, out = run(theatre="Syria")
    assert code == 1
    assert "does not match theatre file 'Syria'" in out


# ---------------------------------------------------------------------------
# 3. Warehouses
# ---------------------------------------------------------------------------


def test_warehouse_unknown_field_with_suggestion(run) -> None:
    warehouses = make_warehouses()
    warehouses["airports"][16]["dynamicSpwn"] = True
    code, out = run(warehouses=warehouses)
    assert code == 1
    assert (
        "warehouses.airports[16]: unknown field 'dynamicSpwn' "
        "(did you mean 'dynamicSpawn'?)"
    ) in out


def test_warehouse_voip_field_passes(run) -> None:
    warehouses = make_warehouses()
    warehouses["airports"][16]["voip"] = False
    warehouses["warehouses"] = {500: {"coalition": "BLUE", "voip": False}}
    code, out = run(warehouses=warehouses)
    assert code == 0, out


def test_warehouse_missing_coalition(run) -> None:
    warehouses = make_warehouses()
    del warehouses["airports"][16]["coalition"]
    _, out = run(warehouses=warehouses)
    assert "warehouses.airports[16]: missing required field 'coalition'" in out


def test_warehouse_missing_airports(run) -> None:
    code, out = run(warehouses={"warehouses": {}})
    assert code == 1
    assert "warehouses: missing or invalid 'airports' table" in out


def test_unit_warehouse_unknown_field(run) -> None:
    warehouses = make_warehouses()
    warehouses["warehouses"] = {500: {"coalition": "BLUE", "bogus": 1}}
    _, out = run(warehouses=warehouses)
    assert "warehouses.warehouses[500]: unknown field 'bogus'" in out


def test_warehouse_unknown_aircrafts_category(run) -> None:
    warehouses = make_warehouses()
    warehouses["airports"][16]["aircrafts"] = {"plane": {}}
    _, out = run(warehouses=warehouses)
    assert (
        "warehouses.airports[16].aircrafts: unknown aircrafts category 'plane' "
        "(did you mean 'planes'?)"
    ) in out


def test_warehouse_unknown_stock_field(run) -> None:
    warehouses = make_warehouses()
    warehouses["airports"][16]["aircrafts"] = {
        "planes": {"Su-27": {"initialAmount": 4, "wsType": [1, 1, 1, 3], "amount": 4}}
    }
    _, out = run(warehouses=warehouses)
    assert "warehouses.airports[16].aircrafts.planes[Su-27]: unknown field" in out
    assert "'amount'" in out


def test_warehouse_airports_starting_at_one(run) -> None:
    mission = make_mission()
    blue_group(mission)["route"]["points"][0]["airdromeId"] = 1
    warehouses = {"airports": {1: {"coalition": "BLUE", "dynamicSpawn": True}}}
    code, out = run(mission, warehouses)
    assert code == 0, out


def test_warehouse_airports_sequence_keeps_ids(run) -> None:
    mission = make_mission()
    blue_group(mission)["route"]["points"][0]["airdromeId"] = 3
    airports: dict[int, dict[str, Any]] = {i: {"coalition": "BLUE"} for i in (1, 2, 3)}
    airports[2]["bogus"] = 1
    code, out = run(mission, {"airports": airports})
    assert code == 1
    assert "warehouses.airports[2]: unknown field 'bogus'" in out
    assert "not found in warehouse airports" not in out


def test_warehouse_airport_not_in_sequence(run) -> None:
    mission = make_mission()
    blue_group(mission)["route"]["points"][0]["airdromeId"] = 4
    airports = {i: {"coalition": "BLUE"} for i in (1, 2, 3)}
    _, out = run(mission, {"airports": airports})
    assert "airdromeId 4 not found in warehouse airports" in out


def test_unit_warehouses_starting_at_one(run) -> None:
    warehouses = make_warehouses()
    warehouses["warehouses"] = {1: {"coalition": "BLUE"}, 2: {"bogus": 1}}
    _, out = run(warehouses=warehouses)
    assert "warehouses.warehouses[2]: unknown field 'bogus'" in out
    assert "warehouses.warehouses[2]: missing required field 'coalition'" in out


def test_normalize_warehouses() -> None:
    warehouses: dict[str, Any] = {"airports": [{"a": 1}, {"b": 2}], "warehouses": {}}
    cm.normalize_warehouses(warehouses)
    assert warehouses == {"airports": {1: {"a": 1}, 2: {"b": 2}}, "warehouses": {}}


# ---------------------------------------------------------------------------
# 4. Groups and units
# ---------------------------------------------------------------------------


def test_missing_group_field(run) -> None:
    mission = make_mission()
    del blue_group(mission)["route"]
    _, out = run(mission)
    assert f"{GROUP_PATH}: missing required group field 'route'" in out


def test_missing_aircraft_group_field(run) -> None:
    mission = make_mission()
    del blue_group(mission)["task"]
    _, out = run(mission)
    assert f"{GROUP_PATH}: missing required group field 'task'" in out


def test_aircraft_group_without_uncontrolled_passes(run) -> None:
    mission = make_mission()
    del blue_group(mission)["uncontrolled"]
    code, out = run(mission)
    assert code == 0, out


def test_missing_unit_field(run) -> None:
    mission = make_mission()
    del blue_group(mission)["units"][0]["skill"]
    _, out = run(mission)
    assert f"{GROUP_PATH}.units[0]: missing required unit field 'skill'" in out


def make_static_mission(**unit_overrides: Any) -> dict[str, Any]:
    mission = make_mission()
    unit: dict[str, Any] = {
        "unitId": 20,
        "name": "Hangar-1",
        "type": "Hangar A",
        "category": "Fortifications",
        "x": 0,
        "y": 0,
        "heading": 0,
    }
    unit.update(unit_overrides)
    group = {
        "groupId": 20,
        "name": "Hangar",
        "units": [unit],
        "route": {"points": [{"x": 0, "y": 0}]},
        "x": 0,
        "y": 0,
    }
    mission["coalition"]["red"]["country"][0]["static"] = {"group": [group]}
    return mission


def test_static_unit_does_not_need_skill(run) -> None:
    code, out = run(make_static_mission())
    assert code == 0, out


def test_static_unit_still_needs_other_fields(run) -> None:
    mission = make_static_mission()
    del mission["coalition"]["red"]["country"][0]["static"]["group"][0]["units"][0][
        "type"
    ]
    _, out = run(mission)
    assert (
        "coalition.red.country[0].static.group[0].units[0]: "
        "missing required unit field 'type'"
    ) in out
    assert "'skill'" not in out


@pytest.mark.parametrize("skill", ["Average", "Expert"])
def test_static_unit_with_skill(run, skill: str) -> None:
    code, out = run(make_static_mission(skill=skill))
    assert code == 1
    assert (
        "coalition.red.country[0].static.group[0].units[0]: static units have no skill"
    ) in out
    assert "unknown skill" not in out


@pytest.mark.parametrize("category", ["vehicle", "ship"])
def test_non_static_unit_needs_skill(run, category: str) -> None:
    mission = make_static_mission()
    country = mission["coalition"]["red"]["country"][0]
    country[category] = country.pop("static")
    _, out = run(mission)
    assert (
        f"coalition.red.country[0].{category}.group[0].units[0]: "
        "missing required unit field 'skill'"
    ) in out


def test_missing_aircraft_unit_field(run) -> None:
    mission = make_mission()
    del blue_group(mission)["units"][0]["payload"]
    _, out = run(mission)
    assert f"{GROUP_PATH}.units[0]: missing required unit field 'payload'" in out


def test_ground_unit_does_not_need_aircraft_fields(run) -> None:
    mission = make_mission()
    unit = {
        "unitId": 10,
        "name": "Tank-1",
        "type": "T-72B",
        "skill": "Average",
        "x": 0,
        "y": 0,
        "heading": 0,
    }
    group = {
        "groupId": 10,
        "name": "Tanks",
        "units": [unit],
        "route": {"points": [{"x": 0, "y": 0}]},
        "x": 0,
        "y": 0,
    }
    mission["coalition"]["red"]["country"][0]["vehicle"] = {"group": [group]}
    code, out = run(mission)
    assert code == 0, out


# ---------------------------------------------------------------------------
# 5. Dynamic spawn templates
# ---------------------------------------------------------------------------


def make_template_mission(**group_overrides: Any) -> dict[str, Any]:
    mission = make_mission()
    group = blue_group(mission)
    group["dynSpawnTemplate"] = True
    group["lateActivation"] = True
    group.update(group_overrides)
    return mission


def make_stocked_warehouses(**stock: Any) -> dict[str, Any]:
    warehouses = make_warehouses()
    entry: dict[str, Any] = {"initialAmount": 0, "wsType": [1, 1, 1, 3]}
    entry.update(stock)
    warehouses["airports"][15]["aircrafts"] = {"planes": {"F-16C_50": entry}}
    return warehouses


def add_carrier(mission: dict[str, Any], unit_id: int = 100) -> None:
    unit = {
        "unitId": unit_id,
        "name": "Carrier",
        "type": "CVN_71",
        "skill": "Average",
        "x": 0,
        "y": 0,
        "heading": 0,
    }
    group = {
        "groupId": 100,
        "name": "CSG",
        "units": [unit],
        "route": {"points": [{"x": 0, "y": 0}]},
        "x": 0,
        "y": 0,
    }
    mission["coalition"]["blue"]["country"][0]["ship"] = {"group": [group]}


def test_valid_template_passes(run) -> None:
    code, out = run(make_template_mission(), make_stocked_warehouses(linkDynTempl=1))
    assert code == 0, out


def test_template_at_airport_one_passes(run) -> None:
    mission = make_template_mission()
    blue_group(mission)["route"]["points"][0]["airdromeId"] = 1
    warehouses = {"airports": {1: {"coalition": "BLUE", "dynamicSpawn": True}}}
    code, out = run(mission, warehouses)
    assert code == 0, out


def test_template_requires_late_activation(run) -> None:
    _, out = run(make_template_mission(lateActivation=False))
    assert "dynSpawnTemplate group must have lateActivation = true" in out


def test_template_requires_client_skill(run) -> None:
    mission = make_template_mission()
    blue_group(mission)["units"][0]["skill"] = "High"
    _, out = run(mission)
    assert "dynSpawnTemplate unit must have skill = 'Client', got 'High'" in out


def test_template_airport_missing_from_warehouses(run) -> None:
    mission = make_template_mission()
    blue_group(mission)["route"]["points"][0]["airdromeId"] = 99
    _, out = run(mission)
    assert "first waypoint airdromeId 99 not found in warehouses" in out


def test_template_airport_requires_dynamic_spawn(run) -> None:
    warehouses = make_warehouses()
    warehouses["airports"][15]["dynamicSpawn"] = False
    _, out = run(make_template_mission(), warehouses)
    assert "warehouse airport 15 must have dynamicSpawn = true" in out


def test_template_airport_coalition_mismatch(run) -> None:
    warehouses = make_warehouses()
    warehouses["airports"][15]["coalition"] = "RED"
    _, out = run(make_template_mission(), warehouses)
    assert "warehouse airport 15 coalition 'RED' does not match group" in out


def test_template_on_ship_passes(run) -> None:
    mission = make_template_mission()
    add_carrier(mission)
    blue_group(mission)["route"]["points"] = [{"linkUnit": 100, "helipadId": 100}]
    warehouses = make_warehouses()
    warehouses["warehouses"] = {100: {"coalition": "BLUE", "dynamicSpawn": True}}
    code, out = run(mission, warehouses)
    assert code == 0, out


def test_template_helipad_mismatch(run) -> None:
    mission = make_template_mission()
    add_carrier(mission)
    blue_group(mission)["route"]["points"] = [{"linkUnit": 100, "helipadId": 101}]
    warehouses = make_warehouses()
    warehouses["warehouses"] = {100: {"coalition": "BLUE", "dynamicSpawn": True}}
    _, out = run(mission, warehouses)
    assert "helipadId 101 does not match linkUnit 100" in out


def test_template_link_unit_not_a_ship(run) -> None:
    mission = make_template_mission()
    blue_group(mission)["route"]["points"] = [{"linkUnit": 100}]
    _, out = run(mission)
    assert "linkUnit 100 is not a ship unit in the mission" in out
    assert "linkUnit 100 has no entry in warehouses.warehouses" in out


def test_stock_requires_ws_type(run) -> None:
    warehouses = make_stocked_warehouses()
    del warehouses["airports"][15]["aircrafts"]["planes"]["F-16C_50"]["wsType"]
    _, out = run(warehouses=warehouses)
    assert "aircraft stock entry needs wsType" in out


def test_stock_rejects_short_ws_type(run) -> None:
    _, out = run(warehouses=make_stocked_warehouses(wsType=[1, 1, 1]))
    assert "aircraft stock entry needs wsType" in out


def test_link_dyn_templ_unknown_group(run) -> None:
    _, out = run(warehouses=make_stocked_warehouses(linkDynTempl=42))
    assert "linkDynTempl 42 is not a dynSpawnTemplate groupId" in out


def test_link_dyn_templ_type_mismatch(run) -> None:
    mission = make_template_mission()
    blue_group(mission)["units"][0]["type"] = "FA-18C_hornet"
    _, out = run(mission, make_stocked_warehouses(linkDynTempl=1))
    assert "linkDynTempl 1 template is type 'FA-18C_hornet', expected 'F-16C_50'" in out


# ---------------------------------------------------------------------------
# 6. ID uniqueness
# ---------------------------------------------------------------------------


def add_second_group(mission: dict[str, Any], group: dict[str, Any]) -> None:
    mission["coalition"]["blue"]["country"][0]["plane"]["group"].append(group)


def test_duplicate_group_id(run) -> None:
    mission = make_mission()
    add_second_group(
        mission, make_aircraft_group(1, "Hornet", [make_aircraft_unit(2, "Hornet-1")])
    )
    _, out = run(mission)
    assert f"duplicate groupId 1 (first seen at {GROUP_PATH})" in out


def test_duplicate_group_name(run) -> None:
    mission = make_mission()
    add_second_group(
        mission, make_aircraft_group(2, "Viper", [make_aircraft_unit(2, "Hornet-1")])
    )
    _, out = run(mission)
    assert "duplicate group name 'Viper'" in out


def test_duplicate_unit_id_and_name(run) -> None:
    mission = make_mission()
    unit = copy.deepcopy(blue_group(mission)["units"][0])
    add_second_group(mission, make_aircraft_group(2, "Hornet", [unit]))
    _, out = run(mission)
    assert "duplicate unitId 1" in out
    assert "duplicate unit name 'Viper-1'" in out


# ---------------------------------------------------------------------------
# 7. Airfield consistency
# ---------------------------------------------------------------------------


def test_waypoint_airdrome_not_in_warehouses(run) -> None:
    mission = make_mission()
    blue_group(mission)["route"]["points"].append({"airdromeId": 99})
    code, out = run(mission)
    assert code == 1
    assert (
        f"{GROUP_PATH}.route.points[1]: airdromeId 99 not found in warehouse airports"
    ) in out


# ---------------------------------------------------------------------------
# Required keys and values
# ---------------------------------------------------------------------------


@pytest.mark.parametrize("key", ["goals", "result", "trig"])
def test_missing_load_critical_key(run, key: str) -> None:
    mission = make_mission()
    del mission[key]
    _, out = run(mission)
    assert f"mission: missing required key '{key}'" in out


def test_unknown_skill(run) -> None:
    mission = make_mission()
    blue_group(mission)["units"][0]["skill"] = "Veteran"
    _, out = run(mission)
    assert f"{GROUP_PATH}.units[0]: unknown skill 'Veteran'" in out


def test_unit_alt_type(run) -> None:
    mission = make_mission()
    blue_group(mission)["units"][0]["alt_type"] = "AGL"
    _, out = run(mission)
    assert f"{GROUP_PATH}.units[0]: alt_type 'AGL' must be 'BARO' or 'RADIO'" in out


def test_waypoint_alt_type(run) -> None:
    mission = make_mission()
    blue_group(mission)["route"]["points"][0]["alt_type"] = "baro"
    _, out = run(mission)
    assert f"{GROUP_PATH}.route.points[0]: alt_type 'baro' must be" in out


# ---------------------------------------------------------------------------
# 8. Coalition countries
# ---------------------------------------------------------------------------


def test_country_not_in_its_coalition(run) -> None:
    mission = make_mission()
    mission["coalitions"]["blue"] = [21]
    mission["coalitions"]["red"] = [0, 2]
    _, out = run(mission)
    assert "coalition.blue.country[0]: country 2 is not in mission.coalitions.blue" in (
        out
    )


def test_country_in_two_coalitions(run) -> None:
    mission = make_mission()
    mission["coalitions"]["red"] = [0, 2]
    _, out = run(mission)
    assert "mission.coalitions.red: country 2 is also assigned to 'blue'" in out


def test_unassigned_country_under_blue(run) -> None:
    mission = make_mission()
    mission["coalitions"]["blue"] = [21]
    _, out = run(mission)
    assert "coalition.blue.country[0]: country 2 is not in mission.coalitions.blue" in (
        out
    )


# ---------------------------------------------------------------------------
# 9. Parking starts
# ---------------------------------------------------------------------------


def make_parking_mission(**unit_fields: Any) -> dict[str, Any]:
    mission = make_mission()
    group = blue_group(mission)
    group["route"]["points"][0]["type"] = "TakeOffParking"
    group["units"][0].update(unit_fields)
    return mission


def test_parking_start_passes(run) -> None:
    code, out = run(make_parking_mission(parking="55", parking_id="36"))
    assert code == 0, out


def test_parking_start_missing_parking_id(run) -> None:
    _, out = run(make_parking_mission(parking="55"))
    assert f"{GROUP_PATH}.units[0]: airfield parking start needs 'parking_id'" in out


def test_parking_start_missing_parking(run) -> None:
    _, out = run(make_parking_mission(parking_id="36"))
    assert f"{GROUP_PATH}.units[0]: airfield parking start needs 'parking'" in out


def test_hot_parking_start_is_checked(run) -> None:
    mission = make_parking_mission()
    blue_group(mission)["route"]["points"][0]["type"] = "TakeOffParkingHot"
    _, out = run(mission)
    assert "airfield parking start needs 'parking'" in out


def test_parking_id_must_be_string(run) -> None:
    _, out = run(make_parking_mission(parking="55", parking_id=36))
    assert "'parking_id' must be a string, got 36" in out


def test_numeric_parking_passes(run) -> None:
    code, out = run(make_parking_mission(parking=55, parking_id="36"))
    assert code == 0, out


@pytest.mark.parametrize("value", [55.5, True, {"spot": 55}])
def test_parking_must_be_string_or_integer(run, value: Any) -> None:
    _, out = run(make_parking_mission(parking=value, parking_id="36"))
    assert "'parking' must be a string or integer, got" in out


def test_ship_parking_start_needs_no_parking(run) -> None:
    mission = make_mission()
    add_carrier(mission)
    blue_group(mission)["route"]["points"] = [
        {"type": "TakeOffParking", "linkUnit": 100, "helipadId": 100}
    ]
    code, out = run(mission)
    assert code == 0, out


# ---------------------------------------------------------------------------
# 10. TACAN beacons
# ---------------------------------------------------------------------------


@pytest.mark.parametrize(
    ("channel", "mode", "aa", "mhz"),
    [
        (1, "X", False, 962),
        (63, "X", False, 1024),
        (64, "X", False, 1151),
        (100, "X", False, 1187),
        (1, "Y", False, 1088),
        (100, "Y", False, 1061),
        (100, "X", True, 1061),
    ],
)
def test_tacan_frequency_hz(channel: int, mode: str, aa: bool, mhz: int) -> None:
    assert cm.tacan_frequency_hz(channel, mode, aa) == mhz * 1_000_000


def make_beacon_mission(**params: Any) -> dict[str, Any]:
    beacon: dict[str, Any] = {
        "type": 4,
        "system": 4,
        "channel": 100,
        "modeChannel": "X",
        "AA": False,
        "frequency": 1187000000,
    }
    beacon.update(params)
    task = {
        "id": "ComboTask",
        "params": {
            "tasks": [
                {
                    "id": "WrappedAction",
                    "params": {"action": {"id": "ActivateBeacon", "params": beacon}},
                }
            ]
        },
    }
    mission = make_mission()
    blue_group(mission)["route"]["points"][0]["task"] = task
    return mission


def test_valid_tacan_passes(run) -> None:
    code, out = run(make_beacon_mission())
    assert code == 0, out


@pytest.mark.parametrize(("mode", "mhz"), [("X", 1187), ("Y", 1061)])
def test_ship_tacan_system_valid_in_both_modes(run, mode: str, mhz: int) -> None:
    mission = make_beacon_mission(system=3, modeChannel=mode, frequency=mhz * 10**6)
    code, out = run(mission)
    assert code == 0, out


@pytest.mark.parametrize(("system", "mode"), [(13, "X"), (14, "Y")])
def test_air_to_air_tacan_passes(run, system: int, mode: str) -> None:
    mission = make_beacon_mission(
        system=system, modeChannel=mode, AA=True, frequency=1061000000
    )
    code, out = run(mission)
    assert code == 0, out


@pytest.mark.parametrize(("system", "mode"), [(13, "Y"), (14, "X")])
def test_air_to_air_tacan_system_mismatch(run, system: int, mode: str) -> None:
    mission = make_beacon_mission(
        system=system, modeChannel=mode, AA=True, frequency=1061000000
    )
    _, out = run(mission)
    assert f"TACAN 100{mode} has system {system}, not valid for mode {mode}" in out


def test_tacan_frequency_mismatch(run) -> None:
    _, out = run(make_beacon_mission(channel=101))
    assert (
        "TACAN 101X frequency 1187000000 does not match channel, expected 1188000000"
    ) in out


def test_tacan_system_mismatch(run) -> None:
    _, out = run(make_beacon_mission(modeChannel="Y", frequency=1061000000))
    assert "TACAN 100Y has system 4, not valid for mode Y" in out


def test_tacan_channel_out_of_range(run) -> None:
    _, out = run(make_beacon_mission(channel=127))
    assert "TACAN channel 127 must be 1 to 126" in out


def test_tacan_bad_mode(run) -> None:
    _, out = run(make_beacon_mission(modeChannel="Z"))
    assert "TACAN modeChannel 'Z' must be 'X' or 'Y'" in out


def test_non_tacan_beacon_ignored(run) -> None:
    code, out = run(make_beacon_mission(type=1, frequency=0))
    assert code == 0, out


# ---------------------------------------------------------------------------
# 11. Drawing layers
# ---------------------------------------------------------------------------

LAYERS_PATH = "mission.drawings.layers"


def make_drawings_mission(layer_names: list[str] | None) -> dict[str, Any]:
    mission = make_mission()
    drawings: dict[str, Any] = {"options": {"hiddenOnF10Map": {}}}
    if layer_names is not None:
        drawings["layers"] = [
            {"visible": True, "name": name, "objects": []} for name in layer_names
        ]
    mission["drawings"] = drawings
    return mission


def test_all_drawing_layers_pass(run) -> None:
    code, out = run(make_drawings_mission(list(cm.DRAWING_LAYERS)))
    assert code == 0, out


def test_drawing_layers_without_options_pass(run) -> None:
    mission = make_mission()
    mission["drawings"] = {}
    code, out = run(mission)
    assert code == 0, out


def test_empty_drawing_layers(run) -> None:
    _, out = run(make_drawings_mission([]))
    for name in cm.DRAWING_LAYERS:
        assert f"{LAYERS_PATH}: missing layer '{name}'" in out


def test_missing_author_layer(run) -> None:
    _, out = run(make_drawings_mission(["Red", "Blue", "Neutral", "Common"]))
    assert f"{LAYERS_PATH}: missing layer 'Author'" in out
    assert "missing layer 'Red'" not in out


def test_drawing_layers_required_with_options(run) -> None:
    _, out = run(make_drawings_mission(None))
    assert f"{LAYERS_PATH}: required when drawings.options is present" in out


def test_unknown_drawing_layer(run) -> None:
    _, out = run(make_drawings_mission([*cm.DRAWING_LAYERS, "Green"]))
    assert f"{LAYERS_PATH}[5]: layer name 'Green' must be one of" in out


def test_duplicate_drawing_layer(run) -> None:
    _, out = run(make_drawings_mission([*cm.DRAWING_LAYERS, "Red"]))
    assert (
        f"{LAYERS_PATH}[5]: duplicate layer 'Red' (first seen at {LAYERS_PATH}[0])"
    ) in out


# ---------------------------------------------------------------------------
# 12. Dictionary and resource references
# ---------------------------------------------------------------------------


def test_missing_dictionary_key(run) -> None:
    mission = make_mission()
    mission["sortie"] = "DictKey_sortie_7"
    mission["maxDictId"] = 7
    _, out = run(mission)
    assert "mission: 'DictKey_sortie_7' is not in l10n/DEFAULT/dictionary" in out


def test_missing_resource_key_in_trigger_string(run) -> None:
    mission = make_mission()
    mission["trig"]["actions"] = [
        'a_do_script_file(getValueResourceByKey("ResKey_Missing"));'
    ]
    _, out = run(mission)
    assert "mission: 'ResKey_Missing' is not in l10n/DEFAULT/mapResource" in out


def test_resource_file_missing(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    mission_dir = write_mission_dir(tmp_path)
    (mission_dir / "l10n" / "DEFAULT" / "Script.lua").unlink()
    assert cm.run_checks(mission_dir) == 1
    out = capsys.readouterr().out
    assert "mapResource.ResKey_Script: file 'Script.lua' is missing" in out


def test_dictionary_id_above_max_dict_id(
    tmp_path: Path, capsys: pytest.CaptureFixture[str]
) -> None:
    mission_dir = write_mission_dir(tmp_path)
    dictionary = make_dictionary()
    dictionary["DictKey_ActionText_12"] = "Hello"
    write_lua(mission_dir / "l10n" / "DEFAULT" / "dictionary", "dictionary", dictionary)
    assert cm.run_checks(mission_dir) == 1
    out = capsys.readouterr().out
    assert "dictionary.DictKey_ActionText_12: ID 12 is greater than maxDictId 0" in out


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------


def run_main(monkeypatch: pytest.MonkeyPatch, *args: str) -> int:
    monkeypatch.setattr(sys, "argv", ["check-mission", *args])
    return cm.main()


def test_main_checks_directory(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    write_mission_dir(tmp_path)
    assert run_main(monkeypatch, "check", str(tmp_path)) == 0


def test_main_checks_miz(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    src = write_mission_dir(tmp_path / "src")
    miz = tmp_path / "test.miz"
    with zipfile.ZipFile(miz, "w") as zf:
        for path in src.rglob("*"):
            if path.is_file():
                zf.write(path, path.relative_to(src))
    assert run_main(monkeypatch, "check", str(miz)) == 0


def test_main_reports_failures(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    write_mission_dir(tmp_path, theatre="Syria")
    assert run_main(monkeypatch, "check", str(tmp_path)) == 1


def test_main_missing_path(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    assert run_main(monkeypatch, "check", str(tmp_path / "nope")) == 2


def test_main_rejects_other_files(
    tmp_path: Path, monkeypatch: pytest.MonkeyPatch
) -> None:
    other = tmp_path / "mission.txt"
    other.write_text("", encoding="utf-8")
    assert run_main(monkeypatch, "check", str(other)) == 2


def test_main_without_command(monkeypatch: pytest.MonkeyPatch) -> None:
    assert run_main(monkeypatch) == 2

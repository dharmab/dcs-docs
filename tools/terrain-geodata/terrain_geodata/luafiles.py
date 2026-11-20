"""Read the plain Lua tables a terrain ships with.

``Map/towns.lua`` and ``Beacons.lua`` are Lua programs (``dofile``, ``local``,
``_()`` translation calls, named constants), not bare data, so they are parsed
to a syntax tree and the table literals are read from it without running
anything.
"""

from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from luaparser import ast

from .landscape import FormatError


@dataclass(frozen=True)
class Town:
    key: str
    display_name: str
    latitude: float
    longitude: float


@dataclass(frozen=True)
class Beacon:
    display_name: str
    callsign: str
    x: float
    z: float
    latitude: float
    longitude: float


def _global_table(path: Path, name: str) -> ast.Table:
    """The table literal assigned to global ``name`` at the top of the file."""
    tree = ast.parse(path.read_text(encoding="utf-8", errors="replace"))
    for statement in tree.body.body:
        if isinstance(statement, ast.LocalAssign) or not isinstance(
            statement, ast.Assign
        ):
            continue
        for target, value in zip(statement.targets, statement.values, strict=False):
            if isinstance(target, ast.Name) and target.id == name:
                if not isinstance(value, ast.Table):
                    raise FormatError(f"{path}: {name} is not a table")
                return value
    raise FormatError(f"{path}: no {name} table")


def _fields(table: ast.Table) -> dict[str, ast.Node]:
    """Named fields of a table (``key = v`` and ``["key"] = v``)."""
    out: dict[str, ast.Node] = {}
    for field in table.fields:
        key = field.key
        if isinstance(key, ast.Name) and not field.between_brackets:
            out[key.id] = field.value
        elif isinstance(key, ast.String):
            out[_text(key)] = field.value
    return out


def _items(table: ast.Table) -> list[ast.Node]:
    """Positional entries of a table."""
    return [
        f.value for f in table.fields if isinstance(f.key, ast.Number) or f.key is None
    ]


def _text(node: ast.String) -> str:
    raw = node.s
    return raw.decode("utf-8", errors="replace") if isinstance(raw, bytes) else raw


def _string(node: ast.Node | None) -> str | None:
    """A string literal, or the literal inside a ``_("...")`` translation call."""
    if isinstance(node, ast.Call) and len(node.args) == 1:
        node = node.args[0]
    return _text(node) if isinstance(node, ast.String) else None


def _number(node: ast.Node | None) -> float | None:
    if isinstance(node, ast.UMinusOp):
        value = _number(node.operand)
        return None if value is None else -value
    return float(node.n) if isinstance(node, ast.Number) else None


def read_towns(path: Path) -> list[Town]:
    towns: list[Town] = []
    for field in _global_table(path, "towns").fields:
        if not isinstance(field.key, ast.String) or not isinstance(
            field.value, ast.Table
        ):
            continue
        entry = _fields(field.value)
        lat = _number(entry.get("latitude"))
        lon = _number(entry.get("longitude"))
        if lat is None or lon is None:
            continue
        key = _text(field.key)
        towns.append(Town(key, _string(entry.get("display_name")) or key, lat, lon))
    return towns


def read_beacons(path: Path) -> list[Beacon]:
    """Beacons that list both a DCS position and a lat/long."""
    beacons: list[Beacon] = []
    for item in _items(_global_table(path, "beacons")):
        if not isinstance(item, ast.Table):
            continue
        entry = _fields(item)
        position, geo = entry.get("position"), entry.get("positionGeo")
        if not isinstance(position, ast.Table) or not isinstance(geo, ast.Table):
            continue
        xyz = [_number(v) for v in _items(position)]
        geo_fields = _fields(geo)
        lat = _number(geo_fields.get("latitude"))
        lon = _number(geo_fields.get("longitude"))
        if len(xyz) != 3 or None in xyz or lat is None or lon is None:
            continue
        x, _, z = xyz
        assert x is not None and z is not None
        beacons.append(
            Beacon(
                _string(entry.get("display_name")) or "",
                _string(entry.get("callsign")) or "",
                x,
                z,
                lat,
                lon,
            )
        )
    return beacons

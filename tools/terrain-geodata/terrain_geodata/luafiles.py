"""Read the plain Lua tables a terrain ships with."""

from __future__ import annotations

import re
from dataclasses import dataclass
from pathlib import Path


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


_NUM = r"(-?[\d.]+(?:[eE][-+]?\d+)?)"
_TOWN_RX = re.compile(
    r'\[\s*"(?P<key>(?:[^"\\]|\\.)*)"\s*\]\s*=\s*\{\s*latitude\s*=\s*'
    + _NUM
    + r"\s*,\s*longitude\s*=\s*"
    + _NUM
    + r'\s*,\s*display_name\s*=\s*_\(\s*"(?P<display>(?:[^"\\]|\\.)*)"\s*\)'
)
_POSITION_RX = re.compile(
    r"\bposition\s*=\s*\{\s*" + _NUM + r"\s*,\s*" + _NUM + r"\s*,\s*" + _NUM + r"\s*\}"
)
_GEO_RX = re.compile(
    r"\bpositionGeo\s*=\s*\{\s*latitude\s*=\s*"
    + _NUM
    + r"\s*,\s*longitude\s*=\s*"
    + _NUM
)
_NAME_RX = re.compile(r"display_name\s*=\s*_\(\s*'([^']*)'\s*\)")
_CALLSIGN_RX = re.compile(r"callsign\s*=\s*'([^']*)'")


def _unescape(s: str) -> str:
    return s.replace('\\"', '"').replace("\\\\", "\\")


def read_towns(path: Path) -> list[Town]:
    text = path.read_text(encoding="utf-8", errors="replace")
    return [
        Town(
            _unescape(m.group("key")),
            _unescape(m.group("display")),
            float(m.group(2)),
            float(m.group(3)),
        )
        for m in _TOWN_RX.finditer(text)
    ]


def read_beacons(path: Path) -> list[Beacon]:
    """Beacons that list both a DCS position and a lat/long."""
    text = path.read_text(encoding="utf-8", errors="replace")
    positions = list(_POSITION_RX.finditer(text))
    beacons: list[Beacon] = []
    for i, m in enumerate(positions):
        # Search only up to the next beacon's position so pairs never cross.
        block_start = positions[i - 1].end() if i else 0
        block_end = positions[i + 1].start() if i + 1 < len(positions) else len(text)
        geo = _GEO_RX.search(text, m.end(), block_end)
        if geo is None:
            continue
        head = text[block_start : m.start()]
        names = _NAME_RX.findall(head)
        calls = _CALLSIGN_RX.findall(head)
        beacons.append(
            Beacon(
                names[-1] if names else "",
                calls[-1] if calls else "",
                float(m.group(1)),
                float(m.group(3)),
                float(geo.group(1)),
                float(geo.group(2)),
            )
        )
    return beacons

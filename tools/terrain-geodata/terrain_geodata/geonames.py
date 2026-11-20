"""Read Mission Editor map labels (``Map/<terrain>.gn4``).

Layout after the common header (see ``landscape``)::

    str  "landscape4::lGeoNamesFile"     at 0x20
    u32  2
    f32  bbox[6]                         unused, always an empty box
    u32  label count
    repeat, 54 bytes each:
        u32  3
        f64  x, y, z                     DCS position (y is always 0)
        u32  style                       label size or zoom class
        u32  0
        u32  name offset                 into the string table
        u32  0
        u16  0
        i32  -1
        u32  1 for towns, 0 for other labels (MGRS squares and so on)
    ...  lookup tables
    string table at the header's data offset: NUL-terminated names

The town labels are the same places as ``towns.lua``, which gives their lat/long,
so pairing the two yields reference points for fitting the projection.
"""

from __future__ import annotations

import struct
from dataclasses import dataclass
from pathlib import Path

from .landscape import TYPE_NAME_OFFSET, FormatError, Reader, read_header

_RECORD = struct.Struct("<IdddIIIIHiI")


@dataclass(frozen=True)
class Label:
    name: str
    x: float
    z: float
    style: int
    is_town: bool


def read_labels(path: Path) -> list[Label]:
    names_offset, type_name = read_header(path)
    if type_name != "landscape4::lGeoNamesFile":
        raise FormatError(f"{path} is {type_name}, not a gn4 file")
    data = path.read_bytes()
    r = Reader(data, TYPE_NAME_OFFSET)
    r.string()
    r.u32()
    r.f32(6)
    count = r.u32()
    labels: list[Label] = []
    for i in range(count):
        ver, x, _y, z, style, _a, name_off, _b, _c, _d, town = _RECORD.unpack_from(
            data, r.pos + i * _RECORD.size
        )
        if ver != 3:
            raise FormatError(f"unexpected label record version {ver}")
        start = names_offset + name_off
        end = data.index(b"\0", start)
        name = data[start:end].decode("utf-8", errors="replace")
        labels.append(Label(name, x, z, style, town == 1))
    return labels

"""Shared pieces of Eagle Dynamics' landscape4/landscape5 binary serialization.

Every landscape file (``.sup5``, ``.surface5``, ``.gn4``, ...) starts with the same
header::

    u32  version       (2)
    u32  header size   (0x30)
    u64  data offset   start of the bulk vertex/index section (or string table)
    ...  zero padding up to 0x20
    str  type name     e.g. "landscape5::sup5File"

Strings are a ``u32`` byte length followed by the bytes, with no terminator.

Geometry is stored as records. A record lists named streams, each pointing into
the bulk data section that follows the metadata::

    u32  1                      marker
    str  name                   "P", "TRI", "LINELIST", "baseIndex", ...
    u16  element type           2 = float3, 4 = u32, 5 = line, 6 = triangle
    u16  element size in bytes
    u32  1 if the stream has one element per primitive, 0 if per vertex
    u64  byte length
    u48  byte offset            relative to the data offset in the header

Vertex positions are float32 ``(x, y, z)`` in DCS axes (x north, y up, z east),
relative to the translation of the node that holds the record.
"""

from __future__ import annotations

import struct
from dataclasses import dataclass
from pathlib import Path

import numpy as np

HEADER_DATA_OFFSET = 8
TYPE_NAME_OFFSET = 0x20

# A node transform is a 4x4 float matrix; terrain nodes only ever translate.
IDENTITY_ROTATION = struct.pack("<12f", 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0)


class FormatError(Exception):
    """The file does not match the layout this tool understands."""


@dataclass(frozen=True)
class Stream:
    name: str
    elem_type: int
    elem_size: int
    per_primitive: bool
    nbytes: int
    offset: int


class Reader:
    """Little-endian cursor over a bytes object."""

    def __init__(self, data: bytes, pos: int = 0) -> None:
        self.data = data
        self.pos = pos

    def _unpack(self, fmt: str) -> tuple:
        values = struct.unpack_from(fmt, self.data, self.pos)
        self.pos += struct.calcsize(fmt)
        return values

    def u16(self) -> int:
        return self._unpack("<H")[0]

    def u32(self) -> int:
        return self._unpack("<I")[0]

    def i32(self) -> int:
        return self._unpack("<i")[0]

    def u48(self) -> int:
        value = int.from_bytes(self.data[self.pos : self.pos + 6], "little")
        self.pos += 6
        return value

    def u64(self) -> int:
        return self._unpack("<Q")[0]

    def f32(self, count: int) -> tuple[float, ...]:
        return self._unpack(f"<{count}f")

    def string(self, max_len: int = 4096) -> str:
        length = self.u32()
        if length > max_len:
            raise FormatError(
                f"implausible string length {length} at {self.pos - 4:#x}"
            )
        value = self.data[self.pos : self.pos + length].decode("latin-1")
        self.pos += length
        return value

    def stream(self) -> Stream:
        marker = self.u32()
        if marker != 1:
            raise FormatError(f"expected stream marker at {self.pos - 4:#x}")
        name = self.string(64)
        elem_type = self.u16()
        elem_size = self.u16()
        per_primitive = self.u32() == 1
        nbytes = self.u64()
        offset = self.u48()
        return Stream(name, elem_type, elem_size, per_primitive, nbytes, offset)


def read_header(path: Path) -> tuple[int, str]:
    """Return ``(data_offset, type_name)`` for a landscape file."""
    with path.open("rb") as f:
        head = f.read(0x100)
    data_offset = struct.unpack_from("<Q", head, HEADER_DATA_OFFSET)[0]
    type_name = Reader(head, TYPE_NAME_OFFSET).string(200)
    return data_offset, type_name


class BulkData:
    """Random access to the bulk section of a landscape file."""

    def __init__(self, path: Path, data_offset: int) -> None:
        self._file = path.open("rb")
        self._base = data_offset

    def array(self, stream: Stream, dtype: str) -> np.ndarray:
        self._file.seek(self._base + stream.offset)
        raw = self._file.read(stream.nbytes)
        if len(raw) != stream.nbytes:
            raise FormatError(f"stream {stream.name} runs past end of file")
        return np.frombuffer(raw, dtype=dtype)

    def positions(self, stream: Stream) -> np.ndarray:
        """Float3 positions as an ``(n, 3)`` float64 array."""
        return self.array(stream, "<f4").reshape(-1, 3).astype(np.float64)

    def indices(self, stream: Stream) -> np.ndarray:
        """Primitive indices as an ``(n, k)`` array, k = 2 for lines, 3 for tris."""
        per_prim = stream.elem_size // 4
        return self.array(stream, "<u4").reshape(-1, per_prim)

    def close(self) -> None:
        self._file.close()

    def __enter__(self) -> BulkData:
        return self

    def __exit__(self, *exc: object) -> None:
        self.close()

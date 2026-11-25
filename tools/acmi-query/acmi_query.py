"""Index and query Tacview ACMI recordings from DCS World.

The first query against a recording parses it into a SQLite cache in the
system temp directory, named by the SHA-256 of the recording. Later queries read
the cache. Caches unused for a day are deleted.

Recordings are untrusted input. Text from them is stripped of control and
format characters before it is stored, so it cannot drive the terminal. Zipped
recordings larger than MAX_TEXT_BYTES when decompressed are rejected.
"""

from __future__ import annotations

import argparse
import bisect
import hashlib
import io
import itertools
import json
import math
import os
import re
import sqlite3
import stat
import sys
import tempfile
import time
import zipfile
from collections import defaultdict
from collections.abc import Iterator
from datetime import datetime, timedelta
from pathlib import Path

SCHEMA_VERSION = 5
CACHE_MAX_AGE_S = 24 * 3600
MAX_TEXT_BYTES = 4 * 1024**3
UNIT_SAMPLE_INTERVAL = 1.0
GRID_DEG = 0.01
LAUNCHER_RADIUS_M = 900.0
M_PER_NM = 1852.0
FT_PER_M = 3.28084
KT_PER_MPS = 1.94384

SCHEMA = """
CREATE TABLE meta (key TEXT PRIMARY KEY, value TEXT);
CREATE TABLE objects (
    rowid INTEGER PRIMARY KEY,
    acmi_id TEXT NOT NULL,
    kind TEXT NOT NULL,
    type TEXT, name TEXT, pilot TEXT, grp TEXT,
    color TEXT, coalition TEXT, country TEXT,
    first_t REAL, last_t REAL, removed INTEGER,
    first_lat REAL, first_lon REAL, first_alt REAL,
    last_lat REAL, last_lon REAL, last_alt REAL,
    launcher INTEGER, launcher_dist REAL,
    first_x REAL, first_y REAL, last_x REAL, last_y REAL
);
CREATE TABLE samples (
    obj INTEGER, t REAL, lat REAL, lon REAL, alt REAL,
    roll REAL, pitch REAL, heading REAL,
    x REAL, y REAL, agl REAL, flight TEXT
);
CREATE TABLE events (t REAL, type TEXT, ids TEXT, text TEXT);
"""

INDEXES = """
CREATE INDEX samples_obj_t ON samples (obj, t);
CREATE INDEX samples_t ON samples (t);
CREATE INDEX objects_acmi_id ON objects (acmi_id);
CREATE INDEX objects_last_t ON objects (last_t);
CREATE INDEX objects_first_t ON objects (first_t);
CREATE INDEX objects_grp ON objects (grp);
CREATE INDEX objects_pilot ON objects (pilot);
CREATE INDEX objects_launcher ON objects (launcher);
"""

# T= field positions by component count. Index into the 9-slot state:
# lon lat alt roll pitch yaw u v heading
# In DCS recordings u is east (mission y) and v is north (mission x).
T_LAYOUTS = {
    3: (0, 1, 2),
    5: (0, 1, 2, 6, 7),
    6: (0, 1, 2, 3, 4, 5),
    9: (0, 1, 2, 3, 4, 5, 6, 7, 8),
}

# Numeric per-frame properties stored as JSON in samples.flight when present.
# Server-side multiplayer recordings omit them; singleplayer recordings may not.
FLIGHT_PROPS = frozenset(
    {
        "IAS",
        "TAS",
        "CAS",
        "Mach",
        "AOA",
        "AOS",
        "HDG",
        "HDM",
        "Throttle",
        "Throttle2",
        "Afterburner",
        "AirBrakes",
        "Flaps",
        "LandingGear",
        "LandingGearHandle",
        "Tailhook",
        "Parachute",
        "DragChute",
        "FuelWeight",
        "FuelVolume",
        "Health",
        "EngineRPM",
        "EngineRPM2",
        "RotorRPM",
        "RotorRPM2",
    }
)
SPEED_PROPS = frozenset({"IAS", "TAS", "CAS"})

ESCAPED_SPLIT = re.compile(r"(?<!\\),")

# C0 and C1 control characters (including ESC and newline), zero-width
# characters, and bidirectional overrides.
UNSAFE_CHARS = re.compile(
    "[\x00-\x1f\x7f-\x9f\u200b-\u200f\u202a-\u202e\u2066-\u2069\ufeff]"
)


def clean(value: str | None) -> str | None:
    """Replace characters that could drive a terminal or hide text."""
    if value is None:
        return None
    return UNSAFE_CHARS.sub(" ", value)


def classify(type_tags: str) -> str:
    tags = set(type_tags.split("+"))
    if tags & {
        "Projectile",
        "Bullet",
        "Decoy",
        "Shrapnel",
        "Container",
        "Explosion",
        "Beam",
        "SmokeGrenade",
    }:
        return "ephemeral"
    if "Weapon" in tags:
        return "weapon"
    if "Navaid" in tags:
        return "navaid"
    return "unit"


def can_launch(type_tags: str) -> bool:
    tags = set(type_tags.split("+"))
    return not tags & {"Static", "Parachutist"}


# ---------------------------------------------------------------------------
# Parsing


def iter_lines(path: Path) -> Iterator[str]:
    """Yield logical ACMI lines, joining backslash-continued lines."""
    if zipfile.is_zipfile(path):
        archive = zipfile.ZipFile(path)
        members = archive.infolist()
        if len(members) != 1:
            sys.exit(f"error: {path} must hold exactly one file, found {len(members)}")
        member = members[0]
        # ZipExtFile stops reading at the declared size, so this bounds the
        # decompressed text.
        if member.file_size > MAX_TEXT_BYTES:
            sys.exit(
                f"error: {path} decompresses to {member.file_size} bytes, "
                f"over the {MAX_TEXT_BYTES} byte limit"
            )
        stream = io.TextIOWrapper(archive.open(member), encoding="utf-8-sig")
    else:
        stream = open(path, encoding="utf-8-sig")  # noqa: SIM115
    pending: list[str] = []
    with stream:
        for raw in stream:
            line = raw.rstrip("\r\n")
            if line.endswith("\\") and not line.endswith("\\\\"):
                pending.append(line[:-1])
                continue
            if pending:
                pending.append(line)
                line = "\n".join(pending)
                pending = []
            if line:
                yield line


def parse_float(value: str) -> float | None:
    try:
        return float(value)
    except ValueError:
        return None


def split_props(rest: str) -> list[tuple[str, str]]:
    if "\\" in rest:
        parts = [p.replace("\\,", ",") for p in ESCAPED_SPLIT.split(rest)]
    else:
        parts = rest.split(",")
    out = []
    for part in parts:
        key, sep, value = part.partition("=")
        if sep:
            out.append((key, value))
    return out


class Obj:
    __slots__ = (
        "rowid",
        "acmi_id",
        "state",
        "props",
        "kind",
        "first_t",
        "first_pos",
        "first_xy",
        "agl",
        "flight",
        "last_sample_t",
        "cell",
        "launcher",
        "launcher_dist",
    )

    def __init__(self, rowid: int, acmi_id: int, t: float) -> None:
        self.rowid = rowid
        self.acmi_id = acmi_id
        self.state: list[float | None] = [None] * 9
        self.props: dict[str, str] = {}
        self.kind = "unit"
        self.first_t = t
        self.first_pos: tuple[float, float, float] | None = None
        self.first_xy: tuple[float | None, float | None] = (None, None)
        self.agl: float | None = None
        self.flight: dict[str, float] = {}
        self.last_sample_t = -1e18
        self.cell: tuple[int, int] | None = None
        self.launcher: int | None = None
        self.launcher_dist: float | None = None


def local_dist(
    lat1: float, lon1: float, alt1: float, lat2: float, lon2: float, alt2: float
) -> float:
    """Slant distance in meters using an equirectangular approximation."""
    dy = (lat2 - lat1) * 110_574.0
    dx = (lon2 - lon1) * 111_320.0 * math.cos(math.radians((lat1 + lat2) / 2))
    dz = alt2 - alt1
    return math.sqrt(dx * dx + dy * dy + dz * dz)


class Indexer:
    def __init__(self, db: sqlite3.Connection) -> None:
        self.db = db
        self.meta: dict[str, str] = {}
        self.ref_lat = 0.0
        self.ref_lon = 0.0
        self.t = 0.0
        self.live: dict[int, Obj] = {}
        self.next_rowid = 1
        self.grid: dict[tuple[int, int], set[Obj]] = defaultdict(set)
        self.samples: list[tuple] = []
        self.objects: list[tuple] = []
        self.events: list[tuple] = []

    def run(self, path: Path) -> None:
        live = self.live
        for line in iter_lines(path):
            first = line[0]
            if first == "#":
                self.t = float(line[1:])
                continue
            if first == "-":
                try:
                    acmi_id = int(line[1:], 16)
                except ValueError:
                    continue
                obj = live.pop(acmi_id, None)
                if obj is not None:
                    self.finish(obj, removed=True)
                continue
            if line.startswith("//"):
                continue
            id_str, sep, rest = line.partition(",")
            if not sep:
                key, _, value = line.partition("=")
                self.meta[clean(key) or ""] = clean(value) or ""
                continue
            if id_str == "0":
                self.global_prop(rest)
                continue
            try:
                acmi_id = int(id_str, 16)
            except ValueError:
                continue
            obj = live.get(acmi_id)
            if obj is None:
                obj = Obj(self.next_rowid, acmi_id, self.t)
                self.next_rowid += 1
                live[acmi_id] = obj
                new = True
            else:
                new = False
            if rest.startswith("T=") and "," not in rest:
                self.update_transform(obj, rest[2:])
            else:
                transform = None
                for key, value in split_props(rest):
                    if key == "T":
                        transform = value
                    else:
                        obj.props[key] = value
                        if key == "Type":
                            obj.kind = classify(value)
                        elif key == "AGL":
                            obj.agl = parse_float(value)
                        elif key in FLIGHT_PROPS:
                            number = parse_float(value)
                            if number is not None:
                                obj.flight[key] = number
                if transform is not None:
                    self.update_transform(obj, transform)
            if new:
                self.on_spawn(obj)
            if len(self.samples) > 200_000:
                self.flush()
        for obj in list(live.values()):
            self.finish(obj, removed=False)
        live.clear()
        self.flush()
        self.meta["Duration"] = str(self.t)
        self.meta["SchemaVersion"] = str(SCHEMA_VERSION)
        self.db.executemany("INSERT INTO meta VALUES (?, ?)", self.meta.items())

    def global_prop(self, rest: str) -> None:
        key, _, value = rest.partition("=")
        if key == "Event":
            parts = value.replace("\\,", ",").split("|")
            ids = ",".join(parts[1:-1]) if len(parts) > 2 else ""
            text = parts[-1] if len(parts) > 1 else ""
            self.events.append((self.t, clean(parts[0]), clean(ids), clean(text)))
            return
        if key == "AuthenticationKey":
            return
        value = value.replace("\\,", ",")
        if key == "ReferenceLatitude":
            self.ref_lat = float(value)
        elif key == "ReferenceLongitude":
            self.ref_lon = float(value)
        self.meta[clean(key) or ""] = clean(value) or ""

    def update_transform(self, obj: Obj, value: str) -> None:
        parts = value.split("|")
        layout = T_LAYOUTS.get(len(parts))
        if layout is None:
            return
        state = obj.state
        for slot, part in zip(layout, parts, strict=True):
            if part:
                state[slot] = float(part)
        if state[0] is None or state[1] is None:
            return
        if obj.kind == "ephemeral":
            return
        if obj.kind == "weapon" or self.t - obj.last_sample_t >= UNIT_SAMPLE_INTERVAL:
            self.add_sample(obj)
        if obj.kind == "unit":
            self.regrid(obj)

    def position(self, obj: Obj) -> tuple[float, float, float] | None:
        s = obj.state
        if s[0] is None or s[1] is None:
            return None
        return (s[1] + self.ref_lat, s[0] + self.ref_lon, s[2] or 0.0)

    @staticmethod
    def mission_xy(obj: Obj) -> tuple[float | None, float | None]:
        """DCS mission coordinates (x north, y east) from Tacview u/v."""
        return (obj.state[7], obj.state[6])

    def add_sample(self, obj: Obj) -> None:
        pos = self.position(obj)
        if pos is None:
            return
        s = obj.state
        heading = s[8] if s[8] is not None else s[5]
        self.samples.append(
            (
                obj.rowid,
                self.t,
                *pos,
                s[3],
                s[4],
                heading,
                *self.mission_xy(obj),
                obj.agl,
                json.dumps(obj.flight) if obj.flight else None,
            )
        )
        obj.last_sample_t = self.t

    def regrid(self, obj: Obj) -> None:
        if not can_launch(obj.props.get("Type", "")):
            return
        pos = self.position(obj)
        if pos is None:
            return
        cell = (int(pos[0] // GRID_DEG), int(pos[1] // GRID_DEG))
        if cell != obj.cell:
            if obj.cell is not None:
                self.grid[obj.cell].discard(obj)
            self.grid[cell].add(obj)
            obj.cell = cell

    def on_spawn(self, obj: Obj) -> None:
        obj.first_pos = self.position(obj)
        obj.first_xy = self.mission_xy(obj)
        if obj.kind in ("weapon", "ephemeral") and obj.first_pos is not None:
            self.find_launcher(obj)

    def find_launcher(self, obj: Obj) -> None:
        assert obj.first_pos is not None
        lat, lon, alt = obj.first_pos
        color = obj.props.get("Color")
        ci, cj = int(lat // GRID_DEG), int(lon // GRID_DEG)
        best: tuple[int, float, Obj] | None = None
        for di in (-1, 0, 1):
            for dj in (-1, 0, 1):
                for cand in self.grid.get((ci + di, cj + dj), ()):
                    pos = self.position(cand)
                    if pos is None:
                        continue
                    d = local_dist(lat, lon, alt, *pos)
                    if d > LAUNCHER_RADIUS_M:
                        continue
                    # Prefer same color, then nearest.
                    rank = 0 if cand.props.get("Color") == color else 1
                    if best is None or (rank, d) < (best[0], best[1]):
                        best = (rank, d, cand)
        if best is not None:
            obj.launcher = best[2].rowid
            obj.launcher_dist = round(best[1], 1)

    def finish(self, obj: Obj, removed: bool) -> None:
        if obj.kind != "ephemeral" and obj.last_sample_t < self.t:
            self.add_sample(obj)
        if obj.cell is not None:
            self.grid[obj.cell].discard(obj)
        p = obj.props
        first = obj.first_pos or (None, None, None)
        last = self.position(obj) or (None, None, None)
        self.objects.append(
            (
                obj.rowid,
                format(obj.acmi_id, "x"),
                obj.kind,
                clean(p.get("Type")),
                clean(p.get("Name")),
                clean(p.get("Pilot")),
                clean(p.get("Group")),
                clean(p.get("Color")),
                clean(p.get("Coalition")),
                clean(p.get("Country")),
                obj.first_t,
                self.t,
                int(removed),
                *first,
                *last,
                obj.launcher,
                obj.launcher_dist,
                *obj.first_xy,
                *self.mission_xy(obj),
            )
        )

    def flush(self) -> None:
        self.db.executemany(
            f"INSERT INTO samples VALUES ({', '.join('?' * 12)})", self.samples
        )
        self.db.executemany(
            f"INSERT INTO objects VALUES ({', '.join('?' * 25)})", self.objects
        )
        self.db.executemany("INSERT INTO events VALUES (?, ?, ?, ?)", self.events)
        self.samples.clear()
        self.objects.clear()
        self.events.clear()


def cache_dir() -> Path:
    """Return a cache directory only the current user can write to."""
    path = Path(tempfile.gettempdir()) / "acmi-query"
    path.mkdir(mode=0o700, exist_ok=True)
    info = path.lstat()
    is_real_dir = stat.S_ISDIR(info.st_mode)
    if not is_real_dir:
        sys.exit(f"error: cache path {path} is not a directory")
    # Windows temp directories are per user and have no POSIX owner or mode.
    if hasattr(os, "getuid"):
        owned_by_user = info.st_uid == os.getuid()
        others_have_access = info.st_mode & 0o077 != 0
        if not owned_by_user or others_have_access:
            sys.exit(f"error: cache directory {path} is shared with other users")
    return path


def prune_cache(directory: Path) -> None:
    """Delete cache files unused for CACHE_MAX_AGE_S."""
    cutoff = time.time() - CACHE_MAX_AGE_S
    for entry in directory.iterdir():
        try:
            if entry.stat().st_mtime < cutoff:
                entry.unlink()
        except FileNotFoundError:
            continue


def cache_path(acmi: Path) -> Path:
    with acmi.open("rb") as f:
        digest = hashlib.file_digest(f, "sha256").hexdigest()
    directory = cache_dir()
    prune_cache(directory)
    return directory / f"{digest}.db"


def build_index(acmi: Path, db_path: Path) -> None:
    tmp = db_path.with_name(f"{db_path.name}.{os.getpid()}.tmp")
    tmp.unlink(missing_ok=True)
    db = sqlite3.connect(tmp)
    start = time.monotonic()
    try:
        db.execute("PRAGMA journal_mode = OFF")
        db.execute("PRAGMA synchronous = OFF")
        db.executescript(SCHEMA)
        print(f"Indexing {acmi.name} ...", file=sys.stderr)
        Indexer(db).run(acmi)
        db.executescript(INDEXES)
        db.commit()
        db.close()
        tmp.replace(db_path)
    finally:
        db.close()
        tmp.unlink(missing_ok=True)
    print(f"Indexed in {time.monotonic() - start:.0f}s -> {db_path}", file=sys.stderr)


def open_db(acmi: Path, force: bool = False) -> sqlite3.Connection:
    if not acmi.exists():
        sys.exit(f"error: {acmi} not found")
    db_path = cache_path(acmi)
    stale = force or not db_path.exists()
    if not stale:
        # Keep caches in use from being pruned.
        db_path.touch()
        db = sqlite3.connect(db_path)
        row = db.execute(
            "SELECT value FROM meta WHERE key = 'SchemaVersion'"
        ).fetchone()
        if row and row[0] == str(SCHEMA_VERSION):
            db.row_factory = sqlite3.Row
            return db
        db.close()
    build_index(acmi, db_path)
    db = sqlite3.connect(db_path)
    db.row_factory = sqlite3.Row
    return db


# ---------------------------------------------------------------------------
# Query helpers


class Recording:
    def __init__(self, db: sqlite3.Connection) -> None:
        self.db = db
        self.meta = {r["key"]: r["value"] for r in db.execute("SELECT * FROM meta")}
        ref = self.meta.get("ReferenceTime", "")
        try:
            self.ref_time: datetime | None = datetime.fromisoformat(
                ref.replace("Z", "+00:00")
            )
        except ValueError:
            self.ref_time = None
        self.duration = float(self.meta.get("Duration", "0"))

    def clock(self, t: float | None) -> str:
        if t is None:
            return ""
        if self.ref_time is None:
            return f"{t:.1f}"
        return (self.ref_time + timedelta(seconds=t)).strftime("%H:%M:%S")

    def parse_time(self, value: str | None) -> float | None:
        """Accept seconds from recording start or HH:MM[:SS] mission clock."""
        if value is None:
            return None
        if ":" not in value:
            return float(value)
        if self.ref_time is None:
            sys.exit("error: recording has no ReferenceTime; use seconds")
        parts = [int(p) for p in value.split(":")]
        while len(parts) < 3:
            parts.append(0)
        clock = self.ref_time.replace(
            hour=parts[0], minute=parts[1], second=parts[2], microsecond=0
        )
        offset = (clock - self.ref_time).total_seconds()
        if offset < 0:
            offset += 86_400
        return offset

    def resolve(
        self,
        ref: str,
        t0: float | None = None,
        t1: float | None = None,
        allow_many: bool = True,
    ) -> list[sqlite3.Row]:
        """Resolve a reference, keeping objects alive in the [t0, t1] window."""
        rows = [
            r
            for r in self.resolve_all(ref)
            if (t0 is None or r["last_t"] >= t0) and (t1 is None or r["first_t"] <= t1)
        ]
        if not rows:
            sys.exit(f"error: {ref!r} has no object alive in that time window")
        if len(rows) > 1 and not allow_many:
            listing = "\n".join(
                f"  {self.label(r)} spawn {self.clock(r['first_t'])}"
                f" gone {self.clock(r['last_t'])}"
                for r in rows[:20]
            )
            sys.exit(
                f"error: {ref!r} matches {len(rows)} objects; pass a hex ID or "
                f"narrow with --from/--to:\n{listing}"
            )
        return rows

    def resolve_all(self, ref: str) -> list[sqlite3.Row]:
        """Resolve a hex ID, unit name (Pilot), or group name to objects."""
        if re.fullmatch(r"[0-9a-fA-F]+", ref):
            rows = self.db.execute(
                "SELECT * FROM objects WHERE acmi_id = ?", (ref.lower(),)
            ).fetchall()
            if rows:
                return rows
        for column in ("pilot", "grp"):
            rows = self.db.execute(
                f"SELECT * FROM objects WHERE {column} = ? ORDER BY first_t",
                (ref,),
            ).fetchall()
            if rows:
                return rows
        sys.exit(f"error: no object with ID, unit name, or group name {ref!r}")

    def samples(
        self, rowid: int, t0: float | None = None, t1: float | None = None
    ) -> list[sqlite3.Row]:
        sql = "SELECT * FROM samples WHERE obj = ?"
        args: list = [rowid]
        if t0 is not None:
            sql += " AND t >= ?"
            args.append(t0)
        if t1 is not None:
            sql += " AND t <= ?"
            args.append(t1)
        return self.db.execute(sql + " ORDER BY t", args).fetchall()

    def position_at(self, rowid: int, t: float) -> tuple[float, float, float] | None:
        """Interpolated position, holding the nearest sample outside the range."""
        before = self.db.execute(
            "SELECT t, lat, lon, alt FROM samples WHERE obj = ? AND t <= ? "
            "ORDER BY t DESC LIMIT 1",
            (rowid, t),
        ).fetchone()
        after = self.db.execute(
            "SELECT t, lat, lon, alt FROM samples WHERE obj = ? AND t >= ? "
            "ORDER BY t LIMIT 1",
            (rowid, t),
        ).fetchone()
        return interpolate(before, after, t)

    def label(self, row: sqlite3.Row | None) -> str:
        if row is None:
            return ""
        name = row["pilot"] or row["name"] or row["acmi_id"]
        if row["pilot"] and row["name"]:
            name = f"{row['pilot']} ({row['name']})"
        return f"{name} [{row['acmi_id']}]"

    def by_rowid(self, rowid: int | None) -> sqlite3.Row | None:
        if rowid is None:
            return None
        return self.db.execute(
            "SELECT * FROM objects WHERE rowid = ?", (rowid,)
        ).fetchone()


def interpolate(before, after, t: float) -> tuple[float, float, float] | None:
    if before is None and after is None:
        return None
    if before is None:
        return (after["lat"], after["lon"], after["alt"])
    if after is None or after["t"] == before["t"]:
        return (before["lat"], before["lon"], before["alt"])
    f = (t - before["t"]) / (after["t"] - before["t"])
    return tuple(  # type: ignore[return-value]
        before[k] + (after[k] - before[k]) * f for k in ("lat", "lon", "alt")
    )


def speed_between(a, b) -> tuple[float | None, float | None]:
    """Ground speed (kt) and vertical speed (fpm) between two samples."""
    dt = b["t"] - a["t"]
    if dt <= 0:
        return None, None
    horiz = local_dist(a["lat"], a["lon"], 0, b["lat"], b["lon"], 0)
    return horiz / dt * KT_PER_MPS, (b["alt"] - a["alt"]) / dt * FT_PER_M * 60


def object_filters(
    args: argparse.Namespace, rec: Recording, prefix: str = ""
) -> tuple[str, list]:
    clauses: list[str] = []
    params: list = []
    type_tags = getattr(args, "type", None)
    if type_tags:
        # Match whole tags so "Air" does not match "AntiAircraft".
        for tag in type_tags.split("+"):
            clauses.append(f"('+' || {prefix}type || '+') LIKE ?")
            params.append(f"%+{tag}+%")
    for column, attr in (
        ("name", "name"),
        ("grp", "group"),
        ("pilot", "unit"),
    ):
        value = getattr(args, attr, None)
        if value:
            clauses.append(f"{prefix}{column} LIKE ?")
            params.append(f"%{value}%")
    if getattr(args, "color", None):
        clauses.append(f"{prefix}color = ? COLLATE NOCASE")
        params.append(args.color)
    t0 = rec.parse_time(getattr(args, "start", None))
    t1 = rec.parse_time(getattr(args, "end", None))
    if t0 is not None:
        clauses.append(f"{prefix}last_t >= ?")
        params.append(t0)
    if t1 is not None:
        clauses.append(f"{prefix}first_t <= ?")
        params.append(t1)
    alive = rec.parse_time(getattr(args, "alive_at", None))
    if alive is not None:
        clauses.append(f"{prefix}first_t <= ? AND {prefix}last_t >= ?")
        params += [alive, alive]
    where = " AND ".join(clauses) if clauses else "1"
    return where, params


# ---------------------------------------------------------------------------
# Output


def emit(rows: list[dict], as_json: bool) -> None:
    if as_json:
        json.dump(rows, sys.stdout, indent=1, default=str)
        print()
        return
    if not rows:
        print("(no results)")
        return
    columns = list(rows[0].keys())
    cells = [[fmt_cell(r.get(c)) for c in columns] for r in rows]
    widths = [
        max(len(c), *(len(row[i]) for row in cells)) for i, c in enumerate(columns)
    ]
    widths = [min(w, 48) for w in widths]
    print("  ".join(c.ljust(w) for c, w in zip(columns, widths, strict=True)))
    for row in cells:
        print(
            "  ".join(v[:w].ljust(w) for v, w in zip(row, widths, strict=True)).rstrip()
        )


def fmt_cell(value) -> str:
    if value is None:
        return ""
    if isinstance(value, float):
        if abs(value) >= 100:
            return f"{value:.1f}"
        return f"{value:.5f}".rstrip("0").rstrip(".")
    return str(value)


# ---------------------------------------------------------------------------
# Commands


def cmd_index(args: argparse.Namespace) -> None:
    open_db(args.acmi, force=args.force).close()


def cmd_summary(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    db = rec.db
    info = {
        k: rec.meta.get(k)
        for k in (
            "Title",
            "DataSource",
            "DataRecorder",
            "ReferenceTime",
            "RecordingTime",
        )
    }
    info["Duration"] = f"{rec.duration:.0f}s ({timedelta(seconds=int(rec.duration))})"
    info["MissionClock"] = f"{rec.clock(0)} - {rec.clock(rec.duration)}"
    event_count = db.execute("SELECT COUNT(*) FROM events").fetchone()[0]
    info["Events"] = str(event_count)
    if args.json:
        types = [
            dict(r)
            for r in db.execute(
                "SELECT kind, type, color, COUNT(*) AS n FROM objects "
                "GROUP BY kind, type, color ORDER BY kind, n DESC"
            )
        ]
        json.dump({"info": info, "types": types}, sys.stdout, indent=1)
        print()
        return
    for k, v in info.items():
        print(f"{k}: {v}")
    print()
    rows = [
        dict(r)
        for r in db.execute(
            "SELECT kind, type, color, COUNT(*) AS n, "
            "SUM(removed) AS removed FROM objects "
            "GROUP BY kind, type, color ORDER BY kind, n DESC"
        )
    ]
    emit(rows, False)


def cmd_objects(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    where, params = object_filters(args, rec)
    if args.kind != "all":
        where += " AND kind = ?"
        params.append(args.kind)
    sql = f"SELECT * FROM objects WHERE {where} ORDER BY first_t LIMIT ?"
    rows = []
    for r in rec.db.execute(sql, [*params, args.limit]):
        rows.append(
            {
                "id": r["acmi_id"],
                "type": r["type"],
                "name": r["name"],
                "unit": r["pilot"],
                "group": r["grp"],
                "color": r["color"],
                "spawn": rec.clock(r["first_t"]),
                "gone": rec.clock(r["last_t"]) if r["removed"] else "end",
                "life_s": r["last_t"] - r["first_t"],
                "spawn_x": None if r["first_x"] is None else round(r["first_x"]),
                "spawn_y": None if r["first_y"] is None else round(r["first_y"]),
            }
        )
    emit(rows, args.json)


def cmd_groups(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    where, params = object_filters(args, rec)
    sql = (
        "SELECT grp, color, GROUP_CONCAT(DISTINCT name) AS types, COUNT(*) AS units,"
        " MIN(first_t) AS first_t, MAX(first_t) AS last_spawn_t,"
        " MAX(last_t) AS last_t, SUM(removed) AS removed"
        f" FROM objects WHERE kind = 'unit' AND grp IS NOT NULL AND {where}"
        " GROUP BY grp, color ORDER BY first_t LIMIT ?"
    )
    rows = []
    for r in rec.db.execute(sql, [*params, args.limit]):
        rows.append(
            {
                "group": r["grp"],
                "color": r["color"],
                "units": r["units"],
                "removed": r["removed"],
                "types": r["types"],
                "first_spawn": rec.clock(r["first_t"]),
                "last_spawn": rec.clock(r["last_spawn_t"]),
                "last_seen": rec.clock(r["last_t"]),
            }
        )
    emit(rows, args.json)


def cmd_timeline(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    where, params = object_filters(args, rec)
    t0 = rec.parse_time(args.start)
    t1 = rec.parse_time(args.end)
    kinds = ["unit"] + ([] if args.no_weapons else ["weapon"])
    sql = (
        f"SELECT * FROM objects WHERE {where} AND kind IN "
        f"({', '.join('?' * len(kinds))})"
    )
    entries: list[tuple[float, dict]] = []
    for r in rec.db.execute(sql, [*params, *kinds]):
        if r["kind"] == "weapon":
            launcher = rec.by_rowid(r["launcher"])
            what = "LAUNCH"
            detail = f"{r['name']} by {rec.label(launcher) or '?'}"
        else:
            what = "SPAWN"
            detail = rec.label(r)
        base = {"group": r["grp"], "color": r["color"]}
        entries.append((r["first_t"], {"event": what, "what": detail, **base}))
        if r["kind"] == "unit" and r["removed"]:
            entries.append(
                (r["last_t"], {"event": "REMOVE", "what": rec.label(r), **base})
            )
    for e in rec.db.execute("SELECT * FROM events"):
        entries.append(
            (
                e["t"],
                {
                    "event": e["type"],
                    "what": f"{e['ids']} {e['text']}".strip(),
                    "group": None,
                    "color": None,
                },
            )
        )
    entries.sort(key=lambda x: x[0])
    rows = []
    for t, entry in entries:
        if (t0 is not None and t < t0) or (t1 is not None and t > t1):
            continue
        rows.append({"t": t, "clock": rec.clock(t), **entry})
        if len(rows) >= args.limit:
            break
    emit(rows, args.json)


def cmd_track(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    t0 = rec.parse_time(args.start)
    t1 = rec.parse_time(args.end)
    objs = rec.resolve(args.object, t0, t1, allow_many=args.all)
    rows = []
    for obj in objs:
        samples = rec.samples(obj["rowid"], t0, t1)
        last_emit = -1e18
        for i, s in enumerate(samples):
            final = i == len(samples) - 1
            if s["t"] - last_emit < args.interval and not final:
                continue
            gs = vs = None
            if i:
                gs, vs = speed_between(samples[i - 1], s)
            rows.append(
                {
                    "id": obj["acmi_id"],
                    "t": s["t"],
                    "clock": rec.clock(s["t"]),
                    "lat": round(s["lat"], 5),
                    "lon": round(s["lon"], 5),
                    "x": None if s["x"] is None else round(s["x"]),
                    "y": None if s["y"] is None else round(s["y"]),
                    "alt_ft": round(s["alt"] * FT_PER_M),
                    "agl_ft": None if s["agl"] is None else round(s["agl"] * FT_PER_M),
                    "hdg": None if s["heading"] is None else round(s["heading"]),
                    "gs_kt": None if gs is None else round(gs),
                    "vs_fpm": None if vs is None else round(vs),
                    "roll": s["roll"],
                    "pitch": s["pitch"],
                    **flight_columns(s["flight"]),
                }
            )
            last_emit = s["t"]
    # Give every row the same columns when some samples carry flight data.
    columns = list(dict.fromkeys(k for r in rows for k in r))
    emit([{k: r.get(k) for k in columns} for r in rows], args.json)


def flight_columns(raw: str | None) -> dict:
    if not raw:
        return {}
    out = {}
    for key, value in sorted(json.loads(raw).items()):
        if key in SPEED_PROPS:
            out[f"f_{key.lower()}_kt"] = round(value * KT_PER_MPS)
        elif key == "FuelWeight":
            out["f_fuel_kg"] = round(value)
        else:
            out[f"f_{key.lower()}"] = value
    return out


def cmd_near(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    target = rec.resolve(
        args.object,
        rec.parse_time(args.start),
        rec.parse_time(args.end),
        allow_many=False,
    )[0]
    t0 = max(rec.parse_time(args.start) or 0.0, target["first_t"])
    t1 = min(
        rec.parse_time(args.end) or target["last_t"],
        target["last_t"],
    )
    track = rec.samples(target["rowid"], t0, t1)
    if not track:
        sys.exit("error: target has no positions in that window")
    radius = args.range * M_PER_NM
    pad_lat = radius / 110_574.0
    pad_lon = radius / (111_320.0 * math.cos(math.radians(track[0]["lat"])))
    lat_lo = min(s["lat"] for s in track) - pad_lat
    lat_hi = max(s["lat"] for s in track) + pad_lat
    lon_lo = min(s["lon"] for s in track) - pad_lon
    lon_hi = max(s["lon"] for s in track) + pad_lon
    kinds = ("unit", "weapon") if args.kind == "all" else (args.kind,)
    where, params = object_filters(
        argparse.Namespace(
            type=args.type, color=args.color, group=None, name=None, unit=None
        ),
        rec,
    )
    candidates = rec.db.execute(
        f"SELECT DISTINCT o.* FROM samples s JOIN objects o ON o.rowid = s.obj "
        f"WHERE s.t BETWEEN ? AND ? AND s.lat BETWEEN ? AND ? "
        f"AND s.lon BETWEEN ? AND ? AND o.rowid != ? "
        f"AND o.kind IN ({', '.join('?' * len(kinds))}) AND {where}",
        [t0, t1, lat_lo, lat_hi, lon_lo, lon_hi, target["rowid"], *kinds, *params],
    ).fetchall()
    # Static objects may have a single sample before the window.
    statics = rec.db.execute(
        f"SELECT o.* FROM objects o WHERE o.first_t <= ? AND o.last_t >= ? "
        f"AND o.last_lat BETWEEN ? AND ? AND o.last_lon BETWEEN ? AND ? "
        f"AND o.rowid != ? AND o.kind IN ({', '.join('?' * len(kinds))}) "
        f"AND {where}",
        [t1, t0, lat_lo, lat_hi, lon_lo, lon_hi, target["rowid"], *kinds, *params],
    ).fetchall()
    seen = {c["rowid"] for c in candidates}
    candidates += [s for s in statics if s["rowid"] not in seen]
    track_t = [s["t"] for s in track]

    def target_at(t: float):
        i = bisect.bisect_left(track_t, t)
        before = track[i - 1] if i > 0 else None
        after = track[i] if i < len(track) else None
        if before is not None and after is not None and after["t"] == t:
            before = after
        return interpolate(before, after, t)

    rows = []
    for cand in candidates:
        lo = max(t0, cand["first_t"])
        hi = min(t1, cand["last_t"])
        cs = rec.samples(cand["rowid"], lo, hi)
        if not cs:
            pos = rec.position_at(cand["rowid"], lo)
            if pos is None:
                continue
            cs = [
                {"t": t, "lat": pos[0], "lon": pos[1], "alt": pos[2]}
                for t in track_t
                if lo <= t <= hi
            ]
        best = None
        first_in = last_in = None
        for s in cs:
            tp = target_at(s["t"])
            if tp is None:
                continue
            d = local_dist(*tp, s["lat"], s["lon"], s["alt"])
            if d <= radius:
                first_in = s["t"] if first_in is None else first_in
                last_in = s["t"]
            if best is None or d < best[0]:
                best = (d, s["t"])
        if first_in is None or best is None:
            continue
        rows.append(
            {
                "id": cand["acmi_id"],
                "kind": cand["kind"],
                "what": rec.label(cand),
                "group": cand["grp"],
                "color": cand["color"],
                "enter": rec.clock(first_in),
                "leave": rec.clock(last_in),
                "closest_nm": round(best[0] / M_PER_NM, 2),
                "closest_at": rec.clock(best[1]),
            }
        )
    rows.sort(key=lambda r: r["closest_nm"])
    emit(rows[: args.limit], args.json)


def nearest_units(
    rec: Recording,
    lat: float,
    lon: float,
    alt: float,
    t: float,
    radius: float,
    exclude: set[int],
) -> list[tuple[float, sqlite3.Row]]:
    """Units within radius of a point at time t, nearest first."""
    pad_lat = radius / 110_574.0
    pad_lon = radius / (111_320.0 * math.cos(math.radians(lat)))
    rows = rec.db.execute(
        "SELECT o.* FROM objects o WHERE o.kind = 'unit' "
        "AND o.first_t <= ? AND o.last_t >= ? AND o.rowid IN ("
        " SELECT obj FROM samples WHERE t BETWEEN ? AND ?"
        " AND lat BETWEEN ? AND ? AND lon BETWEEN ? AND ?"
        " UNION SELECT rowid FROM objects WHERE last_lat BETWEEN ? AND ?"
        " AND last_lon BETWEEN ? AND ?)",
        (
            t + 1,
            t - 1,
            t - 30,
            t + 30,
            lat - pad_lat,
            lat + pad_lat,
            lon - pad_lon,
            lon + pad_lon,
            lat - pad_lat,
            lat + pad_lat,
            lon - pad_lon,
            lon + pad_lon,
        ),
    ).fetchall()
    out = []
    for r in rows:
        if r["rowid"] in exclude or "Static+Aerodrome" in (r["type"] or ""):
            continue
        pos = rec.position_at(r["rowid"], t)
        if pos is None:
            continue
        d = local_dist(lat, lon, alt, *pos)
        if d <= radius:
            out.append((d, r))
    out.sort(key=lambda x: x[0])
    return out


def cmd_shots(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    where, params = object_filters(args, rec)
    if args.launcher:
        ids = [o["rowid"] for o in rec.resolve_all(args.launcher)]
        where += f" AND launcher IN ({', '.join('?' * len(ids))})"
        params += ids
    sql = f"SELECT * FROM objects WHERE kind = 'weapon' AND {where} ORDER BY first_t"
    radius = args.radius
    rows = []
    for w in rec.db.execute(sql, params).fetchall():
        launcher = rec.by_rowid(w["launcher"])
        hit = ""
        hit_dist = None
        fate = ""
        if w["last_lat"] is not None:
            exclude = {w["launcher"]} if w["launcher"] else set()
            near = nearest_units(
                rec,
                w["last_lat"],
                w["last_lon"],
                w["last_alt"],
                w["last_t"],
                radius,
                exclude,
            )
            if near:
                d, unit = near[0]
                hit = rec.label(unit)
                hit_dist = round(d)
                if unit["removed"] and unit["last_t"] - w["last_t"] <= args.window:
                    fate = f"removed +{unit['last_t'] - w['last_t']:.1f}s"
                else:
                    fate = "survived"
        rows.append(
            {
                "clock": rec.clock(w["first_t"]),
                "weapon": w["name"],
                "id": w["acmi_id"],
                "launcher": rec.label(launcher),
                "launch_dist_m": w["launcher_dist"],
                "flight_s": w["last_t"] - w["first_t"],
                "end_alt_ft": None
                if w["last_alt"] is None
                else round(w["last_alt"] * FT_PER_M),
                "nearest_at_end": hit,
                "miss_m": hit_dist,
                "nearest_fate": fate,
            }
        )
        if len(rows) >= args.limit:
            break
    emit(rows, args.json)


def cmd_removals(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    where, params = object_filters(args, rec)
    sql = (
        f"SELECT * FROM objects WHERE kind = 'unit' AND removed = 1 AND {where} "
        "ORDER BY last_t LIMIT ?"
    )
    radius = args.radius
    rows = []
    for u in rec.db.execute(sql, [*params, args.limit]).fetchall():
        last = rec.db.execute(
            "SELECT * FROM samples WHERE obj = ? ORDER BY t DESC LIMIT 30",
            (u["rowid"],),
        ).fetchall()
        gs = None
        agl = last[0]["agl"] if last else None
        # Skip trailing samples where DCS froze the position before removal.
        for newer, older in itertools.pairwise(last):
            if (newer["lat"], newer["lon"]) != (older["lat"], older["lon"]):
                gs, _ = speed_between(older, newer)
                break
        else:
            if len(last) > 1:
                gs = 0.0
        cause = ""
        if u["last_lat"] is not None:
            lat, lon, alt, t = u["last_lat"], u["last_lon"], u["last_alt"], u["last_t"]
            pad_lat = radius / 110_574.0
            pad_lon = radius / (111_320.0 * math.cos(math.radians(lat)))
            best = None
            for w in rec.db.execute(
                "SELECT * FROM objects WHERE kind IN ('weapon', 'ephemeral') "
                "AND type NOT LIKE '%Decoy%' AND type NOT LIKE '%Shrapnel%' "
                "AND last_t BETWEEN ? AND ? AND last_lat BETWEEN ? AND ? "
                "AND last_lon BETWEEN ? AND ?",
                (
                    t - args.window,
                    t + 1,
                    lat - pad_lat,
                    lat + pad_lat,
                    lon - pad_lon,
                    lon + pad_lon,
                ),
            ):
                d = local_dist(
                    lat, lon, alt, w["last_lat"], w["last_lon"], w["last_alt"]
                )
                if d <= radius and (best is None or d < best[0]):
                    best = (d, w)
            if best is not None:
                d, w = best
                launcher = rec.by_rowid(w["launcher"])
                cause = (
                    f"{w['name']} ended {d:.0f}m away; "
                    f"from {rec.label(launcher) or '?'}"
                )
        rows.append(
            {
                "clock": rec.clock(u["last_t"]),
                "unit": rec.label(u),
                "group": u["grp"],
                "color": u["color"],
                "life_s": u["last_t"] - u["first_t"],
                "alt_ft": None
                if u["last_alt"] is None
                else round(u["last_alt"] * FT_PER_M),
                "agl_ft": None if agl is None else round(agl * FT_PER_M),
                "gs_kt": None if gs is None else round(gs),
                "likely_cause": cause or "no weapon nearby",
            }
        )
    emit(rows, args.json)


def cmd_guns(args: argparse.Namespace) -> None:
    rec = Recording(open_db(args.acmi))
    where, params = object_filters(args, rec, prefix="l.")
    sql = (
        "SELECT l.rowid AS lrow, w.name AS shell, COUNT(*) AS n,"
        " MIN(w.first_t) AS first_t, MAX(w.first_t) AS last_t"
        " FROM objects w LEFT JOIN objects l ON l.rowid = w.launcher"
        " WHERE w.kind = 'ephemeral' AND w.type LIKE '%Projectile%'"
        f" AND {where}"
        " GROUP BY l.rowid, w.name ORDER BY first_t LIMIT ?"
    )
    rows = []
    for r in rec.db.execute(sql, [*params, args.limit]):
        launcher = rec.by_rowid(r["lrow"])
        rows.append(
            {
                "shooter": rec.label(launcher) or "?",
                "group": launcher["grp"] if launcher else None,
                "color": launcher["color"] if launcher else None,
                "shell": r["shell"],
                "rounds": r["n"],
                "first": rec.clock(r["first_t"]),
                "last": rec.clock(r["last_t"]),
            }
        )
    emit(rows, args.json)


# ---------------------------------------------------------------------------
# CLI


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="acmi-query",
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", required=True)

    def add(name: str, func, help_text: str, filters: bool = True):
        p = sub.add_parser(name, help=help_text, description=help_text)
        p.add_argument("acmi", type=Path, help="Path to .acmi / .zip.acmi file")
        p.add_argument("--json", action="store_true", help="Emit JSON")
        p.add_argument("--limit", type=int, default=500, help="Max rows")
        if filters:
            p.add_argument("--type", help="Substring of Type, e.g. Air+FixedWing")
            p.add_argument("--name", help="Substring of Name (model), e.g. SA-11")
            p.add_argument("--group", help="Substring of group name")
            p.add_argument("--unit", help="Substring of unit name (Pilot)")
            p.add_argument("--color", help="Red, Blue, Grey, ...")
            p.add_argument(
                "--from", dest="start", help="Seconds or HH:MM[:SS] mission clock"
            )
            p.add_argument("--to", dest="end", help="Seconds or HH:MM[:SS]")
        p.set_defaults(func=func)
        return p

    p = add("index", cmd_index, "Build (or rebuild) the SQLite cache", False)
    p.add_argument("--force", action="store_true", help="Rebuild even if fresh")
    add("summary", cmd_summary, "Recording metadata and object counts", False)
    p = add("objects", cmd_objects, "List objects with spawn/removal times")
    p.add_argument(
        "--kind",
        default="unit",
        choices=["unit", "weapon", "ephemeral", "navaid", "all"],
    )
    p.add_argument("--alive-at", help="Only objects alive at this time")
    add("groups", cmd_groups, "Per-group spawn and loss summary")
    p = add("timeline", cmd_timeline, "Spawns, removals, launches, and events")
    p.add_argument("--no-weapons", action="store_true", help="Hide launches")
    p = add("track", cmd_track, "Position history of one object", False)
    p.add_argument("object", help="Hex ID, unit name, or group name")
    p.add_argument("--interval", type=float, default=10.0, help="Seconds per row")
    p.add_argument("--all", action="store_true", help="Allow multiple objects")
    p.add_argument("--from", dest="start")
    p.add_argument("--to", dest="end")
    p = add("near", cmd_near, "Objects that came within range of an object", False)
    p.add_argument("object", help="Hex ID or unique unit name")
    p.add_argument("--range", type=float, default=10.0, help="Range in nm")
    p.add_argument("--kind", default="unit", choices=["unit", "weapon", "all"])
    p.add_argument("--type")
    p.add_argument("--color")
    p.add_argument("--from", dest="start")
    p.add_argument("--to", dest="end")
    p = add("shots", cmd_shots, "Missile/bomb launches with launcher and outcome")
    p.add_argument("--launcher", help="Hex ID, unit name, or group name")
    p.add_argument("--radius", type=float, default=150.0, help="Hit radius, m")
    p.add_argument("--window", type=float, default=10.0, help="Kill window, s")
    p = add("removals", cmd_removals, "Unit removals with likely cause")
    p.add_argument("--radius", type=float, default=150.0, help="Weapon radius, m")
    p.add_argument("--window", type=float, default=5.0, help="Seconds before")
    add("guns", cmd_guns, "Gun/cannon/AAA fire aggregated by shooter")

    args = parser.parse_args()
    args.func(args)


if __name__ == "__main__":
    main()

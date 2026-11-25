# terrain-geodata

Reads terrain data straight from a DCS World install and writes standard GIS
files to `docs/data/terrains/<theatre>/`. No mission or desanitized scripting
environment is needed. See [docs/terrains/geodata.md](../../docs/terrains/geodata.md)
for what the output contains and how to use it.

## Usage

You must use [uv](https://docs.astral.sh/uv/) to run this tool. Trying to run it
with just `python terrain_geodata/cli.py` will not work.

```bash
# Enter the tool's project directory
cd tools/terrain-geodata
# List the terrains found in the DCS install
uv run terrain-geodata list
# Export every terrain to docs/data/terrains
uv run terrain-geodata export --out ../../docs/data/terrains
# Export only the Caucasus terrain
uv run terrain-geodata export --out ../../docs/data/terrains --terrain Caucasus
```

On Windows the install folder is read from the registry (standalone or Steam).
Elsewhere, or to use a different install, pass `--dcs-path` or set the
`DCS_PATH` environment variable. `--out` defaults to `docs/data/terrains`
relative to the current directory. `--resolution` sets the land cover pixel
size (default 100 m) and `--elevation-resolution` the elevation pixel size
(default 1 km). `--jobs` sets the number of worker processes (default one per
CPU).

Re-run the export after a DCS update that touches terrains, then review the diff
of each `terrain.json`.

## Sources in the install

| Output                       | Read from                                   |
| ---------------------------- | ------------------------------------------- |
| Projection                   | `Beacons.lua`, `Map/towns.lua`, `Map/*.gn4` |
| `places.csv`, `places` layer | `Map/towns.lua`, `Map/*.gn4`                |
| Other `features.gpkg` layers | `Map/*.sup5` (Mission Editor map overlay)   |
| `landcover.tif`              | `Surface/*.surface5` (terrain mesh)         |
| `elevation.tif`              | `Surface/*.surface5` (terrain mesh)         |

The binary layouts are documented in the module docstrings:
[landscape.py](terrain_geodata/landscape.py) (shared header and streams),
[sup5.py](terrain_geodata/sup5.py), [surface5.py](terrain_geodata/surface5.py)
and [geonames.py](terrain_geodata/geonames.py). They were worked out from the
files themselves; nothing here is published by Eagle Dynamics. If an update
changes a layout the tool raises `FormatError` rather than writing bad data.

## Adding a terrain

New terrains are picked up automatically. Check the export log for
`skipped map materials`: these are overlay line or polygon sets the tool could
not place. Road-like lines (`Road`, `Rail`, `Railway`) are sorted into roads and
railways by checking which mesh triangles they sit on; anything that matches
neither can be assigned in `OVERLAY_OVERRIDES` in
[export.py](terrain_geodata/export.py) after plotting it.

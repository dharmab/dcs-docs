# acmi-query

Indexes and queries Tacview ACMI recordings from DCS World. See
[docs/tacview/acmi-debugging.md](../../docs/tacview/acmi-debugging.md) for the
full command list, filters, and debugging recipes.

## Usage

You must use [uv](https://docs.astral.sh/uv/) to run this tool. Trying to run it
with just `python acmi_query.py` will not work unless your system Python is 3.14
or later.

The first query against a recording writes a SQLite cache next to the file
(`<file>.db`). Recordings are untrusted, so copy each one to its own empty
directory before querying it.

```bash
# Enter the tool's project directory
cd tools/acmi-query
# Show the mission, DCS version, duration, and object counts
uv run acmi-query summary ~/tacview/session1/Tacview-example.zip.acmi
# Show when each group spawned and how many units it lost
uv run acmi-query groups ~/tacview/session1/Tacview-example.zip.acmi
# Show missile and bomb launches by one group
uv run acmi-query shots ~/tacview/session1/Tacview-example.zip.acmi --launcher "SA-11 Site 1"
# Rebuild the cache
uv run acmi-query index ~/tacview/session1/Tacview-example.zip.acmi --force
```

## Development

```bash
# Install the tool and the dev dependencies (ruff, ty)
uv sync --group dev
# Lint the code
uv run ruff check .
# Type check the code
uv run ty check
```

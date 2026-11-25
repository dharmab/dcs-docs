# livery-export

Scans a DCS World install for aircraft liveries and writes one Markdown file per
aircraft, plus an index `README.md`, listing the available liveries.

## Usage

You must use [uv](https://docs.astral.sh/uv/) to run this tool. Trying to run it
with just `python extract_liveries.py` will not work unless your system Python is
3.14 or later.

```bash
# Enter the tool's project directory
cd tools/livery-export
# Find the DCS install automatically and write to docs/liveries
uv run extract-liveries --output-dir ../../docs/liveries
# Read from a specific DCS install
uv run extract-liveries --dcs-root "D:/DCS World" --output-dir ../../docs/liveries
```

On Windows the install folder is read from the registry, then from common
install paths. Elsewhere, pass `--dcs-root`. `--output-dir` defaults to
`docs/liveries` relative to the current directory.

## Development

```bash
# Install the tool and the dev dependencies (ruff, ty)
uv sync --group dev
# Lint the code
uv run ruff check .
# Type check the code
uv run ty check
```

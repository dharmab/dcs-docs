LUA_FILES := $(shell git ls-files '*.lua')
PY_TOOLS := $(patsubst %/pyproject.toml,%,$(wildcard tools/*/pyproject.toml))

# scipy has no wheels for newer Pythons yet
export UV_PYTHON := 3.14

.PHONY: format check bun-format bun-format-check lua-format lua-format-check lua-lint python-format python-format-check python-lint python-typecheck

format: bun-format lua-format python-format

check: bun-format-check lua-format-check lua-lint python-format-check python-lint python-typecheck

# JSON, YAML, TOML, and Markdown
bun-format:
	bun fmt

bun-format-check:
	bun fmt --check

lua-format:
	stylua $(LUA_FILES)

lua-format-check:
	stylua --check $(LUA_FILES)

lua-lint:
	lua-language-server --check . --checklevel=Warning

python-format:
	uv run ruff format .

python-format-check:
	uv run ruff format --check .

python-lint:
	uv run ruff check .

# Each tool is a separate uv project, so ty runs in each tool's own environment
python-typecheck:
	uv run ty check scripts missions
	set -e; for dir in $(PY_TOOLS); do uv run --directory $$dir ty check; done

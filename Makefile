LUA_FILES := $(shell git ls-files '*.lua')
PY_TOOLS := $(patsubst %/pyproject.toml,%,$(wildcard tools/*/pyproject.toml))
# Only missions with a mission file; Operation Overwatch has scripts only until
# the Afghanistan terrain export exists
MISSIONS := $(abspath $(patsubst %/mission,%,$(wildcard missions/*/src/mission)))
LUA_TEST_DIRS := $(wildcard missions/*/tests)
PY_TEST_TOOLS := $(patsubst %/tests,%,$(wildcard tools/*/tests))
LUA ?= luajit

# scipy has no wheels for newer Pythons yet
export UV_PYTHON := 3.14

.DEFAULT_GOAL := help

.PHONY: help format check test format-bun check-format-bun format-lua check-format-lua lint-lua test-lua test-python format-python check-format-python lint-python typecheck-python check-missions

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

format: format-bun format-lua format-python ## Format all files

check: check-format-bun check-format-lua lint-lua test check-format-python lint-python typecheck-python check-missions ## Run all checks (CI)

test: test-lua test-python ## Run all tests

format-bun: ## Format JSON, YAML, TOML, and Markdown
	bun fmt

check-format-bun: ## Check JSON, YAML, TOML, and Markdown formatting
	bun fmt --check

format-lua: ## Format Lua
	stylua $(LUA_FILES)

check-format-lua: ## Check Lua formatting
	stylua --check $(LUA_FILES)

# Checks DCS API calls against the stubs in lua-types/
# Each mission is its own workspace (missions/*/.luarc.json), since missions
# copy shared scripts such as Logging.lua that would collide as globals
lint-lua: ## Lint Lua
	set -e; for dir in $(wildcard missions/*/.luarc.json); do lua-language-server --check $$(dirname $$dir) --checklevel=Warning; done

# DCS uses Lua 5.1. Newer lua releases break 5.1 code, so the tests run on
# luajit, which implements 5.1. luajit also accepts some Lua 5.2 syntax, such
# as goto, that 5.1 rejects; lint-lua checks against 5.1 and reports that
# syntax.
test-lua: ## Run mission Lua tests
	set -e; for dir in $(LUA_TEST_DIRS); do $(LUA) $$dir/run.lua $$dir/*_test.lua; done

test-python: ## Run Python tool tests
	set -e; for dir in $(PY_TEST_TOOLS); do uv run --directory $$dir pytest -q; done

format-python: ## Format Python
	uv run ruff format .

check-format-python: ## Check Python formatting
	uv run ruff format --check .

lint-python: ## Lint Python
	uv run ruff check .

# Each tool is a separate uv project, so ty runs in each tool's own environment
typecheck-python: ## Type check Python
	uv run ty check scripts missions
	set -e; for dir in $(PY_TOOLS); do uv run --directory $$dir ty check; done

check-missions: ## Validate mission sources
	set -e; for dir in $(MISSIONS); do uv run --directory tools/mission-check check-mission check $$dir; done

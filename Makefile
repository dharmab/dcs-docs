LUA_FILES := $(shell git ls-files '*.lua')
PY_TOOLS := $(patsubst %/pyproject.toml,%,$(wildcard tools/*/pyproject.toml))
MISSIONS := $(abspath $(wildcard missions/*/src))
LUA_TEST_DIRS := $(wildcard missions/*/tests)
LUA ?= luajit

# scipy has no wheels for newer Pythons yet
export UV_PYTHON := 3.14

.DEFAULT_GOAL := help

.PHONY: help format check test format-bun check-format-bun format-lua check-format-lua lint-lua test-lua format-python check-format-python lint-python typecheck-python check-missions

help: ## Show this help
	@awk 'BEGIN {FS = ":.*## "} /^[a-z-]+:.*## / {printf "  %-22s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

format: format-bun format-lua format-python ## Format all files

check: check-format-bun check-format-lua lint-lua test check-format-python lint-python typecheck-python check-missions ## Run all checks (CI)

test: test-lua ## Run all tests

format-bun: ## Format JSON, YAML, TOML, and Markdown
	bun fmt

check-format-bun: ## Check JSON, YAML, TOML, and Markdown formatting
	bun fmt --check

format-lua: ## Format Lua
	stylua $(LUA_FILES)

check-format-lua: ## Check Lua formatting
	stylua --check $(LUA_FILES)

# Checks DCS API calls against the stubs in lua-types/
lint-lua: ## Lint Lua
	lua-language-server --check . --checklevel=Warning

# DCS uses Lua 5.1. Newer lua releases break 5.1 code, so the tests run on
# luajit, which implements 5.1. luajit also accepts some Lua 5.2 syntax, such
# as goto, that 5.1 rejects; lint-lua checks against 5.1 and reports that
# syntax.
test-lua: ## Run mission Lua tests
	set -e; for dir in $(LUA_TEST_DIRS); do $(LUA) $$dir/run.lua $$dir/*_test.lua; done

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

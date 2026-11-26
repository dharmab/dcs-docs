# lua-types

`dcs.lua` contains [lua-language-server](https://luals.github.io/) type stubs for the DCS Simulator Scripting Engine (SSE) API. The stubs declare the SSE singletons, classes, and enums, such as `trigger`, `Unit`, and `AI`, with their function signatures and field types.

Without the stubs, lua-language-server reports every SSE global as undefined. With the stubs, lua-language-server offers completion and hover documentation in any editor that uses it, and `lua-language-server --check` reports misspelled functions and wrong argument types in mission scripts. DCS reports these errors only when it executes the faulty line, which can be partway through a mission. The error can crash the mission, including a multiplayer server.

## Usage

In this repository, `.luarc.json` at the repository root adds `lua-types` to `workspace.library` and sets the runtime to Lua 5.1. Editors with a lua-language-server extension read this file automatically. To lint all Lua files from the command line, run:

```sh
lua-language-server --check . --checklevel=Warning
```

`make lint-lua` runs this command.

To use the stubs in another project, add the directory to that project's `.luarc.json`:

```json
{
  "runtime.version": "Lua 5.1",
  "workspace.library": ["/path/to/dcs-docs/lua-types"]
}
```

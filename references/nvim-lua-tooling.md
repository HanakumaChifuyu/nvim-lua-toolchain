# Neovim Lua tooling reference

## Table of contents

- Recommended default stack
- Tool choices
- Environment setup
- Testing and coverage notes
- Decision rules

## Recommended default stack

Use this as the default for new Neovim Lua plugin repositories:

- Test with `plenary.nvim` in headless Neovim
- Generate coverage with `luacov`
- Add formatting only if the repository wants it
- Develop with `lua_ls` and `lazydev.nvim`
- Manage plugin dependencies and local development with `lazy.nvim`

This stack is pragmatic, common in the ecosystem, and easy to explain to contributors.

## Tool choices

### Formatting

Use `stylua` only when the repository wants a formatter.

- Deterministic formatter with broad Lua support
- Common choice for Lua and Neovim projects
- Works well in CI and pre-commit flows
- Good Neovim integration directly or through `conform.nvim`

### Linting

Treat linting as optional in this skill.

- There are workable options such as `luacheck`
- However, this skill currently centers on executable test workflows instead of lint-first setups
- If a repository already uses Lua linting successfully, preserve that setup rather than replacing it casually

### Testing

Pick the runner based on the repository shape.

#### `plenary.nvim`

Prefer this for most Neovim Lua plugins.

- Runs tests inside headless Neovim
- Familiar Busted-style test syntax
- Common community workflow
- Best fit when code depends heavily on the `vim` API

Typical command:

```sh
nvim --headless -u NONE -i NONE \
  -c "luafile tests/minimal_init.lua" \
  -c "PlenaryBustedFile tests/tools_spec.lua" \
  -c "qa"
```

This skill includes a sample local setup:

- `lua/my_namespace/tools.lua`
- `justfile`
- `scripts/install-tools.sh`
- `tests/minimal_init.lua`
- `tests/tools_spec.lua`

#### `busted`

Prefer this for pure Lua libraries or when you need richer Busted features.

- Canonical Lua test framework
- Better if tests should also run outside Neovim
- Can still run in Neovim-oriented workflows via `nvim -l` shims

#### `vusted`

Prefer this when the plugin mixes Lua and Vimscript or wants a more explicitly Neovim-aware Busted wrapper.

- Wrapper around `busted` for Neovim plugin testing
- Good fit for mixed or legacy plugin test suites
- Less common than the Plenary workflow for modern pure-Lua plugins

#### Optional editor UX

These are integrations, not the project test framework itself.

- `neotest` gives in-editor test UI
- `neotest-plenary` is useful when the repository uses Plenary tests
- `mini.test` is a viable alternative ecosystem, but not the default recommendation for this skill

### Coverage

Prefer `luacov`.

- Standard Lua coverage tool
- Works with `busted`
- Can also be used with headless Neovim test runs by loading it before executing tests
- Generates `.luacov` stats and a text report

Optional editor integration:

- `nvim-coverage` can visualize `luacov` reports inside Neovim

## Environment setup

### Editor and language tooling

Prefer this baseline:

- Neovim `>= 0.10`
- `lua_ls` for language-server features
- `lazydev.nvim` for Neovim-aware Lua workspace libraries

Do not recommend `neodev.nvim` as the default. It has been superseded by `lazydev.nvim`.

### Plugin manager and local development

Prefer `lazy.nvim`.

- Strong default in the current Neovim ecosystem
- Lockfile support
- Good local plugin development support
- Easy dependency management

For local plugin development, use `lazy.nvim` dev patterns or prepend the local plugin path to `runtimepath`.

### Project layout

Use the standard Neovim plugin layout unless the repository already has a strong convention:

```text
plugin/myplugin.lua
lua/myplugin/init.lua
lua/myplugin/...
tests/
```

- Put entrypoint code in `plugin/`
- Put main logic in `lua/<plugin>/`
- Put headless tests in `tests/`

### Optional quality-of-life plugins

- `neotest` for test UX
- `nvim-coverage` for coverage visualization

These are editor-side conveniences. Do not confuse them with the repository's required CLI toolchain.

## Testing and coverage notes

When using Plenary tests with coverage, load `luacov` before running the tests. A simple pattern is:

```lua
pcall(require, "luacov")
```

Put that in a test bootstrap file or load it during the headless startup path used for tests.

For CI, prefer a stable headless command and keep user config out of the run.

The local sample workflow in this skill is:

```sh
./scripts/install-tools.sh
just test
just test tests/tools_spec.lua
tests/.rocks/bin/luacov
```

## Decision rules

- For a new Neovim Lua plugin, start with `plenary.nvim` + `luacov`.
- If the repository is a pure Lua library, switch the testing default to `busted`.
- If the repository mixes Lua and Vimscript, consider `vusted`.
- If the user asks for formatting, add `stylua` after the test workflow is already in place.
- If the user asks for editor integration, add `neotest` or `nvim-coverage` only after the CLI workflow exists.

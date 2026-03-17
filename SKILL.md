---
name: nvim-lua-toolchain
description: Set up or update local development and test toolchains for Lua projects, especially Neovim Lua plugins. Use when Claude needs to scaffold or standardize plenary.nvim tests, luacov coverage, headless Neovim test workflows, local dependency installation, LuaLS configuration, lazy.nvim local-plugin development, or related CI and dev-environment setup for a Lua or Neovim repository.
---

# Nvim Lua Toolchain

Use this skill to choose and configure a practical test-focused toolchain for Lua repositories, with defaults tuned for Neovim Lua plugin development.

## Workflow

1. Identify the repository type.
   - Pure Lua library: prefer `busted` + `luacov`, and add formatting separately if the repository wants it.
   - Neovim Lua plugin: prefer `plenary.nvim` headless tests + `luacov`.
   - Mixed Lua and Vimscript plugin, or projects needing fuller Busted features: consider `vusted` or `busted` via `nvim -l`.

2. Read `references/nvim-lua-tooling.md` before selecting tools or writing config.

3. Prefer the repository's existing conventions if the current tools are maintained and already wired into CI or contributor workflows.

4. Add the toolchain in this order:
   - test runner
   - coverage
   - local dependency installation
   - local development and CI integration

5. Keep changes minimal and explicit. Do not add extra plugins or wrappers unless they solve a real workflow gap.

## Default recommendations

- Test runner for most Neovim plugins: `plenary.nvim`
- Alternative test runner for advanced or mixed setups: `busted` or `vusted`
- Coverage: `luacov`
- Formatter when explicitly wanted: `stylua`
- Linting: optional, not a default focus for this skill
- Lua language tooling: `lua_ls` + `lazydev.nvim`
- Plugin manager and local dev workflow: `lazy.nvim`
- Optional editor integrations: `neotest`, `nvim-coverage`

## Resources

- `references/nvim-lua-tooling.md`: current tooling research, decision guide, and environment recommendations for Neovim Lua plugin development.
- `scripts/install-tools.sh`: installs local sample-workflow dependencies for `plenary.nvim` and `luacov`.
- `tests/`: runnable sample using `vim.api` with Plenary and `luacov`.

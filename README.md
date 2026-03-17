# nvim-lua-toolchain

A one-command scaffold for a complete code-quality and test toolchain in Neovim Lua plugin repositories.

> 📖 [中文文档](doc/README.zh-CN.md)

## Stack

| Tool | Purpose |
|---|---|
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | Test runner (headless nvim + busted-style specs) |
| [luacov](https://github.com/lunarmodules/luacov) | Lua coverage instrumentation |
| [stylua](https://github.com/JohnnyMorganz/StyLua) | Lua formatter |
| [luacheck](https://github.com/mpeterv/luacheck) | Lua static analysis |
| [lefthook](https://github.com/evilmartians/lefthook) | Git hooks manager |
| [just](https://github.com/casey/just) | Task runner |

---

## Install the Skill

```bash
bash path/to/nvim-lua-toolchain/install.sh
```

Copies the skill into `~/.claude/skills/nvim-lua-toolchain/`.  
Override the destination with `CLAUDE_SKILLS_DIR`.

---

## Bootstrap a Plugin Repo

Run from the root of your plugin repository:

```bash
bash ~/.claude/skills/nvim-lua-toolchain/scripts/install-tools.sh
```

The script will:

- Copy `tests/minimal_init.lua`, `.luacov`, `.luacheckrc`, `justfile`, `stylua.toml`, `lefthook.yml`, and `scripts/code-review.sh` (existing files are skipped)
- Install `stylua` (via cargo, or download a binary from GitHub releases)
- Check for `luacheck` and print install instructions if missing
- Install `luacov` into `tests/.rocks/`
- Run `lefthook install` if lefthook is available and the directory is a git repo

---

## Usage

```bash
just                          # Run all pre-commit checks (fmt → lint → coverage)
just test                     # Run all specs
just test tests/foo_spec.lua  # Run specific spec files
just coverage                 # Generate a luacov report
just check-coverage           # Fail if coverage is below threshold (default: 70%)
just check-coverage min_coverage=90  # Override threshold
just fmt                      # Format all Lua files with stylua
just fmt-check                # Check formatting without modifying files
just lint                     # Run luacheck
```

---

## Git Hooks

| Hook | Actions |
|---|---|
| `pre-commit` | fmt (stylua) → lint (luacheck) → coverage gate |
| `pre-push` | AI code review (`scripts/code-review.sh`) |

Skip hooks when needed:

```bash
LEFTHOOK=0 git commit                    # Skip all hooks
LEFTHOOK_EXCLUDE=coverage git commit     # Skip coverage only
```

---

## Coverage Threshold

Edit `min_coverage` at the top of `justfile`:

```just
min_coverage := "80"
```

Or override per-run:

```bash
just check-coverage min_coverage=90
```

---

## Repository Layout

```
nvim-lua-toolchain/
├── README.md
├── doc/
│   └── README.zh-CN.md         # Chinese documentation
├── SKILL.md                    # Skill descriptor (read by Claude)
├── install.sh                  # Install this skill into ~/.claude/skills/
├── scripts/
│   └── install-tools.sh        # Bootstrap a target plugin repo
├── template_plugin/            # Complete runnable example plugin
│   ├── lua/my_namespace/
│   │   └── tools.lua
│   ├── tests/
│   │   ├── minimal_init.lua    # Headless nvim bootstrap
│   │   └── tools_spec.lua      # Example specs
│   ├── justfile
│   ├── lefthook.yml
│   ├── stylua.toml
│   ├── .luacov
│   ├── .luacheckrc
│   └── scripts/
│       └── code-review.sh
└── references/
    └── nvim-lua-tooling.md     # Tool selection reference
```

---

## Implementation Notes

**Why single-process for coverage?**  
`test_harness.test_directory()` forks a new nvim process per spec file; luacov's `debug.sethook` only sees lines executed in the parent process. The `coverage` recipe uses `plenary.busted.run()` in a single process so the hook captures all executed lines.

**Why `jit.off()`?**  
LuaJIT's JIT compiler bypasses `debug.sethook` line hooks — JIT-compiled functions always report 0% coverage. Call `jit.off()` **before** `require("luacov")` to keep everything interpreted.

**luacov include patterns omit `.lua`**  
luacov strips the `.lua` extension before matching filenames against patterns. Use `"lua/my_namespace/"`, not `"lua/my_namespace/tools.lua"`.

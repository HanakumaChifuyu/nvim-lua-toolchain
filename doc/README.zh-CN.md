# nvim-lua-toolchain

> 🔙 [English README](../README.md)

一键为 Neovim Lua 插件仓库搭建完整开发质量工具链。

## 这是什么？

这是一个 **Claude Code skill**，可以自动化设置完整的 Lua 开发和测试工具链。虽然这些脚本可以独立运行，但将其作为 skill 在 Claude Code 中使用有以下优势：

- **智能自动化**：Claude 理解你的项目结构并相应地调整设置
- **交互式指导**：在设置过程中遇到问题时获得帮助
- **工作流集成**：与其他 Claude Code skills 和工作流无缝集成
- **上下文感知**：Claude 可以根据你的代码库做出明智的配置决策

在 Claude Code 中使用 `/nvim-lua-toolchain` 调用此 skill，或者在处理 Lua/Neovim 项目时让 Claude 自动建议使用。

## 技术栈与依赖

工具链集成了以下工具，安装脚本会自动帮你设置大部分工具：

| 工具 | 用途 | 自动安装 |
|---|---|---|
| [plenary.nvim](https://github.com/nvim-lua/plenary.nvim) | 测试框架（headless nvim + busted 风格） | 手动（Neovim 插件） |
| [luacov](https://github.com/lunarmodules/luacov) | Lua 覆盖率统计 | ✓（通过 luarocks） |
| [stylua](https://github.com/JohnnyMorganz/StyLua) | Lua 代码格式化 | ✓（通过 cargo 或二进制） |
| [luacheck](https://github.com/mpeterv/luacheck) | Lua 静态分析 | 提供安装说明 |
| [lefthook](https://github.com/evilmartians/lefthook) | Git hooks 管理 | 手动 |
| [just](https://github.com/casey/just) | 任务运行器 | 手动 |

**前置要求**：运行初始化脚本前，请先安装 [just](https://github.com/casey/just#installation)，可选安装 [lefthook](https://github.com/evilmartians/lefthook#installation)。

---

## 安装 Skill

```bash
bash path/to/nvim-lua-toolchain/install.sh
```

将 skill 复制到 `~/.claude/skills/nvim-lua-toolchain/`。  
可以通过 `CLAUDE_SKILLS_DIR` 环境变量覆盖安装路径。

---

## 在插件仓库中初始化工具链

在目标插件仓库的根目录运行：

```bash
bash ~/.claude/skills/nvim-lua-toolchain/scripts/install-tools.sh
```

脚本会完成：

- 复制 `tests/minimal_init.lua`、`.luacov`、`.luacheckrc`、`justfile`、`stylua.toml`、`lefthook.yml`、`scripts/code-review.sh`（已存在的文件跳过）
- 安装 `stylua`（优先用 cargo，否则从 GitHub 下载二进制）
- 检查 `luacheck`，若未安装则打印安装说明
- 将 `luacov` 安装到 `tests/.rocks/`
- 在 git 仓库中自动运行 `lefthook install`

---

## 日常使用

```bash
just            # 运行所有 pre-commit 检查（fmt → lint → coverage）
just test       # 跑所有 spec
just test tests/foo_spec.lua   # 跑指定文件
just coverage   # 生成覆盖率报告
just check-coverage            # 覆盖率低于门槛则失败（默认 70%）
just check-coverage min_coverage=90   # 自定义门槛
just fmt        # 格式化所有 Lua 文件
just fmt-check  # 检查格式（不修改文件）
just lint       # 运行 luacheck
```

---

## Git Hooks

| Hook | 触发动作 |
|---|---|
| `pre-commit` | fmt（stylua）→ lint（luacheck）→ 覆盖率检查 |
| `pre-push` | AI 代码审查（`scripts/code-review.sh`） |

临时跳过：

```bash
LEFTHOOK=0 git commit              # 跳过所有 hooks
LEFTHOOK_EXCLUDE=coverage git commit   # 跳过覆盖率检查
```

---

## 覆盖率门槛

修改 `justfile` 顶部的 `min_coverage` 变量：

```just
min_coverage := "80"   # 改成你想要的百分比
```

---

## 目录结构

```
nvim-lua-toolchain/
├── SKILL.md                    # Skill 描述（供 Claude 读取）
├── install.sh                  # 安装 skill 本身
├── scripts/
│   └── install-tools.sh        # 在目标仓库搭建工具链
├── template_plugin/            # 完整可运行的示例插件
│   ├── lua/my_namespace/
│   │   └── tools.lua
│   ├── tests/
│   │   ├── minimal_init.lua    # headless nvim 启动配置
│   │   └── tools_spec.lua      # 示例测试
│   ├── justfile
│   ├── lefthook.yml
│   ├── stylua.toml
│   ├── .luacov
│   ├── .luacheckrc
│   └── scripts/
│       └── code-review.sh
└── references/
    └── nvim-lua-tooling.md     # 工具选型参考
```

---

## 技术说明

**为什么 coverage 要单进程运行？**  
`test_harness.test_directory()` 会为每个 spec 文件 fork 一个新 nvim 进程，导致 luacov 的 `debug.sethook` 在父进程里采集不到数据。`coverage` recipe 改用 `plenary.busted.run()` 单进程跑所有 spec，确保数据完整。

**为什么要 `jit.off()`？**  
LuaJIT 的 JIT 编译会绕过 `debug.sethook` 的行级钩子，导致被 JIT 编译的函数覆盖率永远是 0。必须在 `require("luacov")` **之前**调用 `jit.off()`。

**luacov include 模式不带 `.lua`**  
luacov 在匹配文件名前会自动去掉 `.lua` 扩展名，`.luacov` 里的 `include` 模式不要写扩展名：用 `"lua/my_namespace/"` 而不是 `"lua/my_namespace/tools.lua"`。

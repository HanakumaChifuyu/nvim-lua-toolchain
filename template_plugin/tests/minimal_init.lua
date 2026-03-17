-- Generic headless Neovim bootstrap for plugin testing.
-- Run from repo root: nvim --headless -u NONE -i NONE -c "luafile tests/minimal_init.lua" ...
--
-- Resolution order for plenary.nvim:
--   1. vendor/plenary.nvim  (local, pinned copy — highest priority)
--   2. lazy.nvim data dir   (~/.local/share/nvim/lazy/plenary.nvim)
--   3. packer opt/start     (~/.local/share/nvim/site/pack/packer/...)
--   4. vim-plug / dein dirs (~/.vim/plugged, ~/.config/nvim/plugged, ...)
--   5. mason / rocks dirs   (~/.local/share/nvim/mason/...)
-- If none of the above exist the bootstrap aborts with a clear error.

local uv = vim.loop or vim.uv
local cwd = uv.cwd()

-- ── helper ────────────────────────────────────────────────────────────────────
local function dir_exists(path)
    local stat = uv.fs_stat(path)
    return stat ~= nil and stat.type == "directory"
end

local function expand(path)
    -- Resolve leading ~ to home directory
    return path:gsub("^~", os.getenv("HOME") or "~")
end

-- ── locate plenary ────────────────────────────────────────────────────────────
local plenary_candidates = {
    -- Local vendor copy (pinned, portable — takes priority)
    cwd .. "/vendor/plenary.nvim",
    -- lazy.nvim
    expand("~/.local/share/nvim/lazy/plenary.nvim"),
    -- packer
    expand("~/.local/share/nvim/site/pack/packer/start/plenary.nvim"),
    expand("~/.local/share/nvim/site/pack/packer/opt/plenary.nvim"),
    -- vim-plug default dirs
    expand("~/.vim/plugged/plenary.nvim"),
    expand("~/.config/nvim/plugged/plenary.nvim"),
    expand("~/.local/share/nvim/plugged/plenary.nvim"),
    -- dein
    expand("~/.cache/dein/repos/github.com/nvim-lua/plenary.nvim"),
    -- rocks.nvim / nvim-neorocks
    expand("~/.local/share/nvim/rocks/pack/rocks/start/plenary.nvim"),
    -- mason (uncommon but possible)
    expand("~/.local/share/nvim/mason/packages/plenary.nvim"),
    -- system-wide
    "/usr/share/nvim/site/pack/default/start/plenary.nvim",
    "/usr/local/share/nvim/site/pack/default/start/plenary.nvim",
}

local plenary_path
for _, candidate in ipairs(plenary_candidates) do
    if dir_exists(candidate) then
        plenary_path = candidate
        break
    end
end

if not plenary_path then
    local msg = table.concat({
        "[minimal_init] ERROR: plenary.nvim not found.",
        "Searched:",
        table.concat(plenary_candidates, "\n  "),
        "",
        "Fix options:",
        "  1. Run ./scripts/install-tools.sh  (clones into vendor/)",
        "  2. Or install plenary via your plugin manager and re-run.",
    }, "\n  ")
    io.stderr:write(msg .. "\n")
    vim.cmd("cquit 1")
    return
end

-- ── runtime paths ─────────────────────────────────────────────────────────────
-- Repo root first so `require("my_namespace.module")` resolves locally
vim.opt.runtimepath:prepend(cwd)
vim.opt.runtimepath:prepend(plenary_path)

-- Source plenary's plugin entry-point so :PlenaryBustedFile / Directory exist
local plenary_plugin = plenary_path .. "/plugin/plenary.vim"
if vim.fn.filereadable(plenary_plugin) == 1 then
    vim.cmd("source " .. plenary_plugin)
end

-- ── luarocks tree (luacov) ────────────────────────────────────────────────────
local rocks_cpath = cwd .. "/tests/.rocks/lib/lua/5.1/?.so"
local rocks_path  = cwd .. "/tests/.rocks/share/lua/5.1/?.lua;"
    .. cwd .. "/tests/.rocks/share/lua/5.1/?/init.lua"

package.path      = rocks_path .. ";" .. package.path
package.cpath     = rocks_cpath .. ";" .. package.cpath

-- Load luacov if available (non-fatal — coverage is optional).
-- plenary.busted calls `cquit` to exit, so subsequent -c commands never run.
-- Use VimLeavePre to flush stats before nvim exits regardless of how it quits.
--
-- NOTE: LuaJIT JIT-compiles functions by default, which bypasses debug.sethook
-- line hooks that luacov relies on. jit.off() must be called BEFORE requiring
-- luacov so the hook is installed while the interpreter is already off.
if jit then
  jit.off()
end
local luacov_ok = pcall(require, "luacov")
if luacov_ok then
  vim.api.nvim_create_autocmd("VimLeavePre", {
    callback = function()
      require("luacov.runner").save_stats()
    end,
  })
end

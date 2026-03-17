-- luacheck configuration for Neovim plugin development
-- Docs: https://luacheck.readthedocs.io/en/stable/config.html

-- Use LuaJIT standard (Neovim embeds LuaJIT)
std = "luajit"

-- Neovim injects `vim` as a global; declare it here so luacheck doesn't flag it.
-- We do NOT add vim.api / vim.fn etc. as sub-globals — luacheck does not do
-- deep field checking, so simply declaring `vim` is enough to silence all false
-- positives while still catching typos in your own code.
globals = { "vim" }

-- Plenary / busted test globals (only relevant inside test files)
read_globals = {
  "describe",
  "it",
  "before_each",
  "after_each",
  "pending",
  "assert",
}

-- Ignore line-length warnings (stylua handles formatting)
max_line_length = false

-- Common patterns to exclude (luacheck uses Lua patterns via string.match)
exclude_files = {
  ".*%.rocks/.*",
  ".*/vendor/.*",
  "vendor/.*",
}

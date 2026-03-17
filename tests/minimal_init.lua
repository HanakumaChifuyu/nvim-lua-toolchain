local config_path = debug.getinfo(1, "S").source:sub(2)
local root = vim.fn.fnamemodify(config_path, ":p:h:h")
local plenary = root .. "/vendor/plenary.nvim"
local rocks_share = root .. "/tests/.rocks/share/lua/5.1"
local rocks_lib = root .. "/tests/.rocks/lib/lua/5.1"

vim.opt.runtimepath:prepend(root)

if vim.fn.isdirectory(plenary) == 1 then
  vim.opt.runtimepath:prepend(plenary)
  vim.cmd.runtime({ "plugin/plenary.vim", bang = true })
end

package.path = table.concat({
  root .. "/?.lua",
  root .. "/?/init.lua",
  root .. "/tests/?.lua",
  root .. "/tests/?/init.lua",
  rocks_share .. "/?.lua",
  rocks_share .. "/?/init.lua",
  package.path,
}, ";")

package.cpath = table.concat({
  rocks_lib .. "/?.so",
  package.cpath,
}, ";")

pcall(require, "luacov")

vim.opt.swapfile = false
vim.opt.shada = ""

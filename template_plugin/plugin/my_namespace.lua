-- Registers :MyToolsDemo — opens a scratch buffer with sample content.
-- This file is auto-sourced by Neovim when the plugin dir is in runtimepath.
vim.api.nvim_create_user_command("MyToolsDemo", function()
  local tools = require("my_namespace.tools")

  local bufnr = tools.create_scratch_buffer({ "Hello from my_namespace.tools!", "", "Lines:" })
  for i = 1, 3 do
    tools.append_line(bufnr, string.format("  line %d", i))
  end

  -- Open the scratch buffer in a new split
  vim.cmd("split")
  vim.api.nvim_win_set_buf(0, bufnr)

  vim.notify("MyToolsDemo loaded buffer #" .. bufnr, vim.log.levels.INFO)
end, { desc = "Demo: create a scratch buffer via my_namespace.tools" })

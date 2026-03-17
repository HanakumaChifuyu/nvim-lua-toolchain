local M = {}

function M.create_scratch_buffer(lines)
  if type(lines) ~= "table" then
    error("lines must be a table", 2)
  end

  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return bufnr
end

function M.read_lines(bufnr)
  if type(bufnr) ~= "number" then
    error("bufnr must be a number", 2)
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    error("invalid buffer", 2)
  end

  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

function M.append_line(bufnr, line)
  if type(bufnr) ~= "number" then
    error("bufnr must be a number", 2)
  end

  if type(line) ~= "string" then
    error("line must be a string", 2)
  end

  if not vim.api.nvim_buf_is_valid(bufnr) then
    error("invalid buffer", 2)
  end

  local last_line = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, last_line, last_line, false, { line })
  return M.read_lines(bufnr)
end

return M

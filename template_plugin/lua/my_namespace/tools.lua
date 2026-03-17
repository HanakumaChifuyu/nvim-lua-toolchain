local M = {}

--- Create a scratch buffer pre-populated with lines.
--- @param lines string[]
--- @return integer bufnr
function M.create_scratch_buffer(lines)
  if type(lines) ~= "table" then
    error("lines must be a table")
  end
  local bufnr = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, lines)
  return bufnr
end

--- Read all lines from a buffer.
--- @param bufnr integer
--- @return string[]
function M.read_lines(bufnr)
  if type(bufnr) ~= "number" then
    error("bufnr must be a number")
  end
  return vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
end

--- Append a line to a buffer and return the updated lines.
--- @param bufnr integer
--- @param line string
--- @return string[]
function M.append_line(bufnr, line)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    error("invalid buffer")
  end
  local count = vim.api.nvim_buf_line_count(bufnr)
  vim.api.nvim_buf_set_lines(bufnr, count, count, false, { line })
  return M.read_lines(bufnr)
end

return M

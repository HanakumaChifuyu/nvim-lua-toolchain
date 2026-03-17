local sample_buffer = require("tests.fixtures.sample_buffer")

describe("sample_buffer", function()
  local bufnr

  after_each(function()
    if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
      vim.api.nvim_buf_delete(bufnr, { force = true })
    end
    bufnr = nil
  end)

  it("creates a scratch buffer with the provided lines", function()
    bufnr = sample_buffer.create_scratch_buffer({ "alpha", "beta" })

    assert.True(vim.api.nvim_buf_is_valid(bufnr))
    assert.are.same({ "alpha", "beta" }, sample_buffer.read_lines(bufnr))
  end)

  it("handles empty input", function()
    bufnr = sample_buffer.create_scratch_buffer({})

    assert.are.same({ "" }, sample_buffer.read_lines(bufnr))
  end)

  it("appends a line using vim.api", function()
    bufnr = sample_buffer.create_scratch_buffer({ "first" })

    local lines = sample_buffer.append_line(bufnr, "second")

    assert.are.same({ "first", "second" }, lines)
  end)

  it("preserves special characters", function()
    bufnr = sample_buffer.create_scratch_buffer({ 'quote " test', "emoji 😀", "" })

    assert.are.same({ 'quote " test', "emoji 😀", "" }, sample_buffer.read_lines(bufnr))
  end)

  it("rejects invalid input", function()
    assert.has_error(function()
      sample_buffer.create_scratch_buffer("not-a-table")
    end, "lines must be a table")

    assert.has_error(function()
      sample_buffer.read_lines("bad-buffer")
    end, "bufnr must be a number")

    assert.has_error(function()
      sample_buffer.append_line(-1, "value")
    end, "invalid buffer")
  end)
end)

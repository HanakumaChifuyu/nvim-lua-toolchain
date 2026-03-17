local tools = require("my_namespace.tools")

describe("my_namespace.tools", function()
    local bufnr

    after_each(function()
        if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
            vim.api.nvim_buf_delete(bufnr, { force = true })
        end
        bufnr = nil
    end)

    it("creates a scratch buffer with the provided lines", function()
        bufnr = tools.create_scratch_buffer({ "alpha", "beta" })

        assert.True(vim.api.nvim_buf_is_valid(bufnr))
        assert.are.same({ "alpha", "beta" }, tools.read_lines(bufnr))
    end)

    it("handles empty input", function()
        bufnr = tools.create_scratch_buffer({})

        -- nvim always returns at least one empty string for an empty buffer
        assert.are.same({ "" }, tools.read_lines(bufnr))
    end)

    it("appends a line using vim.api", function()
        bufnr = tools.create_scratch_buffer({ "first" })

        local lines = tools.append_line(bufnr, "second")

        assert.are.same({ "first", "second" }, lines)
    end)

    it("preserves special characters", function()
        bufnr = tools.create_scratch_buffer({ 'quote " test', "emoji 😀", "" })

        assert.are.same({ 'quote " test', "emoji 😀", "" }, tools.read_lines(bufnr))
    end)

    it("rejects invalid input", function()
        assert.has_error(function()
            tools.create_scratch_buffer("not-a-table")
        end, "lines must be a table")

        assert.has_error(function()
            tools.read_lines("bad-buffer")
        end, "bufnr must be a number")

        assert.has_error(function()
            tools.append_line(-1, "value")
        end, "invalid buffer")
    end)
end)

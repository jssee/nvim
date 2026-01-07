---@param s string The string containing Lua pattern special characters that need to be escaped
---@return string The input string with all Lua pattern special characters escaped with a '%' prefix
local function escape_lua_pattern(s)
    local matches = {
        ["^"] = "%^",
        ["$"] = "%$",
        ["("] = "%(",
        [")"] = "%)",
        ["%"] = "%%",
        ["."] = "%.",
        ["["] = "%[",
        ["]"] = "%]",
        ["*"] = "%*",
        ["+"] = "%+",
        ["-"] = "%-",
        ["?"] = "%?",
    }
    return (s:gsub(".", matches))
end

local targets = { '"', "'", "(", ")", "{", "}", "[", "]", "`" }

function Pop()
    local current_row, current_col = unpack(vim.api.nvim_win_get_cursor(0))
    local line_count_in_buf = vim.api.nvim_buf_line_count(0)
    local lines_in_buf =
        vim.api.nvim_buf_get_lines(0, current_row - 1, line_count_in_buf, false)

    local target_row = 0
    local target_col = nil
    for i, line in ipairs(lines_in_buf) do
        for _, char in ipairs(targets) do
            local found_col =
                string.find(line, escape_lua_pattern(char), current_col + 1)
            if found_col and (not target_col or found_col < target_col) then
                target_col = found_col
            end
        end
        if target_col then
            target_row = current_row + i - 1
            break
        end
        current_col = 0
    end
    if target_col then
        vim.api.nvim_win_set_cursor(0, { target_row, target_col })
    else
        print "next target not found."
    end
end

-- vim.keymap.set("i", "<c-l>", function()
--     Pop()
-- end, { desc = "pop in and out of surroundings" })

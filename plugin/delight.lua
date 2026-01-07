-- local Delight = function(char)
--     local toggle = function(c)
--         local keys = { "<CR>", "n", "N", "*", "#", "?", "/" }
--         local new_hlsearch = vim.tbl_contains(keys, c)
--
--         if vim.opt.hlsearch:get() ~= new_hlsearch then
--             vim.opt.hlsearch = new_hlsearch
--         end
--     end
--
--     local key = vim.fn.keytrans(char)
--     local mode = vim.fn.mode()
--     if mode == "n" then
--         toggle(key)
--     end
-- end

---@param mode? "clear"
local function searchCountIndicator(mode)
    local signColumnPlusScrollbarWidth = 2 + 3 -- CONFIG

    local countNs = vim.api.nvim_create_namespace "searchCounter"
    vim.api.nvim_buf_clear_namespace(0, countNs, 0, -1)
    if mode == "clear" then
        return
    end

    local row = vim.api.nvim_win_get_cursor(0)[1]
    local count = vim.fn.searchcount()
    if count.total == 0 then
        return
    end
    local text = (" %d/%d "):format(count.current, count.total)
    local line =
        vim.api.nvim_get_current_line():gsub("\t", (" "):rep(vim.bo.shiftwidth))
    local lineFull = #line + signColumnPlusScrollbarWidth
        >= vim.api.nvim_win_get_width(0)
    local margin = { (" "):rep(lineFull and signColumnPlusScrollbarWidth or 0) }

    vim.api.nvim_buf_set_extmark(0, countNs, row - 1, 0, {
        virt_text = { { text, "IncSearch" }, margin },
        virt_text_pos = lineFull and "right_align" or "eol",
        priority = 200, -- so it comes in front of `nvim-lsp-endhints`
    })
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("plugin/delight", { clear = true }),
    desc = "remove hlsearch after motions",
    callback = function()
        vim.on_key(function(char)
            local key = vim.fn.keytrans(char)
            local isCmdlineSearch = vim.fn.getcmdtype():find "[/?]" ~= nil
            local isNormalMode = vim.api.nvim_get_mode().mode == "n"
            local searchStarted = (key == "/" or key == "?") and isNormalMode
            local searchConfirmed = (key == "<CR>" and isCmdlineSearch)
            local searchCancelled = (key == "<Esc>" and isCmdlineSearch)
            if
                not (
                    searchStarted
                    or searchConfirmed
                    or searchCancelled
                    or isNormalMode
                )
            then
                return
            end

            -- works for RHS, therefore no need to consider remaps
            local searchMovement = vim.tbl_contains({ "n", "N", "*", "#" }, key)
            local shortPattern = vim.fn.getreg("/"):gsub([[\V\C]], ""):len()
                <= 1 -- for `fF`

            if
                searchCancelled or (not searchMovement and not searchConfirmed)
            then
                vim.opt.hlsearch = false
                searchCountIndicator "clear"
            elseif
                (searchMovement and not shortPattern)
                or searchConfirmed
                or searchStarted
            then
                vim.opt.hlsearch = true
                vim.defer_fn(searchCountIndicator, 1)
            end
        end, vim.api.nvim_create_namespace "autoNohlAndSearchCount")
    end,
})

-- without the `searchCountIndicator`, this `on_key` simply does `auto-nohl`
-- vim.on_key(function(char)
--     local key = vim.fn.keytrans(char)
--     local isCmdlineSearch = vim.fn.getcmdtype():find "[/?]" ~= nil
--     local isNormalMode = vim.api.nvim_get_mode().mode == "n"
--     local searchStarted = (key == "/" or key == "?") and isNormalMode
--     local searchConfirmed = (key == "<CR>" and isCmdlineSearch)
--     local searchCancelled = (key == "<Esc>" and isCmdlineSearch)
--     if
--         not (
--             searchStarted
--             or searchConfirmed
--             or searchCancelled
--             or isNormalMode
--         )
--     then
--         return
--     end
--
--     -- works for RHS, therefore no need to consider remaps
--     local searchMovement = vim.tbl_contains({ "n", "N", "*", "#" }, key)
--     local shortPattern = vim.fn.getreg("/"):gsub([[\V\C]], ""):len() <= 1 -- for `fF`
--
--     if searchCancelled or (not searchMovement and not searchConfirmed) then
--         vim.opt.hlsearch = false
--         searchCountIndicator "clear"
--     elseif
--         (searchMovement and not shortPattern)
--         or searchConfirmed
--         or searchStarted
--     then
--         vim.opt.hlsearch = true
--         vim.defer_fn(searchCountIndicator, 1)
--     end
-- end, vim.api.nvim_create_namespace "autoNohlAndSearchCount")

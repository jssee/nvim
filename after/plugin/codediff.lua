-- Modelines such as init.lua's fdm=marker would fold the diff panes. Neovim
-- reapplies modelines whenever a buffer enters a window, so unfold the whole
-- diff tab on open and after each switch, leaving compact mode's folds alone.
local group = vim.api.nvim_create_augroup("after/codediff", { clear = true })

local session = function(tabpage)
    return require("codediff.ui.lifecycle").get_session(tabpage)
end

local unfold = function(tabpage)
    local s = session(tabpage)
    if s and s.compact_mode then
        return
    end
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(tabpage)) do
        vim.wo[win].foldenable = false
    end
end

-- A bare `:CodeDiff file` fires CodeDiffOpen before creating its session.
vim.api.nvim_create_autocmd("User", {
    group = group,
    pattern = "CodeDiffOpen",
    desc = "disable folds in a new codediff tab",
    callback = function(ev)
        unfold(ev.data.tabpage)
    end,
})

vim.api.nvim_create_autocmd("BufWinEnter", {
    group = group,
    desc = "disable folds in codediff panes",
    callback = function()
        local tabpage = vim.api.nvim_get_current_tabpage()
        if session(tabpage) then
            unfold(tabpage)
        end
    end,
})

-- Neovim's default statusline, with the git branch and diff counts from
-- mini.git and mini.diff at the start of its right-aligned section. Extending
-- the default keeps its diagnostics, LSP progress and busy indicator current.
-- Each `%(...%)` group hides itself, spacing included, while its value is empty.
local default = vim.api.nvim_get_option_info2("statusline", {}).default --[[@as string]]
local git = "%(%{get(b:,'minigit_summary_string','')} %)"
    .. "%(%{get(b:,'minidiff_summary_string','')} %)"
vim.o.statusline = default:gsub("%%=", function(align)
    return align .. git
end, 1)

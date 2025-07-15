vim.keymap.set("n", "<leader>tf", function()
    vim.cmd [[VtsExec file_references]]
end)
vim.keymap.set("n", "<leader>ti", function()
    vim.cmd [[VtsExec add_missing_imports]]
end)
vim.keymap.set("n", "<leader>tr", function()
    vim.cmd [[VtsExec remove_unused_importsadd_missing_imports]]
end)
vim.keymap.set("n", "<leader>tt", [[:VtsExec<space>]])

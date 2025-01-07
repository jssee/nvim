vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.astro",
    command = "set filetype=astro",
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
    pattern = "*.heex",
    command = "set filetype=heex",
})


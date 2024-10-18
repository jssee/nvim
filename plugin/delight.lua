local Delight = function(char)
    local toggle = function(c)
        local keys = { "<CR>", "n", "N", "*", "#", "?", "/" }
        local new_hlsearch = vim.tbl_contains(keys, c)

        if vim.opt.hlsearch:get() ~= new_hlsearch then
            vim.opt.hlsearch = new_hlsearch
        end
    end

    local key = vim.fn.keytrans(char)
    local mode = vim.fn.mode()
    if mode == "n" then
        toggle(key)
    end
end

vim.api.nvim_create_autocmd("VimEnter", {
    group = vim.api.nvim_create_augroup("plugin/delight", { clear = true }),
    desc = "remove hlsearch after motions",
    callback = function()
        vim.on_key(Delight, vim.api.nvim_create_namespace "delight")
    end,
})

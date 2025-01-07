local Qgrep = function(args)
    vim.api.nvim_exec_autocmds(
        "QuickFixCmdPre",
        { pattern = "cgetexpr", modeline = false }
    )

    vim.fn.setqflist({}, " ", {
        title = "search results",
        lines = vim.fn.systemlist(vim.opt.grepprg:get() .. " " .. args),
    })

    vim.api.nvim_exec_autocmds(
        "QuickFixCmdPost",
        { pattern = "cgetexpr", modeline = false }
    )
end

vim.api.nvim_create_user_command("Qg", function(opts)
    Qgrep(opts.args)
end, {
    nargs = "+",
    complete = "file_in_path",
    bar = true,
})

vim.keymap.set("n", "<leader>/", [[:Qg<space>]], { desc = "quick grep" })
vim.keymap.set(
    "n",
    "<leader>.",
    [[:Qg <C-R>=expand("<cword>")<CR><CR>]],
    { desc = "quick grep" }
)

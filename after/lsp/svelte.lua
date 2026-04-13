local root_markers = {
    {
        "package-lock.json",
        "yarn.lock",
        "pnpm-lock.yaml",
        "bun.lockb",
        "bun.lock",
        "deno.lock",
    },
    ".git",
}

---@type vim.lsp.Config
return {
    cmd = { "svelteserver", "--stdio" },
    filetypes = { "svelte" },
    root_dir = function(bufnr, on_dir)
        local file_path = vim.api.nvim_buf_get_name(bufnr)

        -- Svelte LSP only supports file:// URIs.
        if vim.uv.fs_stat(file_path) == nil then
            return
        end

        on_dir(vim.fs.root(bufnr, root_markers) or vim.fn.getcwd())
    end,
    on_attach = function(client, bufnr)
        local ts_or_js_group = vim.api.nvim_create_augroup(
            ("lsp.svelte.%d"):format(client.id),
            { clear = true }
        )

        -- Work around missing JS/TS change notifications.
        -- https://github.com/sveltejs/language-tools/issues/2008
        vim.api.nvim_create_autocmd("BufWritePost", {
            group = ts_or_js_group,
            pattern = { "*.js", "*.ts" },
            callback = function(ctx)
                ---@diagnostic disable-next-line: param-type-mismatch
                client:notify("$/onDidChangeTsOrJsFile", { uri = ctx.match })
            end,
        })

        vim.api.nvim_buf_create_user_command(
            bufnr,
            "LspMigrateToSvelte5",
            function()
                client:exec_cmd {
                    title = "Migrate Component to Svelte 5 Syntax",
                    command = "migrate_to_svelte_5",
                    arguments = { vim.uri_from_bufnr(bufnr) },
                }
            end,
            { desc = "Migrate Component to Svelte 5 Syntax" }
        )
    end,
}

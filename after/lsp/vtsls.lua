local mason_packages = vim.fs.joinpath(vim.fn.expand "$MASON", "packages")
local root_markers = {
    {
        "package-lock.json",
        "yarn.lock",
        "pnpm-lock.yaml",
        "bun.lockb",
        "bun.lock",
    },
    ".git",
}

---@return table
local function get_svelte_ls_plugin()
    local location = vim.fs.joinpath(mason_packages, "svelte-language-server")
    if vim.fn.isdirectory(location) == 0 then
        return {}
    end

    return {
        name = "typescript-svelte-plugin",
        location = location,
        languages = { "svelte" },
        configNamespace = "typescript",
        enableForWorkspaceTypeScriptVersions = true,
    }
end

---@type vim.lsp.Config
return {
    cmd = { "vtsls", "--stdio" },
    init_options = {
        hostInfo = "neovim",
    },
    filetypes = {
        "javascript",
        "javascriptreact",
        "javascript.jsx",
        "typescript",
        "typescriptreact",
        "typescript.tsx",
        "svelte",
    },
    settings = {
        vtsls = {
            tsserver = {
                globalPlugins = {
                    get_svelte_ls_plugin(),
                },
            },
        },
        typescript = {
            inlayHints = {
                parameterNames = { enabled = "literals" },
                parameterTypes = { enabled = true },
                variableTypes = { enabled = true },
                propertyDeclarationTypes = { enabled = true },
                functionLikeReturnTypes = { enabled = true },
                enumMemberValues = { enabled = true },
            },
        },
    },
    root_dir = function(bufnr, on_dir)
        if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
            return
        end

        on_dir(vim.fs.root(bufnr, root_markers) or vim.fn.getcwd())
    end,
}

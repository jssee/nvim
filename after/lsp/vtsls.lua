local mason_packages = vim.fn.expand "$MASON/packages"
local function get_svelte_ls_config()
    local svelte_ls_path = mason_packages .. "/svelte-language-server"

    return vim.fn.isdirectory(svelte_ls_path) == 1
            and {
                name = "typescript-svelte-plugin",
                location = svelte_ls_path,
                languages = { "svelte" },
                configNamespace = "typescript",
                enableForWorkspaceTypeScriptVersions = true,
            }
        or {}
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
                    get_svelte_ls_config(),
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
        -- The project root is where the LSP can be started from
        -- As stated in the documentation above, this LSP supports monorepos and simple projects.
        -- We select then from the project root, which is identified by the presence of a package
        -- manager lock file.
        local root_markers = {
            "package-lock.json",
            "yarn.lock",
            "pnpm-lock.yaml",
            "bun.lockb",
            "bun.lock",
        }
        -- Give the root markers equal priority by wrapping them in a table
        root_markers = vim.fn.has "nvim-0.11.3" == 1
                and { root_markers, { ".git" } }
            or vim.list_extend(root_markers, { ".git" })

        -- exclude deno
        if vim.fs.root(bufnr, { "deno.json", "deno.jsonc", "deno.lock" }) then
            return
        end

        -- We fallback to the current working directory if no project root is found
        local project_root = vim.fs.root(bufnr, root_markers) or vim.fn.getcwd()

        on_dir(project_root)
    end,
}

--@variables
vim.g.mapleader = " "
vim.g.softabstop = 2
vim.g.showbreak = "↪  "

--@opts
vim.opt.breakindent = true
vim.opt.copyindent = true
vim.opt.clipboard = vim.opt.clipboard:append "unnamedplus"
vim.opt.cursorline = true
vim.opt.cursorlineopt = { "number" }
vim.opt.expandtab = true
vim.opt.exrc = true
vim.opt.fillchars = { diff = "╱" }
vim.opt.grepprg = [[rg --vimgrep]]
vim.opt.ignorecase = true
vim.opt.infercase = true
vim.opt.laststatus = 3
vim.opt.list = true
vim.opt.listchars =
    { tab = "⁚⁚", trail = "·", extends = "→", precedes = "←" }
vim.opt.number = true
vim.opt.ruler = false
vim.opt.scrolloff = 999
vim.opt.shiftround = true
vim.opt.signcolumn = "yes:1"
vim.opt.showcmd = false
vim.opt.showmode = false
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.textwidth = 200
vim.opt.undofile = true
vim.opt.completeopt = {
    "menuone", -- only show popup when theres more than one item
    "popup", -- show extra info in popup
    "noselect", -- do not auto select a match
    "fuzzy", -- enable fuzzy-matching
    "nosort",
}

--@keymaps
vim.keymap.set({ "n", "x" }, ";", ":", { desc = "command mode" })
vim.keymap.set({ "n", "x" }, ":", ";")
vim.keymap.set({ "i", "c" }, "kj", "<esc>")
vim.keymap.set("n", "j", [[gj]])
vim.keymap.set("n", "k", [[gk]])
vim.keymap.set("n", "*", [[*zvzzN]])
vim.keymap.set("n", "n", [[nzvzz]])
vim.keymap.set("n", "N", [[Nzvzz]])
vim.keymap.set("n", "<backspace>", [[^]])
vim.keymap.set("n", "q", "<nop>")

--@autocmds
local augroup = vim.api.nvim_create_augroup("user_cmds", { clear = true })
vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "highlight on yank",
    group = augroup,
    callback = function()
        vim.highlight.on_yank { higroup = "Visual", timeout = 300 }
    end,
})
vim.api.nvim_create_autocmd("FileType", {
    desc = "close window with <q>",
    group = augroup,
    pattern = {
        "help",
        "qf",
        "man",
        "scratch",
        "DiffviewFileHistory",
        "DiffviewFiles",
    },
    callback = function(args)
        vim.keymap.set("n", "q", [[<cmd>close<cr>]], { buffer = args.buf })
    end,
})
vim.api.nvim_create_autocmd("WinResized", {
    desc = "rebalance window sizes",
    group = augroup,
    callback = function()
        vim.cmd.wincmd [[=]]
    end,
})

--@packages

local setup_files = function()
    require("mini.files").setup {
        mappings = {
            go_in_plus = "l",
        },
    }

    vim.keymap.set("n", "-", function()
        local MiniFiles = require "mini.files"
        if not MiniFiles.close() then
            MiniFiles.open(vim.api.nvim_buf_get_name(0))
            MiniFiles.reveal_cwd()
        end
    end, { silent = true, desc = "toggle mini.files" })

    vim.api.nvim_create_autocmd("User", {
        desc = "Add minifiles split keymaps",
        pattern = "MiniFilesBufferCreate",
        callback = function(args)
            local buf_id = args.data.buf_id
            local MiniFiles = require "mini.files"
            local map_split = function(buf, lhs, direction)
                local rhs = function()
                    -- Make new window and set it as target
                    local new_target_window
                    vim.api.nvim_win_call(
                        MiniFiles.get_explorer_state().target_window,
                        function()
                            vim.cmd(direction .. " split")
                            new_target_window = vim.api.nvim_get_current_win()
                        end
                    )
                    MiniFiles.set_target_window(new_target_window)
                    MiniFiles.go_in()
                    MiniFiles.close()
                end
                local desc = "Split " .. direction
                vim.keymap.set("n", lhs, rhs, { buffer = buf, desc = desc })
            end

            map_split(buf_id, "s", "belowright horizontal")
            map_split(buf_id, "v", "belowright vertical")
        end,
    })
end

local setup_picker = function()
    require("mini.pick").setup {
        window = {
            config = {
                height = math.floor(vim.o.lines * 0.2),
                border = "none",
            },
        },
    }
    vim.ui.select = require("mini.pick").ui_select
    vim.keymap.set("n", "<leader>fb", function()
        require("mini.pick").builtin.buffers()
    end, { silent = true, desc = "open buffer picker" })
    vim.keymap.set("n", "<leader>fg", function()
        require("mini.pick").builtin.grep_live()
    end, { silent = true, desc = "open live grep" })
    vim.keymap.set("n", "<leader><space>", function()
        require("mini.pick").builtin.files()
    end, { silent = true, desc = "open file picker" })
    vim.keymap.set("n", "<leader>z", function()
        require("mini.pick").builtin.resume()
    end, { silent = true, desc = "resume last picker" })
end

local setup_completion = function()
    local MiniCompletion = require "mini.completion"
    local MiniMapMulti = require("mini.keymap").map_multistep

    local process_items_opts =
        -- filter out Text and Snippet items, use fuzzy matching
        { filtersort = "fuzzy", kind_priority = { Text = -1, Snippet = -1 } }
    local process_items = function(items, base)
        return MiniCompletion.default_process_items(
            items,
            base,
            process_items_opts
        )
    end

    MiniCompletion.setup {
        lsp_completion = {
            source_func = "omnifunc",
            auto_setup = false,
            process_items = process_items,
        },
    }

    local on_attach = function(args)
        vim.bo[args.buf].omnifunc = "v:lua.MiniCompletion.completefunc_lsp"
    end
    vim.api.nvim_create_autocmd("LspAttach", { callback = on_attach })
    vim.lsp.config(
        "*",
        { capabilities = MiniCompletion.get_lsp_capabilities() }
    )

    MiniMapMulti(
        "i",
        "<Tab>",
        { "pmenu_next", "increase_indent", "jump_after_close" }
    )
    MiniMapMulti(
        "i",
        "<S-Tab>",
        { "pmenu_prev", "decrease_indent", "jump_before_open" }
    )
end

vim.pack.add({
    "https://github.com/nvim-lua/plenary.nvim",
    "https://github.com/folke/snacks.nvim",
    "https://github.com/sindrets/diffview.nvim",
    "https://github.com/yioneko/nvim-vtsls",
    {
        src = "https://github.com/folke/tokyonight.nvim",
        data = {
            setup = function()
                vim.cmd.colo [[tokyonight]]
            end,
        },
    },
    {
        src = "https://github.com/strash/everybody-wants-that-line.nvim",
        data = {
            setup = function()
                require("everybody-wants-that-line").setup {
                    filename = { enabled = false },
                    separator = " ",
                }
            end,
        },
    },
    {
        src = "https://github.com/coder/claudecode.nvim",
        data = {
            setup = function()
                local toggle_key = "<C-,>"
                require("claudecode").setup {
                    terminal = {
                        snacks_win_opts = {
                            position = "right",
                            width = 0.4,
                            height = 1.0,
                            border = "rounded",
                            keys = {
                                claude_hide = {
                                    toggle_key,
                                    function(self)
                                        self:hide()
                                    end,
                                    mode = "t",
                                    desc = "Hide",
                                },
                            },
                        },
                    },
                    diff_opts = {
                        open_in_current_tab = false,
                    },
                }
                vim.keymap.set(
                    { "n", "x" },
                    toggle_key,
                    "<cmd>ClaudeCodeFocus<cr>",
                    { silent = true, desc = "claudecode toggle" }
                )
                vim.keymap.set(
                    { "n", "x" },
                    "<leader>da",
                    "<cmd>ClaudeCodeDiffAccept<cr>",
                    { silent = true, desc = "claudecode diff accept" }
                )
                vim.keymap.set(
                    { "n", "x" },
                    "<leader>dd",
                    "<cmd>ClaudeCodeDiffDeny<cr>",
                    { silent = true, desc = "claudecode diff deny" }
                )
            end,
        },
    },
    {
        src = "https://github.com/stevearc/conform.nvim",
        data = {
            setup = function()
                local conform = require "conform"
                local util = require "conform.util"
                local mason_bin = vim.fn.expand "$MASON/bin"
                conform.setup {
                    formatters_by_ft = {
                        astro = { "prettierd" },
                        css = { "prettierd" },
                        html = { "prettierd" },
                        javascript = { "prettierd" },
                        javascriptreact = { "prettierd" },
                        lua = { "stylua" },
                        svelte = { "prettierd" },
                        typescript = { "prettierd" },
                        typescriptreact = { "prettierd" },
                        go = { "gofmt" },
                        elixir = { "mix", "format" },
                        heex = { "mix", "format" },
                    },
                    format_on_save = {
                        timeout_ms = 800,
                        lsp_format = "fallback",
                    },
                    formatters = {
                        prettierd = {
                            command = util.find_executable({
                                "node_modules/.bin/prettierd",
                                mason_bin .. "/prettierd",
                            }, "prettierd"),
                        },
                        stylua = {
                            command = util.find_executable({
                                mason_bin .. "/stylua",
                            }, "stylua"),
                        },
                    },
                }

                vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
            end,
        },
    },
    {
        src = "https://github.com/folke/flash.nvim",
        data = {
            setup = function()
                require("flash").setup {}
                vim.keymap.set("o", "s", function()
                    require("flash").remote()
                end, { silent = true, desc = "flash remote" })
                vim.keymap.set({ "n", "x" }, "<leader>s", function()
                    require("flash").jump()
                end, { desc = "flash jump" })
                vim.keymap.set({ "n", "x" }, "<leader>S", function()
                    require("flash").treesitter()
                end, { desc = "flash jump" })
            end,
        },
    },
    {
        src = "https://github.com/mason-org/mason.nvim",
        data = {
            setup = function()
                require("mason").setup()
                vim.lsp.enable {
                    "lua",
                    "svelte",
                    "tailwindcss",
                    "vtsls",
                }

                vim.api.nvim_create_autocmd("LspAttach", {
                    desc = "setup lsp actions",
                    group = vim.api.nvim_create_augroup(
                        "lsp",
                        { clear = true }
                    ),
                    callback = function(event)
                        local on_attach = function(client, _)
                            -- disable lsp formatting in favor of conform
                            client.server_capabilities.documentFormattingProvider =
                                false
                            client.server_capabilities.documentRangeFormattingProvider =
                                false
                        end
                        local client =
                            vim.lsp.get_client_by_id(event.data.client_id)
                        on_attach(client, event.buf)
                    end,
                })

                -- Add diagnostics to quick-fix list
                do
                    local diagnostics = "textDocument/publishDiagnostics"
                    local default_handler = vim.lsp.handlers[diagnostics]
                    vim.lsp.handlers[diagnostics] = function(
                        err,
                        method,
                        result,
                        client_id
                    )
                        default_handler(err, method, result, client_id)
                        vim.diagnostic.setloclist { open = false }
                    end
                end

                -- Customize how diagnostics are displayed
                vim.diagnostic.config {
                    virtual_text = { current_line = true },
                    signs = { priority = 0 },
                    update_in_insert = false,
                    severity_sort = false,
                }
            end,
        },
    },
    {
        src = "https://github.com/nvim-mini/mini.nvim",
        data = {
            setup = function()
                require("mini.ai").setup {}
                require("mini.align").setup {}
                require("mini.bracketed").setup {}
                require("mini.cmdline").setup {}
                require("mini.diff").setup {}
                require("mini.extra").setup {}
                require("mini.icons").setup {}
                require("mini.pairs").setup {}
                require("mini.surround").setup {}
                require("mini.operators").setup {
                    replace = { prefix = "rg" }, -- for the sake of lsp gr*
                }
                require("mini.icons").tweak_lsp_kind()
                require("mini.notify").setup {
                    window = {
                        config = {
                            border = "none",
                        },
                    },
                }
                local notify_opts = { ERROR = { duration = 10000 } }
                vim.notify = require("mini.notify").make_notify(notify_opts)

                setup_completion()
                setup_files()
                setup_picker()
            end,
        },
    },
    {
        src = "https://github.com/NeogitOrg/neogit",
        data = {
            setup = function()
                require("neogit").setup {
                    disable_hint = true,
                    graph_style = "kitty",
                    integrations = {
                        diffview = true,
                        mini_pick = true,
                    },
                    sections = {
                        recent = { folded = false },
                    },
                    signs = {
                        -- { CLOSED, OPENED }
                        section = { "▸", "▾" },
                        item = { "▸", "▾" },
                    },
                }
                vim.keymap.set("n", "<leader>gg", function()
                    require("neogit").open()
                end, { silent = true, desc = "git status" })
                vim.keymap.set("n", "<leader>gc", function()
                    require("neogit").open { "commit" }
                end, { silent = true, desc = "git commit" })

                require("diffview").setup {
                    use_icons = false,
                }
                vim.keymap.set("n", "<leader>gh", function()
                    vim.cmd.DiffviewFileHistory "%"
                end, { silent = true, desc = "git status" })
            end,
        },
    },
    {
        src = "https://github.com/stevearc/overseer.nvim",
        data = {
            setup = function()
                require("overseer").setup {}
                vim.keymap.set("n", "<leader>oo", "<cmd>OverseerToggle<CR>")
                vim.keymap.set("n", "<leader>or", "<cmd>OverseerRun<CR>")
                vim.keymap.set("n", "<leader>os", "<cmd>OverseerShell<CR>")
            end,
        },
    },
    {
        src = "https://github.com/stevearc/quicker.nvim",
        data = {
            setup = function()
                local quicker = require "quicker"
                quicker.setup {
                    highlight = {
                        lsp = false,
                        load_buffers = false,
                    },
                    keys = {
                        {
                            ">",
                            function()
                                quicker.expand {
                                    before = 2,
                                    after = 2,
                                    add_to_existing = true,
                                }
                            end,
                            desc = "expand qf context",
                        },
                        {
                            "<",
                            function()
                                quicker.collapse()
                            end,
                            desc = "collapse qf context",
                        },
                    },
                }
                vim.keymap.set("n", "<leader>q", function()
                    quicker.toggle()
                end, { silent = true, desc = "toggle quickfix" })
                vim.keymap.set("n", "<leader>l", function()
                    quicker.toggle { loclist = true }
                end, { silent = true, desc = "toggle loclist" })
            end,
        },
    },
    {
        src = "https://github.com/stevearc/stickybuf.nvim",
        data = {
            setup = function()
                require("stickybuf").setup {}
            end,
        },
    },
    {
        src = "https://github.com/supermaven-inc/supermaven-nvim",
        data = {
            setup = function()
                require("supermaven-nvim").setup {
                    keymaps = {
                        accept_suggestion = "<c-;>",
                        clear_suggestion = "<c-.>",
                        accept_word = "<c-j>",
                    },
                }
            end,
        },
    },
    {
        src = "https://github.com/nvim-treesitter/nvim-treesitter",
        data = {
            setup = function()
                vim.api.nvim_create_autocmd("FileType", {
                    pattern = {
                        "svelte",
                        "lua",
                        "javascript",
                        "typescript",
                        "html",
                    },
                    callback = function()
                        -- syntax highlighting, provided by Neovim
                        vim.treesitter.start()
                        -- folds, provided by Neovim
                        vim.wo.foldexpr = "v:lua.vim.treesitter.foldexpr()"
                        vim.wo.foldmethod = "expr"
                        vim.wo.foldlevel = 4
                    end,
                })
            end,
        },
    },
    {
        src = "https://github.com/ten3roberts/window-picker.nvim",
        data = {
            setup = function()
                vim.keymap.set("n", "<leader>ww", function()
                    vim.cmd [[WindowPick]]
                end, { silent = true, desc = "pick window" })
                vim.keymap.set("n", "<leader>wq", function()
                    vim.cmd [[WindowZap]]
                end, { silent = true, desc = "close window" })
                vim.keymap.set("n", "<leader>wo", function()
                    vim.cmd [[wincmd o]]
                end, {
                    silent = true,
                    desc = "close all other windows",
                })
                vim.keymap.set("n", "<leader>wv", function()
                    vim.cmd [[wincmd v]]
                end, {
                    silent = true,
                    desc = "spit window vertically",
                })
                vim.keymap.set("n", "<leader>ws", function()
                    vim.cmd [[wincmd s]]
                end, {
                    silent = true,
                    desc = "spit window horizontally",
                })
            end,
        },
    },
    {
        src = "https://github.com/gbprod/yanky.nvim",
        data = {
            setup = function()
                require("yanky").setup {}
                vim.keymap.set({ "n", "x" }, "y", "<Plug>(YankyYank)")
                vim.keymap.set({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
                vim.keymap.set({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
                vim.keymap.set({ "n", "x" }, "gp", "<Plug>(YankyGPutAfter)")
                vim.keymap.set({ "n", "x" }, "gP", "<Plug>(YankyGPutBefore)")
                vim.keymap.set("n", "]p", "<Plug>(YankyPutIndentAfterLinewise)")
                vim.keymap.set(
                    "n",
                    "[p",
                    "<Plug>(YankyPutIndentBeforeLinewise)"
                )

                vim.keymap.set("n", "<c-p>", "<Plug>(YankyPreviousEntry)")
                vim.keymap.set("n", "<c-n>", "<Plug>(YankyNextEntry)")

                vim.keymap.set(
                    { "n", "x" },
                    "<leader>p",
                    vim.cmd.YankyRingHistory
                )
            end,
        },
    },
}, {
    load = function(plug)
        local data = plug.spec.data or {}
        local setup = data.setup
        vim.cmd.packadd(plug.spec.name)
        if setup ~= nil and type(setup) == "function" then
            setup()
        end
    end,
})

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
vim.opt.fillchars = vim.opt.fillchars:append { diff = " " }
vim.opt.grepprg = [[rg --vimgrep]]
vim.opt.ignorecase = true
vim.opt.infercase = true
vim.opt.laststatus = 3
vim.opt.list = true
vim.opt.listchars = {
    tab = "⁚⁚",
    trail = "·",
    extends = "→",
    precedes = "←",
}
vim.opt.number = true
vim.opt.ruler = false
vim.opt.scrolloff = 999
vim.opt.shiftround = true
vim.opt.signcolumn = "number"
vim.opt.showcmd = false
vim.opt.showmode = false
vim.opt.smartcase = true
vim.opt.smartindent = true
vim.opt.splitbelow = true
vim.opt.splitright = true
vim.opt.swapfile = false
vim.opt.tabstop = 4
vim.opt.textwidth = 80
vim.opt.undodir = vim.fn.stdpath "cache" .. "/undo"
vim.opt.undofile = true
vim.opt.completeopt = {
    "menuone", -- only show popup when theres more than one item
    "popup", -- show extra info in popup
    "noselect", -- do not auto select a match
    -- "fuzzy" -- enable fuzzy-matching
}
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"

--@keymaps
vim.keymap.set({ "n", "x" }, ";", ":", { desc = "command mode" })
vim.keymap.set({ "i", "c" }, "kj", "<esc>")
vim.keymap.set({ "i", "c" }, "kj", "<esc>")
vim.keymap.set("n", "j", [[gj]])
vim.keymap.set("n", "k", [[gk]])
vim.keymap.set("n", "*", [[*zvzzN]])
vim.keymap.set("n", "n", [[nzvzz]])
vim.keymap.set("n", "N", [[Nzvzz]])
vim.keymap.set("n", "<tab>", [[<cmd>bnext<cr>]], { desc = "next buffer" })
vim.keymap.set("n", "<s-tab>", [[<cmd>bprev<cr>]], { desc = "prev buffer" })
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
    callback = function() vim.cmd.wincmd [[=]] end,
})

--@deps
local path_package = vim.fn.stdpath "data" .. "/site/"
local mini_path = path_package .. "pack/deps/start/mini.nvim"
if not vim.loop.fs_stat(mini_path) then
    vim.cmd [[echo "Installing `mini.nvim`" | redraw]]
    local clone_cmd = {
        "git",
        "clone",
        "--filter=blob:none",
        "https://github.com/echasnovski/mini.nvim",
        mini_path,
    }
    vim.fn.system(clone_cmd)
    vim.cmd [[packadd mini.nvim | helptags ALL]]
    vim.cmd [[echo "Installed `mini.nvim`" | redraw]]
end

require("mini.deps").setup { path = { package = path_package } }
local add, now, later = MiniDeps.add, MiniDeps.now, MiniDeps.later

--@plugins
now(function()
    -- ui
    add "sheerun/vim-polyglot"
    add "stevearc/dressing.nvim"
    add "cormacrelf/dark-notify"
    add "strash/everybody-wants-that-line.nvim"
    require("everybody-wants-that-line").setup { filename = { enabled = false } }
    add "j-hui/fidget.nvim"
    add "bekaboo/dropbar.nvim"
    vim.keymap.set("n", "<leader>-", function()
        require("dropbar.api").pick()
    end, { silent = true, desc = "pick symbol" })
    add "zenbones-theme/zenbones.nvim"
    vim.g.zenwritten_compat = 1
    vim.cmd.colo [[zenwritten]]

    -- mini
    require("mini.ai").setup {}
    require("mini.align").setup {}
    require("mini.bracketed").setup {}
    require("mini.diff").setup {}
    require("mini.extra").setup {}
    require("mini.files").setup {}
    require("mini.icons").setup {}
    require("mini.pairs").setup {}
    require("mini.pick").setup {
        window = {
            config = {
                height = math.floor(vim.o.lines * 0.2),
                border = "none",
            },
        },
    }
    require("mini.surround").setup {}

    vim.keymap.set("n", "<leader><space>", function()
        require("mini.pick").builtin.files()
    end, { silent = true, desc = "open file picker" })

    vim.keymap.set("n", "-", function()
        local MiniFiles = require "mini.files"
        if not MiniFiles.close() then
            MiniFiles.open(vim.api.nvim_buf_get_name(0))
            MiniFiles.reveal_cwd()
        end
    end, { silent = true, desc = "toggle mini.files" })

    -- lsp
    add {
        source = "neovim/nvim-lspconfig",
        depends = { "williamboman/mason.nvim", "williamboman/mason-lspconfig.nvim" },
    }
    local lsp = require "lspconfig"
    local default_handler = function(server)
        lsp[server].setup {}
    end
    require("mason").setup()
    require("mason-lspconfig").setup {
        ensure_installed = {
            "lua_ls",
        },
        handlers = {
            default_handler,
        },
    }
    vim.api.nvim_create_autocmd("LspAttach", {
        desc = "setup lsp actions",
        group = vim.api.nvim_create_augroup("lsp", { clear = true }),
        callback = function(event)
            local on_attach = function(client, _)
                -- disable lsp formatting in favor of conform
                client.server_capabilities.docuementFormattingProvider = false
                client.server_capabilities.documentRangeFormattingProvider = false
            end
            local client = vim.lsp.get_client_by_id(event.data.client_id)
            on_attach(client, event.buf)
        end,
    })

    -- treesitter
    add {
        source = "nvim-treesitter/nvim-treesitter",
        depends = {
            -- "rrethy/nvim-treesitter-endwise",
            "joosepalviste/nvim-ts-context-commentstring",
            "windwp/nvim-ts-autotag",
        },
        hooks = {
            post_checkout = function()
                vim.cmd [[TSUpdate]]
            end,
        },
    }
    require("nvim-treesitter.configs").setup {
        auto_install = true,
        highlight = { enable = true },
        indent = { enable = true },
        endwise = { enable = true },
        autotag = {
            enable = true,
        },
        incremental_selection = {
            enable = true,
            keymaps = {
                init_selection = "<cr>",
                node_incremental = "<cr>",
                node_decremental = "<s-cr>",
            },
        },
    }

    -- conform
    add "stevearc/conform.nvim"
    require("conform").setup {
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
        },
        format_on_save = {
            -- These options will be passed to conform.format()
            timeout_ms = 800,
            lsp_format = "fallback",
        },
    }
    vim.o.formatexpr = "v:lua.require'conform'.formatexpr()"
    vim.api.nvim_create_user_command("Format", function(args)
        local range = nil
        if args.count ~= -1 then
            local end_line = vim.api.nvim_buf_get_lines(0, args.line2 - 1, args.line2, true)[1]
            range = {
                start = { args.line1, 0 },
                ["end"] = { args.line2, end_line:len() },
            }
        end
        require("conform").format { async = true, lsp_fallback = true, range = range }
    end, { range = true })

    -- completion
    add {
        source = "saghen/blink.cmp",
        depends = { "rafamadriz/friendly-snippets" },
        checkout = "v0.3.1",
    }
    require("blink.cmp").setup {
        highlight = {
            -- sets the fallback highlight groups to nvim-cmp's highlight groups
            -- useful for when your theme doesn't support blink.cmp
            -- will be removed in a future release, assuming themes add support
            use_nvim_cmp_as_default = true,
        },
    }
    add "supermaven-inc/supermaven-nvim"
    require("supermaven-nvim").setup {
        color = {
            suggestion_color = "#AA58A9",
            cterm = 244,
        },
        keymaps = {
            accept_suggestion = "<c-;>",
            clear_suggestion = "<c-,>",
        },
    }
end)

later(function()
    -- git
    add {
        source = "neogitorg/neogit",
        depends = { "sindrets/diffview.nvim", "nvim-lua/plenary.nvim" },
    }
    require("neogit").setup {
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
    vim.keymap.set("n", "<leader>gh", function()
        vim.cmd.DiffviewFileHistory "%"
    end, { silent = true, desc = "git status" })

    -- quickfix
    add {
        source = "stevearc/quicker.nvim",
        depends = {
            "romainl/vim-qf",
        },
    }
    vim.g.qf_mapping_ack_style = 1
    require("quicker").setup {
        highlight = {
            lsp = false,
            load_buffers = false,
        },
    }
    vim.keymap.set("n", "<leader>q", function()
        require("quicker").toggle()
    end, { silent = true, desc = "toggle quickfix" })
    vim.keymap.set("n", "<leader>l", function()
        require("quicker").toggle { loclist = true }
    end, { silent = true, desc = "toggle loclist" })
    vim.keymap.set("n", ">", function()
        require("quicker").expand { before = 2, after = 2, add_to_existing = true }
    end, { silent = true, desc = "expand quickfix" })
    vim.keymap.set("n", "<", function()
        require("quicker").collapse()
    end, { silent = true, desc = "collapse quickfix" })

    -- windows
    add "ten3roberts/window-picker.nvim"
    vim.keymap.set("n", "<leader>ww", function()
        vim.cmd [[WindowPick]]
    end, { silent = true, desc = "pick window" })
    vim.keymap.set("n", "<leader>wq", function()
        vim.cmd [[WindowZap]]
    end, { silent = true, desc = "close window" })
    vim.keymap.set("n", "<leader>wo", function()
        vim.cmd [[wincmd o]]
    end, { silent = true, desc = "close all other windows" })
    vim.keymap.set("n", "<leader>wv", function()
        vim.cmd [[wincmd v]]
    end, { silent = true, desc = "spit window vertically" })
    vim.keymap.set("n", "<leader>ws", function()
        vim.cmd [[wincmd s]]
    end, { silent = true, desc = "spit window horizontally" })
end)

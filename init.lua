--[[
    .-'"'-.
   / #     \
  : #       :  .-'"'-.
   \       /  / #     \
    \     /  : #       :
     `'q'`    \       /
       (       \     /
        )       `'p'`
       (          )
        )        (
                  ) @jssee
--]]
-- Helpers {{{1
local add = vim.pack.add

local gr = vim.api.nvim_create_augroup("user-config", { clear = true })
local autocmd = function(event, pattern, callback, desc)
    local opts =
        { group = gr, pattern = pattern, callback = callback, desc = desc }
    vim.api.nvim_create_autocmd(event, opts)
end

local on_packchanged = function(plugin_name, kinds, callback, desc)
    local f = function(ev)
        local name, kind = ev.data.spec.name, ev.data.kind
        if not (name == plugin_name and vim.tbl_contains(kinds, kind)) then
            return
        end
        if not ev.data.active then
            vim.cmd.packadd(plugin_name)
        end
        callback(ev.data)
    end
    autocmd("PackChanged", "*", f, desc)
end

local map = function(modes, lhs, rhs, desc, opts)
    local map_opts = vim.tbl_extend("force", { silent = true }, opts or {})
    map_opts.desc = desc
    vim.keymap.set(modes, lhs, rhs, map_opts)
end

local nmap = function(lhs, rhs, desc, opts)
    map("n", lhs, rhs, desc, opts)
end

-- Options {{{1
vim.g.mapleader = " "

local o = vim.o
-- `vim.opt` accepts tables, but nightly annotates its fields as `vim.Option`,
-- which rejects every assignment. Drop the cast once upstream types it properly.
local opt = vim.opt --[[@as table<string, any>]]
o.autocomplete = true
o.breakindent = true
o.clipboard = "unnamedplus"
o.complete = "o^10,.^5,w^5,b^5" -- `o` brings LSP into 'autocomplete'
opt.completeopt = {
    "menuone", -- only show the popup when there is more than one match
    "popup", -- show extra info in a side popup
    "noselect", -- do not preselect a match
    "fuzzy", -- use fuzzy matching
    "nosort",
}
o.copyindent = true
o.cursorline = true
o.cursorlineopt = "number"
o.expandtab = true
opt.fillchars = { diff = "╱" }
o.grepprg = [[rg --vimgrep]]
o.ignorecase = true
o.infercase = true
o.laststatus = 3
o.list = true
opt.listchars =
    { tab = "⁚⁚", trail = "·", extends = "→", precedes = "←" }
o.nrformats = "unsigned"
o.number = true
o.ruler = false
o.scrolloff = 999
o.scrolloffpad = 1 -- keep the cursor centered at the end of the file
o.shada = "'100,<50,s10,:1000,/100,@100,h"
o.shiftround = true
o.shortmess = "CFOSWaco"
o.showbreak = "↪  "
o.showcmd = false
o.showmode = false
o.signcolumn = "yes:1"
o.smartcase = true
o.smartindent = true
o.shiftwidth = 2
o.softtabstop = 2
o.splitbelow = true
o.splitright = true
o.swapfile = false
o.tabstop = 4
o.textwidth = 200
o.undofile = true

-- Keymaps {{{1
map({ "n", "x" }, ";", ":", "command mode")
map({ "n", "x" }, ":", ";")
map({ "i", "c" }, "kj", "<Esc>", "escape")
nmap("j", "gj", "move by screen line")
nmap("k", "gk", "move by screen line")
nmap("<Backspace>", "^", "first non-blank")

-- Diagnostics {{{1
local HINT = vim.diagnostic.severity.HINT
local WARN = vim.diagnostic.severity.WARN
local ERROR = vim.diagnostic.severity.ERROR
vim.diagnostic.config {
    signs = { priority = 9999, severity = { min = WARN, max = ERROR } },
    underline = { severity = { min = HINT, max = ERROR } },
    virtual_lines = false,
    virtual_text = {
        current_line = true,
        severity = { min = ERROR, max = ERROR },
    },
    update_in_insert = false,
}

-- Autocommands {{{1
autocmd({ "TextYankPost", "TextPutPost" }, nil, function()
    vim.hl.hl_op { higroup = "Visual", timeout = 300 }
end, "highlight yanked and put text")

-- Packages {{{1
vim.cmd.packadd "nvim.undotree"

add { "https://github.com/nvim-mini/mini.nvim" }
require("mini.ai").setup {}
require("mini.align").setup {}
require("mini.bracketed").setup {}
require("mini.cmdline").setup {}
require("mini.diff").setup {}
require("mini.extra").setup {}
require("mini.git").setup {}
require("mini.icons").setup {}
require("mini.icons").tweak_lsp_kind()
require("mini.input").setup {}
require("mini.notify").setup {}
require("mini.pairs").setup {}
require("mini.surround").setup {}
require("mini.operators").setup {
    exchange = { prefix = "cx" }, -- keep `gx` for opening URLs
    replace = { prefix = "rg" }, -- keep `gr*` available for LSP
}

local map_multistep = require("mini.keymap").map_multistep
map_multistep(
    "i",
    "<Tab>",
    { "pmenu_next", "jump_after_tsnode", "jump_after_close" }
)
map_multistep("i", "<S-Tab>", { "pmenu_prev", "jump_before_tsnode" })
map_multistep("i", "<CR>", { "pmenu_accept", "minipairs_cr" })
map_multistep("i", "<BS>", { "minipairs_bs" })

local MiniPick = require "mini.pick"
MiniPick.setup {
    window = {
        config = {
            height = math.floor(vim.o.lines * 0.2),
        },
    },
}

vim.notify = require("mini.notify").make_notify {
    ERROR = { duration = 10000 },
}
vim.ui.select = MiniPick.ui_select
nmap("<leader><space>", MiniPick.builtin.files, "pick files")
nmap("<leader>/", MiniPick.builtin.grep_live, "live grep")
nmap("<leader>.", ":Pick grep pattern='<cword>'<cr>", "grep current word")
nmap("<leader>fp", ":Pick ", "pick builtin")
nmap("<leader>p", "<cmd>Pick registers<cr>", "pick register to put")

-- local MiniFiles = require "mini.files"
-- MiniFiles.setup {}
-- local minifiles_toggle = function(...)
--     if not MiniFiles.close() then
--         MiniFiles.open(vim.api.nvim_buf_get_name(0))
--         MiniFiles.reveal_cwd()
--     end
-- end
-- map("n", "-", minifiles_toggle, "toggle minifiles")

add { "https://github.com/stevearc/oil.nvim" }
require("oil").setup {
    skip_confirm_for_simple_edits = true,
    watch_for_changes = true,
    view_options = {
        show_hidden = true,
    },
    keymaps = {
        ["l"] = "actions.select",
        ["q"] = { "actions.close", mode = "n" },
        ["v"] = { "actions.select", mode = "n", opts = { vertical = true } },
        ["s"] = { "actions.select", mode = "n", opts = { horizontal = true } },
    },
}
nmap("-", "<cmd>Oil<cr>", "open parent directory")

add {
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/yioneko/nvim-vtsls",
}
require("mason").setup()
vim.lsp.enable {
    "expert",
    "lua",
    "svelte",
    "tailwindcss",
    "vtsls",
}
autocmd("LspAttach", nil, function(ev)
    local toggle_codelens = function()
        vim.lsp.codelens.enable(not vim.lsp.codelens.is_enabled())
    end
    vim.lsp.completion.enable(true, ev.data.client_id, ev.buf, {
        convert = function(item)
            return { abbr = item.label:gsub("%b()", "") }
        end,
    })
    nmap("grc", toggle_codelens, "toggle codelens", { buffer = ev.buf })
end, "setup lsp actions")

add {
    "https://github.com/nvim-treesitter/nvim-treesitter",
    "https://github.com/rrethy/nvim-treesitter-endwise",
}
-- Lua, markdown, vimdoc and a few others ship with Neovim.
require("nvim-treesitter").install {
    "astro",
    "css",
    "eex",
    "elixir",
    "heex",
    "html",
    "javascript",
    "json",
    "ruby",
    "scss",
    "svelte",
    "tsx",
    "typescript",
}
autocmd("FileType", "*", function(ev)
    pcall(vim.treesitter.start, ev.buf)
end, "start treesitter when a parser exists")
on_packchanged("nvim-treesitter", { "update" }, function()
    vim.cmd.TSUpdate()
end, "update treesitter parsers after plugin updates")

add { "https://github.com/stevearc/conform.nvim" }
local web_formatter = {
    "prettier",
    stop_after_first = true,
}
require("conform").setup {
    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
    formatters_by_ft = {
        lua = { "stylua" },
        javascript = web_formatter,
        javascriptreact = web_formatter,
        typescript = web_formatter,
        typescriptreact = web_formatter,
        svelte = web_formatter,
        html = web_formatter,
        css = web_formatter,
        eruby = { "htmlbeautifier" },
        astro = { "prettier" },
        markdown = { "prettier" },
    },
}
o.formatexpr = "v:lua.require'conform'.formatexpr()"

add { "https://github.com/yorickpeterse/nvim-jump" }
require("jump").setup {}
map("n", "<leader>s", require("jump").start, "jump")

add { "https://github.com/nvim-lua/plenary.nvim" }
add { "https://github.com/esmuellert/codediff.nvim" }
require("codediff").setup {
    explorer = {
        view_mode = "tree",
    },
}
add { "https://github.com/neogitorg/neogit" }
require("neogit").setup {
    graph_style = "kitty",
    integrations = {
        mini_pick = true,
        codediff = true,
    },
}
nmap("<leader>gg", "<cmd>Neogit<cr>", "git status")
nmap("<leader>gc", "<cmd>Neogit commit<cr>", "git commit")
nmap("<leader>gp", "<cmd>Neogit push<cr>", "git push")

add { "https://github.com/stevearc/overseer.nvim" }
require("overseer").setup {}
nmap("<leader>oo", "<cmd>OverseerToggle<CR>", "toggle overseer")
nmap("<leader>or", "<cmd>OverseerRun<CR>", "run task")
nmap("<leader>os", "<cmd>OverseerShell<CR>", "run shell task")

add { "https://github.com/stevearc/stickybuf.nvim" }
require("stickybuf").setup {}

add { "https://github.com/stevearc/quicker.nvim" }
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
            desc = "expand quickfix context",
        },
        {
            "<",
            quicker.collapse,
            desc = "collapse quickfix context",
        },
    },
}
nmap("<leader>q", quicker.toggle, "toggle quickfix")
nmap("<leader>l", function()
    quicker.toggle { loclist = true }
end, "toggle loclist")

add { "https://github.com/ten3roberts/window-picker.nvim" }
nmap("<leader>ww", "<cmd>WindowPick<CR>", "pick window")
nmap("<leader>wq", "<cmd>WindowZap<CR>", "close window")
nmap("<leader>wo", "<cmd>wincmd o<CR>", "close other windows")
nmap("<leader>wv", "<cmd>wincmd v<CR>", "split window vertically")
nmap("<leader>ws", "<cmd>wincmd s<CR>", "split window horizontally")

add { "https://github.com/ember-theme/nvim" }
vim.cmd.colo "ember-auto"

-- vim: fdm=marker fdl=0

vim.o.bg = "dark"
-- Small helpers keep this file cheap to extend without turning it into a framework.

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

-- Core editor defaults. Keep these boring and global.
vim.g.mapleader = " "

local opt = vim.opt
opt.autocomplete = true
opt.breakindent = true
opt.clipboard:append "unnamedplus"
opt.complete = ".^5,w^5,b^5"
opt.completeopt = {
    "menuone", -- only show the popup when there is more than one match
    "popup", -- show extra info in a side popup
    "noselect", -- do not preselect a match
    "fuzzy", -- use fuzzy matching
    "nosort",
}
opt.copyindent = true
opt.cursorline = true
opt.cursorlineopt = { "number" }
opt.expandtab = true
opt.fillchars = { diff = "╱" }
opt.grepprg = [[rg --vimgrep]]
opt.ignorecase = true
opt.infercase = true
opt.laststatus = 3
opt.list = true
opt.listchars =
    { tab = "⁚⁚", trail = "·", extends = "→", precedes = "←" }
opt.nrformats = "unsigned"
opt.number = true
opt.ruler = false
opt.scrolloff = 10
opt.shada = "'100,<50,s10,:1000,/100,@100,h"
opt.shiftround = true
opt.shortmess = "CFOSWaco"
opt.showbreak = "↪  "
opt.showcmd = false
opt.showmode = false
opt.signcolumn = "yes:1"
opt.smartcase = true
opt.smartindent = true
opt.shiftwidth = 2
opt.softtabstop = 2
opt.splitbelow = true
opt.splitright = true
opt.swapfile = false
opt.tabstop = 4
opt.textwidth = 200
opt.undofile = true

-- Conservative diagnostics: underline everything, speak up only for real errors.
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

autocmd("TextYankPost", nil, function()
    vim.highlight.on_yank { higroup = "Visual", timeout = 300 }
end, "highlight yanked text")

autocmd("WinResized", nil, function()
    vim.cmd.wincmd [[=]]
end, "rebalance window sizes")

-- Global keymaps.
map({ "n", "x" }, ";", ":", "command mode")
map({ "n", "x" }, ":", ";")
map({ "i", "c" }, "kj", "<Esc>", "escape")
nmap("j", "gj", "move by screen line")
nmap("k", "gk", "move by screen line")
nmap("<Backspace>", "^", "first non-blank")
nmap("q", "<Nop>", "disable Ex mode")

vim.api.nvim_create_user_command("PackUpdate", function(args)
    local names = #args.fargs > 0 and args.fargs or nil
    vim.pack.update(names, { force = args.bang })
end, {
    bang = true,
    nargs = "*",
    desc = "Update vim.pack plugins",
})

-- Plugins: completion, text objects, picker, and general editing quality of life.
add { "https://github.com/supermaven-inc/supermaven-nvim" }
require("supermaven-nvim").setup {}

add { "https://github.com/nvim-mini/mini.nvim" }
require("mini.ai").setup {}
require("mini.align").setup {}
require("mini.bracketed").setup {}
require("mini.cmdline").setup {}
require("mini.diff").setup {}
require("mini.extra").setup {}
require("mini.icons").setup {}
require("mini.icons").tweak_lsp_kind()
require("mini.notify").setup {}
require("mini.operators").setup {
    replace = { prefix = "rg" }, -- keep `gr*` available for LSP
}
require("mini.pairs").setup {}
require("mini.surround").setup {}

vim.notify = require("mini.notify").make_notify {
    ERROR = { duration = 10000 },
}

local pick = require "mini.pick"
pick.setup {
    window = {
        config = {
            height = math.floor(vim.o.lines * 0.2),
        },
    },
}
vim.ui.select = pick.ui_select
nmap("<leader><space>", pick.builtin.files, "pick files")
nmap("<leader>fg", pick.builtin.grep_live, "live grep")
nmap("<leader>fp", ":Pick ", "pick builtin")

require("mini.files").setup {}
local minifiles_toggle = function(...)
    if not MiniFiles.close() then
        MiniFiles.open(...)
    end
end
map("n", "-", minifiles_toggle, "toggle minifiles")

add { "https://github.com/yorickpeterse/nvim-jump" }
require("jump").setup {
    label = "OkMsg",
}
map({ "n", "x", "o" }, "<leader>s", require("jump").start, "jump")

add { "https://github.com/gbprod/yanky.nvim" }
require("yanky").setup {}
map({ "n", "x" }, "y", "<Plug>(YankyYank)")
map({ "n", "x" }, "p", "<Plug>(YankyPutAfter)")
map({ "n", "x" }, "P", "<Plug>(YankyPutBefore)")
nmap("]p", "<Plug>(YankyPutIndentAfterLinewise)")
nmap("[p", "<Plug>(YankyPutIndentBeforeLinewise)")
nmap("<C-p>", "<Plug>(YankyPreviousEntry)")
nmap("<C-n>", "<Plug>(YankyNextEntry)")
map({ "n", "x" }, "<leader>p", vim.cmd.YankyRingHistory, "open yank history")

-- Plugins: lists, windows, and task running.
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

add { "https://github.com/strash/everybody-wants-that-line.nvim" }
require("everybody-wants-that-line").setup {
    filename = { enabled = false },
    separator = " ",
}

-- Plugins: language tooling.
add {
    "https://github.com/mason-org/mason.nvim",
    "https://github.com/yioneko/nvim-vtsls",
}
require("mason").setup()
vim.lsp.enable {
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
        autotrigger = true,
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
autocmd(
    "FileType",
    { "svelte", "lua", "javascript", "typescript", "html" },
    function(ev)
        vim.treesitter.start(ev.buf)
    end,
    "start treesitter"
)
on_packchanged("nvim-treesitter", { "update" }, function()
    vim.cmd.TSUpdate()
end, "update treesitter parsers after plugin updates")

add { "https://github.com/stevearc/conform.nvim" }
require("conform").setup {
    format_on_save = {
        timeout_ms = 500,
        lsp_format = "fallback",
    },
    formatters_by_ft = {
        lua = { "stylua" },
    },
}
opt.formatexpr = "v:lua.require'conform'.formatexpr()"

add { "https://github.com/esmuellert/codediff.nvim" }
add { "https://github.com/nvim-lua/plenary.nvim" }
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

add { "https://github.com/ember-theme/nvim" }
vim.cmd.colo "ember"

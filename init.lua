-- Set <space> as the leader key
-- See `:help mapleader`
--  NOTE: Must happen before plugins are loaded (otherwise wrong leader will be used)
vim.g.mapleader = ','
vim.g.maplocalleader = ' '

-- Set to true if you have a Nerd Font installed and selected in the terminal
vim.g.have_nerd_font = true

-- [[ Setting options ]]
-- See `:help vim.o`
-- NOTE: You can change these options as you wish!
--  For more options, you can see `:help option-list`

-- Make line numbers default
vim.o.number = true
-- You can also add relative line numbers, to help with jumping.
--  Experiment for yourself to see if you like it!
-- vim.o.relativenumber = true

-- Enable mouse mode, can be useful for resizing splits for example!
vim.o.mouse = 'a'

-- Don't show the mode, since it's already in the status line
vim.o.showmode = false

-- Ensure 'y' and other yank commands copy/paste directly to keyboard
vim.opt.clipboard = 'unnamedplus'

-- Sync clipboard between OS and Neovim.
--  Schedule the setting after `UiEnter` because it can increase startup-time.
--  Remove this option if you want your OS clipboard to remain independent.
--  See `:help 'clipboard'`
vim.schedule(function() vim.o.clipboard = 'unnamedplus' end)

-- Enable break indent
vim.o.breakindent = true

-- Enable undo/redo changes even after closing and reopening a file
vim.o.undofile = true

-- Case-insensitive searching UNLESS \C or one or more capital letters in the search term
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.background = "dark"

-- Keep signcolumn on by default
vim.o.signcolumn = 'yes'

-- Decrease update time
vim.o.updatetime = 250

-- Decrease mapped sequence wait time
vim.o.timeoutlen = 300

-- Configure how new splits should be opened
vim.o.splitright = true
vim.o.splitbelow = true

-- fix double backspace
vim.keymap.set('i', '<C-h>', '<BS>', { noremap = true })

-- ignore DEL if it's duplicated
vim.keymap.set('i', '<Del>', '<Nop>', { noremap = true })

-- fix double enter
vim.keymap.set('i', '<CR>', function() return '\n' end, { expr = true })

-- Sets how neovim will display certain whitespace characters in the editor.
--  See `:help 'list'`
--  and `:help 'listchars'`
--
--  Notice listchars is set using `vim.opt` instead of `vim.o`.
--  It is very similar to `vim.o` but offers an interface for conveniently interacting with tables.
--   See `:help lua-options`
--   and `:help lua-guide-options`
vim.o.list = true
vim.opt.listchars = { tab = '» ', trail = '·', nbsp = '␣' }

-- Preview substitutions live, as you type!
vim.o.inccommand = 'split'

-- Show which line your cursor is on
vim.o.cursorline = true

-- Minimal number of screen lines to keep above and below the cursor.
vim.o.scrolloff = 10

-- if performing an operation that would fail due to unsaved changes in the buffer (like `:q`),
-- instead raise a dialog asking if you wish to save the current file(s)
-- See `:help 'confirm'`
vim.o.confirm = true

-- [[ Basic Keymaps ]]
--  See `:help vim.keymap.set()`

-- Clear highlights on search when pressing <Esc> in normal mode
--  See `:help hlsearch`
vim.keymap.set('n', '<Esc>', '<cmd>nohlsearch<CR>')

-- Diagnostic Config & Keymaps
-- See :help vim.diagnostic.Opts
vim.diagnostic.config {
  update_in_insert = false,
  severity_sort = true,
  float = { border = 'rounded', source = 'if_many' },
  underline = { severity = { min = vim.diagnostic.severity.WARN } },

  -- Can switch between these as you prefer
  virtual_text = true, -- Text shows up at the end of the line
  virtual_lines = false, -- Text shows up underneath the line, with virtual lines

  -- Auto open the float, so you can easily read the errors when jumping with `[d` and `]d`
  jump = { float = true },
}

vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostic [Q]uickfix list' })

-- Exit terminal mode in the builtin terminal with a shortcut that is a bit easier
-- for people to discover. Otherwise, you normally need to press <C-\><C-n>, which
-- is not what someone will guess without a bit more experience.
--
-- NOTE: This won't work in all terminal emulators/tmux/etc. Try your own mapping
-- or just use <C-\><C-n> to exit terminal mode
vim.keymap.set('t', '<Esc><Esc>', '<C-\\><C-n>', { desc = 'Exit terminal mode' })

-- TIP: Disable arrow keys in normal mode
-- vim.keymap.set('n', '<left>', '<cmd>echo "Use h to move!!"<CR>')
-- vim.keymap.set('n', '<right>', '<cmd>echo "Use l to move!!"<CR>')
-- vim.keymap.set('n', '<up>', '<cmd>echo "Use k to move!!"<CR>')
-- vim.keymap.set('n', '<down>', '<cmd>echo "Use j to move!!"<CR>')

-- Keybinds to make split navigation easier.
--  Use CTRL+<hjkl> to switch between windows
--
--  See `:help wincmd` for a list of all window commands
vim.keymap.set('n', '<C-h>', '<C-w><C-h>', { desc = 'Move focus to the left window' })
vim.keymap.set('n', '<C-l>', '<C-w><C-l>', { desc = 'Move focus to the right window' })
vim.keymap.set('n', '<C-j>', '<C-w><C-j>', { desc = 'Move focus to the lower window' })
vim.keymap.set('n', '<C-k>', '<C-w><C-k>', { desc = 'Move focus to the upper window' })

-- NOTE: Some terminals have colliding keymaps or are not able to send distinct keycodes
-- vim.keymap.set("n", "<C-S-h>", "<C-w>H", { desc = "Move window to the left" })
-- vim.keymap.set("n", "<C-S-l>", "<C-w>L", { desc = "Move window to the right" })
-- vim.keymap.set("n", "<C-S-j>", "<C-w>J", { desc = "Move window to the lower" })
-- vim.keymap.set("n", "<C-S-k>", "<C-w>K", { desc = "Move window to the upper" })

-- [[ Basic Autocommands ]]
--  See `:help lua-guide-autocommands`

-- Highlight when yanking (copying) text
--  Try it with `yap` in normal mode
--  See `:help vim.hl.on_yank()`
vim.api.nvim_create_autocmd('TextYankPost', {
  desc = 'Highlight when yanking (copying) text',
  group = vim.api.nvim_create_augroup('kickstart-highlight-yank', { clear = true }),
  callback = function() vim.hl.on_yank() end,
})

-- Custom commands
vim.cmd [[
  cnoreabbrev <expr> db getcmdtype() == ":" && getcmdline() == "db" ? "Dashboard" : "db"
  cnoreabbrev <expr> config getcmdtype() == ":" && getcmdline() == "config" ? "e ~/.config/nvim/init.lua" : "config"
  colorscheme moonfly
  hi Normal guibg=#000000 guifg=NONE
  hi NormalNC guibg=#000000 guifg=NONE
]]

-- [[ Install plugins with vim.pack.add (Neovim 0.11+) ]]
-- Use the native package manager. Packpath under data/site/pack/core/opt or start.

local packpath = vim.fn.stdpath('data') .. '/site/pack/core/opt'
vim.fn.mkdir(packpath, 'p')

-- Moonfly colorscheme: ensure it's available
local moonfly_dir = packpath .. '/vim-moonfly-colors'
if vim.fn.isdirectory(moonfly_dir) == 0 then
  vim.fn.system({'git', 'clone', 'https://github.com/bluz71/vim-moonfly-colors', moonfly_dir})
end
vim.cmd('packadd vim-moonfly-colors')

-- Define plugins with vim.pack.add (we'll load them as needed by calling packadd or
-- let autocommands/events handle; for simple cases we can also add to start if preferred)
-- Build minimal: add required plugins

local plugins = {
  {dir = 'guess-indent.nvim', url = 'https://github.com/NMAC427/guess-indent.nvim'},
  {dir = 'vim-commentary', url = 'https://github.com/tpope/vim-commentary'},
  {dir = 'nvim-lspconfig', url = 'https://github.com/neovim/nvim-lspconfig'},
  {dir = 'cmp-nvim-lsp', url = 'https://github.com/hrsh7th/cmp-nvim-lsp'},
  {dir = 'cmp-buffer', url = 'https://github.com/hrsh7th/cmp-buffer'},
  {dir = 'cmp-path', url = 'https://github.com/hrsh7th/cmp-path'},
  {dir = 'cmp-cmdline', url = 'https://github.com/hrsh7th/cmp-cmdline'},
  {dir = 'LuaSnip', url = 'https://github.com/L3MON4D3/LuaSnip'},
  {dir = 'nvim-cmp', url = 'https://github.com/hrsh7th/nvim-cmp'},
  {dir = 'nvim-surround', url = 'https://github.com/kylechui/nvim-surround'},
  {dir = 'leap.nvim', url = 'https://codeberg.org/andyg/leap.nvim'},
  {dir = 'plenary.nvim', url = 'https://github.com/nvim-lua/plenary.nvim'},
  {dir = 'telescope-fzf-native.nvim', url = 'https://github.com/nvim-telescope/telescope-fzf-native.nvim'},
  {dir = 'telescope.nvim', url = 'https://github.com/nvim-telescope/telescope.nvim'},
  {dir = 'dashboard-nvim', url = 'https://github.com/nvimdev/dashboard-nvim'},
  {dir = 'gitsigns.nvim', url = 'https://github.com/lewis6991/gitsigns.nvim'},
  {dir = 'which-key.nvim', url = 'https://github.com/folke/which-key.nvim'},
  {dir = 'telescope-ui-select.nvim', url = 'https://github.com/nvim-telescope/telescope-ui-select.nvim'},
  {dir = 'nvim-web-devicons', url = 'https://github.com/nvim-tree/nvim-web-devicons'},
  {dir = 'mason.nvim', url = 'https://github.com/mason-org/mason.nvim'},
  {dir = 'mason-lspconfig.nvim', url = 'https://github.com/mason-org/mason-lspconfig.nvim'},
  {dir = 'mason-tool-installer.nvim', url = 'https://github.com/WhoIsSethDaniel/mason-tool-installer.nvim'},
  {dir = 'fidget.nvim', url = 'https://github.com/j-hui/fidget.nvim'},
  {dir = 'conform.nvim', url = 'https://github.com/stevearc/conform.nvim'},
  {dir = 'blink.cmp', url = 'https://github.com/saghen/blink.cmp'},
  {dir = 'friendly-snippets', url = 'https://github.com/rafamadriz/friendly-snippets'},
  {dir = 'todo-comments.nvim', url = 'https://github.com/folke/todo-comments.nvim'},
  {dir = 'mini.nvim', url = 'https://github.com/nvim-mini/mini.nvim'},
  {dir = 'nvim-treesitter', url = 'https://github.com/nvim-treesitter/nvim-treesitter'},
}

for _, p in ipairs(plugins) do
  local d = packpath .. '/' .. p.dir
  if vim.fn.isdirectory(d) == 0 then
    vim.fn.system({'git', 'clone', p.url, d})
  end
  vim.cmd('packadd ' .. p.dir)
end

-- Dashboard (restore green theme)
do
  local db = require 'dashboard'

  local forest = {
    header = '#76a882',
    icon = '#62856b',
    desc = '#c8d5cb',
    key = '#8fbea2',
    shortcut = '#76a882',
    footer = '#62856b',
  }
  vim.api.nvim_set_hl(0, 'DashboardHeader', { fg = forest.header })
  vim.api.nvim_set_hl(0, 'DashboardIcon', { fg = forest.icon })
  vim.api.nvim_set_hl(0, 'DashboardDesc', { fg = forest.desc })
  vim.api.nvim_set_hl(0, 'DashboardKey', { fg = forest.key, bold = true })
  vim.api.nvim_set_hl(0, 'DashboardShortCut', { fg = forest.shortcut })
  vim.api.nvim_set_hl(0, 'DashboardFooter', { fg = forest.footer })

  local header_ascii = {
    '',
    '                             ▄▄▄▄',
    '                     ██      ▀▀██',
    '██▄████  ▄▄█████▄  ███████     ██',
    '██▀      ██▄▄▄▄ ▀    ██        ██',
    '██        ▀▀▀▀██▄    ██        ██',
    '   ██       █▄▄▄▄▄██    ██▄▄▄     ██▄▄▄',
    '   ▀▀        ▀▀▀▀▀▀      ▀▀▀▀      ▀▀▀▀',
    '',
  }

  local function vertical_center(header, center, footer)
    local total_lines = #header + #center + #footer
    local top_padding = math.floor((vim.o.lines - total_lines) / 2)
    local padded_header = {}
    for _ = 1, top_padding do
      table.insert(padded_header, '')
    end
    for _, line in ipairs(header) do
      table.insert(padded_header, line)
    end
    return padded_header
  end

  local center_text = {
    { icon = '  ', desc = 'new file', key = 'e', action = 'enew' },
    { icon = '  ', desc = 'find file', key = 'f', action = 'Telescope find_files' },
    { icon = '  ', desc = 'recent files', key = 'r', action = 'Telescope oldfiles' },
    { icon = '  ', desc = 'find word', key = 'w', action = 'Telescope grep_string' },
    { icon = '  ', desc = 'live grep', key = 'g', action = 'Telescope live_grep' },
    { icon = '  ', desc = 'config', key = 'c', action = 'edit ~/.config/nvim/init.lua' },
    { icon = '  ', desc = 'quit', key = 'q', action = 'qa' },
  }

  local footer_text = { '', 'no mouse. no mercy.' }

  db.setup {
    theme = 'doom',
    config = {
      header = vertical_center(header_ascii, center_text, footer_text),
      center = center_text,
      footer = footer_text,
    },
  }
end

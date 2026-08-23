-- [[ Plugin management with Neovim's builtin `vim.pack` ]]
--    See `:h vim.pack` (requires Neovim >= 0.12)
--
--  To update all plugins:
--    :lua vim.pack.update()
--    Review the changes, then `:write` to apply or `:quit` to discard.
--    Afterwards restart and run `:TSUpdate` to refresh treesitter parsers.
--
--  To remove a plugin: delete its spec below, restart, then run
--    :lua vim.pack.del({ 'plugin-name' })

local gh = function(repo) return 'https://github.com/' .. repo end
local cb = function(repo) return 'https://codeberg.org/' .. repo end

-- [[ Build steps ]]
-- Equivalent of lazy.nvim's `build = ...`: commands to run whenever a plugin is
-- freshly installed or updated.
local build_steps = {
  ['telescope-fzf-native.nvim'] = { 'make' },
}

if vim.fn.has 'win32' == 0 and vim.fn.executable 'make' == 1 then
  -- Build step is needed for regex support in snippets.
  -- This step is not supported in many windows environments.
  build_steps.LuaSnip = { 'make', 'install_jsregexp' }
end

-- NOTE: Must be registered before `vim.pack.add()` below so that it also
-- triggers on the initial install of each plugin.
vim.api.nvim_create_autocmd('PackChanged', {
  desc = 'Run plugin build steps after install/update',
  callback = function(ev)
    local cmd = build_steps[ev.data.spec.name]
    if not cmd or (ev.data.kind ~= 'install' and ev.data.kind ~= 'update') then return end

    local out = vim.system(cmd, { cwd = ev.data.path, text = true }):wait()
    if out.code ~= 0 then error(('Build step failed for `%s`:\n%s'):format(ev.data.spec.name, out.stderr)) end
  end,
})

-- [[ Install plugins ]]
-- There is no dependency resolution: list plugins before their dependents.
-- Plugins load eagerly at startup (like `lazy = false`); there is no built-in
-- lazy-loading. All of these were effectively eager under lazy.nvim anyway.
vim.pack.add {
  -- Telescope stack
  gh 'nvim-lua/plenary.nvim',
  gh 'nvim-telescope/telescope-fzf-native.nvim',
  gh 'nvim-telescope/telescope-ui-select.nvim',
  gh 'nvim-telescope/telescope.nvim',

  gh 'NMAC427/guess-indent.nvim',
  gh 'tpope/vim-commentary',
  gh 'folke/which-key.nvim',
  gh 'lewis6991/gitsigns.nvim',
  gh 'kylechui/nvim-surround',

  -- Useful status updates for LSP
  gh 'j-hui/fidget.nvim',

  gh 'stevearc/conform.nvim',
  gh 'folke/todo-comments.nvim',
  gh 'nvim-mini/mini.nvim',
  gh 'nvimdev/dashboard-nvim',

  -- Charcoal nvim theme
  gh 'bluz71/vim-moonfly-colors',

  -- Mason must be loaded before its dependents (nvim-lspconfig)
  gh 'mason-org/mason.nvim',
  -- Maps LSP server names between nvim-lspconfig and Mason package names
  gh 'mason-org/mason-lspconfig.nvim',
  gh 'WhoIsSethDaniel/mason-tool-installer.nvim',
  gh 'neovim/nvim-lspconfig',

  -- Snippet Engine
  { src = gh 'L3MON4D3/LuaSnip', version = vim.version.range '2' },
  -- Blink.cmp includes an optional, recommended rust fuzzy matcher,
  -- which automatically downloads a prebuilt binary when enabled.
  --
  -- By default, we use the Lua implementation instead, so no build step is needed.
  { src = gh 'saghen/blink.cmp', version = vim.version.range '1' },

  -- nvim-cmp family
  gh 'hrsh7th/cmp-nvim-lsp',
  gh 'hrsh7th/cmp-buffer',
  gh 'hrsh7th/cmp-path',
  gh 'hrsh7th/cmp-cmdline',
  gh 'hrsh7th/nvim-cmp',

  -- Highlight, edit, and navigate code
  { src = gh 'nvim-treesitter/nvim-treesitter', version = 'main' },

  -- Discord rich presence
  gh 'vyfor/cord.nvim',
}

if vim.g.have_nerd_font then
  -- Useful for getting pretty icons, but requires a Nerd Font
  vim.pack.add { gh 'nvim-tree/nvim-web-devicons' }
end

-- leap.nvim is hosted on codeberg
-- https://codeberg.org/andyg/leap.nvim
vim.pack.add { cb 'andyg/leap.nvim' }

-- [[ Configure plugins ]]
-- This replaces lazy.nvim's `opts` / `config` keys: call `setup()` explicitly.

require('guess-indent').setup {}

-- Adds git related signs to the gutter, as well as utilities for managing changes
-- See `:help gitsigns` to understand what the configuration keys do
require('gitsigns').setup {
  signs = {
    add = { text = '+' },
    change = { text = '~' },
    delete = { text = '_' },
    topdelete = { text = '‾' },
    changedelete = { text = '~' },
  },
}

require('nvim-surround').setup {}

do
  local leap = require 'leap'
  leap.setup {}
  leap.opts.highlight_unlabeled_phase_one_targets = true
  leap.opts.case_sensitive = false

  leap.opts.labels = 'abcdefghijklmnopqrstuvwxyz'
  leap.opts.safe_labels = 'abcdefghijklmnopqrstuvwxyz'

  vim.keymap.set({ 'n', 'x', 'o' }, 'f', function() leap.leap { target_windows = { vim.fn.win_getid() } } end)
  vim.keymap.set({ 'n', 'x', 'o' }, 'F', function() leap.leap { target_windows = { vim.fn.win_getid() }, backward = true } end)
end

-- Useful plugin to show you pending keybinds
require('which-key').setup {
  -- delay between pressing a key and opening which-key (milliseconds)
  delay = 0,
  icons = { mappings = vim.g.have_nerd_font },

  -- Document existing key chains
  spec = {
    { '<leader>s', group = '[S]earch', mode = { 'n', 'v' } },
    { '<leader>t', group = '[T]oggle' },
    { '<leader>h', group = 'Git [H]unk', mode = { 'n', 'v' } }, -- Enable gitsigns recommended keymaps first
    { 'gr', group = 'LSP Actions', mode = { 'n' } },
  },
}

do
  local db = require 'dashboard'

  -- rstl.sway foresty palette for the dashboard.
  -- Applied via a ColorScheme autocommand because the colorscheme is set in
  -- 'init.lua' after this module runs, and applying a colorscheme clears any
  -- highlights defined before it (`highlight clear`).
  vim.api.nvim_create_autocmd('ColorScheme', {
    group = vim.api.nvim_create_augroup('dashboard-palette', { clear = true }),
    desc = 'Foresty highlight palette for dashboard-nvim',
    callback = function()
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
    end,
  })

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
    -- total number of lines
    local total_lines = #header + #center + #footer
    local top_padding = math.floor((vim.o.lines - total_lines) / 2)

    local padded_header = {}
    for _ = 1, top_padding do
      table.insert(padded_header, '') -- empty line
    end

    -- append original header after padding
    for _, line in ipairs(header) do
      table.insert(padded_header, line)
    end

    return padded_header
  end

  local center_text = {
    { icon = '  ', desc = 'new file', key = 'e', action = 'enew' },
    { icon = '  ', desc = 'find file', key = 'f', action = 'Telescope find_files' },
    { icon = '  ', desc = 'recent files', key = 'r', action = 'Telescope oldfiles' },
    { icon = '  ', desc = 'find word', key = 'w', action = 'Telescope grep_string' },
    { icon = '  ', desc = 'live grep', key = 'g', action = 'Telescope live_grep' },
    { icon = '  ', desc = 'config', key = 'c', action = 'edit ~/.config/nvim/init.lua' },
    { icon = '  ', desc = 'quit', key = 'q', action = 'qa' },
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

-- Collection of various small independent plugins/modules
do
  -- Better Around/Inside textobjects
  --
  -- Examples:
  --  - va)  - [V]isually select [A]round [)]paren
  --  - yinq - [Y]ank [I]nside [N]ext [Q]uote
  --  - ci'  - [C]hange [I]nside [']quote
  require('mini.ai').setup { n_lines = 500 }

  -- Add/delete/replace surroundings (brackets, quotes, etc.)
  --
  -- - saiw) - [S]urround [A]dd [I]nner [W]ord [)]Paren
  -- - sd'   - [S]urround [D]elete [']quotes
  -- - sr)'  - [S]urround [R]eplace [)] [']
  require('mini.surround').setup()

  -- Simple and easy statusline.
  --  You could remove this setup call if you don't like it,
  --  and try some other statusline plugin
  local statusline = require 'mini.statusline'
  -- set use_icons to true if you have a Nerd Font
  statusline.setup { use_icons = vim.g.have_nerd_font }

  -- You can configure sections in the statusline by overriding their
  -- default behavior. For example, here we set the section for
  -- cursor location to LINE:COLUMN
  ---@diagnostic disable-next-line: duplicate-set-field
  statusline.section_location = function() return '%2l:%-2v' end

  -- ... and there is more!
  --  Check out: https://github.com/nvim-mini/mini.nvim
end

-- Highlight todo, notes, etc in comments
require('todo-comments').setup { signs = false }

-- Autoformat
require('conform').setup {
  notify_on_error = false,
  format_on_save = function(bufnr)
    -- Disable "format_on_save lsp_fallback" for languages that don't
    -- have a well standardized coding style. You can add additional
    -- languages here or re-enable it for the disabled ones.
    local disable_filetypes = { c = true, cpp = true }
    if disable_filetypes[vim.bo[bufnr].filetype] then
      return nil
    else
      return {
        timeout_ms = 500,
        lsp_format = 'fallback',
      }
    end
  end,
  formatters_by_ft = {
    lua = { 'stylua' },
    -- Conform can also run multiple formatters sequentially
    -- python = { "isort", "black" },
    --
    -- You can use 'stop_after_first' to run the first available formatter from the list
    -- javascript = { "prettierd", "prettier", stop_after_first = true },
  },
}

vim.keymap.set('', '<leader>f', function() require('conform').format { async = true, lsp_format = 'fallback' } end, { desc = '[F]ormat buffer' })

-- [[ LSP Configuration ]]
-- Brief aside: **What is LSP?**
--
-- LSP is an initialism you've probably heard, but might not understand what it is.
--
-- LSP stands for Language Server Protocol. It's a protocol that helps editors
-- and language tooling communicate in a standardized fashion.
--
-- In general, you have a "server" which is some tool built to understand a particular
-- language (such as `gopls`, `lua_ls`, `rust_analyzer`, etc.). These Language Servers
-- (sometimes called LSP servers, but that's kind of like ATM Machine) are standalone
-- processes that communicate with some "client" - in this case, Neovim!
--
-- LSP provides Neovim with features like:
--  - Go to definition
--  - Find references
--  - Autocompletion
--  - Symbol Search
--  - and more!
--
-- Thus, Language Servers are external tools that must be installed separately from
-- Neovim. This is where `mason` and related plugins come into play.
--
-- If you're wondering about lsp vs treesitter, you can check out the wonderfully
-- and elegantly composed help section, `:help lsp-vs-treesitter`

--  This function gets run when an LSP attaches to a particular buffer.
--    That is to say, every time a new file is opened that is associated with
--    an lsp (for example, opening `main.rs` is associated with `rust_analyzer`) this
--    function will be executed to configure the current buffer
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('kickstart-lsp-attach', { clear = true }),
  callback = function(event)
    -- NOTE: Remember that Lua is a real programming language, and as such it is possible
    -- to define small helper and utility functions so you don't have to repeat yourself.
    --
    -- In this case, we create a function that lets us more easily define mappings specific
    -- for LSP related items. It sets the mode, buffer and description for us each time.
    local map = function(keys, func, desc, mode)
      mode = mode or 'n'
      vim.keymap.set(mode, keys, func, { buffer = event.buf, desc = 'LSP: ' .. desc })
    end

    -- Rename the variable under your cursor.
    --  Most Language Servers support renaming across files, etc.
    map('grn', vim.lsp.buf.rename, '[R]e[n]ame')

    -- Execute a code action, usually your cursor needs to be on top of an error
    -- or a suggestion from your LSP for this to activate.
    map('gra', vim.lsp.buf.code_action, '[G]oto Code [A]ction', { 'n', 'x' })

    -- WARN: This is not Goto Definition, this is Goto Declaration.
    --  For example, in C this would take you to the header.
    map('grD', vim.lsp.buf.declaration, '[G]oto [D]eclaration')

    -- The following two autocommands are used to highlight references of the
    -- word under your cursor when your cursor rests there for a little while.
    --    See `:help CursorHold` for information about when this is executed
    --
    -- When you move your cursor, the highlights will be cleared (the second autocommand).
    local client = vim.lsp.get_client_by_id(event.data.client_id)
    if client and client:supports_method('textDocument/documentHighlight', event.buf) then
      local highlight_augroup = vim.api.nvim_create_augroup('kickstart-lsp-highlight', { clear = false })
      vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.document_highlight,
      })

      vim.api.nvim_create_autocmd({ 'CursorMoved', 'CursorMovedI' }, {
        buffer = event.buf,
        group = highlight_augroup,
        callback = vim.lsp.buf.clear_references,
      })

      vim.api.nvim_create_autocmd('LspDetach', {
        group = vim.api.nvim_create_augroup('kickstart-lsp-detach', { clear = true }),
        callback = function(event2)
          vim.lsp.buf.clear_references()
          vim.api.nvim_clear_autocmds { group = 'kickstart-lsp-highlight', buffer = event2.buf }
        end,
      })
    end

    -- The following code creates a keymap to toggle inlay hints in your
    -- code, if the language server you are using supports them
    --
    -- This may be unwanted, since they displace some of your code
    if client and client:supports_method('textDocument/inlayHint', event.buf) then
      map('<leader>th', function() vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled { bufnr = event.buf }) end, '[T]oggle Inlay [H]ints')
    end
  end,
})

-- Enable the following language servers
--  Feel free to add/remove any LSPs that you want here. They will automatically be installed.
--  See `:help lsp-config` for information about keys and how to configure
---@type table<string, vim.lsp.Config>
local servers = {
  -- clangd = {},
  -- gopls = {},
  -- pyright = {},
  -- rust_analyzer = {},
  --
  -- Some languages (like typescript) have entire language plugins that can be useful:
  --    https://github.com/pmizio/typescript-tools.nvim
  --
  -- But for many setups, the LSP (`ts_ls`) will work just fine
  -- ts_ls = {},

  stylua = {}, -- Used to format Lua code

  -- Special Lua Config, as recommended by neovim help docs
  lua_ls = {
    on_init = function(client)
      if client.workspace_folders then
        local path = client.workspace_folders[1].name
        if path ~= vim.fn.stdpath 'config' and (vim.uv.fs_stat(path .. '/.luarc.json') or vim.uv.fs_stat(path .. '/.luarc.jsonc')) then return end
      end

      client.config.settings.Lua = vim.tbl_deep_extend('force', client.config.settings.Lua, {
        runtime = {
          version = 'LuaJIT',
          path = { 'lua/?.lua', 'lua/?/init.lua' },
        },
        workspace = {
          checkThirdParty = false,
          -- NOTE: this is a lot slower and will cause issues when working on your own configuration.
          --  See https://github.com/neovim/nvim-lspconfig/issues/3189
          library = vim.tbl_extend('force', vim.api.nvim_get_runtime_file('', true), {
            '${3rd}/luv/library',
            '${3rd}/busted/library',
          }),
        },
      })
    end,
    settings = {
      Lua = {},
    },
  },
}

-- Ensure the servers and tools above are installed
--
-- To check the current status of installed tools and/or manually install
-- other tools, you can run
--    :Mason
--
-- You can press `g?` for help in this menu.
require('mason').setup {}
local ensure_installed = vim.tbl_keys(servers or {})
vim.list_extend(ensure_installed, {
  -- You can add other tools here that you want Mason to install
})
require('mason-tool-installer').setup { ensure_installed = ensure_installed }

for name, server in pairs(servers) do
  vim.lsp.config(name, server)
  vim.lsp.enable(name)
end

-- [[ Autocompletion ]]

-- Snippet engine
require('luasnip').setup {}

-- Blink.cmp
-- See :h blink-cmp-config for all options
require('blink.cmp').setup {
  keymap = {
    -- 'default' (recommended) for mappings similar to built-in completions
    --   <c-y> to accept ([y]es) the completion.
    --    This will auto-import if your LSP supports it.
    --    This will expand snippets if the LSP sent a snippet.
    -- 'super-tab' for tab to accept
    -- 'enter' for enter to accept
    -- 'none' for no mappings
    --
    -- For an understanding of why the 'default' preset is recommended,
    -- you will need to read `:help ins-completion`
    --
    -- No, but seriously. Please read `:help ins-completion`, it is really good!
    --
    -- All presets have the following mappings:
    -- <tab>/<s-tab>: move to right/left of your snippet expansion
    -- <c-space>: Open menu or open docs if already open
    -- <c-n>/<c-p> or <up>/<down>: Select next/previous item
    -- <c-e>: Hide menu
    -- <c-k>: Toggle signature help
    --
    -- See :h blink-cmp-config-keymap for defining your own keymap
    preset = 'default',

    -- For more advanced Luasnip keymaps (e.g. selecting choice nodes, expansion) see:
    --    https://github.com/L3MON4D3/LuaSnip?tab=readme-ov-file#keymaps
  },

  appearance = {
    -- 'mono' (default) for 'Nerd Font Mono' or 'normal' for 'Nerd Font'
    -- Adjusts spacing to ensure icons are aligned
    nerd_font_variant = 'mono',
  },

  completion = {
    -- By default, you may press `<c-space>` to show the documentation.
    -- Optionally, set `auto_show = true` to show the documentation after a delay.
    documentation = { auto_show = false, auto_show_delay_ms = 500 },
  },

  sources = {
    default = { 'lsp', 'path', 'snippets' },
  },

  snippets = { preset = 'luasnip' },

  -- See :h blink-cmp-config-fuzzy for more information
  fuzzy = { implementation = 'lua' },

  -- Shows a signature help window while you type arguments for a function
  signature = { enabled = true },
}

-- nvim-cmp
local cmp = require 'cmp'
cmp.setup {
  completion = { completeopt = 'menu,menuone,noselect' },
  mapping = cmp.mapping.preset.insert {
    ['<C-n>'] = cmp.mapping.select_next_item(),
    ['<C-p>'] = cmp.mapping.select_prev_item(),
    ['<CR>'] = cmp.mapping.confirm { select = true },
  },
  sources = cmp.config.sources {
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  },
}

-- [[ Fuzzy Finder (files, lsp, etc) ]]
-- Telescope is a fuzzy finder that comes with a lot of different things that
-- it can fuzzy find! It's more than just a "file finder", it can search
-- many different aspects of Neovim, your workspace, LSP, and more!
--
-- The easiest way to use Telescope, is to start by doing something like:
--  :Telescope help_tags
--
-- After running this command, a window will open up and you're able to
-- type in the prompt window. You'll see a list of `help_tags` options and
-- a corresponding preview of the help.
--
-- Two important keymaps to use while in Telescope are:
--  - Insert mode: <c-/>
--  - Normal mode: ?
--
-- This opens a window that shows you all the keymaps for the current
-- Telescope picker. This is really useful to discover what Telescope can
-- do as well as how to actually do it!

require('telescope').setup {
  -- You can put your default mappings / updates / etc. in here
  --  All the info you're looking for is in `:help telescope.setup()`
  extensions = {
    ['ui-select'] = { require('telescope.themes').get_dropdown() },
  },
}

-- Enable Telescope extensions if they are installed
pcall(require('telescope').load_extension, 'fzf')
pcall(require('telescope').load_extension, 'ui-select')

-- See `:help telescope.builtin`
local builtin = require 'telescope.builtin'
vim.keymap.set('n', '<leader>sh', builtin.help_tags, { desc = '[S]earch [H]elp' })
vim.keymap.set('n', '<leader>sk', builtin.keymaps, { desc = '[S]earch [K]eymaps' })
vim.keymap.set('n', '<leader>sf', builtin.find_files, { desc = '[S]earch [F]iles' })
vim.keymap.set('n', '<leader>ss', builtin.builtin, { desc = '[S]earch [S]elect Telescope' })
vim.keymap.set({ 'n', 'v' }, '<leader>sw', builtin.grep_string, { desc = '[S]earch current [W]ord' })
vim.keymap.set('n', '<leader>sg', builtin.live_grep, { desc = '[S]earch by [G]rep' })
vim.keymap.set('n', '<leader>sd', builtin.diagnostics, { desc = '[S]earch [D]iagnostics' })
vim.keymap.set('n', '<leader>sr', builtin.resume, { desc = '[S]earch [R]esume' })
vim.keymap.set('n', '<leader>s.', builtin.oldfiles, { desc = '[S]earch Recent Files ("." for repeat)' })
vim.keymap.set('n', '<leader>sc', builtin.commands, { desc = '[S]earch [C]ommands' })
vim.keymap.set('n', '<leader><leader>', builtin.buffers, { desc = '[ ] Find existing buffers' })

-- This runs on LSP attach per buffer (see main LSP attach function above for more info).
-- This allows easily switching between pickers if you prefer using something else!
vim.api.nvim_create_autocmd('LspAttach', {
  group = vim.api.nvim_create_augroup('telescope-lsp-attach', { clear = true }),
  callback = function(event)
    local buf = event.buf

    -- Find references for the word under your cursor.
    vim.keymap.set('n', 'grr', builtin.lsp_references, { buffer = buf, desc = '[G]oto [R]eferences' })

    -- Jump to the implementation of the word under your cursor.
    -- Useful when your language has ways of declaring types without an actual implementation.
    vim.keymap.set('n', 'gri', builtin.lsp_implementations, { buffer = buf, desc = '[G]oto [I]mplementation' })

    -- Jump to the definition of the word under your cursor.
    -- This is where a variable was first declared, or where a function is defined, etc.
    -- To jump back, press <C-t>.
    vim.keymap.set('n', 'grd', builtin.lsp_definitions, { buffer = buf, desc = '[G]oto [D]efinition' })

    -- Fuzzy find all the symbols in your current document.
    -- Symbols are things like variables, functions, types, etc.
    vim.keymap.set('n', 'gO', builtin.lsp_document_symbols, { buffer = buf, desc = 'Open Document Symbols' })

    -- Fuzzy find all the symbols in your current workspace.
    -- Similar to document symbols, except searches over your entire project.
    vim.keymap.set('n', 'gW', builtin.lsp_dynamic_workspace_symbols, { buffer = buf, desc = 'Open Workspace Symbols' })

    -- Jump to the type of the word under your cursor.
    -- Useful when you're not sure what type a variable is and you want to see
    -- the definition of its *type*, not where it was *defined*.
    vim.keymap.set('n', 'grt', builtin.lsp_type_definitions, { buffer = buf, desc = '[G]oto [T]ype Definition' })
  end,
})

-- Override default behavior and theme when searching
vim.keymap.set('n', '<leader>/', function()
  -- You can pass additional configuration to Telescope to change the theme, layout, etc.
  builtin.current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
    winblend = 10,
    previewer = false,
  })
end, { desc = '[/] Fuzzily search in current buffer' })

-- It's also possible to pass additional configuration options.
--  See `:help telescope.builtin.live_grep()` for information about particular keys
vim.keymap.set(
  'n',
  '<leader>s/',
  function()
    builtin.live_grep {
      grep_open_files = true,
      prompt_title = 'Live Grep in Open Files',
    }
  end,
  { desc = '[S]earch [/] in Open Files' }
)

-- Shortcut for searching your Neovim configuration files
vim.keymap.set('n', '<leader>sn', function() builtin.find_files { cwd = vim.fn.stdpath 'config' } end, { desc = '[S]earch [N]eovim files' })

-- [[ Configure Treesitter ]] See `:help nvim-treesitter-intro`
do
  local parsers = { 'bash', 'c', 'diff', 'html', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'query', 'vim', 'vimdoc' }

  -- Install any missing parsers (e.g. on first run); refresh existing ones with `:TSUpdate`
  local parser_dir = vim.fs.joinpath(vim.fn.stdpath 'data', 'site', 'parser')
  local missing = vim.iter(parsers):filter(function(lang) return not vim.uv.fs_stat(vim.fs.joinpath(parser_dir, lang .. '.so')) end):totable()
  if #missing > 0 then require('nvim-treesitter').install(missing) end

  vim.api.nvim_create_autocmd('FileType', {
    callback = function(args)
      local buf, filetype = args.buf, args.match

      local language = vim.treesitter.language.get_lang(filetype)
      if not language then return end

      -- check if parser exists and load it
      if not vim.treesitter.language.add(language) then return end
      -- enables syntax highlighting and other treesitter features
      vim.treesitter.start(buf, language)

      -- enables treesitter based folds
      -- for more info on folds see `:help folds`
      -- vim.wo.foldexpr = 'v:lua.vim.treesitter.foldexpr()'
      -- vim.wo.foldmethod = 'expr'

      -- enables treesitter based indentation
      vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end,
  })
end

-- Cord.nvim settings
require('cord').setup {
  display = {
    view = 'asset',
    theme = 'minecraft',
    flavor = 'accent', -- dark/light/accent
  },

  hooks = {
    post_activity = function(opts, activity)
      activity.status_display_type = 'details' -- 'name' | 'details' | 'state'
    end,
  },

  --  idle = {
  --    enabled = true,
  --    timeout = 300,
  --  },
}

-- vim: ts=2 sts=2 sw=2 et

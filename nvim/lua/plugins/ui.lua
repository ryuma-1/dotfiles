local colors = require('config.colors')

return {
-- カラースキーム (Monokai Pro)
    {
        "loctvl842/monokai-pro.nvim", -- 💡 「loctvl842」に修正しました
        lazy = false,
        priority = 1000,
        config = function()
            require("monokai-pro").setup({
                filter = "pro",
                styles = {
                    comment = { italic = true },
                    keyword = { italic = true },
                },
                -- Plugins listed here use editor.background instead of their own panel colors.
                -- The defaults are kept and nvim-tree / which-key are added so they share the black code bg
                -- (which-key otherwise uses the gray suggest-widget bg for its popup)
                background_clear = { "toggleterm", "telescope", "renamer", "notify", "nvim-tree", "which-key" },
                -- bufferline is themable, so monokai-pro's BufferLine*Selected groups (including devicons)
                -- take precedence; they all derive from tab.activeBackground, so match it to the code bg here.
                -- editor.background is also overridden because plugin highlights (Telescope, FloatBorder, ...)
                -- are built from it directly, so overriding only Normal would leave them on the theme's gray bg.
                -- Non-selected tabs (inactive, and visible in another window) take the bufferline fill color
                -- so that they blend into the empty area and only the selected tab stands out
                override_scheme = function(scheme)
                    local fill = scheme.editorGroupHeader.tabsBackground
                    return {
                        editor = { background = "#000000" },
                        tab = {
                            activeBackground = "#000000",
                            inactiveBackground = fill,
                            unfocusedActiveBackground = fill,
                        },
                    }
                end,
                override = function(c)
                    return {
                        Normal = { bg = "#000000" },
                        -- Inactive windows use NormalNC, which otherwise keeps the theme's gray bg;
                        -- tint.nvim already marks unfocused windows, so the bg stays identical to Normal
                        NormalNC = { bg = "#000000" },
                        -- navic icons define only fg and inherit WinBar's bg, so keep it equal to Normal
                        WinBar = { bg = "#000000" },
                        WinBarNC = { bg = "#000000" },
                        -- treesitter-context links to NormalFloat by default, whose gray bg stands out too much against the black code area
                        TreesitterContext = { bg = colors.overlay_bg },
                        -- Folded lines share the treesitter-context bg so both "collapsed/pinned" areas look alike
                        -- (UfoFoldedBg is reapplied in nvim-ufo's config, see edit.lua)
                        Folded = { bg = colors.overlay_bg },
                    }
                end,
            })

            vim.cmd("colorscheme monokai-pro")
        end
    },
    -- ステータスライン
    {
        'nvim-lualine/lualine.nvim',
        lazy = false,
        dependencies = { 'nvim-tree/nvim-web-devicons', 'SmiteshP/nvim-navic' },
        config = function()
            local navic = require('nvim-navic')
            local my_sections = {
                -- Rounded outer caps give the bubbles look from lualine's examples/bubbles.lua
                lualine_a = { { 'filename', separator = { left = '' }, right_padding = 2 } },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { { 'filename', file_status = false, path = 3 }, 'selectioncount' },
                lualine_x = { { require('lazy.status').updates, cond = require('lazy.status').has_updates } },
                lualine_y = { 'encoding', 'fileformat', 'filetype' },
                lualine_z = { { '%l/%L:%c (%p%%)', separator = { right = '' }, left_padding = 2 } }
            }
            ---Winbar showing the nvim-navic breadcrumbs of the cursor position.
            ---The component is hidden while no LSP with documentSymbol is attached.
            local my_winbar = {
                lualine_c = { { function() return navic.get_location() end, cond = navic.is_available } },
            }
            ---Monokai Pro lualine theme whose middle sections share the editor background,
            ---so the winbar (drawn with section c) blends into the code area.
            local my_theme = vim.deepcopy(require('lualine.themes.monokai-pro'))
            my_theme.normal.c.bg = '#000000'
            my_theme.normal.x.bg = '#000000'
            require('lualine').setup({
                options = {
                    theme = my_theme,
                    component_separators = '',
                    section_separators = { left = '', right = '' },
                },
                sections = my_sections,
                winbar = my_winbar,
            })
        end
    },
    -- Breadcrumbs of the current code context, provided by LSP document symbols
    {
        'SmiteshP/nvim-navic',
        dependencies = { 'neovim/nvim-lspconfig' },
        lazy = true,
        opts = {
            -- Attach automatically on LspAttach, so no on_attach wiring is needed in lsp.lua
            lsp = { auto_attach = true },
            highlight = true,
        },
        ---Sets up navic, then repaints WinBar to match the code background.
        ---monokai-pro applies its navic highlights (including WinBar) when nvim-navic is first
        ---required, bypassing the user `override`, so the bg has to be reapplied afterwards.
        config = function(_, opts)
            require('nvim-navic').setup(opts)
            for _, group in ipairs({ 'WinBar', 'WinBarNC' }) do
                local hl = vim.api.nvim_get_hl(0, { name = group, link = false })
                vim.api.nvim_set_hl(0, group, vim.tbl_extend('force', hl, { bg = '#000000' }))
            end
        end,
    },
    -- バッファライン
    {
        'akinsho/bufferline.nvim',
        version = '*',
        event = 'VimEnter',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        keys = {
            { '<leader>wp', '<CMD>BufferLineTogglePin<CR>', desc = 'Toggle Pin Buffer' },
        },
        opts = {
            options = {
                -- Slanted tab edges, as shown in the bufferline.nvim README
                separator_style = 'slant',
                diagnostics = 'nvim_lsp',
                -- Reveal the close icon only while hovering, so idle tabs stay uncluttered.
                -- Requires 'mousemoveevent' (set in config/base.lua)
                hover = {
                    enabled = true,
                    delay = 200,
                    reveal = { 'close' },
                },
            },
        },
    },
    -- カラーコード着色
    {
        'norcalli/nvim-colorizer.lua',
        event = { 'BufReadPre', 'BufNewFile' },
        config = function() require('colorizer').setup() end
    },
    -- Highlights the current chunk and draws indent guides.
    -- Replaces snacks.nvim indent so that guides are rendered by a single plugin.
    {
        'shellRaining/hlchunk.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = {
            chunk = {
                enable = true,
                -- The second entry is used for invalid chunks, so it stays red to keep errors noticeable.
                style = {
                    { fg = '#FFFFFF' },
                    { fg = '#C21F30' },
                },
            },
            indent = {
                enable = true,
                -- Cycled per indent level (red, yellow, green, cyan, blue, violet, orange).
                -- Dark tones are used so the guides stay in the background and don't distract from the code.
                style = {
                    '#70363A',
                    '#72603D',
                    '#4C613C',
                    '#2B5B61',
                    '#305777',
                    '#633C6E',
                    '#684D33',
                },
            },
        },
    },
    -- Whitespace強調
    {
        'ntpeters/vim-better-whitespace',
        event = 'VeryLazy',
        config = function()
            vim.g.better_whitespace_filetypes_blacklist = { 'toggleterm', 'diff', 'qf', 'help', 'snacks_dashboard' }
            vim.api.nvim_set_hl(0, 'ExtraWhitespace', { bg = '#CF572D' })
        end
    },
    -- Dims inactive windows so the focused one stands out when the screen is split
    {
        'levouh/tint.nvim',
        event = 'VeryLazy',
        opts = {
            -- Darker than the default (-40) so unfocused text fades further toward the black bg
            tint = -80,
            ---Excludes floating windows from tint.
            ---tint applies its own copy of every highlight to a window via nvim_win_set_hl_ns, which
            ---bypasses the window's winhl, so floats like lazygit (NormalFloat -> LazyGitFloat) lost their bg.
            ---@param winid integer
            ---@return boolean
            window_ignore_function = function(winid)
                return vim.api.nvim_win_get_config(winid).relative ~= ''
            end,
        },
    },
    -- Scrollbar that marks diagnostics and git changes, giving a whole-file overview like VSCode
    {
        'petertriho/nvim-scrollbar',
        event = 'VeryLazy',
        -- hlslens is a dependency so its own setup runs first; the search handler patches hlslens.config
        -- directly, and a later hlslens setup would drop the scrollbar callback
        dependencies = { 'lewis6991/gitsigns.nvim', 'kevinhwang91/nvim-hlslens' },
        ---Sets up the scrollbar, then registers the gitsigns and search handlers.
        ---The handlers are registered explicitly (not via `handlers.*`) as the README recommends,
        ---so they are guaranteed to be wired after gitsigns and hlslens themselves are loaded.
        config = function()
            require('scrollbar').setup({
                marks = {
                    -- Search marks take their fg from the Search group, but monokai-pro defines only a bg there,
                    -- so they became black on the black code bg; Monokai Pro yellow is set explicitly instead
                    Search = { color = '#FFD866' },
                },
            })
            require('scrollbar.handlers.gitsigns').setup()
            require('scrollbar.handlers.search').setup()
        end,
    },
    -- Shows the index and total count of search matches as virtual text next to each match
    {
        'kevinhwang91/nvim-hlslens',
        -- n/N/*/# start the lens explicitly, and `/` or `?` searches are picked up once the plugin is loaded
        keys = {
            -- n/N keep the previous `nzz`/`Nzz` behavior (formerly in config/keymaps.lua) so the match stays centered
            { 'n', [[<Cmd>execute('normal! ' . v:count1 . 'nzz')<CR><Cmd>lua require('hlslens').start()<CR>]], desc = 'Next match (hlslens)' },
            { 'N', [[<Cmd>execute('normal! ' . v:count1 . 'Nzz')<CR><Cmd>lua require('hlslens').start()<CR>]], desc = 'Prev match (hlslens)' },
            { '*', [[*<Cmd>lua require('hlslens').start()<CR>]], desc = 'Search word forward (hlslens)' },
            { '#', [[#<Cmd>lua require('hlslens').start()<CR>]], desc = 'Search word backward (hlslens)' },
            { 'g*', [[g*<Cmd>lua require('hlslens').start()<CR>]], desc = 'Search partial word forward (hlslens)' },
            { 'g#', [[g#<Cmd>lua require('hlslens').start()<CR>]], desc = 'Search partial word backward (hlslens)' },
        },
        event = 'CmdlineEnter',
        opts = {},
    },
    -- Pins the enclosing function/class header at the top so the current scope stays visible in long blocks
    {
        'nvim-treesitter/nvim-treesitter-context',
        event = { 'BufReadPost', 'BufNewFile' },
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        opts = {
            -- Capped so deeply nested code cannot push the context window over most of the screen
            max_lines = 3,
        },
    },
    -- Switches to absolute numbers in insert mode and unfocused windows, relative numbers otherwise
    {
        'myusuf3/numbers.vim',
        event = { 'BufReadPost', 'BufNewFile' },
        ---Sets the exclude list before the plugin script is sourced, since it is read when autocmds fire.
        ---Overrides the default list (unite/nerdtree etc.) with the special buffers used in this config,
        ---so numbers.vim does not force line numbers onto them.
        init = function()
            vim.g.numbers_exclude = {
                'NvimTree', 'toggleterm', 'snacks_dashboard', 'lazy', 'mason',
                'help', 'qf', 'TelescopePrompt', 'lazygit', 'DiffviewFiles', 'Avante',
            }
        end,
    },
    -- Shows a popup of the available follow-up keys after a prefix key such as <leader> is pressed
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        ---@type wk.Opts
        opts = {
            preset = 'modern',
            -- Show the popup only after a pause, so it does not flash while typing a known sequence.
            -- Applied to the built-in marks/registers popups too (their default is 0ms).
            -- Kept below timeoutlen (1000ms) so the popup appears before an ambiguous mapping times out
            delay = 500,
        },
        keys = {
            {
                '<leader>?',
                ---Shows the buffer-local keymaps, which are otherwise mixed into the global popup.
                function() require('which-key').show({ global = false }) end,
                desc = 'Buffer Local Keymaps (which-key)',
            },
        },
    },
}

local colors = require('config.colors')

return {
-- カラースキーム (Monokai Pro)
    {
        "loctvl842/monokai-pro.nvim",
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
                -- colors.enabled is checked instead of is_active() because vim.g.colors_name
                -- still holds the previous colorscheme while monokai-pro is being loaded
                override_scheme = function(scheme)
                    if not colors.enabled then
                        return {}
                    end
                    local fill = scheme.editorGroupHeader.tabsBackground
                    return {
                        editor = { background = colors.code_bg },
                        tab = {
                            activeBackground = colors.code_bg,
                            inactiveBackground = fill,
                            unfocusedActiveBackground = fill,
                        },
                    }
                end,
                override = function(c)
                    local groups = {}
                    if colors.enabled then
                        -- overlay_bg is tuned against the black code area, so it is only used together with it;
                        -- with the black bg disabled these groups keep the theme's own colors
                        -- treesitter-context links to NormalFloat by default, whose gray bg stands out too much against the black code area
                        groups.TreesitterContext = { bg = colors.overlay_bg }
                        -- Folded lines share the treesitter-context bg so both "collapsed/pinned" areas look alike
                        -- (UfoFoldedBg is reapplied by colors.apply_code_bg(), see config/colors.lua)
                        groups.Folded = { bg = colors.overlay_bg }
                        local black = { bg = colors.code_bg }
                        groups.Normal = black
                        -- Inactive windows use NormalNC, which otherwise keeps the theme's gray bg;
                        -- tint.nvim already marks unfocused windows, so the bg stays identical to Normal
                        groups.NormalNC = black
                        -- navic icons define only fg and inherit WinBar's bg, so keep it equal to Normal
                        groups.WinBar = black
                        groups.WinBarNC = black
                        -- The theme paints floats with the gray suggest-widget bg, and Lspsaga (hover, code action,
                        -- diagnostics), vim.diagnostic floats and avante's prompt input all link to NormalFloat;
                        -- FloatBorder already uses editor.background, so only the body needs to match it
                        groups.NormalFloat = black
                    end
                    return groups
                end,
            })

            vim.cmd("colorscheme monokai-pro")
        end
    },
    -- Colorscheme (Tokyo Night), loaded on demand so that monokai-pro stays the initial colorscheme
    {
        'folke/tokyonight.nvim',
        lazy = true,
        priority = 1000,
        opts = {
            ---Replaces the dark backgrounds with the shared black code bg.
            ---colors.enabled is checked instead of is_active() because vim.g.colors_name still holds
            ---the previous colorscheme while tokyonight is being loaded. The light variant (tokyonight-day)
            ---is excluded through 'background', which tokyonight sets from the variant before calling this.
            ---Everything derived from these keys (Normal, floats, sidebars, statusline) follows automatically.
            ---@param c table tokyonight palette
            on_colors = function(c)
                if not colors.enabled or vim.o.background ~= 'dark' then
                    return
                end
                c.bg = colors.code_bg
                c.bg_dark = colors.code_bg
                c.bg_float = colors.code_bg
                c.bg_sidebar = colors.code_bg
                c.bg_popup = colors.code_bg
                c.bg_statusline = colors.code_bg
            end,
            ---Gives folded lines and the pinned treesitter-context the overlay bg, as monokai-pro does.
            ---The same guard as on_colors applies, so the theme keeps its own colors in tokyonight-day and while disabled.
            ---@param hl table highlight groups of the theme
            on_highlights = function(hl)
                if not colors.enabled or vim.o.background ~= 'dark' then
                    return
                end
                hl.Folded = vim.tbl_extend('force', hl.Folded or {}, { bg = colors.overlay_bg })
                hl.TreesitterContext = { bg = colors.overlay_bg }
            end,
        },
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
            ---Winbar of unfocused windows showing only the file name.
            ---The focused window already shows its file in the statusline, so the name is needed only
            ---where the statusline cannot tell which file a split is displaying.
            local my_inactive_winbar = {
                lualine_c = {
                    {
                        'filename',
                        -- Limited to file buffers so panels like NvimTree or terminals do not show
                        -- their internal buffer names (e.g. "NvimTree_1 [-]")
                        cond = function() return vim.bo.buftype == '' end,
                    },
                },
            }
            ---Builds the lualine theme for the current colorscheme.
            ---monokai-pro keeps its explicit theme (with the middle sections sharing the editor background
            ---while the black bg is active, so the winbar drawn with section c blends into the code area).
            ---Other colorschemes use 'auto', which loads the theme bundled with the colorscheme
            ---(tokyonight ships one per variant and already reads its black palette) or derives one from highlights.
            ---@return table|string
            local function build_theme()
                if vim.g.colors_name ~= 'monokai-pro' then
                    return 'auto'
                end
                local theme = vim.deepcopy(require('lualine.themes.monokai-pro'))
                if colors.is_active() then
                    theme.normal.c.bg = colors.code_bg
                    theme.normal.x.bg = colors.code_bg
                end
                return theme
            end
            ---(Re)applies the lualine config with a theme built for the current colorscheme and black bg state.
            local function setup_lualine()
                require('lualine').setup({
                    options = {
                        theme = build_theme(),
                        component_separators = '',
                        section_separators = { left = '', right = '' },
                    },
                    sections = my_sections,
                    winbar = my_winbar,
                    inactive_winbar = my_inactive_winbar,
                })
            end
            setup_lualine()
            -- The theme depends on the colorscheme and on :BlackBgToggle (which reloads the colorscheme),
            -- so lualine is set up again whenever the colorscheme is loaded
            vim.api.nvim_create_autocmd('ColorScheme', {
                group = vim.api.nvim_create_augroup('LualineBlackBg', { clear = true }),
                callback = setup_lualine,
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
            colors.apply_code_bg()
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
    -- その他特定用途
    { 'eandrju/cellular-automaton.nvim', cmd = 'CellularAutomaton' },
}

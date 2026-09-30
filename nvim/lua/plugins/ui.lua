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
                override = function(c)
                    return {
                        Normal = { bg = "#000000" },
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
                lualine_a = { 'filename' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { { 'filename', file_status = false, path = 3 }, 'selectioncount' },
                lualine_x = { { require('lazy.status').updates, cond = require('lazy.status').has_updates } },
                lualine_y = { 'encoding', 'fileformat', 'filetype' },
                lualine_z = { '%l/%L:%c (%p%%)' }
            }
            ---Winbar showing the nvim-navic breadcrumbs of the cursor position.
            ---The component is hidden while no LSP with documentSymbol is attached.
            local my_winbar = {
                lualine_c = { { function() return navic.get_location() end, cond = navic.is_available } },
            }
            require('lualine').setup({ sections = my_sections, winbar = my_winbar })
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
    },
    -- バッファライン
    {
        'akinsho/bufferline.nvim',
        version = '*',
        event = 'VimEnter',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        opts = {
            options = {
                -- Slanted tab edges, as shown in the bufferline.nvim README
                separator_style = 'slant',
                diagnostics = 'nvim_lsp',
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
    }
}

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
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        config = function()
            local my_sections = {
                lualine_a = { 'filename' },
                lualine_b = { 'branch', 'diff', 'diagnostics' },
                lualine_c = { { 'filename', file_status = false, path = 3 }, 'selectioncount' },
                lualine_x = { { require('lazy.status').updates, cond = require('lazy.status').has_updates } },
                lualine_y = { 'encoding', 'fileformat', 'filetype' },
                lualine_z = { '%l/%L:%c (%p%%)' }
            }
            require('lualine').setup({ sections = my_sections })
        end
    },
    -- バッファライン
    {
        'romgrk/barbar.nvim',
        event = 'VimEnter',
        dependencies = { 'nvim-tree/nvim-web-devicons', 'lewis6991/gitsigns.nvim' },
        init = function()
            -- lazy.nvim calls setup() via opts, so disable barbar's auto setup to avoid a double setup
            vim.g.barbar_auto_setup = false
        end,
        opts = {},
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
            chunk = { enable = true },
            indent = { enable = true },
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

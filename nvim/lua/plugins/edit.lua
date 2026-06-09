return {
    -- 囲い文字操作
    { 'machakann/vim-sandwich', event = 'VeryLazy' },
    -- インデント自動調整
    {
        'timakro/vim-yadi',
        event = 'VeryLazy',
        config = function() vim.cmd('DetectIndent') end
    },
    -- 括弧の自動補完
    {
        'hrsh7th/nvim-insx',
        event = 'InsertEnter',
        config = function() require('insx.preset.standard').setup() end
    },
    -- TODOコメント強調
    {
        'folke/todo-comments.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {},
    },
    -- キーマップガイド
    {
        'folke/which-key.nvim',
        event = 'VeryLazy',
        config = function()
            require('which-key').setup()
            vim.o.timeout = true
            vim.o.timeoutlen = 1000
        end,
    },
    -- スムーズスクロール
    {
        'karb94/neoscroll.nvim',
        event = 'VeryLazy',
        opts = {
            mappings = { '<C-u>', '<C-d>', '<C-b>', '<C-f>', '<C-y>', '<C-e>', 'zt', 'zz', 'zb' },
            duration_multiplier = 0.5,
        },
    },
    -- コメントアウト
    { 'numToStr/Comment.nvim', event = 'VeryLazy', opts = {} },
    -- マクロステータス表示
    { 'chrisgrieser/nvim-recorder', event = 'VeryLazy', dependencies = "rcarriga/nvim-notify", opts = {} },
    -- 高機能な文字ジャンプ (f, F, t, T)
    {
        'smoka7/hop.nvim',
        event = 'VeryLazy',
        config = function()
            local hop = require('hop')
            local directions = require('hop.hint').HintDirection
            vim.keymap.set('', 'f', function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = true }) end, { remap = true })
            vim.keymap.set('', 'F', function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = true }) end, { remap = true })
            vim.keymap.set('', 't', function() hop.hint_char1({ direction = directions.AFTER_CURSOR, current_line_only = false }) end, { remap = true })
            vim.keymap.set('', 'T', function() hop.hint_char1({ direction = directions.BEFORE_CURSOR, current_line_only = false }) end, { remap = true })
            hop.setup()
        end,
    },
    -- 行番号指定時のプレビュー
    { 'nacro90/numb.nvim', event = 'VeryLazy', opts = {} },
    -- 翻訳ツール
    {
        'uga-rosa/translate.nvim',
        opts = {},
        keys = { { '<leader>t', ':Translate ja -output=floating<CR>', mode = { 'n', 'v' }, desc = 'Translate', silent = true } },
    },
    -- ファイラ (NvimTree)
    {
        'nvim-tree/nvim-tree.lua',
        keys = { { "<leader>o", "<cmd>NvimTreeToggle<CR>", desc = "NvimTreeToggle" } },
        opts = {},
    },
    -- ウィンドウを維持してバッファ削除
    {
        'ojroques/nvim-bufdel',
        keys = { { "<leader>w", "<cmd>BufDel<CR>", desc = "Buffer Delete" } },
        opts = { next = 'tabs', quit = false },
    },
    -- 組み込みターミナル改善
    {
        'akinsho/toggleterm.nvim',
        keys = {
            { '<C-t>', '<CMD>ToggleTerm direction=float<CR>', mode = {'n', 'v', 'i'}, desc = 'ToggleTerm open float' },
            { '<leader>yt', '<CMD>ToggleTerm direction=horizontal size=10<CR>', mode = {'n', 'v'}, desc = 'ToggleTerm open horizontal' },
            { '<leader>yy', '<CMD>ToggleTerm direction=vertical size=50<CR>', mode = {'n', 'v'}, desc = 'ToggleTerm open side' },
        },
        config = function()
            require('toggleterm').setup()
            vim.api.nvim_create_autocmd('TermOpen', {
                pattern = { 'term://*' },
                callback = function()
                    vim.api.nvim_buf_set_keymap(0, 't', '<ESC>', [[<C-\><C-n>]], { noremap = true, silent = true })
                end
            })
        end
    },
    -- 各種汎用ユーティリティ (Snacks)
    {
        "folke/snacks.nvim",
        lazy = false,
        opts = {
            bigfile = { enabled = true },
            dashboard = { enabled = true },
            explorer = { enabled = false },
            indent = { enabled = true },
            input = { enabled = true },
            picker = { enabled = true },
            notifier = { enabled = true },
            quickfile = { enabled = true },
            scope = { enabled = true },
            scroll = { enabled = false },
            statuscolumn = { enabled = true },
            words = { enabled = true },
            styles = { scratch = { width = 200, height = 50 } }
        },
        keys = {
            { "<leader>.",  function() Snacks.scratch() end, desc = "Toggle Scratch Buffer" },
            { "<leader>S",  function() Snacks.scratch.select() end, desc = "Select Scratch Buffer" },
            { "<leader>n",  function() Snacks.notifier.show_history() end, desc = "Notification History" },
            { "<leader>un", function() Snacks.notifier.hide() end, desc = "Dismiss All Notifications" },
        },
        init = function()
            vim.api.nvim_create_autocmd("User", {
                pattern = "VeryLazy",
                callback = function()
                    _G.dd = function(...) Snacks.debug.inspect(...) end
                    _G.bt = function() Snacks.debug.backtrace() end

                    if vim.fn.has("nvim-0.11") == 1 then
                        vim.print = function(_, ...) dd(...) end
                    else
                        vim.print = _G.dd
                    end

                    Snacks.toggle.diagnostics():map("<leader>ud")
                    Snacks.toggle.inlay_hints():map("<leader>uh")
                end,
            })
        end,
    },
    -- ヤンク履歴管理
    {
        "gbprod/yanky.nvim",
        dependencies = { "folke/snacks.nvim" },
        opts = {
            ring = {
                history_length = 100,
                storage = "shada",
                storage_path = vim.fn.stdpath("data") .. "/databases/yanky.db",
                sync_with_numbered_registers = true,
                cancel_event = "update",
                ignore_registers = { "_" },
                update_register_on_cycle = false,
            },
            system_clipboard = { sync_with_ring = true },
        },
        keys = {
            { "y", "<Plug>(YankyYank)", mode = { "n", "x" } },
            { "p", "<Plug>(YankyPutAfter)", mode = { "n", "x" } },
            { "P", "<Plug>(YankyPutBefore)", mode = { "n", "x" } },
            { "gp", "<Plug>(YankyGPutAfter)", mode = { "n", "x" } },
            { "gP", "<Plug>(YankyGPutBefore)", mode = { "n", "x" } },
            { "=p", "<Plug>(YankyPutAfterFilter)" },
            { "=P", "<Plug>(YankyPutBeforeFilter)" },
            { "<leader>p", function() Snacks.picker.yanky() end, mode = { "n", "x" }, desc = "Open Yank History" },
        },
    },
    -- ファジーファインダー (Telescope)
    {
        'nvim-telescope/telescope.nvim',
        cmd = 'Telescope',
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            { '<leader>ff', '<CMD>Telescope find_files<CR>', desc = 'Telescope find files'},
            { '<leader>fg', '<CMD>Telescope live_grep<CR>', desc = 'Telescope live grep'},
        },
        config = function()
            require('telescope').setup({
                defaults = {
                    -- 💡 検索から除外したいファイル・フォルダをここに指定します
                    file_ignore_patterns = {
                        "%.meta$",       -- Unityの.metaファイルを完全に除外
                        "%.asset$",      -- .assetファイルを除外（必要なら）
                        "%.unity$",      -- シーンファイルを除外（コードだけに集中したい場合）
			"%.prefab$",	 -- prefabファイルの除外
                        "^Library/",     -- Unityの内部キャッシュフォルダを除外
                        "^Temp/",        -- 一時フォルダを除外
                        "^Logs/",        -- ログフォルダを除外
                        "^obj/",         -- .NETのビルド生成フォルダを除外
                        "%.user$",       -- 個人設定ファイルを除外
                        "%.DS_Store$",   -- Macのシステムファイルを除外
                    },

                    -- パスの表示方法（ファイル名を見やすくする設定。お好みで）
                    path_display = { "truncate" },
                },
            })
        end,
    }
}

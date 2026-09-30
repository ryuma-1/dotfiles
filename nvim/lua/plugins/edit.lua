-- 方向ごとに独立したセッションを持たせ，同じキーで開閉トグルできるよう，
-- toggleterm の Terminal インスタンスを遅延生成して保持する
local edge_terminals = {}

--- Per-direction terminal definitions.
--- `wincmd` moves the window to the screen edge, and `dim`/`size` fix its width or height afterwards.
--- Both are applied in on_open because toggleterm ignores `size` on Terminal:new, has no left/top direction,
--- and splits the most recently opened terminal window when another one is already open.
--- `id` is a fixed high number and `hidden` is set so that `:ToggleTerm` (default target id 1),
--- <C-t>, <leader>yt and <leader>yy never pick up or rewrite these terminals.
local edge_terminal_defs = {
    float = { id = 101, direction = 'float' },
    left = { id = 102, direction = 'vertical', wincmd = 'H', dim = 'width', size = 50 },
    bottom = { id = 103, direction = 'horizontal', wincmd = 'J', dim = 'height', size = 10 },
    top = { id = 104, direction = 'horizontal', wincmd = 'K', dim = 'height', size = 10 },
    right = { id = 105, direction = 'vertical', wincmd = 'L', dim = 'width', size = 50 },
}

--- Re-apply the fixed size of every open split terminal.
--- Moving a window to an edge redistributes the other windows, which would otherwise shrink or grow the terminals opened earlier.
local function apply_edge_sizes()
    for name, term in pairs(edge_terminals) do
        local def = edge_terminal_defs[name]
        if def.dim and term:is_open() then
            if def.dim == 'width' then
                vim.api.nvim_win_set_width(term.window, def.size)
            else
                vim.api.nvim_win_set_height(term.window, def.size)
            end
        end
    end
end

--- Toggle the terminal registered under `name`, creating it on first use.
--- Creation is deferred because `toggleterm.terminal` is only available after the plugin is lazy loaded.
---@param name string one of 'float', 'left', 'bottom', 'top', 'right'
local function toggle_edge_terminal(name)
    if not edge_terminals[name] then
        local Terminal = require('toggleterm.terminal').Terminal
        local def = edge_terminal_defs[name]
        edge_terminals[name] = Terminal:new({
            id = def.id,
            hidden = true,
            direction = def.direction,
            on_open = def.wincmd and function()
                vim.cmd('wincmd ' .. def.wincmd)
                apply_edge_sizes()
            end or nil,
        })
    end
    edge_terminals[name]:toggle()
end

return {
    -- 囲い文字操作
    { 'machakann/vim-sandwich', event = 'VeryLazy' },
    -- インデント自動調整
    {
        'timakro/vim-yadi',
        event = 'VeryLazy',
        config = function()
            -- Markdown は after/ftplugin/markdown.lua の 2 スペース設定を優先する
            if vim.bo.filetype ~= 'markdown' then
                vim.cmd('DetectIndent')
            end
        end
    },
    -- 括弧の自動補完
    {
        "windwp/nvim-autopairs",
        event = "InsertEnter",
        config = function()
            require("nvim-autopairs").setup({
                check_ts = true, -- Treesitter連携
                ts_config = {
                    lua = { "string" },
                    javascript = { "template_string" },
                },
                disable_filetype = {
                    "TelescopePrompt",
                    "vim",
                },
            })

            -- nvim-cmp連携
            local cmp_autopairs = require("nvim-autopairs.completion.cmp")
            local cmp = require("cmp")

            cmp.event:on(
                "confirm_done",
                cmp_autopairs.on_confirm_done()
            )
        end,
    },
    {
        "kylechui/nvim-surround",
        version = "*", -- 最新の安定版
        event = "VeryLazy",
        config = function()
            require("nvim-surround").setup({})
        end,
    },
    -- TODOコメント強調
    {
        'folke/todo-comments.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        dependencies = { 'nvim-lua/plenary.nvim' },
        opts = {},
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
    -- Treesitter によるコードブロックの分割/結合
    {
        'Wansmer/treesj',
        dependencies = { 'nvim-treesitter/nvim-treesitter' },
        keys = {
            { '<leader>st', function() require('treesj').toggle() end, desc = 'Toggle split/join (treesj)' },
        },
        cmd = { 'TSJToggle', 'TSJSplit', 'TSJJoin' },
        -- デフォルトの <leader>s は分割系 prefix (<leader>sh/sv) と衝突するため無効化し，必要なキーだけ keys で定義する
        opts = { use_default_keymaps = false, max_join_length = 150 },
    },
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
        keys = { { '<leader>r', ':Translate ja -output=floating<CR>', mode = { 'n', 'v' }, desc = 'Translate', silent = true } },
    },
    -- ファイラ (NvimTree)
    {
        'nvim-tree/nvim-tree.lua',
        -- `nvim <dir>` のディレクトリバッファを起動時に乗っ取るため，キー押下を待たずに読み込む
        lazy = false,
        keys = {
            { "<leader>b", "<cmd>NvimTreeToggle<CR>", desc = "NvimTreeToggle" },
            { "<leader>e", "<cmd>NvimTreeFocus<CR>", desc = "NvimTreeFocus" },
        },
        opts = {},
    },
    -- ウィンドウを維持してバッファ削除
    {
        'ojroques/nvim-bufdel',
        keys = {
            { "<leader>ww", "<cmd>BufDel<CR>", desc = "Close Current Buffer" },
            { "<leader>wa", "<cmd>BufDelAll<CR>", desc = "Close All Buffers" },
            { "<leader>wo", "<cmd>BufDelOthers<CR>", desc = "Close Other Buffers" },
        },
        opts = { next = 'tabs', quit = false },
    },
    -- 組み込みターミナル改善
    {
        'akinsho/toggleterm.nvim',
        keys = {
            -- インサートモードでの <C-t> は Vim 標準のインデントキーであり，
            -- autolist.nvim の AutolistTab が内部でこれを発火してリストをインデントするため，
            -- ここに割り当てると markdown でリスト行を Tab したときにターミナルが開いてしまう
            { '<C-t>', '<CMD>ToggleTerm direction=float<CR>', mode = {'n', 'v'}, desc = 'ToggleTerm open float' },
            -- 旧 <leader>t を残すと <leader>t* の prefix になり timeoutlen 待ちの遅延が出るため削除した
            { '<leader>tt', function() toggle_edge_terminal('float') end, mode = {'n', 'v'}, desc = 'Toggle terminal (float)' },
            { '<leader>th', function() toggle_edge_terminal('left') end, mode = {'n', 'v'}, desc = 'Toggle terminal (left)' },
            { '<leader>tj', function() toggle_edge_terminal('bottom') end, mode = {'n', 'v'}, desc = 'Toggle terminal (bottom)' },
            { '<leader>tk', function() toggle_edge_terminal('top') end, mode = {'n', 'v'}, desc = 'Toggle terminal (top)' },
            { '<leader>tl', function() toggle_edge_terminal('right') end, mode = {'n', 'v'}, desc = 'Toggle terminal (right)' },
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
            -- Disabled to avoid double rendering with hlchunk.nvim, which now draws indent guides.
            indent = { enabled = false },
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
            { "<leader>P", function() Snacks.picker.yanky() end, mode = { "n", "x" }, desc = "Open Yank History" },
        },
    },
    -- ファジーファインダー (Telescope)
    {
        'nvim-telescope/telescope.nvim',
        cmd = 'Telescope',
        dependencies = { 'nvim-lua/plenary.nvim' },
        keys = {
            { '<leader>p', '<CMD>Telescope find_files<CR>', desc = 'Telescope find files'},
            { '<leader>ff', '<CMD>Telescope find_files<CR>', desc = 'Telescope find files'},
            { '<leader>f', '<CMD>Telescope live_grep<CR>', desc = 'Telescope live grep'},
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

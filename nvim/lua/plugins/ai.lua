return {
    -- GitHub Copilot
    {
        "zbirenbaum/copilot.lua",
        event = 'InsertEnter',
        dependencies = { "copilotlsp-nvim/copilot-lsp" }, -- Next Edit Suggestions 用
        config = function()
            require("copilot").setup({
                -- Ctrl+Enter は端末では Enter と同一バイト列になり判別できないため，
                -- 確実に判別できる Option+Enter (<M-CR>) を NES の確定キーとして使う (後述)．
                -- 既定の panel.keymap.open も <M-CR> であり，将来 nes.keymap などに <M-CR> を割り当てた際に
                -- copilot.lua のモード判定バグで "Duplicate keymap" と誤検知されないよう，予防として無効化しておく．
                panel = { enabled = false, keymap = { open = false } },
                -- インライン提案 (ゴーストテキスト) は copilot-cmp 経由で nvim-cmp の
                -- 補完メニューに統合するため無効化する (両方有効だと AI 提案が二重表示される)
                suggestion = { enabled = false },
                -- Next Edit Suggestions (VSCode: github.copilot.nextEditSuggestions.enabled)
                -- nes.keymap 経由でキーマップを登録すると，copilot.lua 側のモード判定バグにより
                -- 他の設定 (panel/suggestion) のキーマップと "Duplicate keymap" に誤検知される
                -- おそれがあるため，ここでは登録せず，下記で Normal モード用に自前でキーマップする
                nes = {
                    enabled = true,
                    -- タイピングのたびに自動発火させず，<M-n> による手動リクエストのみに絞る
                    auto_trigger = false,
                },
            })

            -- Option+Enter で Next Edit Suggestion を確定 (VSCode: github.copilot.nextEditSuggestions.accept)
            -- suggestion.enabled = false のため Insert モードの <M-CR> は copilot.lua 側に
            -- 登録されず，この Normal モード限定のキーマップとは衝突しない
            vim.keymap.set('n', '<M-CR>', function()
                local nes_api = require('copilot.nes.api')
                if nes_api.nes_apply_pending_nes() then
                    nes_api.nes_walk_cursor_end_edit()
                end
            end, { silent = true, desc = 'Copilot: Accept Next Edit Suggestion' })

            -- Option+n で Next Edit Suggestion を手動リクエストする (auto_trigger を無効化したため)
            -- copilot.lua の nes_api には手動リクエスト用の関数が公開されていないため，
            -- copilot-lsp の内部関数を直接呼び出す (内部API依存のリスクは実装計画の「リスク・確認事項」参照)
            vim.keymap.set('i', '<M-n>', function()
                require('copilot-lsp.nes').request_nes('copilot_ls')
            end, { silent = true, desc = 'Copilot: Request Next Edit Suggestion (manual)' })
        end,
    },
    -- Copilot を nvim-cmp の補完ソースとして統合する (インライン提案の代替)
    {
        "zbirenbaum/copilot-cmp",
        dependencies = { "zbirenbaum/copilot.lua" },
        event = 'InsertEnter',
        config = function()
            require("copilot_cmp").setup()
        end,
    },
    -- スニペットエンジン
    {
        'hrsh7th/vim-vsnip',
        event = 'InsertEnter',
        dependencies = { 'hrsh7th/vim-vsnip-integ', 'rafamadriz/friendly-snippets' },
        config = function()
            vim.g.vsnip_snippet_dir = vim.fn.stdpath('data') .. '/snip'

            -- Option+l でスニペットの展開 or 前方ジャンプ (VSCode: editor.action.insertSnippet 相当)
            -- <Plug> マッピングの展開には remap = true が必須
            vim.keymap.set({ 'i', 's' }, '<M-l>', function()
                if vim.fn['vsnip#available'](1) == 1 then
                    return '<Plug>(vsnip-expand-or-jump)'
                end
                return '<M-l>'
            end, { expr = true, remap = true })

            -- Option+h でスニペットの後方ジャンプ
            vim.keymap.set({ 'i', 's' }, '<M-h>', function()
                if vim.fn['vsnip#jumpable'](-1) == 1 then
                    return '<Plug>(vsnip-jump-prev)'
                end
                return '<M-h>'
            end, { expr = true, remap = true })
        end
    },
    -- 補完エンジン本体とソース群
    {
        'hrsh7th/nvim-cmp',
        event = {'InsertEnter', 'CmdlineEnter'},
        dependencies = {
            'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-path', 'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-cmdline', 'hrsh7th/cmp-vsnip', 'hrsh7th/cmp-calc',
            'hrsh7th/vim-vsnip', "onsails/lspkind.nvim", 'zbirenbaum/copilot-cmp',
        },
        config = function()
            vim.opt.completeopt = 'menu,menuone,noselect'
            local cmp = require('cmp')

            cmp.setup({
                snippet = { expand = function(args) vim.fn['vsnip#anonymous'](args.body) end },
                window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
                mapping = cmp.mapping.preset.insert({
                    -- <Tab>/<S-Tab> はインデント調整専用とし，補完候補の選択や
                    -- 補完の手動トリガー，vsnip のジャンプとは責務を分離する
                    -- (これらを <Tab> に混在させると，インデント操作と AI/LSP の提案操作が
                    --  同じキーで衝突するため．候補選択は <C-n>/<C-p>，
                    --  vsnip のジャンプは <M-l>/<M-h> に割り当てる)
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        -- Markdown はリスト・チェックボックスのインデント変更を autolist.nvim に委譲する
                        -- (cmp がバッファローカルの <Tab> を InsertEnter 毎に再設定し、
                        --  after/ftplugin/markdown.lua 側のマッピングを上書きしてしまうため)
                        if vim.bo.filetype == 'markdown' then vim.cmd('AutolistTab')
                        else fallback() end
                    end, { 'i', 's' }),
                    ["<S-Tab>"] = cmp.mapping(function(fallback)
                        if vim.bo.filetype == 'markdown' then vim.cmd('AutolistShiftTab')
                        else fallback() end
                    end, { "i", "s" }),
                    ["<C-n>"] = cmp.mapping.select_next_item(),
                    ["<C-p>"] = cmp.mapping.select_prev_item(),
                    ['<C-s>'] = cmp.mapping.complete(),
                    ['<C-c>'] = cmp.mapping.abort(),
                    ["<CR>"] = cmp.mapping({
                        i = function(fallback)
                            if cmp.visible() and cmp.get_active_entry() then
                                cmp.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false })
                            else fallback() end
                        end,
                        s = cmp.mapping.confirm({ select = true }),
                        c = cmp.mapping.confirm({ behavior = cmp.ConfirmBehavior.Replace, select = false }),
                    }),
                }),
                sources = cmp.config.sources({
                    { name = 'nvim_lsp' }, { name = 'vsnip' }, { name = 'path' },
                    { name = 'buffer', keyword_length = 3 },
                    { name = 'copilot' },
                    { name = 'calc' }, { name = "lazydev", group_index = 0 },
                }),
                formatting = {
                    fields = { "kind", "abbr", "menu" },
                    format = function(entry, vim_item)
                        local kind = require("lspkind").cmp_format({ mode = "symbol_text", maxwidth = 50 })(entry, vim_item)
                        local strings = vim.split(kind.kind, "%s", { trimempty = true })
                        kind.kind = " " .. (strings[1] or "") .. " "
                        kind.menu = "    (" .. (strings[2] or "") .. ")"
                        return kind
                    end,
                },
            })
            cmp.setup.cmdline('/', { mapping = cmp.mapping.preset.cmdline(), sources = { { name = 'buffer' } } })
            cmp.setup.cmdline(':', { mapping = cmp.mapping.preset.cmdline(), sources = cmp.config.sources({ { name = 'path' }, { name = 'cmdline' } }) })
        end
    }
}

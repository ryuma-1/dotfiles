return {
    -- GitHub Copilot
    {
        "zbirenbaum/copilot.lua",
        event = 'InsertEnter',
        config = function()
            require("copilot").setup({
                -- パネル表示は使用しないため無効化する
                panel = { enabled = false },
                -- インライン提案 (ゴーストテキスト) は copilot-cmp 経由で nvim-cmp の
                -- 補完メニューに統合するため無効化する (両方有効だと AI 提案が二重表示される)
                suggestion = { enabled = false },
            })
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

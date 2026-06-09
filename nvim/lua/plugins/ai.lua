return {
    -- GitHub Copilot
    {
        "zbirenbaum/copilot.lua",
        event = 'InsertEnter',
        config = function()
            require("copilot").setup({
                suggestion = { enabled = true },
                panel = { enabled = false },
            })
        end,
    },
    -- Copilot を nvim-cmp のソース化
    {
        "zbirenbaum/copilot-cmp",
        event = 'InsertEnter',
        dependencies = {"zbirenbaum/copilot.lua"},
        config = function() require("copilot_cmp").setup() end
    },
    -- AIチャットツール (Avante)
    {
        "CopilotC-Nvim/CopilotChat.nvim",
        dependencies = {
            { "zbirenbaum/copilot.lua" }, -- すでに設定済みのインライン補完と連携
            { "nvim-lua/plenary.nvim" },  -- 必須の補助プラグイン
        },
        build = "make tiktoken", -- 動作を高速化するための設定（Mac/Linux推奨）
        opts = {
            -- チャットウィンドウの設定
            window = {
                layout = 'vertical', -- 'vertical' (サイドバー) や 'float' (浮き出し) を選べます
                width = 0.3,
                height = 0.8,
            },
            -- デフォルトのシステムプロンプト（日本語で返答してもらうための工夫）
            prompts = {
                Explain = {
                    prompt = "/COPILOT_EXPLAIN 選択したコードを日本語で分かりやすく説明してください。",
                },
                Review = {
                    prompt = "/COPILOT_REVIEW 選択したコードをレビューし、日本語で改善点を提案してください。",
                },
                Fix = {
                    prompt = "/COPILOT_FIX このコードのバグを修正し、原因を日本語で説明してください。",
                },
            },
        },
        -- 呼び出し用のショートカットキー登録
        keys = {
            {
                "<leader>cc", -- スペース(またはバックスラッシュ) + c + c
                ":CopilotChatToggle<CR>",
                mode = { "n", "v" },
                desc = "CopilotChat - チャット画面の開閉",
            },
            {
                "<leader>ce", -- スペース + c + e
                ":CopilotChatExplain<CR>",
                mode = { "n", "v" },
                desc = "CopilotChat - コードの解説",
            },
        },
    },
    -- スニペットエンジン
    {
        'hrsh7th/vim-vsnip',
        event = 'InsertEnter',
        dependencies = { 'hrsh7th/vim-vsnip-integ', 'rafamadriz/friendly-snippets' },
        config = function()
            vim.g.vsnip_snippet_dir = vim.fn.stdpath('data') .. '/snip'
        end
    },
    -- 補完エンジン本体とソース群
    {
        'hrsh7th/nvim-cmp',
        event = {'InsertEnter', 'CmdlineEnter'},
        dependencies = {
            'hrsh7th/cmp-nvim-lsp', 'hrsh7th/cmp-path', 'hrsh7th/cmp-buffer',
            'hrsh7th/cmp-cmdline', 'hrsh7th/cmp-vsnip', 'hrsh7th/cmp-calc',
            'hrsh7th/vim-vsnip', 'zbirenbaum/copilot-cmp', "onsails/lspkind.nvim",
        },
        config = function()
            vim.opt.completeopt = 'menu,menuone,noselect'
            local cmp = require('cmp')
            local feedkey = function(key, mode)
                vim.api.nvim_feedkeys(vim.api.nvim_replace_termcodes(key, true, true, true), mode, true)
            end
            local has_words_before = function()
                unpack = unpack or table.unpack
                local line, col = unpack(vim.api.nvim_win_get_cursor(0))
                return col ~= 0 and vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1]:sub(col, col):match("%s") == nil
            end

            cmp.setup({
                snippet = { expand = function(args) vim.fn['vsnip#anonymous'](args.body) end },
                window = { completion = cmp.config.window.bordered(), documentation = cmp.config.window.bordered() },
                mapping = cmp.mapping.preset.insert({
                    ["<Tab>"] = cmp.mapping(function(fallback)
                        if cmp.visible() then cmp.select_next_item()
                        elseif vim.fn["vsnip#available"](1) == 1 then feedkey("<Plug>(vsnip-expand-or-jump)", "")
                        elseif has_words_before() then cmp.complete()
                        else fallback() end
                    end, { 'i', 's' }),
                    ["<S-Tab>"] = cmp.mapping(function()
                        if cmp.visible() then cmp.select_prev_item()
                        elseif vim.fn["vsnip#jumpable"](-1) == 1 then feedkey("<Plug>(vsnip-jump-prev)", "") end
                    end, { "i", "s" }),
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
                    { name = 'buffer', keyword_length = 3 }, { name = 'copilot' },
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

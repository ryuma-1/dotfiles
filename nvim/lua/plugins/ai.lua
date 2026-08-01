return {
    -- GitHub Copilot
    {
        "zbirenbaum/copilot.lua",
        event = 'InsertEnter',
        dependencies = { "copilotlsp-nvim/copilot-lsp" }, -- Next Edit Suggestions 用
        config = function()
            require("copilot").setup({
                -- Ctrl+Enter は端末では Enter と同一バイト列になり判別できないため、
                -- 確実に判別できる Option+Enter (<M-CR>) を確定キーとして使う。
                -- 既定の panel.keymap.open も <M-CR> のため、後述の重複検知を避けるために無効化する
                panel = { enabled = false, keymap = { open = false } },
                suggestion = {
                    enabled = true,
                    -- タイピング中に自動で候補を表示する (VSCode の Copilot と同じ挙動。既定値は false で無効)
                    auto_trigger = true,
                    -- Option+Enter で提案を確定 (VSCode: editor.action.inlineSuggest.commit)
                    keymap = {
                        accept = '<M-CR>',
                        -- Alt+l で単語単位の確定 (VSCode: editor.action.inlineSuggest.acceptNextWord)
                        accept_word = '<M-l>',
                    },
                },
                -- Next Edit Suggestions (VSCode: github.copilot.nextEditSuggestions.enabled)
                -- nes.keymap 経由で <M-CR> を登録すると、copilot.lua 側のモード判定バグにより
                -- suggestion.keymap.accept (Insert) と "Duplicate keymap" に誤検知されるため、
                -- ここでは登録せず、下記で Normal モード用に自前でキーマップする
                nes = {
                    enabled = true,
                    auto_trigger = true,
                },
            })

            -- Option+Enter で Next Edit Suggestion を確定 (VSCode: github.copilot.nextEditSuggestions.accept)
            -- suggestion.keymap.accept (Insert) と物理キーは同じだが実行モードが異なるため衝突しない
            vim.keymap.set('n', '<M-CR>', function()
                local nes_api = require('copilot.nes.api')
                if nes_api.nes_apply_pending_nes() then
                    nes_api.nes_walk_cursor_end_edit()
                end
            end, { silent = true, desc = 'Copilot: Accept Next Edit Suggestion' })
        end,
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
            'hrsh7th/vim-vsnip', "onsails/lspkind.nvim",
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
                    { name = 'buffer', keyword_length = 3 },
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

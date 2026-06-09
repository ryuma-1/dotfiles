-- ====================================================================
-- LSP共通キーマップ定義
-- ====================================================================
local lsp_keybindings = function(client, bufnr)
    local opts_lsp = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>Lspsaga goto_definition<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>Lspsaga finder<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'grn', '<cmd>Lspsaga rename<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gca', '<cmd>Lspsaga code_action<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gs', '<cmd>Lspsaga hover_doc<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'g]', '<cmd>Lspsaga diagnostic_jump_next<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'g[', '<cmd>Lspsaga diagnostic_jump_prev<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gf', '', {
        noremap = true, silent = true, desc = "Format buffer",
        callback = function() vim.lsp.buf.format({ bufnr = bufnr }) end
    })
end

return {
    -- 構文ハイライト (Treesitter)
    {
        'nvim-treesitter/nvim-treesitter',
        lazy = false,
        build = ':TSUpdate',
        config = function()
            vim.api.nvim_create_autocmd("FileType", {
                group = vim.api.nvim_create_augroup("vim-treesitter-start", {}),
                callback = function() pcall(vim.treesitter.start) end,
            })
        end
    },
    -- LSP UI改善
    {
        'nvimdev/lspsaga.nvim',
        dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-tree/nvim-web-devicons' },
        event = 'LspAttach',
        opts = { ui = { code_action = '' }, lightbulb = { virtual_text = false } },
    },
    -- LSP インストーラ (Mason)
    { 
        'mason-org/mason.nvim', 
        lazy = false, 
        opts = { 
            ui = { border = 'single' },
            -- 💡 以下の registries の設定を追加すると roslyn が Mason で見つかるようになります
            registries = {
                "github:mason-org/mason-registry",
                "github:Crashdummyy/mason-registry",
            }
        } 
    },
    {
        'mason-org/mason-lspconfig.nvim',
        dependencies = { 'mason-org/mason.nvim', 'neovim/nvim-lspconfig' },
        lazy = false,
        opts = { automatic_enable = { exclude = { "rust_analyzer" } } },
    },
    -- LSP 本体設定
    {
        'neovim/nvim-lspconfig',
        lazy = false, -- 起動時から :LspInfo などを有効にする
        config = function()
            vim.lsp.config('*', { capabilities = require('cmp_nvim_lsp').default_capabilities() })
            vim.lsp.inlay_hint.enable()

            vim.api.nvim_create_user_command('InlayHintToggle', function()
                vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled())
                print(string.format("Inlay Hint: %s", vim.lsp.inlay_hint.is_enabled()))
            end, {})

            vim.api.nvim_create_autocmd('LspAttach', {
                group = vim.api.nvim_create_augroup('LspAttachSettings', {}),
                callback = function(args)
                    local client = assert(vim.lsp.get_client_by_id(args.data.client_id))
                    local bufnr = args.buf
                    lsp_keybindings(client, bufnr)

                    vim.diagnostic.config({ virtual_text = false })


                    vim.g.show_diagnostics = true
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>l', '', {
                        noremap = true, silent = true, desc = 'Change Diagnostic View',
                        callback = function()
                            vim.g.show_diagnostics = not vim.g.show_diagnostics
                            print(string.format("Show Diagnostic: %s", vim.g.show_diagnostics))
                        end
                    })

                    if not client:supports_method('textDocument/willSaveWaitUntil') and client:supports_method('textDocument/formatting') then
                        vim.api.nvim_create_autocmd('BufWritePre', {
                            group = vim.api.nvim_create_augroup('LspAutoFormat', { clear = false }),
                            buffer = bufnr,
                            callback = function()
                                if vim.g.autoformat then
                                    vim.lsp.buf.format({ bufnr = bufnr, id = client.id, timeout_ms = 1000 })
                                end
                            end,
                        })
                    end

                    vim.g.autoformat = true
                    vim.api.nvim_create_user_command('AutoFormatToggle', function()
                        vim.g.autoformat = not vim.g.autoformat
                        print(string.format("Auto Format: %s", vim.g.autoformat))
                    end, {})
                end,
            })
        end
    },
    -- 💡 Roslyn 関連プラグインの統合
    {
        "khoido2003/roslyn-filewatch.nvim",
        lazy = true,
    },
    {
        "seblyng/roslyn.nvim",
        ft = { "cs" },
        config = function()
            -- 1. ファイル同期プラグイン（filewatch）のセットアップ
            local ok, filewatch = pcall(require, "roslyn-filewatch")
            if ok then
                filewatch.setup({
                    preset = "unity",
                })
            end

            -- 2. roslyn のセットアップ
            require("roslyn").setup({
                choose_target = function(targets)
                    for _, target in ipairs(targets) do
                        -- ".Player.sln" や ".slnx" という名前が含まれていない、
                        -- メインの ".sln" ファイルを見つけたらそれを自動で返す
                        if not target:match("%.Player%.sln$") and not target:match("%.slnx$") then
                            return target
                        end
                    end
                    -- 見つからなかった場合の保険として最初のものを返す
                    return targets[1]
                end,
            })

            -- `gl` (Go to Line-error) でポップアップを表示する設定
            vim.keymap.set('n', 'gl', vim.diagnostic.open_float, { desc = "Show line diagnostics" })
        end,
    },
    -- 進捗表示
    { 'j-hui/fidget.nvim', lazy = false, opts = {} },
    -- 言語・環境固有プラグイン
    { 'mrcjkb/rustaceanvim', ft = {'rust'}, lazy = false },
    {
        'nvim-flutter/flutter-tools.nvim',
        event = {'BufReadPre', 'BufNewFile'},
        ft = {'dart'},
        dependencies = { 'nvim-lua/plenary.nvim', 'stevearc/dressing.nvim' },
        opts = {},
    },
    {
        "folke/lazydev.nvim",
        ft = "lua",
        opts = { library = { { path = "${3rd}/luv/library", words = { "vim%.uv" } } } },
    },
    -- Markdown 拡張
    {
        'MeanderingProgrammer/render-markdown.nvim',
        event = { 'BufReadPre', 'BufNewFile' },
        opts = { file_types = { "markdown", "Avante" } },
        ft = { "markdown", "Avante" },
    },
    {
        'iamcco/markdown-preview.nvim',
        cmd = { 'MarkdownPreview' },
        ft = 'markdown',
        build = "cd app && yarn install",
        init = function() vim.g.mkdp_filetypes = { "markdown" } end,
    },
    -- LaTeX 拡張 (VimTex)
    {
        'lervag/vimtex',
        ft = 'tex',
        event = 'VeryLazy',
        config = function()
            if IsWSL then vim.g.vimtex_view_method = 'wsl-open' else vim.g.vimtex_view_method = 'zathura' end
            vim.g.vimtex_compiler_method = 'generic'
            vim.g.vimtex_compiler_generic = { command = 'make all' }
            vim.g.vimtex_syntax_enabled = 0
        end
    },
    -- その他特定用途
    { 'eandrju/cellular-automaton.nvim', cmd = 'CellularAutomaton' },
    {
        "vinnymeller/swagger-preview.nvim",
        file_types = { "yaml" },
        cmd = { "SwaggerPreview", "SwaggerPreviewStop", "SwaggerPreviewToggle" },
        build = "npm i",
        opts = {},
    }
}

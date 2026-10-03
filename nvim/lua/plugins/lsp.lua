-- ====================================================================
-- LSP共通キーマップ定義
-- ====================================================================
local lsp_keybindings = function(client, bufnr)
    local opts_lsp = { noremap = true, silent = true }
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gd', '<cmd>Lspsaga goto_definition<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gr', '<cmd>Lspsaga finder<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'grn', '<cmd>Lspsaga rename<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gca', '<cmd>Lspsaga code_action<CR>', opts_lsp)
    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'gh', '<cmd>Lspsaga hover_doc<CR>', opts_lsp)
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
        -- Load mason.nvim first so its bin dir is already on PATH when the
        -- tree-sitter CLI is looked up below.
        dependencies = { 'mason-org/mason.nvim' },
        config = function()
            ---Parsers to install automatically.
            ---Kept minimal on purpose; only the languages needed for TS/JS.
            local ensure_parsers = { 'typescript', 'tsx', 'javascript' }

            ---Install the configured parsers with nvim-treesitter.
            ---Already installed parsers are a no-op, so this is safe on every startup.
            local function install_parsers()
                local ok, err = pcall(function()
                    require('nvim-treesitter').install(ensure_parsers)
                end)
                if not ok then
                    vim.notify('nvim-treesitter: parser install failed: ' .. tostring(err), vim.log.levels.ERROR)
                end
            end

            ---Make sure the tree-sitter CLI exists, then install parsers.
            ---The main branch of nvim-treesitter needs the CLI to build parsers, and
            ---Mason installs it asynchronously, so parsers must wait for it to finish.
            local function ensure_cli_and_parsers()
                if vim.fn.executable('tree-sitter') == 1 then
                    install_parsers()
                    return
                end

                local ok, registry = pcall(require, 'mason-registry')
                if not ok then
                    vim.notify('nvim-treesitter: tree-sitter CLI not found and mason-registry is unavailable',
                        vim.log.levels.WARN)
                    return
                end

                -- The registry may not be cached yet on a fresh environment,
                -- so refresh it before looking the package up.
                -- schedule_wrap is required because Mason may invoke the callback
                -- from a luv context on failure, where vim.notify/vim.fn raise E5560.
                registry.refresh(vim.schedule_wrap(function(refresh_ok, refresh_err)
                    if not refresh_ok then
                        -- Keep going: a previously cached registry may still be usable,
                        -- but the user must know the refresh did not succeed.
                        vim.notify('nvim-treesitter: Mason registry refresh failed ('
                            .. tostring(refresh_err) .. '); trying cached registry', vim.log.levels.WARN)
                    end

                    local found, pkg = pcall(registry.get_package, 'tree-sitter-cli')
                    if not found then
                        vim.notify('nvim-treesitter: tree-sitter-cli not found in Mason registry: '
                            .. tostring(pkg), vim.log.levels.WARN)
                        return
                    end
                    if pkg:is_installed() then
                        -- Installed by Mason but not on PATH, so parsers cannot be built.
                        vim.notify('nvim-treesitter: tree-sitter-cli is installed but not executable from PATH',
                            vim.log.levels.WARN)
                        return
                    end

                    if pkg:is_installing() then
                        -- Package:install asserts on concurrent installs, so do not call it;
                        -- parsers will be installed on the next startup.
                        vim.notify('nvim-treesitter: tree-sitter-cli is already being installed by Mason; '
                            .. 'restart Neovim after it finishes to install parsers', vim.log.levels.WARN)
                        return
                    end

                    vim.notify('nvim-treesitter: installing tree-sitter-cli via Mason...')
                    pkg:install(nil, vim.schedule_wrap(function(success, err)
                        if not success then
                            vim.notify('nvim-treesitter: failed to install tree-sitter-cli via Mason ('
                                .. tostring(err) .. '); parsers were not installed', vim.log.levels.WARN)
                        elseif vim.fn.executable('tree-sitter') ~= 1 then
                            vim.notify('nvim-treesitter: tree-sitter-cli installed but not found on PATH',
                                vim.log.levels.WARN)
                        else
                            install_parsers()
                        end
                    end))
                end))
            end

            ensure_cli_and_parsers()

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
        opts = {
            ui = { code_action = '' },
            lightbulb = { virtual_text = false },
            -- Breadcrumbs are shown by nvim-navic in the lualine winbar instead
            symbol_in_winbar = { enable = false },
        },
        ---Sets up lspsaga and closes the code action preview together with its action list.
        ---lspsaga closes the preview only from its own keys (`q`, `<CR>`, number shortcuts),
        ---so leaving the list any other way (`:q`, `<leader>q`, window moves) orphans the
        ---preview, which is unfocusable and therefore cannot be closed by hand.
        ---@param opts table
        config = function(_, opts)
            require('lspsaga').setup(opts)

            vim.api.nvim_create_autocmd('WinLeave', {
                group = vim.api.nvim_create_augroup('lspsaga-codeaction-preview', {}),
                callback = function()
                    -- Avoid loading the module just to check; no list can exist before it is loaded
                    local codeaction = package.loaded['lspsaga.codeaction']
                    if not codeaction or vim.api.nvim_get_current_win() ~= codeaction.action_winid then
                        return
                    end
                    -- Windows cannot be closed while WinLeave is still being processed
                    vim.schedule(function() codeaction:close_action_window() end)
                end,
            })

            -- Patch the metatable rather than the module table: the module table is lspsaga's
            -- ctx, whose keys are all wiped by clean_ctx() after every applied action.
            local action_list = getmetatable(require('lspsaga.codeaction'))
            local action_callback = action_list.action_callback
            ---Opens the action list, then restores linewise j/k inside it.
            ---The global j/k -> gj/gk mapping lands on the second screen row of a wrapped item,
            ---and lspsaga's CursorMoved handler snaps the cursor back to column 1 of the same
            ---item, so the cursor could never leave a wrapped item.
            ---@param self table
            action_list.action_callback = function(self, ...)
                action_callback(self, ...)
                if self.action_bufnr and vim.api.nvim_buf_is_valid(self.action_bufnr) then
                    for _, key in ipairs({ 'j', 'k' }) do
                        vim.keymap.set('n', key, key, { buffer = self.action_bufnr, nowait = true })
                    end
                end
            end
        end,
    },
    -- 診断一覧 (Trouble)
    -- Mapped via lazy `keys` instead of LspAttach so the list also opens for
    -- diagnostics from non-LSP sources and before any server has attached.
    {
        'folke/trouble.nvim',
        dependencies = { 'nvim-tree/nvim-web-devicons' },
        cmd = 'Trouble',
        keys = {
            { 'gl', '<cmd>Trouble diagnostics toggle<CR>', desc = 'Diagnostics list (Trouble)' },
        },
        opts = {
            -- Move the cursor into the list on open so it can be navigated right away
            focus = true,
        },
        ---Sets up Trouble and lets tint dim the list like other unfocused windows.
        ---@param opts table
        config = function(_, opts)
            require('trouble').setup(opts)

            ---Copies the Trouble* highlight groups into tint's namespaces.
            ---tint snapshots highlights only at startup, and Trouble defines its groups
            ---later (on load, and per source on first open), so tint must be refreshed.
            ---Trouble also defines them as `default = true` links, which tint copies as is,
            ---and a default link is ignored in a namespace once the group exists globally,
            ---so the flag is dropped first; the links themselves are kept unchanged.
            local function tint_trouble_highlights()
                for name, def in pairs(vim.api.nvim_get_hl(0, {})) do
                    if def.default and name:find('^Trouble') then
                        def.default = nil
                        vim.api.nvim_set_hl(0, name, def)
                    end
                end
                require('tint').refresh()
            end

            tint_trouble_highlights()
            vim.api.nvim_create_autocmd('FileType', {
                group = vim.api.nvim_create_augroup('TroubleTint', {}),
                pattern = 'trouble',
                callback = tint_trouble_highlights,
            })
        end,
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
        opts = {
            -- Install ts_ls automatically so a fresh environment gets TS/JS support
            ensure_installed = { "ts_ls" },
            automatic_enable = { exclude = { "rust_analyzer" } },
        },
    },
    -- LSP 本体設定
    {
        'neovim/nvim-lspconfig',
        lazy = false, -- 起動時から :LspInfo などを有効にする
        config = function()
            vim.lsp.config('*', { capabilities = require('cmp_nvim_lsp').default_capabilities() })

            ---Inlay hint settings for ts_ls.
            ---ts_ls returns no inlay hints unless they are explicitly enabled on the
            ---server side, so the global vim.lsp.inlay_hint.enable() alone is not enough.
            ---"literals" is used for parameter names to avoid excessive noise.
            local ts_inlay_hints = {
                includeInlayParameterNameHints = 'literals',
                includeInlayParameterNameHintsWhenArgumentMatchesName = false,
                includeInlayFunctionParameterTypeHints = true,
                includeInlayVariableTypeHints = true,
                includeInlayVariableTypeHintsWhenTypeMatchesName = false,
                includeInlayPropertyDeclarationTypeHints = true,
                includeInlayFunctionLikeReturnTypeHints = true,
                includeInlayEnumMemberValueHints = true,
            }
            vim.lsp.config('ts_ls', {
                settings = {
                    typescript = { inlayHints = ts_inlay_hints },
                    javascript = { inlayHints = ts_inlay_hints },
                },
            })

            ---Show inlay hints only while <C-A-i> is held.
            ---Terminals never report modifier-only presses, so holding Ctrl+Alt alone
            ---is undetectable. Instead we rely on key auto-repeat: each repeat restarts
            ---a timer, and once repeats stop (key released) the timer hides the hints.
            ---Two timeouts are used: the first press must outlast the OS initial repeat
            ---delay (500ms) to avoid flicker, but once repeats flow (every 30ms) a short
            ---timeout suffices, which makes the hints disappear quickly on release.
            local hold_first_ms = 600
            local hold_repeat_ms = 100
            local hold_timer = assert(vim.uv.new_timer())
            -- Remember whether hints were already on (e.g. via <leader>uh) so releasing
            -- the key does not turn off a persistent toggle.
            local enabled_before_hold = nil
            vim.keymap.set({ 'n', 'i', 'x' }, '<C-A-i>', function()
                -- nil means this is the first press of a hold, not an auto-repeat
                local is_first_press = enabled_before_hold == nil
                if is_first_press then
                    enabled_before_hold = vim.lsp.inlay_hint.is_enabled()
                    vim.lsp.inlay_hint.enable(true)
                end
                hold_timer:stop()
                local timeout = is_first_press and hold_first_ms or hold_repeat_ms
                hold_timer:start(timeout, 0, vim.schedule_wrap(function()
                    if not enabled_before_hold then
                        vim.lsp.inlay_hint.enable(false)
                    end
                    enabled_before_hold = nil
                end))
            end, { silent = true, desc = 'Show inlay hints while held' })

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


                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>la', '<cmd>Lspsaga show_workspace_diagnostics<CR>', {
                        noremap = true, silent = true, desc = 'LSP Workspace Diagnostics',
                    })
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', 'ge', '<cmd>Lspsaga show_cursor_diagnostics<CR>', {
                        noremap = true, silent = true, desc = 'LSP Cursor Diagnostics',
                    })

                    -- virtual_text is off, so pop up the diagnostic under the cursor instead.
                    -- Cleared per buffer because LspAttach fires once for each attached client.
                    local hover_group = vim.api.nvim_create_augroup('DiagnosticHoverFloat', { clear = false })
                    vim.api.nvim_clear_autocmds({ group = hover_group, buffer = bufnr })
                    vim.api.nvim_create_autocmd('CursorHold', {
                        group = hover_group,
                        buffer = bufnr,
                        callback = function()
                            if vim.g.show_diagnostics then
                                vim.diagnostic.open_float({ scope = 'cursor', focus = false })
                            end
                        end,
                    })

                    vim.g.show_diagnostics = true
                    vim.api.nvim_buf_set_keymap(bufnr, 'n', '<leader>ul', '', {
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
        opts = {
            file_types = { "markdown", "Avante" },
            overrides = {
                buftype = {
                    -- Lspsaga hover (gh) is a nofile markdown buffer whose content is mostly a code block,
                    -- so the gray RenderMarkdownCode bg covered the black HoverNormal float almost entirely
                    nofile = { code = { disable_background = true } },
                },
            },
        },
        ft = { "markdown", "Avante" },
    },
    {
        'iamcco/markdown-preview.nvim',
        cmd = { 'MarkdownPreview', 'MarkdownPreviewStop', 'MarkdownPreviewToggle' },
        ft = 'markdown',
        -- yarn is not installed globally, so run it through npx to avoid a build failure
        build = "cd app && npx --yes yarn install",
        init = function() vim.g.mkdp_filetypes = { "markdown" } end,
    },
    {
        'gaoDean/autolist.nvim',
        ft = 'markdown',
        config = function() require('autolist').setup() end,
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

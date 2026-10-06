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
            ---Kept minimal on purpose; only the languages needed for TS/JS and Go.
            local ensure_parsers = { 'typescript', 'tsx', 'javascript', 'go' }

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
}

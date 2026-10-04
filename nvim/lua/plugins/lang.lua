return {
    -- 言語・環境固有プラグイン
    { 'mrcjkb/rustaceanvim', lazy = false },
    {
        'nvim-flutter/flutter-tools.nvim',
        ft = {'dart'},
        dependencies = { 'nvim-lua/plenary.nvim', 'stevearc/dressing.nvim' },
        opts = {},
    },
    -- Markdown 拡張
    {
        'MeanderingProgrammer/render-markdown.nvim',
        ft = { "markdown", "Avante" },
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
        -- vimtex は自前で遅延読み込みを行うため，lazy.nvim 側では遅延させない
        lazy = false,
        -- vim.g は読み込み前に設定する必要があるため，config ではなく init を使う
        init = function()
            vim.g.vimtex_view_method = vim.fn.has('wsl') == 1 and 'wsl-open' or 'zathura'
            vim.g.vimtex_compiler_method = 'generic'
            vim.g.vimtex_compiler_generic = { command = 'make all' }
            vim.g.vimtex_syntax_enabled = 0
        end
    },
    -- その他特定用途
    {
        "vinnymeller/swagger-preview.nvim",
        cmd = { "SwaggerPreview", "SwaggerPreviewStop", "SwaggerPreviewToggle" },
        build = "npm i",
        opts = {},
    }
}

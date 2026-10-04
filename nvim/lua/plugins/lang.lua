return {
    -- 言語・環境固有プラグイン
    { 'mrcjkb/rustaceanvim', ft = {'rust'}, lazy = false },
    {
        'nvim-flutter/flutter-tools.nvim',
        event = {'BufReadPre', 'BufNewFile'},
        ft = {'dart'},
        dependencies = { 'nvim-lua/plenary.nvim', 'stevearc/dressing.nvim' },
        opts = {},
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
    {
        "vinnymeller/swagger-preview.nvim",
        file_types = { "yaml" },
        cmd = { "SwaggerPreview", "SwaggerPreviewStop", "SwaggerPreviewToggle" },
        build = "npm i",
        opts = {},
    }
}

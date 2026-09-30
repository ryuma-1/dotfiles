-- VSCode風の細い縦線で差分を表示するための gitsigns の記号
local diff_signs = {
    add          = { text = '▎' },
    change       = { text = '▎' },
    delete       = { text = '▁' },
    topdelete    = { text = '▔' },
    changedelete = { text = '▎' },
    untracked    = { text = '▎' },
}

return {
    -- Gitの差分行表示
    {
        'lewis6991/gitsigns.nvim',
        event = 'VeryLazy',
        opts = {
            signcolumn = true,
            numhl = false,
            signs = diff_signs,
            -- staged の行も未 staged の行と同じ形の線で表示するため
            signs_staged = diff_signs,
        }
    },
    -- Git Diffを並べて表示
    { 'sindrets/diffview.nvim', event = 'VeryLazy' },
    -- Lazygit 連携
    {
        "kdheepak/lazygit.nvim",
        dependencies = { "nvim-lua/plenary.nvim" },
        keys = { { "<leader>g", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
    }
}

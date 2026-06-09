return {
    -- Gitの差分行表示
    {
        'lewis6991/gitsigns.nvim',
        event = 'VeryLazy',
        opts = { signcolumn = false, numhl = true }
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

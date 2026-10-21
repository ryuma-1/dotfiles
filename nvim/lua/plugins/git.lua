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
        keys = {
            { '<leader>gh', '<cmd>Gitsigns preview_hunk<cr>', desc = 'Preview hunk' },
            { '<leader>gi', '<cmd>Gitsigns preview_hunk_inline<cr>', desc = 'Preview hunk inline' },
            { '<leader>gb', '<cmd>Gitsigns blame_line<cr>', desc = 'Blame line' },
            { '<leader>ga', '<cmd>Gitsigns blame<cr>', desc = 'Blame buffer' },
            { '<leader>gn', '<cmd>Gitsigns nav_hunk next<cr>', desc = 'Next hunk' },
            { '<leader>gp', '<cmd>Gitsigns nav_hunk prev<cr>', desc = 'Prev hunk' },
            -- ':' で呼ぶことでビジュアルモードの選択範囲が渡される
            { '<leader>gs', ':Gitsigns stage_hunk<cr>', mode = { 'n', 'x' }, silent = true, desc = 'Stage hunk' },
            { '<leader>gr', ':Gitsigns reset_hunk<cr>', mode = { 'n', 'x' }, silent = true, desc = 'Reset hunk' },
        },
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
        keys = { { "<leader>gg", "<cmd>LazyGit<cr>", desc = "LazyGit" } },
    }
}

return {
    -- GitHub Copilot
    {
        "zbirenbaum/copilot.lua",
        event = 'InsertEnter',
        config = function()
            require("copilot").setup({
                -- パネル表示は使用しないため無効化する
                panel = { enabled = false },
                -- インライン提案 (ゴーストテキスト) は copilot-cmp 経由で nvim-cmp の
                -- 補完メニューに統合するため無効化する (両方有効だと AI 提案が二重表示される)
                suggestion = { enabled = false },
            })
        end,
    },
    -- Copilot を nvim-cmp の補完ソースとして統合する (インライン提案の代替)
    {
        "zbirenbaum/copilot-cmp",
        dependencies = { "zbirenbaum/copilot.lua" },
        event = 'InsertEnter',
        config = function()
            require("copilot_cmp").setup()
        end,
    },
    -- AI チャット / インライン編集 (Cursor 風)
    -- 既に認証済みの Copilot を流用し，別途 API キーを管理せずに済むようにする
    {
        "avante-corp/avante.nvim",
        -- Rust 製のバイナリが必要なため，ビルド済みのものを make で取得する
        build = "make",
        event = "VeryLazy",
        -- 公式がタグ版の利用を非推奨としているため常に最新を追う
        version = false,
        dependencies = {
            "nvim-lua/plenary.nvim",
            "MunifTanjim/nui.nvim",
            { "ColinKennedy/mega.cmdparse", dependencies = { "ColinKennedy/mega.logging" } },
            "nvim-telescope/telescope.nvim",
            "hrsh7th/nvim-cmp",
            "folke/snacks.nvim",
            "nvim-tree/nvim-web-devicons",
            "zbirenbaum/copilot.lua",
            "MeanderingProgrammer/render-markdown.nvim",
        },
        keys = {
            { "<leader>cc", "<cmd>AvanteChat<cr>", mode = "n", desc = "Avante: open chat" },
            -- フローティング入力で質問し，返答はバッファではなくサイドバーに表示する
            -- (edit() は LLM の出力でバッファを直接書き換えるため，質問用途には使わない)
            { "<leader>ci", function() require("avante.api").ask({ floating = true }) end, mode = { "n", "v" }, desc = "Avante: inline chat" },
            -- 選択範囲がある場合はその範囲を，無い場合は現在行を AI に書き換えさせる
            { "<leader>ce", function() require("avante.api").edit() end, mode = { "n", "v" }, desc = "Avante: inline edit" },
        },
        opts = {
            provider = "copilot",
            selector = { provider = "telescope" },
            input = { provider = "snacks" },
        },
    },
}

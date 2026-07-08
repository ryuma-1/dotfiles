--[[
  init.lua
  ------------------------------------------------------------------
  VSCodeの settings.json / keybindings.json (vim拡張 + Copilot設定)
  と同等の挙動をNeovim単体で再現するための設定ファイル。

  想定プラグインマネージャ: lazy.nvim
  (~/.local/share/nvim/lazy/lazy.nvim に自動インストールされます)

  対応関係の概要:
    - vim.* 系設定       → VSCode "vim.xxx" 設定
    - easymotion         → hop.nvim (leader-leader-f / t / T)
    - ステータスバー色    → lualine.nvim + カラー指定
    - ファイルツリー      → nvim-tree.nvim (<leader>b, <leader>e, <leader>o)
    - あいまい検索        → telescope.nvim (<leader>p, <leader>f)
    - Git                → gitsigns.nvim (<leader>g)
    - LSP                → nvim-lspconfig (gr, gn, ga, <leader>ll, <leader>la)
    - 補完               → nvim-cmp (Ctrl+Enterで確定)
    - ターミナル/パネル    → toggleterm.nvim (<leader>t, <leader>j)
    - バッファ操作        → bufferline.nvim (Ctrl+H/L, Ctrl+J/K, Ctrl+W)
    - AIチャット (Copilot相当) はNeovim標準には無いため、
      avante.nvim または CodeCompanion.nvim 導入を想定したプレースホルダのみ用意。
------------------------------------------------------------------]]

----------------------------------------------------------------------
-- 0. 基本設定 (リーダーキーは最初に設定する)
----------------------------------------------------------------------
vim.g.mapleader = " "      -- "vim.leader": "<space>"
vim.g.maplocalleader = " "

----------------------------------------------------------------------
-- 1. lazy.nvim ブートストラップ
----------------------------------------------------------------------
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

----------------------------------------------------------------------
-- 2. エディタ基本オプション (settings.json 対応)
----------------------------------------------------------------------
local opt = vim.opt

opt.relativenumber = true        -- "editor.lineNumbers": "relative"
opt.number = true                -- 相対表示でも現在行の絶対行番号は表示
opt.wrap = true                  -- "editor.wordWrap": "on"
opt.hlsearch = true               -- "vim.hlsearch": true
opt.incsearch = true
opt.clipboard = "unnamedplus"    -- "vim.useSystemClipboard": true
opt.ignorecase = true
opt.smartcase = true
opt.scrolloff = 8
opt.termguicolors = true
opt.signcolumn = "yes"
opt.splitright = true
opt.splitbelow = true

-- スムーススクロール相当 (Neovim標準にスムーススクロールは無いため近似)
opt.mousescroll = "ver:3,hor:6"

-- 保存時の挙動 ("files.trimTrailingWhitespace" / "insertFinalNewline")
opt.fixendofline = true
opt.endofline = true

-- markdown だけ tabSize=2 ("[markdown]": { "editor.tabSize": 2 })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  callback = function()
    vim.bo.tabstop = 2
    vim.bo.shiftwidth = 2
    vim.bo.expandtab = true
  end,
})

-- 保存時: 行末の空白削除 + 最終行に改行を保証
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])                -- trimTrailingWhitespace
    vim.fn.setpos(".", save_cursor)
  end,
})

-- 保存時フォーマット + import整理 (LSPが対応していれば実行)
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function(args)
    -- "editor.formatOnSave": true
    pcall(vim.lsp.buf.format, { bufnr = args.buf, timeout_ms = 2000 })
    -- "source.organizeImports": "always" (対応LSPのみ有効)
    local clients = vim.lsp.get_clients({ bufnr = args.buf })
    for _, client in ipairs(clients) do
      if client.supports_method("textDocument/codeAction") then
        local params = vim.lsp.util.make_range_params()
        params.context = { only = { "source.organizeImports" } }
        local result = client.request_sync("textDocument/codeAction", params, 2000, args.buf)
        if result and result.result then
          for _, action in ipairs(result.result) do
            if action.edit then
              vim.lsp.util.apply_workspace_edit(action.edit, client.offset_encoding)
            end
          end
        end
      end
    end
  end,
})

----------------------------------------------------------------------
-- 3. プラグイン定義
----------------------------------------------------------------------
require("lazy").setup({
  -- カラーテーマ (One Dark Pro 相当)
  {
    "navarasu/onedark.nvim",
    priority = 1000,
    config = function()
      require("onedark").setup({ style = "dark" })
      require("onedark").load()

      -- workbench.colorCustomizations 相当の上書き
      vim.api.nvim_set_hl(0, "Normal", { bg = "#09070e" })
      vim.api.nvim_set_hl(0, "StatusLine", { bg = "#a947c2", fg = "#ffffff" })
      vim.api.nvim_set_hl(0, "IndentBlanklineContextChar", { fg = "#f0f0f0" })
    end,
  },

  -- アイコン
  { "nvim-tree/nvim-web-devicons" },

  -- ステータスバー (モードごとの色制御 = vim.statusBarColorControl)
  {
    "nvim-lualine/lualine.nvim",
    config = function()
      require("lualine").setup({
        options = { theme = "auto", globalstatus = true },
      })
    end,
  },

  -- easymotion 相当 (vim.easymotion, vim.visualstar)
  {
    "smoothie/vim-smoothie", -- スムーススクロールの補助 (任意)
  },
  {
    "phaazon/hop.nvim",
    branch = "v2",
    config = function()
      require("hop").setup()
    end,
  },

  -- ファイルツリー (sidebar toggle / explorer)
  {
    "nvim-tree/nvim-tree.lua",
    config = function()
      require("nvim-tree").setup()
    end,
  },

  -- あいまい検索 (quickOpen / findInFiles)
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
  },

  -- Git (scm view)
  { "lewis6991/gitsigns.nvim", config = function() require("gitsigns").setup() end },

  -- バッファをタブのように扱う (Ctrl+H/L でのバッファ切替に利用)
  {
    "akinsho/bufferline.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      require("bufferline").setup({})
    end,
  },

  -- ターミナル/パネル
  {
    "akinsho/toggleterm.nvim",
    config = function()
      require("toggleterm").setup({ open_mapping = nil })
    end,
  },

  -- LSP + 補完
  { "neovim/nvim-lspconfig" },
  { "williamboman/mason.nvim", config = function() require("mason").setup() end },
  { "williamboman/mason-lspconfig.nvim" },
  {
    "hrsh7th/nvim-cmp",
    dependencies = { "hrsh7th/cmp-nvim-lsp", "L3MonDe3/LuaSnip" },
  },

  -- インデントガイド (editorIndentGuide.activeBackground1 相当)
  {
    "lukas-reineke/indent-blankline.nvim",
    main = "ibl",
    config = function()
      require("ibl").setup({
        scope = { highlight = "IndentBlanklineContextChar" },
      })
    end,
  },

  -- 行移動 (alt+j / alt+k)
  { "fedepujol/move.nvim", config = function() require("move").setup({}) end },

  -- コメントアウト (Copilotの add-comment に近い補助、任意)
  { "numToStr/Comment.nvim", config = function() require("Comment").setup() end },
})

----------------------------------------------------------------------
-- 4. 補完設定 (Ctrl+Enterで確定 = insertSuggest.commit 相当)
----------------------------------------------------------------------
local ok_cmp, cmp = pcall(require, "cmp")
if ok_cmp then
  cmp.setup({
    mapping = cmp.mapping.preset.insert({
      ["<C-CR>"] = cmp.mapping.confirm({ select = true }), -- Ctrl+Enterで確定
      ["<C-Space>"] = cmp.mapping.complete(),
    }),
  })
end

----------------------------------------------------------------------
-- 5. キーマップ: インサートモード
----------------------------------------------------------------------
local map = vim.keymap.set

-- jk → Esc ("vim.insertModeKeyBindings": jk -> <Esc>)
map("i", "jk", "<Esc>", { desc = "インサートモードを抜ける" })

-- Ctrl+h / Ctrl+l → 左右移動 (インサートモード中)
map("i", "<C-h>", "<Left>", { desc = "左へ移動" })
map("i", "<C-l>", "<Right>", { desc = "右へ移動" })

-- ;; → 補完トリガー ("editor.action.triggerSuggest")
map("i", ";;", function()
  if ok_cmp then cmp.complete() end
end, { desc = "補完を表示" })

----------------------------------------------------------------------
-- 6. キーマップ: ノーマルモード
----------------------------------------------------------------------

-- Enter → 下に行を挿入してインサートモード ("insertLineAfter")
map("n", "<CR>", "o", { desc = "下に行を挿入" })
-- Shift+Enter → 上に行を挿入 ("insertLineBefore")
map("n", "<S-CR>", "O", { desc = "上に行を挿入" })

-- j/k → 折り返し行単位の移動 (wordWrap: on との組み合わせ)
map("n", "j", "gj", { desc = "折り返し単位で下へ" })
map("n", "k", "gk", { desc = "折り返し単位で上へ" })

-- t / T → easymotion 1文字ジャンプ ("<leader><leader>f" / "F" 相当)
map("n", "t", "<cmd>HopChar1<CR>", { desc = "1文字ジャンプ(前方/後方)" })
map("n", "T", "<cmd>HopChar1<CR>", { desc = "1文字ジャンプ" })

-- <leader>l l / a → hover / 診断一覧
map("n", "<leader>ll", vim.lsp.buf.hover, { desc = "ホバー情報表示" })
map("n", "<leader>la", vim.diagnostic.setloclist, { desc = "エラー/警告一覧" })

-- <leader>t → ターミナル切替
map("n", "<leader>t", "<cmd>ToggleTerm<CR>", { desc = "ターミナル切替" })

-- <leader>s / v → 画面分割 (下/右)
map("n", "<leader>s", "<cmd>split<CR>", { desc = "水平分割" })
map("n", "<leader>v", "<cmd>vsplit<CR>", { desc = "垂直分割" })

-- <leader>b / o → サイドバー(ファイルツリー)表示切替
map("n", "<leader>b", "<cmd>NvimTreeToggle<CR>", { desc = "サイドバー切替" })
map("n", "<leader>o", "<cmd>NvimTreeFocus<CR>", { desc = "エクスプローラー表示" })
map("n", "<leader>e", "<cmd>NvimTreeFocus<CR>", { desc = "エクスプローラー表示" })

-- <leader>f → ファイル内/全体検索
map("n", "<leader>f", "<cmd>Telescope live_grep<CR>", { desc = "全文検索" })

-- <leader>g → Git (SCM) ビュー相当
map("n", "<leader>g", "<cmd>Gitsigns<CR>", { desc = "Git操作" })

-- <leader>x → 拡張機能ビュー相当 (lazy.nvimのUIで代替)
map("n", "<leader>x", "<cmd>Lazy<CR>", { desc = "プラグイン管理" })

-- <leader>j → パネル(ターミナル)トグル
map("n", "<leader>j", "<cmd>ToggleTerm<CR>", { desc = "パネル切替" })

-- <leader>p → クイックオープン (ファイル検索)
map("n", "<leader>p", "<cmd>Telescope find_files<CR>", { desc = "ファイルを開く" })

-- <leader>c i → インラインチャット (AIプラグイン導入時に割り当て)
-- 例: avante.nvim / codecompanion.nvim を入れた場合はここでコマンドを指定
map("n", "<leader>ci", function()
  vim.notify("AIチャットプラグイン (avante.nvim 等) 未導入です", vim.log.levels.WARN)
end, { desc = "インラインチャット開始 (要AIプラグイン)" })

-- <leader>c c / g / p → チャット関連 (同上、プレースホルダ)
map("n", "<leader>cc", function()
  vim.notify("チャットを開く: AIプラグイン導入後にコマンドを設定してください", vim.log.levels.INFO)
end, { desc = "チャットを開く" })

-- <leader>c q → 補助バー(右サイド)切替。ここではnvim-treeの右側表示等で代替
map("n", "<leader>cq", "<cmd>NvimTreeToggle<CR>", { desc = "補助バー切替" })

-- <leader>w w / a → 全バッファを閉じる
map("n", "<leader>ww", "<cmd>%bdelete<CR>", { desc = "全バッファを閉じる" })
map("n", "<leader>wa", "<cmd>%bdelete<CR>", { desc = "全バッファを閉じる" })

-- <leader>w o → 他のバッファを閉じる
map("n", "<leader>wo", "<cmd>%bdelete|edit#|bdelete#<CR>", { desc = "他のバッファを閉じる" })

-- <leader>w g → グループ内のバッファを閉じる (現ウィンドウのバッファのみ閉じる)
map("n", "<leader>wg", "<cmd>bdelete<CR>", { desc = "現在のバッファを閉じる" })

-- <leader>w p / u → バッファをピン留め/解除 (bufferline)
map("n", "<leader>wp", "<cmd>BufferLineTogglePin<CR>", { desc = "バッファをピン留め" })
map("n", "<leader>wu", "<cmd>BufferLineTogglePin<CR>", { desc = "バッファのピン留め解除" })

-- g r / n / a → LSP: 参照検索 / リネーム / コードアクション
map("n", "gr", vim.lsp.buf.references, { desc = "参照を検索" })
map("n", "gn", vim.lsp.buf.rename, { desc = "リネーム" })
map("n", "ga", vim.lsp.buf.code_action, { desc = "コードアクション" })

----------------------------------------------------------------------
-- 7. キーマップ: ビジュアルモード
----------------------------------------------------------------------
map("v", "t", "<cmd>HopChar1<CR>", { desc = "1文字ジャンプ" })
map("v", "T", "<cmd>HopChar1<CR>", { desc = "1文字ジャンプ" })
map("v", "<leader>ci", function()
  vim.notify("AIチャットプラグイン未導入です", vim.log.levels.WARN)
end, { desc = "選択範囲をインラインチャットへ" })

----------------------------------------------------------------------
-- 8. keybindings.json 相当の設定
----------------------------------------------------------------------

-- Escape: ターミナル/検索/サイドバーからエディタへフォーカスを戻す
map("t", "<Esc>", "<C-\\><C-n>", { desc = "ターミナルモードを抜ける" })

-- Ctrl+W: バッファを閉じる
-- 注意: Vim標準では Ctrl+W はウィンドウ操作の prefix キーです。
-- ここで上書きするとウィンドウ移動 (Ctrl+W hjkl 等) が使えなくなるため、
-- 「バッファを閉じる」を別キーに割り当てることを推奨します。
-- どうしてもVSCodeと同じキーにしたい場合は下記を有効化してください。
-- map("n", "<C-w>", "<cmd>bdelete<CR>", { desc = "バッファを閉じる" })
map("n", "<leader>bd", "<cmd>bdelete<CR>", { desc = "バッファを閉じる (推奨キー)" })

-- Ctrl+H / Ctrl+L: 前/次のバッファへ切替
map("n", "<C-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "前のバッファ" })
map("n", "<C-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "次のバッファ" })

-- Ctrl+J / Ctrl+K: バッファ(タブ)の並び順を左右に移動
map("n", "<C-j>", "<cmd>BufferLineMovePrev<CR>", { desc = "バッファを左へ移動" })
map("n", "<C-k>", "<cmd>BufferLineMoveNext<CR>", { desc = "バッファを右へ移動" })

-- Alt+H/J/K/L: ウィンドウ間のフォーカス移動
map("n", "<A-h>", "<C-w>h", { desc = "左のウィンドウへ" })
map("n", "<A-l>", "<C-w>l", { desc = "右のウィンドウへ" })
map("n", "<A-j>", "<C-w>j", { desc = "下のウィンドウへ" })
map("n", "<A-k>", "<C-w>k", { desc = "上のウィンドウへ" })

-- Ctrl+Alt+H/J/K/L: 現在のウィンドウ(タブ)を隣のグループへ移動
map("n", "<C-A-h>", "<C-w>H", { desc = "ウィンドウを左のグループへ移動" })
map("n", "<C-A-l>", "<C-w>L", { desc = "ウィンドウを右のグループへ移動" })
map("n", "<C-A-k>", "<C-w>K", { desc = "ウィンドウを上のグループへ移動" })
map("n", "<C-A-j>", "<C-w>J", { desc = "ウィンドウを下のグループへ移動" })

-- Alt+J/K (ノーマルモード): 行の移動 (move.nvim使用)
map("n", "<A-j>", "<cmd>MoveLine(1)<CR>", { desc = "行を下へ移動" })
map("n", "<A-k>", "<cmd>MoveLine(-1)<CR>", { desc = "行を上へ移動" })
-- ※ 上のAlt+J/Kはウィンドウ移動と同じキーのため、用途に応じてどちらかを
--   別キー (例: <leader>j / <leader>k) に変更してご利用ください。

----------------------------------------------------------------------
-- 9. その他 (extensions.ignoreRecommendations, activityBar.hidden 等は
--    VSCode固有機能のためNeovimに直接対応するものはありません)
----------------------------------------------------------------------
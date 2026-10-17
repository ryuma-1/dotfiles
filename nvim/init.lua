-- ====================================================================
-- 1. 高速化と初期読み込み
-- ====================================================================
vim.loader.enable()

-- ====================================================================
-- 2. lazy.nvim の自動インストール（ブートストラップ）
-- ====================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- ====================================================================
-- 3. プラグインに依存しない基本設定の読み込み
-- ====================================================================
-- ※ mapleader は基本設定やキーマップより前に定義する必要があります
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- ディレクトリ表示は nvim-tree に任せる．netrw が残ると `nvim <dir>` で重複バッファを作り
-- bufferline に余計なタブが出るため，nvim-tree の推奨どおりプラグイン読み込み前に無効化する
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- ftplugin/<filetype>.lua にあるファイルタイプ別設定を読み込む
vim.cmd("filetype plugin indent on")

require('config.base')
require('config.keymaps')
require('config.unity')

-- ====================================================================
-- 4. lazy.nvim によるプラグイン一括管理
-- ====================================================================
local lazy_opt = {
  ui = { border = 'single' },
  change_detection = { notify = false },
  checker = {
    enabled = true,
    notify = false,
  },
}

require("lazy").setup("plugins", lazy_opt)

-- ====================================================================
-- 5. カラースキームの適用（前回のものを復元）と保存
-- ====================================================================
-- 前回のカラースキームを直接適用し，保存がなければ monokai-pro にする．
-- monokai-pro は一度適用すると，後から読み込まれたプラグイン（bufferline など）に
-- 他のテーマへ切り替えた後でも自分の色を当てるため，前回のテーマの前に適用してはいけない．
-- 'background' も保存するのは，iceberg のように同じ名前でライト版とダーク版を切り替えるテーマがあるため
local colorscheme_file = vim.fn.stdpath("state") .. "/colorscheme"
local saved = vim.uv.fs_stat(colorscheme_file) and vim.fn.readfile(colorscheme_file) or {}
local name, background = saved[1], saved[2]
if background == "dark" or background == "light" then
  vim.o.background = background
end
-- 保存がない，またはアンインストールしたテーマが保存されていた場合は monokai-pro にする
if not (name and pcall(vim.cmd.colorscheme, name)) then
  vim.o.background = "dark"
  vim.cmd.colorscheme("monokai-pro")
end
vim.api.nvim_create_autocmd("ColorScheme", {
  group = vim.api.nvim_create_augroup("SaveColorScheme", { clear = true }),
  callback = function()
    vim.fn.writefile({ vim.g.colors_name, vim.o.background }, colorscheme_file)
  end,
})

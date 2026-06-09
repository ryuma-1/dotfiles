-- ====================================================================
-- 1. 高速化と初期読み込み
-- ====================================================================
vim.loader.enable()

-- ====================================================================
-- 2. lazy.nvim の自動インストール（ブートストラップ）
-- ====================================================================
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
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

require('config.base')
require('config.keymaps')

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

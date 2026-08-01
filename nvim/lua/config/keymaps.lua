vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local function set_keymap(...)
    vim.api.nvim_set_keymap(...)
end
local opts = { noremap = true, silent = true }

-- 基本操作
set_keymap('i', 'jk', '<ESC>', opts)
set_keymap('n', '<ESC><ESC>', '<CMD>nohlsearch<CR>', opts)
set_keymap('n', 'j', 'gj', opts)
set_keymap('n', 'k', 'gk', opts)
set_keymap('n', 'n', 'nzz', opts)
set_keymap('n', 'N', 'Nzz', opts)
set_keymap('n', 'zx', '<CMD>CenterCursorToggle<CR>zz', opts)

-- Enter: 現在行の下に新規行を挿入してインサートモードへ (VSCode: insertLineAfter)
set_keymap('n', '<CR>', 'o', opts)
-- Shift+Enter: 現在行の上に新規行を挿入してインサートモードへ (VSCode: insertLineBefore)
set_keymap('n', '<S-CR>', 'O', opts)

-- Visual mode ペースト
set_keymap('v', 'p', 'P', opts)
set_keymap('v', 'P', 'p', opts)

-- インサート / コマンドモードでのカーソル移動・削除
set_keymap('i', '<C-h>', '<Left>', opts)
set_keymap('i', '<C-l>', '<Right>', opts)
set_keymap('c', '<C-h>', '<Left>', opts)
set_keymap('c', '<C-l>', '<Right>', opts)
set_keymap('i', '<C-j>', '<Down>', opts)
set_keymap('i', '<C-k>', '<Up>', opts)
set_keymap('i', '<C-q>', '<BS>', opts)
set_keymap('i', '<C-e>', '<Del>', opts)
set_keymap('n', '<A-j>', ':move .+1<CR>==', opts)
set_keymap('n', '<A-k>', ':move .-2<CR>==', opts)
set_keymap('v', '<A-j>', ":move '>+1<CR>gv=gv", opts)
set_keymap('v', '<A-k>', ":move '<-2<CR>gv=gv", opts)

-- バッファ / ウィンドウ操作 (VSCode の keybindings.json と対応させる)
-- Ctrl+h/l: バッファ切替 (VSCode: previousEditor / nextEditor)
set_keymap('n', '<C-h>', ':bprevious<CR>', opts)
set_keymap('n', '<C-l>', ':bnext<CR>', opts)

-- Ctrl+j/k: バッファの並び替え (VSCode: moveEditorLeftInGroup / moveEditorRightInGroup)
set_keymap('n', '<C-j>', '<CMD>BufferLineMovePrev<CR>', opts)
set_keymap('n', '<C-k>', '<CMD>BufferLineMoveNext<CR>', opts)
-- Alt+h/l: ウィンドウ(分割)フォーカス移動 (VSCode: navigateLeft / navigateRight)
-- 上下 (Alt+j/k) は行移動 (下記) と衝突するため素の <C-w>j / <C-w>k を使用する
set_keymap('n', '<A-h>', '<C-w>h', opts)
set_keymap('n', '<A-l>', '<C-w>l', opts)
-- Ctrl+Alt+h/j/k/l: ウィンドウを画面端へ移動 (VSCode: moveEditorToLeftGroup 等)
set_keymap('n', '<C-A-h>', '<C-w>H', opts)
set_keymap('n', '<C-A-l>', '<C-w>L', opts)
set_keymap('n', '<C-A-j>', '<C-w>J', opts)
set_keymap('n', '<C-A-k>', '<C-w>K', opts)
set_keymap('n', '<leader>s', ':split<CR>', opts)
set_keymap('n', '<leader>v', ':vsplit<CR>', opts)
set_keymap('n', '<leader>q', '<C-w>q', opts)
-- <leader>x: プラグイン管理UI (VSCode: view.extensions)
set_keymap('n', '<leader>x', ':Lazy<CR>', opts)

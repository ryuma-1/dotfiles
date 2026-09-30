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
-- :bnext/:bprevious はバッファ番号順なので，並び替え後の表示順で移動するため bufferline のコマンドを使う
set_keymap('n', '<C-h>', '<CMD>BufferLineCyclePrev<CR>', opts)
set_keymap('n', '<C-l>', '<CMD>BufferLineCycleNext<CR>', opts)
-- Ctrl+w: バッファを閉じる (VSCode: closeActiveEditor)
-- :bdelete だと最後のウィンドウレイアウトが崩れるため，ウィンドウを保持する Snacks.bufdelete を使う
-- Neovim 標準の <C-w>d / <C-w><C-d> が残ると後続キー待ち (timeoutlen) で遅延するため削除する
vim.keymap.del('n', '<C-w>d')
vim.keymap.del('n', '<C-w><C-d>')
set_keymap('n', '<C-w>', '<CMD>lua Snacks.bufdelete()<CR>', opts)

-- Ctrl+j/k: バッファの並び替え (VSCode: moveEditorLeftInGroup / moveEditorRightInGroup)
set_keymap('n', '<C-j>', '<CMD>BufferLineMovePrev<CR>', opts)
set_keymap('n', '<C-k>', '<CMD>BufferLineMoveNext<CR>', opts)
-- Alt+h/l: ウィンドウ(分割)フォーカス移動 (VSCode: navigateLeft / navigateRight)
set_keymap('n', '<A-h>', '<C-w>h', opts)
set_keymap('n', '<A-l>', '<C-w>l', opts)
-- Leader+w j/k: ウィンドウ上下フォーカス移動
-- Alt+j/k は行移動 (下記) と衝突し，<C-w> はバッファを閉じる操作に専念させたため leader に逃がす
set_keymap('n', '<leader>wj', '<C-w>j', opts)
set_keymap('n', '<leader>wk', '<C-w>k', opts)
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

-- 基本操作
vim.keymap.set('i', 'jk', '<ESC>', { silent = true })
vim.keymap.set('n', '<ESC><ESC>', '<CMD>nohlsearch<CR>', { silent = true })
vim.keymap.set('n', 'j', 'gj', { silent = true })
vim.keymap.set('n', 'k', 'gk', { silent = true })
vim.keymap.set('n', 'zx', '<CMD>CenterCursorToggle<CR>zz', { silent = true })

-- Enter: 現在行の下に新規行を挿入してインサートモードへ (VSCode: insertLineAfter)
vim.keymap.set('n', '<CR>', 'o', { silent = true })
-- Shift+Enter: 現在行の上に新規行を挿入してインサートモードへ (VSCode: insertLineBefore)
vim.keymap.set('n', '<S-CR>', 'O', { silent = true })

-- Visual mode ペースト
vim.keymap.set('v', 'p', 'P', { silent = true })
vim.keymap.set('v', 'P', 'p', { silent = true })

-- インサート / コマンドモードでのカーソル移動・削除
vim.keymap.set('i', '<C-h>', '<Left>', { silent = true })
vim.keymap.set('i', '<C-l>', '<Right>', { silent = true })
vim.keymap.set('c', '<C-h>', '<Left>', { silent = true })
vim.keymap.set('c', '<C-l>', '<Right>', { silent = true })
vim.keymap.set('i', '<C-j>', '<Down>', { silent = true })
vim.keymap.set('i', '<C-k>', '<Up>', { silent = true })
vim.keymap.set('i', '<C-q>', '<BS>', { silent = true })
vim.keymap.set('i', '<C-e>', '<Del>', { silent = true })
-- Ctrl+Alt+j/k: 行移動 (Alt+j/k はウィンドウフォーカス移動に使うため Ctrl を加えて逃がす)
vim.keymap.set('n', '<C-A-j>', ':move .+1<CR>==', { silent = true })
vim.keymap.set('n', '<C-A-k>', ':move .-2<CR>==', { silent = true })
vim.keymap.set('v', '<C-A-j>', ":move '>+1<CR>gv=gv", { silent = true })
vim.keymap.set('v', '<C-A-k>', ":move '<-2<CR>gv=gv", { silent = true })

-- バッファ / ウィンドウ操作 (VSCode の keybindings.json と対応させる)
-- Ctrl+h/l: バッファ切替 (VSCode: previousEditor / nextEditor)
-- :bnext/:bprevious はバッファ番号順なので，並び替え後の表示順で移動するため bufferline のコマンドを使う
vim.keymap.set('n', '<C-h>', '<CMD>BufferLineCyclePrev<CR>', { silent = true })
vim.keymap.set('n', '<C-l>', '<CMD>BufferLineCycleNext<CR>', { silent = true })
-- Ctrl+w: バッファを閉じる (VSCode: closeActiveEditor)
-- :bdelete だと最後のウィンドウレイアウトが崩れるため，ウィンドウを保持する Snacks.bufdelete を使う
-- Neovim 標準の <C-w>d / <C-w><C-d> が残ると後続キー待ち (timeoutlen) で遅延するため削除する
vim.keymap.del('n', '<C-w>d')
vim.keymap.del('n', '<C-w><C-d>')
vim.keymap.set('n', '<C-w>', '<CMD>lua Snacks.bufdelete()<CR>', { silent = true })

-- Ctrl+j/k: バッファの並び替え (VSCode: moveEditorLeftInGroup / moveEditorRightInGroup)
vim.keymap.set('n', '<C-j>', '<CMD>BufferLineMovePrev<CR>', { silent = true })
vim.keymap.set('n', '<C-k>', '<CMD>BufferLineMoveNext<CR>', { silent = true })
-- Alt+h/j/k/l: ウィンドウ(分割)フォーカス移動 (VSCode: navigateLeft / navigateRight 等)
vim.keymap.set('n', '<A-h>', '<C-w>h', { silent = true })
vim.keymap.set('n', '<A-j>', '<C-w>j', { silent = true })
vim.keymap.set('n', '<A-k>', '<C-w>k', { silent = true })
vim.keymap.set('n', '<A-l>', '<C-w>l', { silent = true })
-- Leader+w j/k: ウィンドウ上下フォーカス移動 (Alt+j/k と同等．既存の手癖のために残す)
vim.keymap.set('n', '<leader>wj', '<C-w>j', { silent = true })
vim.keymap.set('n', '<leader>wk', '<C-w>k', { silent = true })
-- Ctrl+Alt+h/l: ウィンドウを画面左右端へ移動 (VSCode: moveEditorToLeftGroup 等)
-- Ctrl+Alt+j/k は行移動に割り当てたため，上下端への移動は持たない
vim.keymap.set('n', '<C-A-h>', '<C-w>H', { silent = true })
vim.keymap.set('n', '<C-A-l>', '<C-w>L', { silent = true })
-- <leader>s を分割系の prefix にまとめ，treesj の <leader>st と共存させる
vim.keymap.set('n', '<leader>sh', ':split<CR>', { silent = true })
vim.keymap.set('n', '<leader>sv', ':vsplit<CR>', { silent = true })
vim.keymap.set('n', '<leader>q', '<C-w>q', { silent = true })
-- <leader>x: プラグイン管理UI (VSCode: view.extensions)
vim.keymap.set('n', '<leader>x', ':Lazy<CR>', { silent = true })

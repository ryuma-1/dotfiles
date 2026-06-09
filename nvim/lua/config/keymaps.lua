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

-- バッファ / ウィンドウ操作
set_keymap('n', '<C-j>', ':bn<CR>', opts)
set_keymap('n', '<C-k>', ':bp<CR>', opts)
set_keymap('n', '<C-h>', '<C-w>W', opts)
set_keymap('n', '<C-l>', '<C-w>w', opts)
set_keymap('n', '<leader>s', ':split<CR>', opts)
set_keymap('n', '<leader>v', ':vsplit<CR>', opts)
set_keymap('n', '<leader>q', '<C-w>q', opts)

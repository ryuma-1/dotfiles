-- 基本操作
vim.keymap.set('i', 'jk', '<ESC>', { silent = true })
vim.keymap.set('n', '<ESC><ESC>', '<CMD>nohlsearch<CR>', { silent = true })
-- カウントなしは表示行，10j のようなカウント付きは relativenumber と一致するよう論理行で移動
vim.keymap.set('n', 'j', function() return vim.v.count == 0 and 'gj' or 'j' end, { silent = true, expr = true })
vim.keymap.set('n', 'k', function() return vim.v.count == 0 and 'gk' or 'k' end, { silent = true, expr = true })
vim.keymap.set('n', 'zx', '<CMD>CenterCursorToggle<CR>zz', { silent = true })

-- Enter: カーソル位置で行を分割し，カーソル以降を次の行へ送る
vim.keymap.set('n', '<CR>', 'i<CR><ESC>', { silent = true })
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
-- <leader>w は which-key の proxy で <C-w> として振る舞う (plugins/ui.lua)
-- Ctrl+Alt+h/l: ウィンドウを画面左右端へ移動 (VSCode: moveEditorToLeftGroup 等)
-- Ctrl+Alt+j/k は行移動に割り当てたため，上下端への移動は持たない
vim.keymap.set('n', '<C-A-h>', '<C-w>H', { silent = true })
vim.keymap.set('n', '<C-A-l>', '<C-w>L', { silent = true })
-- LazyVim 風の分割・終了キー
vim.keymap.set('n', '<leader>-', '<CMD>split<CR>', { silent = true, desc = 'Split Window Below' })
vim.keymap.set('n', '<leader>|', '<CMD>vsplit<CR>', { silent = true, desc = 'Split Window Right' })
vim.keymap.set('n', '<leader>wd', '<C-w>q', { silent = true, desc = 'Delete Window' })
vim.keymap.set('n', '<leader>qq', '<CMD>qa<CR>', { silent = true, desc = 'Quit All' })
-- :only は avante のサイドバーを閉じた際に連鎖して閉じられる入力欄で E445 となり，
-- 以降のウィンドウ (Trouble 等) が残るため，1 つずつ閉じて既に閉じられたものは飛ばす
vim.keymap.set('n', '<leader>wo', function()
    local current = vim.api.nvim_get_current_win()
    for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if win ~= current and vim.api.nvim_win_is_valid(win) then
            vim.api.nvim_win_close(win, false)
        end
    end
end, { silent = true, desc = 'Close Other Windows' })
-- <leader>l: プラグイン管理UI (LazyVim と同じ)
vim.keymap.set('n', '<leader>l', '<CMD>Lazy<CR>', { silent = true, desc = 'Lazy' })

-- LSP リネームは lspsaga の gn に割り当てたため，Neovim 標準の grn は不要になる
-- 残すと Lspsaga finder の gr が後続キー待ち (timeoutlen) で遅延する原因にもなるため削除する
vim.keymap.del('n', 'grn')

-- Reading モード: バッファの編集を禁止し，u/d で半画面スクロールする (バッファごとにトグル)
-- d は surround 等の d から始まるマップと衝突して待たされるため nowait にする
-- remap: neoscroll の <C-u>/<C-d> マップを経由させてなめらかにスクロールさせる
local function toggle_reading_mode()
    if vim.b.reading_mode then
        vim.bo.modifiable = vim.b.reading_mode_prev_modifiable
        vim.keymap.del('n', 'u', { buffer = 0 })
        vim.keymap.del('n', 'd', { buffer = 0 })
        vim.b.reading_mode = nil
        vim.notify('Reading mode: off')
    else
        vim.b.reading_mode_prev_modifiable = vim.bo.modifiable
        vim.bo.modifiable = false
        vim.keymap.set('n', 'u', '<C-u>', { buffer = 0, nowait = true, silent = true, remap = true })
        vim.keymap.set('n', 'd', '<C-d>', { buffer = 0, nowait = true, silent = true, remap = true })
        vim.b.reading_mode = true
        vim.notify('Reading mode: on')
    end
end
vim.api.nvim_create_user_command('ReadingMode', toggle_reading_mode, {})
vim.keymap.set('n', '<leader>ur', toggle_reading_mode, { silent = true, desc = 'Toggle reading mode' })

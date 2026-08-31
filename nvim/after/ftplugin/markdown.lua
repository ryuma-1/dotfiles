-- Markdown 専用のインデント設定
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2

-- 箇条書き・タスクリストの自動継続 (autolist.nvim)
-- (Vim 標準の formatoptions/comments では記号のみで [ ] チェックボックスや
--  番号付きリストの採番まで再現できないため，専用プラグインに委譲する)
vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<CR>', { buffer = true })
vim.keymap.set('n', 'o', 'o<cmd>AutolistNewBullet<CR>', { buffer = true })
vim.keymap.set('n', 'O', 'O<cmd>AutolistNewBulletBefore<CR>', { buffer = true })
vim.keymap.set('n', '<C-r>', '<cmd>AutolistRecalculate<CR>', { buffer = true, desc = 'Markdown: Recalculate List' })
-- Tab / Shift-Tab での箇条書き（チェックボックス含む）インデント変更は，
-- nvim-cmp が InsertEnter 毎に <Tab> を再設定してここでの定義を上書きしてしまうため，
-- lua/plugins/ai.lua の cmp mapping 側 (AutolistTab / AutolistShiftTab 呼び出し) で処理する

-- VSCode (Markdown All in One) の m 系キーバインドに合わせた装飾トグル
-- 現在の Visual 選択範囲を marker で囲む
-- (終端側を先に編集して、開始位置がずれないようにする)
local function wrap_visual_selection(marker)
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, start_col = start_pos[2] - 1, start_pos[3] - 1
  local end_line, end_col = end_pos[2] - 1, end_pos[3]

  vim.api.nvim_buf_set_text(0, end_line, end_col, end_line, end_col, { marker })
  vim.api.nvim_buf_set_text(0, start_line, start_col, start_line, start_col, { marker })
end

-- Normal モードではカーソル下の単語を対象にする
local function toggle_decoration(marker)
  if vim.fn.mode() == 'n' then
    local esc = vim.api.nvim_replace_termcodes('<Esc>', true, false, true)
    vim.cmd('normal! viw' .. esc)
  end
  wrap_visual_selection(marker)
end

local function toggle_checkbox_line(lnum)
  local line = vim.api.nvim_buf_get_lines(0, lnum, lnum + 1, false)[1]
  if not line then
    return
  end
  local replaced, count = line:gsub('%[ %]', '[x]', 1)
  if count == 0 then
    replaced, count = line:gsub('%[[xX]%]', '[ ]', 1)
  end
  if count > 0 then
    vim.api.nvim_buf_set_lines(0, lnum, lnum + 1, false, { replaced })
  end
end

local function toggle_checkbox()
  if vim.fn.mode() == 'n' then
    toggle_checkbox_line(vim.fn.line('.') - 1)
    return
  end

  local start_line = vim.fn.getpos("'<")[2] - 1
  local end_line = vim.fn.getpos("'>")[2] - 1
  for lnum = start_line, end_line do
    toggle_checkbox_line(lnum)
  end
end

for _, mode in ipairs({ 'n', 'x' }) do
  vim.keymap.set(mode, 'mb', function() toggle_decoration('**') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Bold' })
  vim.keymap.set(mode, 'mi', function() toggle_decoration('_') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Italic' })
  vim.keymap.set(mode, 'ms', function() toggle_decoration('~~') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Strikethrough' })
  vim.keymap.set(mode, 'mm', function() toggle_decoration('$') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Math' })
  vim.keymap.set(mode, 'mc', toggle_checkbox,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Checkbox' })
  vim.keymap.set(mode, 'mvv', '<CMD>MarkdownPreview<CR>',
    { buffer = true, silent = true, desc = 'Markdown: Show Preview' })
  vim.keymap.set(mode, 'mvk', '<CMD>MarkdownPreview<CR>',
    { buffer = true, silent = true, desc = 'Markdown: Show Preview' })
end

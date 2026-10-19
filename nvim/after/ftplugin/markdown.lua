-- Markdown 専用のインデント設定
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 4
vim.opt_local.shiftwidth = 4
vim.opt_local.softtabstop = 4

-- 箇条書き・タスクリストの自動継続 (autolist.nvim)
-- (Vim 標準の formatoptions/comments では記号のみで [ ] チェックボックスや
--  番号付きリストの採番まで再現できないため，専用プラグインに委譲する)
vim.keymap.set('i', '<CR>', '<CR><cmd>AutolistNewBullet<CR>', { buffer = true })
vim.keymap.set('n', 'o', 'o<cmd>AutolistNewBullet<CR>', { buffer = true })
vim.keymap.set('n', 'O', 'O<cmd>AutolistNewBulletBefore<CR>', { buffer = true })
-- <C-r> は Vim 標準の redo と衝突し Markdown で redo できなくなるため使わず，
-- 他の Markdown 専用キー (<leader>m 系) に揃えて <leader>mr に割り当てる．
vim.keymap.set('n', '<leader>mr', '<cmd>AutolistRecalculate<CR>', { buffer = true, silent = true, desc = 'Markdown: Recalculate List' })
-- Tab / Shift-Tab での箇条書き（チェックボックス含む）インデント変更は，
-- nvim-cmp が InsertEnter 毎に <Tab> を再設定してここでの定義を上書きしてしまうため，
-- lua/plugins/completion.lua の cmp mapping 側 (<C-t>/<C-d> + AutolistRecalculate) で処理する．
-- (cmp 側の <Tab>/<S-Tab> は補完候補の選択には使わず，Insert モードでは
--  全ファイルタイプ共通でインデント調整のみを行うマッピングである)

-- VSCode (Markdown All in One) の m 系キーバインドに合わせた装飾トグル
-- (素の m 始まりは Vim 標準のマーク設定 (m{a-z}) を潰すため，<leader> を前置する)
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
  vim.keymap.set(mode, '<leader>mb', function() toggle_decoration('**') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Bold' })
  vim.keymap.set(mode, '<leader>mi', function() toggle_decoration('_') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Italic' })
  vim.keymap.set(mode, '<leader>ms', function() toggle_decoration('~~') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Strikethrough' })
  vim.keymap.set(mode, '<leader>mm', function() toggle_decoration('$') end,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Math' })
  vim.keymap.set(mode, '<leader>mc', toggle_checkbox,
    { buffer = true, silent = true, desc = 'Markdown: Toggle Checkbox' })
end

-- markdown-preview.nvim is declared in lua/plugins/lang.lua; only the buffer-local key lives here
vim.keymap.set('n', '<leader>mp', '<cmd>MarkdownPreviewToggle<CR>',
  { buffer = true, silent = true, desc = 'Markdown: Toggle Preview' })

-- リンク [text](target) を Ctrl+クリックで開く (VSCode 風)
-- Neovim 既定の <C-LeftMouse> はタグジャンプ，gx はローカルファイルも外部アプリで開いてしまうため自前で定義する．
-- URL は vim.ui.open でブラウザへ，ローカルファイルは md ファイルからの相対パスで解決して Neovim で開く
local function link_target_under_cursor()
  local line = vim.api.nvim_get_current_line()
  local col = vim.fn.col('.')
  local init = 1
  while true do
    local s, e, target = line:find('%b[]%((.-)%)', init)
    if not s then
      return nil
    end
    if col >= s and col <= e then
      -- <path with spaces> / path "title" を考慮してパス部分だけ取り出す
      return target:match('^<(.-)>') or target:match('^(%S+)') or ''
    end
    init = e + 1
  end
end

vim.keymap.set('n', '<C-LeftMouse>', function()
  -- まずクリック位置へカーソルを移動させる
  vim.api.nvim_feedkeys(vim.keycode('<LeftMouse>'), 'nx', false)
  local path = link_target_under_cursor()
  if not path or path == '' then
    return
  end
  if path:match('^%a[%w+.-]*:') then
    vim.ui.open(path)
    return
  end
  path = vim.fn.expand(vim.uri_decode((path:gsub('#.*$', ''))))
  if path == '' then
    return
  end
  if path:sub(1, 1) ~= '/' then
    path = vim.fs.joinpath(vim.fn.expand('%:p:h'), path)
  end
  if vim.uv.fs_stat(path) then
    vim.cmd.edit(vim.fn.fnameescape(vim.fs.normalize(path)))
  else
    vim.notify('File not found: ' .. path, vim.log.levels.WARN)
  end
end, { buffer = true, desc = 'Markdown: Open Link (Ctrl+Click)' })

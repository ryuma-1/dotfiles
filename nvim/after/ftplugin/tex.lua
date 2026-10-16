-- TeX は文章編集向けのローカル設定
vim.opt_local.spell = true
vim.opt_local.spelllang = { 'en', 'cjk' } -- 日本語をスペルミス扱いしない
vim.opt_local.wrap = true
-- linebreak は breakat(ASCII 記号のみ)でしか折り返さず，日本語の途中で折り返せなくなるため無効
vim.opt_local.linebreak = false

-- \item 行で改行すると次行にも \item を継続し，空の \item で改行したら \item を消す
-- (cmp の <CR> はこのバッファローカルマッピングを fallback として呼ぶ)
-- 現在行が \begin{env} で，次行が対応する \end{env} でなければ env を返す
local function unclosed_env()
  local env = vim.api.nvim_get_current_line():match('^%s*\\begin{([^}]+)}')
  local row = vim.api.nvim_win_get_cursor(0)[1]
  local next_line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ''
  if env and not next_line:match('^%s*\\end{' .. vim.pesc(env) .. '}') then return env end
end

vim.keymap.set('i', '<CR>', function()
  local line = vim.api.nvim_get_current_line()
  if line:match('^%s*\\item%s*$') then return '<C-o>"_cc' end
  if line:match('^%s*\\item') then return '<CR>\\item ' end
  -- \begin{env} の行末で改行したら \end{env} を補い，間の行にカーソルを置く
  local env = unclosed_env()
  if env and vim.api.nvim_win_get_cursor(0)[2] == #line then
    return '<CR>\\end{' .. env .. '}<C-o>O'
  end
  return '<CR>'
end, { buffer = true, expr = true })
for _, key in ipairs({ 'o', 'O' }) do
  vim.keymap.set('n', key, function()
    local env = key == 'o' and unclosed_env()
    if env then return 'o\\end{' .. env .. '}<C-o>O' end
    return vim.api.nvim_get_current_line():match('^%s*\\item') and key .. '\\item ' or key
  end, { buffer = true, expr = true })
end

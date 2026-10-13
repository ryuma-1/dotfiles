-- TeX は文章編集向けのローカル設定
vim.opt_local.spell = true
vim.opt_local.spelllang = { 'en', 'cjk' } -- 日本語をスペルミス扱いしない
vim.opt_local.wrap = true
vim.opt_local.linebreak = true

-- \item 行で改行すると次行にも \item を継続し，空の \item で改行したら \item を消す
-- (cmp の <CR> はこのバッファローカルマッピングを fallback として呼ぶ)
vim.keymap.set('i', '<CR>', function()
  local line = vim.api.nvim_get_current_line()
  if line:match('^%s*\\item%s*$') then return '<C-o>"_cc' end
  if line:match('^%s*\\item') then return '<CR>\\item ' end
  return '<CR>'
end, { buffer = true, expr = true })
for _, key in ipairs({ 'o', 'O' }) do
  vim.keymap.set('n', key, function()
    return vim.api.nvim_get_current_line():match('^%s*\\item') and key .. '\\item ' or key
  end, { buffer = true, expr = true })
end

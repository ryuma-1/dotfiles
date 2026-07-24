-- Markdown 専用のインデント設定
vim.opt_local.expandtab = true
vim.opt_local.tabstop = 2
vim.opt_local.shiftwidth = 2
vim.opt_local.softtabstop = 2

-- 選択範囲を Markdown の太字記法で囲む
vim.keymap.set('x', '<C-b>', function()
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")
  local start_line, start_col = start_pos[2] - 1, start_pos[3] - 1
  local end_line, end_col = end_pos[2] - 1, end_pos[3]

  -- 終端側を先に編集して、開始位置がずれないようにする
  vim.api.nvim_buf_set_text(0, end_line, end_col, end_line, end_col, { '**' })
  vim.api.nvim_buf_set_text(0, start_line, start_col, start_line, start_col, { '**' })
end, { buffer = true, silent = true, desc = '選択範囲を太字にする' })

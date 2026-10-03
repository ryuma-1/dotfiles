-- ====================================================================
-- Unity 連携: Editor.log のコンパイルエラー / スタックトレースを quickfix に取り込む
-- ====================================================================

--- Unity の Editor.log のパスを返す．
--- Unity はOSごとに固定の場所へログを書き出すため，OSで分岐する．
--- @return string
local function unity_log_path()
  if vim.fn.has("mac") == 1 then
    return vim.fn.expand("~/Library/Logs/Unity/Editor.log")
  end
  return vim.fn.expand("~/.config/unity3d/Editor.log")
end

--- ログ行を quickfix 項目に変換する errorformat．
--- パスは Unity プロジェクトルートからの相対パス (Assets/...) で出力されるため，
--- Neovim の cwd がプロジェクトルートであることを前提とする．
local efm = table.concat({
  -- Assets/Foo.cs(12,5): error CS0103: ...
  [[%f(%l\,%c): %trror CS%n: %m]],
  -- Assets/Foo.cs(12,5): warning CS0168: ...
  [[%f(%l\,%c): %tarning CS%n: %m]],
  -- Foo:Bar () (at Assets/Foo.cs:12)
  [[%.%#(at %f:%l)]],
}, ",")

--- 最後に C# コンパイルを実行したビルドの開始行番号を返す．
--- "[ScriptCompilation] Requested script compilation" は実際にはコンパイルしない場合にも出力されるため，
--- Bee ビルドの開始行を区切りとし，その中に Csc ステップを含むものだけを「コンパイル」とみなす．
--- Csc を含まないビルドは診断を一切出さないので，これを区切りにすると直前の結果が消えてしまう．
--- @param lines string[]
--- @return integer 該当がなければ 1 (ログ全体)
local function last_compile_start(lines)
  local last, current = 1, nil
  for i, line in ipairs(lines) do
    if line:find("bee_backend --ipc", 1, true) then
      current = i
    elseif current and line:find("] Csc ", 1, true) then
      last = current
    end
  end
  return last
end

--- Editor.log の最後のコンパイル以降から，エラー・警告・スタックトレース行を quickfix リストに設定して開く．
local function load_unity_log()
  local path = unity_log_path()
  if vim.fn.filereadable(path) == 0 then
    vim.notify("Editor.log が見つかりません: " .. path, vim.log.levels.WARN)
    return
  end

  local lines = vim.fn.readfile(path)
  local seen, items = {}, {}
  for i = last_compile_start(lines), #lines do
    local line = lines[i]
    local hit = line:find("): error CS", 1, true)
      or line:find("): warning CS", 1, true)
      or line:find("(at Assets/", 1, true)
    -- Unity はコンパイラ出力をそのまま流した後に同じ内容を再度ログ出力するので重複を除く
    if hit and not seen[line] then
      seen[line] = true
      table.insert(items, line)
    end
  end

  vim.fn.setqflist({}, " ", { title = "Unity Editor.log", lines = items, efm = efm })
  vim.cmd("copen")
end

vim.api.nvim_create_user_command("UnityLog", load_unity_log, { desc = "Load Unity Editor.log into quickfix" })
vim.keymap.set("n", "<leader>ue", load_unity_log, { noremap = true, silent = true, desc = "Unity: Editor.log to quickfix" })

# 実装計画: キーマップ定義を vim.keymap.set に統一し mapleader の重複を解消する

## 元Issue
- #17: [Refactor] キーマップ定義を vim.keymap.set に統一し mapleader の重複を解消する
- https://github.com/ryuma-1/dotfiles/issues/17

## 概要
`vim.api.nvim_set_keymap` / `nvim_buf_set_keymap` が残っている箇所をすべて `vim.keymap.set` に置き換える．あわせて `lua/config/keymaps.lua` 先頭の `mapleader` / `maplocalleader` の重複設定を削除し，`init.lua` の 1 箇所に集約する．
キー割り当てと挙動は変えない．単純な置換が中心なので，複雑度は「単純」（レイヤー跨りなし，既存インターフェースは `lsp_keybindings` のローカル関数シグネチャのみ）と判断した．

## 要件
- すべてのキーマップを `vim.keymap.set` で定義する．バッファローカルは `{ buffer = bufnr }` を使う．
- `mapleader` / `maplocalleader` は `init.lua` のみで設定する．
- 既存のキー割り当てと挙動は変えない．
- `config/keymaps.lua` の `set_keymap` ラッパーと `opts` を削除する．`noremap = true` は `vim.keymap.set` のデフォルト（`remap = false`）なので不要．
- `lsp_keybindings` の未使用 `client` 引数を整理する．
- 対象は次の 4 か所．
  - `nvim/init.lua:26-27` と `nvim/lua/config/keymaps.lua:1-2`（`mapleader` の重複）
  - `nvim/lua/config/keymaps.lua:4-7`（ラッパー）
  - `nvim/lua/plugins/lsp.lua:4-15, 304-332`
  - `nvim/lua/plugins/edit.lua:229`

## 実装方針
調査の結果は次のとおり．
- 旧 API の使用箇所は上記 4 か所のみ．`after/ftplugin/markdown.lua` や `config/unity.lua` などは既に `vim.keymap.set` を使っている．
- `mapleader` は `init.lua:26-27` で，`require('config.keymaps')`（38 行）と `require("lazy").setup`（53 行）より前に設定済み．`keymaps.lua` 側の重複を削除しても `<leader>` の展開結果は変わらない．`init.lua` の設定位置は動かさない．
- `expr` を使うマッピングは存在しない．`replace_keycodes` の差異を気にする必要はない．
- すべての旧マッピングが `silent = true` を指定している．置換後も `silent = true` を維持する．
- `<ESC>` `<CR>` などの特殊キー表記は，`vim.keymap.set` でも同様に解釈される．rhs の文字列は変更しない．
- `callback` 付き空文字 rhs（`gf`，`<leader>ul`）は，関数を rhs に直接渡す形に整理する．
- 新規に `desc` を付けるのは，`lsp_keybindings` 内の `gd` `gr` `grn` `gca` `gh` と `TermOpen` 内の `<ESC>` に限る．既に `desc` があるものは維持する．`keymaps.lua` の既存キー割り当ては変えない．
- `lsp_keybindings(client, bufnr)` は `client` が未使用なので，`lsp_keybindings(bufnr)` に変更する．呼び出し元は `lsp.lua:299` の 1 か所のみで，他ファイルからの参照はない．
- ユーザー規約に従い，新設・変更する関数には doc comment を付ける．コメントは why を書く．インラインコメントはコードの上の行に置く．日本語コメントは「，」「．」を使う．
- `keymaps.lua:48-49` の `vim.keymap.del` は既存のまま触らない．

### keymaps.lua の置換方針
- `local opts = { noremap = true, silent = true }` を削除し，`local map = vim.keymap.set` のような別名を作らず，直接 `vim.keymap.set(mode, lhs, rhs, { silent = true })` と書く．
- 繰り返しを避けたい場合のみ，`local silent = { silent = true }` を 1 つ定義して使う方針でもよい．ただしラッパー関数は復活させない．
- 既存のコメントは維持する．

## タスク一覧
### init.lua / keymaps.lua
- [x] `lua/config/keymaps.lua` 1-2 行目の `vim.g.mapleader` / `vim.g.maplocalleader` を削除する（`init.lua` の設定は維持）
- [x] `set_keymap` ラッパーと `opts` を削除する
- [x] 全 `set_keymap(...)` 呼び出しを `vim.keymap.set(mode, lhs, rhs, { silent = true })` に置換する（`noremap` は削除）
- [x] `<leader>wj` / `<leader>sh` など `<leader>` を使うマッピングが，`init.lua` 側の leader 設定で解決されることを確認する

### lsp.lua
- [x] `lsp_keybindings` のシグネチャを `(bufnr)` に変更し，`client` 引数を削除する．doc comment も更新する
- [x] `gd` `gr` `grn` `gca` `gh` を `vim.keymap.set('n', ..., { buffer = bufnr, silent = true, desc = ... })` に置換する
- [x] `gf` を `vim.keymap.set('n', 'gf', function() vim.lsp.buf.format({ bufnr = bufnr }) end, { buffer = bufnr, silent = true, desc = 'Format buffer' })` の形に置換する
- [x] LspAttach 内の呼び出しを `lsp_keybindings(bufnr)` に更新する（`client` は後段の `supports_method` や `format` で使うので残す）
- [x] LspAttach 内の `<leader>la` / `ge` / `<leader>ul` を `vim.keymap.set` に置換する．既存の `desc` と `silent = true` を維持し，`<leader>ul` は関数を直接 rhs に渡す

### edit.lua
- [x] `TermOpen` 内の `vim.api.nvim_buf_set_keymap(0, 't', '<ESC>', [[<C-\><C-n>]], ...)` を `vim.keymap.set('t', '<ESC>', [[<C-\><C-n>]], { buffer = 0, silent = true, desc = ... })` に置換する

### 検証
- [x] 変更後に `rg "nvim_set_keymap|nvim_buf_set_keymap" /Users/ryuma/git/dotfiles/nvim` で 0 件であることを確認する
- [x] `rg "mapleader|maplocalleader" /Users/ryuma/git/dotfiles/nvim` が `init.lua` のみであることを確認する
- [x] `nvim --headless "+qa"` を実行し，起動エラーがないことを確認する
- [x] 変更前後のマッピング一覧を比較する．
  - 変更前に `nvim --headless -c 'redir! > before.txt | silent verbose map | silent verbose imap | silent verbose cmap | silent verbose vmap | redir END' -c qa` で出力を取得する（出力先はスクラッチパッド）
  - 変更後も同様に取得し，`diff` で lhs / rhs / `silent` 属性に差がないことを確認する．`desc` や `Last set from` の行番号の差分は許容する
- [x] `nvim --headless -c 'lua print(vim.g.mapleader == " ", vim.g.maplocalleader == " ")' -c qa` で leader が空白になっていることを確認する
- [x] 実機で LSP 付きファイルを開く．`:verbose nmap gd` `:verbose nmap gf` `:verbose nmap <leader>ul` でバッファローカル（`@`）の割り当てを確認し，`gf` の整形と `<leader>ul` のトグルが動くことを確認する
- [x] `:terminal` や ToggleTerm を開き，ターミナルモードの `<ESC>` でノーマルモードに戻れることを確認する

## リスク・確認事項
- `gf` と `<leader>ul` で，空文字 rhs ＋ `callback` から関数 rhs に変わる．挙動は等価だが，`:verbose map` の rhs 表示が `<Lua function>` に変わる．差分比較時は想定内の差として扱う．
- `TermOpen` の `buffer = 0` は，現在のバッファ（TermOpen 発火時のターミナルバッファ）を指す．旧実装の `bufnr = 0` と同じ意味である．
- `vim.keymap.set` のデフォルトは `remap = false` なので，旧 `noremap = true` と等価．`keymaps.lua` 内に，別マッピングへ再マップされることを前提にした定義があるかは，実装時に再確認する．現状の調査では見当たらない．
- `desc` を追加すると，which-key などが導入されている場合に表示が増える可能性がある．機能面の影響はない．

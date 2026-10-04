# 実装計画: AutoFormatToggle / 診断表示トグルが LspAttach のたびにリセットされる問題の修正

## 元Issue
- #21: [Bug] AutoFormatToggle / 診断表示トグルが LspAttach のたびにオンに戻る
- https://github.com/ryuma-1/dotfiles/issues/21

## 概要
`vim.g.autoformat` と `vim.g.show_diagnostics` の初期化，および `AutoFormatToggle` コマンドの定義が `LspAttach` コールバック内にある．そのため，別バッファで LSP がアタッチされるたびに値が `true` に戻る．
これらを LspAttach の外（lsp.lua の該当 `config` 関数内）へ移し，起動時に一度だけ実行されるようにして解消する．
判定は「単純」．対象は 1 ファイルで，レイヤー跨りはない．

## 要件
- `:AutoFormatToggle` で `Auto Format: false` にした後，別ファイルで LSP がアタッチされても `false` のままであること．
- `<leader>ul` で切り替えた `vim.g.show_diagnostics` も，LspAttach で `true` に戻らないこと．
- 初期値は現状どおり `true` を維持する（Issue が求めているのはリセットの解消のみ）．
- 初期値の設定とユーザーコマンドの定義は，LspAttach の外で一度だけ行う．

## 実装方針
対象ファイルは `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lsp.lua` のみ．現在のコードは次のとおり（Issue 記載の行番号 325, 346-350 とは異なる．現在は 229 と 250-254）．

- 229行: LspAttach 内の `vim.g.show_diagnostics = true`
- 250-254行: LspAttach 内の `vim.g.autoformat = true` と `nvim_create_user_command('AutoFormatToggle', ...)`

変更内容:
- 上記 3 か所を LspAttach コールバックから削除する．
- `InlayHintToggle` を定義している 193-196行付近（LspAttach の autocmd 定義 198行の直前）に移す．既存の同種コマンドと並べて一貫性を保つ．
- コメントは英語で書く．doc comment を付け，「LspAttach は client ごと・buffer ごとに発火するため，トグル状態が上書きされないよう一度だけ初期化する」という why を明記する．

挙動への影響の確認結果:
- `vim.g.*` と `nvim_create_user_command` はいずれもグローバルである．LspAttach 外へ移しても，スコープは変わらない．
- バッファローカルの要素（`<leader>ul` の `nvim_buf_set_keymap`，`CursorHold` autocmd，`BufWritePre` autocmd）は `bufnr` に依存する．これらは LspAttach 内に残し，移動しない．
- `<leader>ul` と `BufWritePre` のコールバックは，実行時に `vim.g.*` を読む．そのため，初期化を外に出しても読み取り側は影響を受けない．
- 他ファイルからの参照: `nvim/` 配下に `vim.g.autoformat` / `show_diagnostics` の参照は lsp.lua のみ．
- リポジトリルートの `/Users/ryuma/git/dotfiles/init.lua`（973-1015行付近）にも同名の処理がある．こちらは旧設定とみられ，`autoformat` の初期値が `false` で，LspAttach 外ではない可能性がある．Issue の対象外のため，変更しない．

## タスク一覧
### 実装（`/Users/ryuma/git/dotfiles/nvim/lua/plugins/lsp.lua`）
- [x] LspAttach 内の `vim.g.show_diagnostics = true`（229行）を削除する
- [x] LspAttach 内の `vim.g.autoformat = true` と `AutoFormatToggle` のユーザーコマンド定義（250-254行）を削除する
- [x] LspAttach autocmd の定義より前（`InlayHintToggle` の近く）に，次の 3 つを追加する（※上の 2 タスクと同時に行う）
  - `vim.g.show_diagnostics = true` の初期化
  - `vim.g.autoformat = true` の初期化
  - `AutoFormatToggle` コマンドの定義（`print` の出力形式は現行どおり）
- [x] 追加箇所に，why を説明する英語の doc comment を付ける
- [x] `<leader>ul`，`CursorHold`，`BufWritePre` の各処理は LspAttach 内に残し，変更しない

### 動作確認
- [x] 手動で再現手順を実行する
  - LSP が有効なファイル A を開く
  - `:AutoFormatToggle` を実行し，`Auto Format: false` を確認する
  - LSP が有効な別ファイル B を開く
  - A に戻って整形が必要な編集をし，`:w` する．フォーマットされないことを確認する
  - `:lua print(vim.g.autoformat)` で `false` を確認する
- [x] 同様に，`<leader>ul` で `Show Diagnostic: false` にした後，別ファイルを開いても診断フロートが出ないこと（`vim.g.show_diagnostics` が `false` のまま）を確認する
- [x] 再度 `:AutoFormatToggle` を実行すると `true` に戻り，保存時にフォーマットされることを確認する
- [x] `nvim --headless` で Lua の構文エラーとコマンド登録を確認する（例: `-c "lua print(vim.fn.exists(':AutoFormatToggle'))" -c q`）．ただし lazy 読み込みの条件によっては，プラグイン読み込み後にしか確認できない場合がある

### コミット
- [x] Conventional Commits 形式の英語メッセージでコミットする（例: `fix: initialize autoformat and diagnostic toggles once outside LspAttach (#21)`）

## リスク・確認事項
- コマンドと初期値の定義を置く `config` 関数は，対象プラグインが lazy ロードされるまで実行されない．LSP 利用前に `:AutoFormatToggle` が使えるかは，読み込みトリガー（`event` / `ft` など）に依存する．現状は LspAttach 後にしか使えないため，退行はない．実装時に，該当 spec の読み込み条件を確認する．
- 複数クライアントが同一バッファにアタッチされる場合，`BufWritePre` autocmd が重複する可能性がある（`clear = false`）．これは別問題であり，Issue のスコープ外のため扱わない．
- ルートの `/Users/ryuma/git/dotfiles/init.lua` の重複定義が現在も読み込まれているかは，未確認である．読み込まれている場合は `autoformat` の初期値（`false`）が競合する可能性があるため，実装時に確認する．

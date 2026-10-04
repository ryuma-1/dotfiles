# 実装計画: WSL 判定・vim.loop・lazy spec の矛盾など細かな不整合の整理

## 元Issue
- #20: [Refactor] WSL 判定・vim.loop・lazy spec の矛盾など細かな不整合を整理する
- https://github.com/ryuma-1/dotfiles/issues/20

## 概要
起動処理，lazy.nvim の spec，コメントに残っている細かな不整合を整理する．
具体的には，`IsWSL` と起動時のシェル実行の廃止，`vim.loop` から `vim.uv` への置換，lazy spec の矛盾解消，行末空白と作業途中コメントの除去，`nvim/nvim.log` の git 管理除外を行う．
動作を変える変更は WSL 判定と lazy の読み込み条件の 2 点に限る．

## 要件
- WSL 判定を `vim.fn.has('wsl') == 1` に置き換える．グローバル変数 `IsWSL` と，起動時の `uname -r | grep` の同期実行（最大 1 秒待機）をなくす．
- `init.lua` の `vim.loop` を `vim.uv` に置き換える．
- lazy spec を各プラグイン README の推奨設定に合わせて整理する．
  - vimtex: `ft = 'tex'` と `event = 'VeryLazy'` が併用されている．
  - rustaceanvim: `ft` と `lazy = false` が併用されている．
  - render-markdown と flutter-tools: `event` と `ft` が併用されている．
  - swagger-preview: `file_types` は lazy.nvim の spec キーではない．
- 行末空白と作業途中の AI コメント（`💡 ...`）を除去する．
- `nvim/nvim.log` を `git rm --cached` で管理から外し，`.gitignore` で除外する．

## 実装方針
Issue の行番号は #19 の再編前のものなので，現在の位置を調査した結果に読み替える．

| Issue の記載 | 現在の位置 |
|---|---|
| `lsp.lua:439` の `IsWSL` | `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lang.lua:46` |
| `lsp.lua:391-453` の lazy spec | `lang.lua:3-59` |
| `base.lua:1-4` の `IsWSL` | 同じ位置（`/Users/ryuma/git/dotfiles/nvim/lua/config/base.lua:1-4`） |
| `init.lua:10` の `vim.loop` | 同じ位置（`/Users/ryuma/git/dotfiles/nvim/init.lua:10`） |
| `lsp.lua:209-219` の行末空白 | `lsp.lua:113-116,123`（mason spec） |
| 作業途中コメント | 下記のとおり |

作業途中コメントの現在位置:
- `ui.lua:6`
- `lsp.lua:118`
- `lsp.lua:259`
- `edit.lua:337`

Issue の記載と現状の差分は次のとおり．
- 行末空白は `base.lua:27,29,36,37,44,45` にもある．
- `lsp.lua:214` と `lsp.lua:355` に相当するコメントは，`lsp.lua:118` と `lsp.lua:259` に移っている．

### lazy spec の整理方針と根拠
- **vimtex**: `ft` と `event` を削除し，`lazy = false` にする．
  - 根拠: vimtex 公式 README は遅延読み込みを非推奨としている．vimtex は自前で filetype 判定と遅延を行う．
  - `config` は `init` に移すかどうかを実装時に確認する．vimtex は読み込み時に `vim.g.vimtex_*` を参照する．`lazy = false` なら lazy.nvim が起動時に `config` を実行するため，現状の `config` のままでも読み込みより前に設定されない恐れがある．`init` に移すのが README の推奨（`vim.g` は読み込み前に設定する）に沿う．
- **rustaceanvim**: `ft` を削除し，`lazy = false` のみにする．
  - 根拠: README は「このプラグインは自前で遅延読み込みされるため，lazy.nvim 側で遅延させない」としている．`lazy = false` を指定する場合 `ft` は無意味になる．
- **render-markdown**: `event` を削除し，`ft` のみにする．重複している `ft` の位置を `opts` の前に寄せる．
  - 根拠: `event` が `BufReadPre`/`BufNewFile` にあると，全ファイルで読み込まれる．README の lazy.nvim 例は `ft = { 'markdown' }` である．
  - `opts.file_types` は lazy のキーではなく，プラグイン自身の設定キーなので残す．
  - `ai.lua:43` で Avante の依存として参照されているため，Avante バッファで読み込まれるよう `ft` に `"Avante"` を残す．
- **flutter-tools**: `event` を削除し，`ft = {'dart'}` のみにする．
  - 根拠: README は `ft = 'dart'` による遅延読み込みを示している．
- **swagger-preview**: `file_types = { "yaml" }` を削除する．issue の「`ft` に置き換え」の方針どおり `ft = { "yaml" }` を追加するかは，下記のリスクで確認する．
  - 根拠: `file_types` は lazy のキーではなく無視される．`cmd` があるため，コマンド経由でも読み込める．

## タスク一覧
### 起動処理
- [x] `/Users/ryuma/git/dotfiles/nvim/lua/config/base.lua:1-4` の WSL 判定ブロック（`vim.system` と `IsWSL` 代入）を削除する．
- [x] `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lang.lua:46` の `if IsWSL then ... end` を `vim.g.vimtex_view_method = vim.fn.has('wsl') == 1 and 'wsl-open' or 'zathura'` に置き換える（※`base.lua` の削除と同時に行う）．
- [x] リポジトリ全体で `IsWSL` の参照が残っていないことを Grep で確認する（対象: `/Users/ryuma/git/dotfiles/nvim`）．
- [x] `/Users/ryuma/git/dotfiles/nvim/init.lua:10` の `vim.loop.fs_stat` を `vim.uv.fs_stat` に置き換える．

### lazy spec 整理（`/Users/ryuma/git/dotfiles/nvim/lua/plugins/lang.lua`）
- [x] rustaceanvim（3 行目）から `ft = {'rust'}` を削除する．
- [x] flutter-tools（6 行目）から `event = {'BufReadPre','BufNewFile'}` を削除する．
- [x] render-markdown（14 行目）から `event` を削除し，`ft`（25 行目）の位置を整える．
- [x] vimtex（43-44 行目）から `ft` と `event` を削除し，`lazy = false` を設定する．あわせて `config` から `init` への移行を検討する．
- [x] swagger-preview（55 行目）から無効な `file_types` を削除し，必要なら `ft = { "yaml" }` を追加する．

### 体裁・コメント
- [x] `/Users/ryuma/git/dotfiles/nvim/lua/config/base.lua` の 27, 29, 36, 37, 44, 45 行目の行末空白を除去する．`opt` 行の右側コメント用の空白も対象だが，コメントが無いので単純に削る．
- [x] `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lsp.lua:113-116,123` の行末空白を除去する．
- [x] 作業途中コメントを除去するか，通常のコメントに書き直す．
  - `/Users/ryuma/git/dotfiles/nvim/lua/plugins/ui.lua:6` の `-- 💡 「loctvl842」に修正しました` は削除する．
  - `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lsp.lua:118` は，Mason registries の理由を示す通常の説明コメントにする（例: roslyn を Mason で見つけるための registry 追加）．
  - `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lsp.lua:259` の `💡` は絵文字と「統合」の言い回しを除いた見出しにする．
  - `/Users/ryuma/git/dotfiles/nvim/lua/plugins/edit.lua:337` は `💡` と「します」調を除いた説明コメントにする．
- [x] 新しいコメントは「why」を説明する形にし，日本語コメントでは「，」「．」を使う．
- [x] `Grep` で `💡|修正しました` と `[ \t]+$`（`*.lua`）を再確認する．

### ログファイル
- [x] `/Users/ryuma/git/dotfiles/nvim/nvim.log` を `git rm --cached nvim/nvim.log` で管理から外す．ファイル自体は削除しない．
- [x] `.gitignore` を新規作成する．リポジトリルートには存在せず，`nvim/` 配下にもない．`/Users/ryuma/git/dotfiles/.gitignore` に `nvim/nvim.log` を追加するか，`nvim/.gitignore` に `nvim.log` を書く．配置は実装時に決める．実行時ログ全般を除外するなら `*.log` も選択肢になる．

### 動作確認
- [x] `nvim --headless "+Lazy! sync" +qa` 等でエラーがないことを確認する．
- [x] `:checkhealth lazy` で spec 警告（無効キー，ft/event の矛盾）が出ないことを確認する．
- [x] `.tex` / `.rs` / `.dart` / `.md` / `.yaml` を開き，プラグインが想定どおり読み込まれることを確認する．
- [x] `git status` で `nvim.log` が untracked にならず，`.gitignore` で除外されていることを確認する．

## リスク・確認事項
- **vimtex の設定タイミング**: `lazy = false` にした場合，`config` 内の `vim.g.vimtex_*` が読み込み後に設定され，反映されない恐れがある．`init` へ移す必要の有無を実機で確認する．
- **`vim.fn.has('wsl')`**: Neovim 0.4.4 以降で使える．現環境のバージョンを確認する．WSL1 でも `1` を返す．
- **swagger-preview の `ft`**: Issue は `file_types` を ft に置き換える方針だが，yaml 全般で読み込むと `build = "npm i"` を含むプラグインが全 yaml で有効になる．`cmd` のみで足りるかを確認する．
- **render-markdown の Avante**: `ft` から `"Avante"` を外すと，Avante の描画に影響する．`ai.lua:43` の依存指定と合わせて動作確認する．
- **`nvim.log` の履歴**: 履歴からの削除は範囲外（`git rm --cached` のみ）．
- **`.gitignore` の配置**: 存在しないため，どこに作るかを実装時に決める必要がある．

## 参考ファイル
- `/Users/ryuma/git/dotfiles/nvim/init.lua`
- `/Users/ryuma/git/dotfiles/nvim/lua/config/base.lua`
- `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lang.lua`
- `/Users/ryuma/git/dotfiles/nvim/lua/plugins/lsp.lua`
- `/Users/ryuma/git/dotfiles/nvim/lua/plugins/ui.lua`
- `/Users/ryuma/git/dotfiles/nvim/lua/plugins/edit.lua`
- `/Users/ryuma/git/dotfiles/nvim/lua/plugins/ai.lua`
- `/Users/ryuma/git/dotfiles/nvim/nvim.log`

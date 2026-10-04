# 実装計画: カーソル位置復元で commit / rebase バッファが除外されない問題の修正

## 元Issue
- #22: [Bug] カーソル位置復元で commit / rebase バッファが除外されない
- https://github.com/ryuma-1/dotfiles/issues/22

## 概要
`nvim/lua/config/base.lua` のカーソル位置復元 autocmd には，commit / rebase バッファを除外する条件があります．この条件は論理演算子の誤りのため常に真になり，除外が働いていません．演算子を修正して，意図どおり除外されるようにします．

## 要件
- 対象は `/Users/ryuma/git/dotfiles/nvim/lua/config/base.lua` の79行目です．条件は `not (ft:match('commit') and ft:match('rebase'))` です．
- `ft:match('commit') and ft:match('rebase')` は，filetype が両方の文字列を含む場合だけ真になります．そのため，この条件全体はほぼ常に真になります．
- `git commit`，`git commit --amend`，`git rebase -i` で開くバッファでは，前回のカーソル位置を復元せず，先頭行から始めます．
- それ以外の filetype の既存の復元動作は変えません．復元の条件は，`last_known_line > 1` と，行数以内であることです．

## 実装方針
79行目の `and` を `or` に変更し，`not (ft:match('commit') or ft:match('rebase'))` とします．変更は1行だけです．他の条件や構造には手を入れません．

## タスク一覧
- [x] `nvim/lua/config/base.lua` 79行目の `and` を `or` に変更する
- [x] 検証: 手動で再現手順を試す
  - `git commit` でメッセージを数行書いて保存して閉じる
  - もう一度 `git commit --amend` を実行し，カーソルが1行目から始まることを確認する
  - `git rebase -i` でも同様に確認する
- [x] 検証: 通常ファイル（例: lua ファイル）では，カーソル位置が従来どおり復元されることを確認する
- [x] 補助確認（任意）: `nvim --headless -c "lua print(not ('gitcommit'):match('commit') ...)"` などで，`gitcommit` と `gitrebase` の両方が除外されることを確認する

## リスク・確認事項
- `ft:match('commit')` は部分一致です．`gitcommit` と `gitrebase` は除外されます．他の filetype で名前に "commit" や "rebase" を含むものも除外されます．実用上は問題ない見込みです．
- Issue には，`BufWinEnter` のタイミングで filetype が設定済みかどうかの記述がありません．手動確認で commit バッファが除外されない場合は，この点を再調査します．

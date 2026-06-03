# --------------------------------------------------
# Git ブランチ名表示の設定
# --------------------------------------------------
# zshの関数呼び出し機能を有効にする
autoload -Uz vcs_info
setopt prompt_subst

# バージョン管理システム（Git）から情報を取得する設定
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' formats '%F{yellow}(%b%u%c%F{yellow})%f'
zstyle ':vcs_info:git:*' actionformats '%F{yellow}(%b|%a%u%c%F{yellow})%f'
zstyle ':vcs_info:git:*' unstagedstr '%F{#E06C75}*%f'
zstyle ':vcs_info:git:*' stagedstr '%F{#93CD7E}+%f'
# コマンド実行前に毎回実行される関数
precmd() { vcs_info }

# プロンプトの表示設定（パスをシアン、Gitブランチを紫に）
PROMPT='%F{cyan}%~%f ${vcs_info_msg_0_} '

# --------------------------------------------------
# Tabキーでの補完候補を矢印キーで選択できるようにする
# --------------------------------------------------
# 補完機能を有効にする
autoload -Uz compinit
compinit

# メニュー補完を有効にする
zstyle ':completion:*' menu true select
# macOSの標準色設定を Zshの補完システム（list-colors）に変換して適用
zstyle ':completion:*' list-colors "${(s.:.)LSCOLORS}"
# 大文字と小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# ../ の後の補完でPWDを候補から外す
zstyle ':completion:*' ignore-parents parent pwd ..
# sudo の後にコマンドを補完する
zstyle ':completion:*:sudo:*' command-path $PATH
# xxx
zstyle ':completion:*' verbose yes
# xxx
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history

# ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt auto_param_slash
# ファイル名の展開でディレクトリにマッチした場合 末尾に / を付加
setopt mark_dirs
# 補完候補一覧でファイルの種別を識別マーク表示
setopt list_types
# 補完キー連打で順に補完候補を自動で補完
setopt auto_menu
# カッコの対応などを自動的に補完
setopt auto_param_keys
# コマンドラインでも # 以降をコメントと見なす
setopt interactive_comments
# コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt magic_equal_subst
# 語の途中でもカーソル位置で補完
setopt complete_in_word
# カーソル位置は保持したままファイル名一覧を順次その場で表示
setopt always_last_prompt
# 拡張グロブで補完(~とか^とか。例えばless *.txt~memo.txt ならmemo.txt 以外の *.txt にマッチ)
setopt extended_glob
# 一覧を詰めて表示
setopt list_packed

# 自作のコマンド省略形（エイリアス）
alias xc='xclip -selection clipboard'

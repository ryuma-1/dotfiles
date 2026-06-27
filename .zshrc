# =============================================================================
# 1. 環境変数・PATHの設定
# =============================================================================

# 基本のPATH設定
export PATH="$HOME/.local/bin:$PATH"

# rbenv の設定
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"

# NVM (Node Version Manager) の設定
export NVM_DIR="$([ -z "${XDG_CONFIG_HOME-}" ] && printf %s "${HOME}/.nvm" || printf %s "${XDG_CONFIG_HOME}/nvm")"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # nvm 本体を読み込む
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvm の補完機能を読み込む

# 外部ツール (RASK) のAPI・URL設定
export RASK_API_KEY="rask-639984cb-2193-424d-bf22-ce6fa38f710d"
export RASK_URL="http://rask.nomlab.org"

# =============================================================================
# 2. 履歴 (History) の設定
# =============================================================================
# メモリ上に保存する履歴の件数
export HISTSIZE=100000
# 履歴ファイルに保存する履歴の件数
export SAVEHIST=100000

# =============================================================================
# 3. Zsh 基本設定 (Options)
# =============================================================================
# コマンドラインでも # 以降をコメントと見なす
setopt interactive_comments
# 拡張グロブを有効化 (~ や ^ などを強力なパターンマッチに使用)
setopt extended_glob
# コマンドラインの引数で --prefix=/usr などの = 以降でもパスを補完する
setopt magic_equal_subst

# =============================================================================
# 4. 補完機能 (Completion) の設定
# =============================================================================
# 補完機能を有効化
autoload -Uz compinit
compinit

# --- 補完の基本動作 (setopt) ---
# ディレクトリ名の補完で末尾に / を自動的に付加する
setopt auto_param_slash
# ファイル名の展開でディレクトリにマッチした場合、末尾に / を付加する
setopt mark_dirs
# 補完候補一覧でファイルの種別を識別マーク（/, *, @ など）で表示する
setopt list_types
# 補完キー連打で順に補完候補を自動で選択する
setopt auto_menu
# カッコの対応などを自動的に補完する
setopt auto_param_keys
# 語の途中でもカーソル位置で補完を試みる
setopt complete_in_word
# カーソル位置は保持したままファイル名一覧を順次その場で表示する
setopt always_last_prompt
# 補完候補の一覧を詰めて表示し、画面を節約する
setopt list_packed

# --- zstyle を使った詳細な補完設定 ---
# タブキーでの補完候補を矢印キーで選択できるようにする
zstyle ':completion:*' menu true select
# macOSの標準色設定を Zshの補完システムに変換して適用
zstyle ':completion:*' list-colors "${(s.:.)LSCOLORS}"
# 大文字と小文字を区別せずに補完する
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# ../ の後の補完でカレントディレクトリ (PWD) や .. 自身を候補から外す
zstyle ':completion:*' ignore-parents parent pwd ..
# sudo の後に続くコマンドも PATH から補完できるようにする
zstyle ':completion:*:sudo:*' command-path $PATH
# 補完候補にファイル種別などの追加の説明（詳細情報）を表示する
zstyle ':completion:*' verbose yes
# 補完を試みる順番を設定（変数展開 -> 通常補完 -> パターンマッチ -> 前方一致 -> 曖昧検索 -> 一覧表示 -> 履歴）
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history

# =============================================================================
# 5. プロンプトと Git 情報の表示設定
# =============================================================================
# プロンプトでの変数展開を有効にする
setopt prompt_subst

# バージョン管理システム（Git）から情報を取得する機能の有効化
autoload -Uz vcs_info
# コマンド実行前に毎回 Git 情報を更新する
precmd() { vcs_info }

# Git 情報のフォーマット設定
# 変更の有無をチェックする
zstyle ':vcs_info:git:*' check-for-changes true
# 通常時の表示フォーマット
zstyle ':vcs_info:git:*' formats '%F{#beb3ff}(%b%u%c%F{#beb3ff})%f'
# rebase や merge などのアクション実行中の表示フォーマット
zstyle ':vcs_info:git:*' actionformats '%F{#beb3ff}(%b|%a%u%c%F{#beb3ff})%f'
# unstaged (変更あり・未add) のマーク（赤色の *）
zstyle ':vcs_info:git:*' unstagedstr '%F{#E06C75}*%f'
# staged (add済み) のマーク（緑色の +）
zstyle ':vcs_info:git:*' stagedstr '%F{#93CD7E}+%f'

# 実際のプロンプト表示（左側にシアン色でカレントパス、右側に Git 情報を表示）
PROMPT='%F{cyan}%~%f ${vcs_info_msg_0_} '

# =============================================================================
# 6. エイリアス (Aliases)
# =============================================================================
# クリップボード操作 (xclip) の省略形
alias xc='xclip -selection clipboard'
alias xp='xclip -selection clipboard -o'

# 特定のプロジェクトディレクトリへのショートカット
alias cdm='cd ~/gitlab/ikeda-r/mydocuments/meeting'

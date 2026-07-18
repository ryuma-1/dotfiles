# =============================================================================:
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

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# =============================================================================
# 2. 履歴 (History) の設定
# =============================================================================
export HISTFILE=$HOME/.zsh_history
export HISTSIZE=100000
export SAVEHIST=100000

# =============================================================================
# 3. Zsh 基本設定 (Options)
# =============================================================================
setopt interactive_comments   # コマンドラインでも # 以降をコメントと見なす
setopt extended_glob          # 拡張グロブを有効化 (~ や ^ などを強力なパターンマッチに使用)
setopt magic_equal_subst      # --prefix=/usr などの = 以降でもパスを補完する
setopt prompt_subst           # プロンプトでの変数展開を有効にする (pure テーマが利用)

# =============================================================================
# 4. antidote によるプラグイン管理
# =============================================================================
# antidote 本体の読み込み (Homebrew / git clone どちらでも動くようにパスを探索)
if [[ -f "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" ]]; then
  # git clone でインストールした場合
  source "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh"
elif [[ -f "$(brew --prefix 2>/dev/null)/opt/antidote/share/antidote/antidote.zsh" ]]; then
  # macOS Homebrew でインストールした場合
  source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"
else
  echo "antidote が見つかりません。'brew install antidote' を実行してください。" >&2
  return
fi

# 静的ロード用ファイルが古い/存在しない場合は再生成
zsh_plugins="${ZDOTDIR:-$HOME}/.zsh_plugins.zsh"
zsh_plugins_txt="${ZDOTDIR:-$HOME}/.zsh_plugins.txt"
if [[ ! "$zsh_plugins" -nt "$zsh_plugins_txt" ]]; then
  antidote bundle <"$zsh_plugins_txt" >"$zsh_plugins"
fi
source "$zsh_plugins"

# =============================================================================
# 5. 補完機能 (Completion) の設定
# =============================================================================
# zsh-completions が上記で fpath に追加済みなのでここで compinit を実行
autoload -Uz compinit
compinit

# --- 補完の基本動作 (setopt) ---
setopt auto_param_slash   # ディレクトリ名の補完で末尾に / を自動的に付加する
setopt mark_dirs          # ファイル名の展開でディレクトリにマッチした場合、末尾に / を付加する
setopt list_types         # 補完候補一覧でファイルの種別を識別マーク（/, *, @ など）で表示する
setopt auto_menu          # 補完キー連打で順に補完候補を自動で選択する
setopt auto_param_keys    # カッコの対応などを自動的に補完する
setopt complete_in_word   # 語の途中でもカーソル位置で補完を試みる
setopt always_last_prompt # カーソル位置は保持したままファイル名一覧を順次その場で表示する
setopt list_packed        # 補完候補の一覧を詰めて表示し、画面を節約する

# --- zstyle を使った詳細な補完設定 ---
zstyle ':completion:*' menu true select
# macOS(BSD形式:LSCOLORS) と Linux(GNU形式:LS_COLORS) で変数が異なるため分岐
if [[ "$OSTYPE" == darwin* ]]; then
  zstyle ':completion:*' list-colors "${(s.:.)LSCOLORS}"
else
  zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
fi
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' ignore-parents parent pwd ..
zstyle ':completion:*:sudo:*' command-path $PATH
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history

# =============================================================================
# 6. プラグイン固有の初期化設定
# =============================================================================

# --- pure プロンプト ---
# vcs_info や独自 PROMPT は pure に置き換え済みのため削除
autoload -U promptinit
promptinit
prompt pure

# --- zsh-history-substring-search ---
# 上下矢印キーで履歴の部分文字列検索を行う
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
bindkey -M vicmd 'k' history-substring-search-up
bindkey -M vicmd 'j' history-substring-search-down

# --- zsh-autosuggestions (お好みで調整可) ---
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# --- rupa/z ---
# `z <キーワード>` でよく使うディレクトリへジャンプ可能

# =============================================================================
# 7. エイリアス (Aliases)
# =============================================================================
# クリップボード操作の省略形 (macOS: pbcopy/pbpaste, Linux: xclip)
if [[ "$OSTYPE" == darwin* ]]; then
  alias xc='pbcopy'
  alias xp='pbpaste'
else
  alias xc='xclip -selection clipboard'
  alias xp='xclip -selection clipboard -o'
fi

# 特定のプロジェクトディレクトリへのショートカット
alias cdm='cd ~/gitlab/ikeda-r/mydocuments/meeting'

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

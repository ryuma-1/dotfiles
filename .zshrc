# =============================================================================:
# 1. 環境変数・PATHの設定
# =============================================================================

# PATH の重複を自動で取り除く (遅延初期化で同じパスが再追加されても増えないようにする)
typeset -U path PATH

# 基本のPATH設定
export PATH="$HOME/.local/bin:$PATH"

# --- rbenv (遅延初期化) ---
# shims を PATH に直接入れておけば ruby / gem / bundle などは init なしで動く．
# `rbenv init -` は rbenv コマンド自体 (rbenv shell など) を初めて使うときに実行する．
export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
export RBENV_SHELL=zsh
function rbenv() {
  unfunction rbenv
  eval "$(command rbenv init - --no-rehash zsh)"
  rbenv "$@"
}

# --- NVM (遅延初期化) ---
# nvm.sh の読み込みは重いため起動時には行わず，default の node だけを PATH に追加する．
# (node / npm / npx は Neovim などシェル関数を経由しないツールからもそのまま使える)
# nvm コマンド自体は初めて使うときに nvm.sh を読み込む．
export NVM_DIR="${XDG_CONFIG_HOME:+${XDG_CONFIG_HOME}/nvm}"
export NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

function _nvm_default_bin() {
  local alias_name=""
  local -a candidates
  [[ -r "$NVM_DIR/alias/default" ]] && alias_name="$(<"$NVM_DIR/alias/default")"
  alias_name="${alias_name#v}"

  # system の node を使う設定なら何もしない
  [[ "$alias_name" == system ]] && return

  # 22 や 22.1 のようなバージョン指定なら，該当するインストール済みの最新版を選ぶ
  if [[ "$alias_name" == [0-9]* ]]; then
    candidates=("$NVM_DIR"/versions/node/v${alias_name}(|.*)(N/nOn))
  fi
  # lts/* や node など名前付きのエイリアスは，インストール済みの最新版で代用する
  (( ${#candidates} )) || candidates=("$NVM_DIR"/versions/node/v*(N/nOn))

  (( ${#candidates} )) && print -r -- "${candidates[1]}/bin"
}
_nvm_bin="$(_nvm_default_bin)"
[[ -n "$_nvm_bin" ]] && export PATH="$_nvm_bin:$PATH"
unset _nvm_bin
unfunction _nvm_default_bin

function nvm() {
  unfunction nvm
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # nvm 本体を読み込む
  [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # nvm の補完機能を読み込む
  nvm "$@"
}

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# go
# `go env GOPATH` は起動のたびに go バイナリを実行するため，既定値 ($HOME/go) を直接使う
export PATH="$PATH:/usr/local/go/bin"
export PATH="$PATH:${GOPATH:-$HOME/go}/bin"

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

# zsh-vi-mode の再帰エラー対策として ZLE エンジンを使用
ZVM_READKEY_ENGINE=$ZVM_READKEY_ENGINE_ZLE

# 全モード共通で jk を脱出キーに設定
ZVM_VI_ESCAPE_BINDKEY=jk

# オペレータ待機モードの脱出キーは vicmd キーマップに束縛されるため，
# jk のままだとノーマルモードの j が jk の前置キーとなり KEYTIMEOUT 分の遅延が発生する．
# ノーマルモードの j を即時反応させるため ESC のみにする．
ZVM_VI_OPPEND_ESCAPE_BINDKEY='^['

# Vim の clipboard=unnamedplus と同じく，ヤンク・削除をシステムクリップボードへ同期する．
# コピー/貼り付けコマンドは pbcopy/pbpaste などをプラグインが自動検出する．
ZVM_SYSTEM_CLIPBOARD_ENABLED=true

# =============================================================================
# 4. antidote によるプラグイン管理
# =============================================================================
# antidote 本体の読み込み (Homebrew / git clone どちらでも動くようにパスを探索)
# `brew --prefix` は外部コマンドの実行になるため，既知のパスを順に確認する
for _antidote_path in \
  "${ZDOTDIR:-$HOME}/.antidote/antidote.zsh" \
  "${HOMEBREW_PREFIX:-/opt/homebrew}/opt/antidote/share/antidote/antidote.zsh" \
  "/usr/local/opt/antidote/share/antidote/antidote.zsh" \
  "/home/linuxbrew/.linuxbrew/opt/antidote/share/antidote/antidote.zsh"
do
  [[ -f "$_antidote_path" ]] && break
  _antidote_path=""
done

if [[ -n "$_antidote_path" ]]; then
  source "$_antidote_path"
  unset _antidote_path
else
  unset _antidote_path
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
# compinit は起動時には実行せず，最初に Tab が押されたときに実行する (遅延初期化)．
# zsh-completions が上記で fpath に追加済みなので，そのまま compinit で認識される．
autoload -Uz compinit

function _lazy_compinit() {
  # .zcompdump が 24 時間以上古ければフルチェック，そうでなければキャッシュを使う．
  # -i: 安全でないディレクトリがあっても確認プロンプトを出さずに無視する
  #     (ZLE ウィジェット内では y/n の入力待ちができないため)
  if [[ -n ${ZDOTDIR:-$HOME}/.zcompdump(#qN.mh+24) ]]; then
    compinit -i
  else
    compinit -C
  fi

  # bun の補完 (内部で compdef を使うため compinit の後に読み込む)
  [ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

  # 以降の Tab は通常の補完ウィジェットに戻す
  bindkey -M viins '^I' expand-or-complete
  bindkey -M emacs '^I' expand-or-complete

  # 今回押された Tab の分の補完を実行する
  zle expand-or-complete
}
zle -N _lazy_compinit
bindkey -M viins '^I' _lazy_compinit
bindkey -M emacs '^I' _lazy_compinit

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
# (zstyle は設定値を登録するだけなので compinit より前に書いても問題ない)
zstyle ':completion:*' menu true select
# 補完メニューの候補選択を Ctrl+hjkl で行う (menuselect キーマップは zsh/complist が提供)
zmodload zsh/complist
bindkey -M menuselect '^h' backward-char
bindkey -M menuselect '^j' down-line-or-history
bindkey -M menuselect '^k' up-line-or-history
bindkey -M menuselect '^l' forward-char
# list-colors は GNU 形式 (LS_COLORS) しか解釈しない (BSD 形式の LSCOLORS は不可)
# LS_COLORS は自動では設定されないので、Linux は dircolors で生成し、
# dircolors の無い macOS は BSD ls のデフォルト配色 (exfxcxdxbxegedabagacad) 相当を直接指定する
if [[ -z "$LS_COLORS" ]]; then
  if (( $+commands[dircolors] )); then
    eval "$(dircolors -b)"
  else
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43'
  fi
fi
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
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
# vi モードごとにプロンプト記号を切り替える (prompt pure の初期化時に読まれるため先に定義)
# insert モード
PURE_PROMPT_SYMBOL='→'
# normal / visual モード
PURE_PROMPT_VICMD_SYMBOL='N'
autoload -U promptinit
promptinit
prompt pure

# add したときにマークを追加
zstyle ':prompt:pure:git:dirty' detailed yes

# ▼▼▼ ここから追加：pure の配色カスタマイズ ▼▼▼
zstyle ':prompt:pure:path' color '#00FFFF' # パスを明るいシアンに
zstyle ':prompt:pure:prompt:success' color '#ad9eff'  # 成功時
# ▲▲▲ ここまで追加 ▲▲▲

# --- zsh-autosuggestions (お好みで調整可) ---
export ZSH_AUTOSUGGEST_STRATEGY=(history completion)

# --- zsh-history-substring-search ---
# 上下矢印キーで履歴の部分文字列検索を行う
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# zsh-vi-mode の初期化完了後に vicmd(ノーマルモード)用のキーを設定
# ※ zsh-vi-mode がキーマップを再構築するため、この関数の中で設定する必要がある
function zvm_after_init() {
  bindkey -M vicmd 'k' history-substring-search-up
  bindkey -M vicmd 'j' history-substring-search-down

  # zsh-vi-mode が viins を再構築して Tab の割り当てが戻されるため，ここで再設定する．
  # ただし既に compinit 済み (= _lazy_compinit が実行済み) なら通常の補完のままにする．
  if (( ! $+functions[compdef] )); then
    bindkey -M viins '^I' _lazy_compinit
  fi
}

# p/P をシステムクリップボードからの貼り付けに差し替える
# ※ vicmd/visual のキーは初回ノーマルモード移行時に遅延登録されるため，
#    zvm_after_init ではなくこの関数の中で上書きしないとデフォルトに戻される
function zvm_after_lazy_keybindings() {
  zvm_bindkey vicmd  'p' zvm_paste_clipboard_after
  zvm_bindkey vicmd  'P' zvm_paste_clipboard_before
  zvm_bindkey visual 'p' zvm_visual_paste_clipboard
  zvm_bindkey visual 'P' zvm_visual_paste_clipboard
}

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

# 特定のプロジェクトディレクトリへのショートカットのエイリアス
alias cdm='cd ~/gitlab/ikeda-r/mydocuments/meeting'

# 一時的なメモをグローバル上で作成するためのエイリアス
alias m='nvim ~/Documents/tmp.md'

# 一時的なメモをプロジェクトのローカル上で起動するためのエイリアス
mp() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/Local" ]]; then
            nvim "$dir/Local/tmp.md"
            return
        fi

        dir="$(dirname "$dir")"
    done

    echo "Local フォルダが見つかりませんでした。"
}

# プロジェクトの個人タスクを開くためのエイリアス
task() {
    local dir="$PWD"

    while [[ "$dir" != "/" ]]; do
        if [[ -d "$dir/Local" ]]; then
            nvim "$dir/Local/task.md"
            return
        fi

        dir="$(dirname "$dir")"
    done

    echo "Local フォルダが見つかりませんでした。"
}

# md-cosense-bridge の起動エイリアス
mts () {
  local md_path=$(realpath "$1")
  cd ~/git/md-cosense-bridge || return 1
  npm start -- import nompedia test "$md_path"
  cat input.txt | xc
  cd - > /dev/null
}

# bun completions は compdef を使うため _lazy_compinit 内で読み込む (5. 補完機能 を参照)

if [[ -f ~/.zshrc.local ]]; then
    source ~/.zshrc.local
fi

# wft: share state across machines via pCloud
export WFT_STATE_DIR="$HOME/pCloudDrive/wft"

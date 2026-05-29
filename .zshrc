# ----------------------------------------------
# Git ブランチ名表示の設定
# ----------------------------------------------
autoload -Uz vcs_info
precmd() { vcs_info }

# %c (staged) と %u (unstaged) をブランチ名の後ろに追加します
zstyle ':vcs_info:git:*' formats '%F{147}(%b)%f%c%u'
zstyle ':vcs_info:git:*' actionformats '%F{147}(%b|%a)%f%c%u'
zstyle ':vcs_info:*' check-for-changes true

# git add した場合（staged）は緑色の +
zstyle ':vcs_info:*' stagedstr '%F{green}+%f'

# 変更があるけれど add していない場合（unstaged）は赤色の *
zstyle ':vcs_info:*' unstagedstr '%F{red}*%f'

# ----------------------------------------------
# プロンプト（画面表示）の設定
# ----------------------------------------------
setopt prompt_subst
PROMPT="%F{cyan}%~%f \${vcs_info_msg_0_} "

eval "$(~/.rbenv/bin/rbenv init - zsh)"

export PATH="$PATH:/opt/nvim-linux-x86_64/bin"

# ----------------------------------------------
# 補完 (Completion) の設定（WSL安全対策版）
# ----------------------------------------------
autoload -Uz compinit
compinit -i # ← WSLでのエラーを防ぐために -i を指定

# メニュー補完を有効にする
zstyle ':completion:*' menu true select

# WSL(Linux)の dircolors を利用して補完候補を色付けする
if type dircolors > /dev/null 2>&1; then
    eval "$(dircolors -b)"
fi
zstyle ':completion:*' list-colors $LS_COLORS

# 大文字と小文字を区別しない
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
# ../ の後の補完でPWDを候補から外す
zstyle ':completion:*' ignore-parents parent pwd ..
# sudo の後にコマンドを補完する
zstyle ':completion:*:sudo:*' command-path $PATH
# 補完の詳細な情報を表示する
zstyle ':completion:*' verbose yes
# 補完関数の順序を指定
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history

# ----------------------------------------------
# その他のオプション設定
# ----------------------------------------------
setopt auto_param_slash
setopt mark_dirs
setopt list_types
setopt auto_menu
setopt auto_param_keys
setopt interactive_comments
setopt magic_equal_subst
setopt complete_in_word
setopt always_last_prompt
setopt extended_glob
setopt list_packed

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init -)"
. "$HOME/.cargo/env"

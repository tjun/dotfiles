#!/bin/zsh

# PATHの重複を防ぐ
typeset -U PATH path

# ファイル作成時のデフォルトパーミッション設定
umask 022

bindkey -e # emacs bind
export EDITOR='vim'

setopt auto_cd
setopt auto_pushd
setopt pushd_ignore_dups
setopt auto_list
setopt auto_menu
setopt auto_remove_slash
setopt auto_param_keys
setopt auto_param_slash
setopt mark_dirs

HISTFILE=$HOME/.zsh-history
HISTSIZE=1000000
SAVEHIST=1000000
setopt share_history
setopt hist_ignore_all_dups
setopt hist_reduce_blanks
setopt hist_ignore_space
setopt hist_save_no_dups
setopt inc_append_history
setopt extended_history

setopt prompt_subst
setopt no_beep
setopt no_list_beep
setopt no_hist_beep
setopt no_flow_control

# setopt print_exit_value
setopt notify

autoload -Uz compinit
if [ $(date +'%j') != $(/usr/bin/stat -f '%Sm' -t '%j' ${ZDOTDIR:-$HOME}/.zcompdum* 2>/dev/null) ]; then
  compinit
else
  compinit -C
fi

autoload -Uz bashcompinit && bashcompinit

# auto complate with case insensitive
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

if type brew &>/dev/null
then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

if [ -x "$(which zoxide)" ]; then
  eval "$(zoxide init zsh)"
  # alias cd='z'
  alias d='zi'
fi

function git-nb() {
  if [ $# -eq 2 ]; then
    branch="${USER}/$1/$2"
  elif [ $# -eq 1 ]; then
    branch="${USER}/$1"
  else
    echo "Usage: git nb [type] name   or   git nb name"
    return 1
  fi

  echo "Creating branch: $branch"
  git switch -c "$branch"
}

alias g='git'
alias ga='git add -p'
alias gdc='git dc'
alias gcm='git ci -m'
alias gs='git status'
alias gr='git restore'
alias gsw='git switch'
alias gp='git pull -S origin $(git rev-parse --abbrev-ref HEAD)'
alias gps='git push origin HEAD'
alias gpso='gps && gh pr create --web'
alias gl='git log -p'
alias gm='git co $(git main)'
alias gnb='git-nb'
alias gnbf='git bf'
alias gcb='git current-branch'
alias gsee='gh repo view --web'
alias gf='git fetch origin'
alias gb='git recent-branch'
alias gpr='git fw'
alias gwl='git worktree list'
alias gwa='git wa'
# alias cdu='cd $(git rev-parse --show-toplevel)'
alias cdu='cd $(git rev-parse --git-common-dir | sed "s/\/\.git$//")'
alias gca='gcloud auth login --update-adc'

alias update-serena='uvx --from git+https://github.com/oraios/serena serena project index $(pwd)'

# if WSL
if [[ -f /proc/version ]] && grep -iq Microsoft /proc/version; then
  eval "$(ssh-agent -s)"
  alias pbcopy="/mnt/c/windows/system32/clip.exe"
  export GOROOT=/usr/local/go
  export GOPATH=$HOME/dev
  export PATH=$GOPATH/bin:$GOROOT/bin:$PATH
else
  export HOMEBREW_ANALYTICS_DEBUG=1
  export GOROOT=$(go env GOROOT)
  export GOPATH=$HOME/dev
  export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
  export GODEBUG=asyncpreemptoff=1 # To fix terraform issue
fi

# ssh-agent
if [ -z "$SSH_AUTH_SOCK" ]; then
    eval "$(ssh-agent -s)"
fi

# sheldon
eval "$(sheldon source)"

if [ -e $HOME/.cargo/env ]; then
  source $HOME/.cargo/env
fi

if [ -x "$(which eza)" ]; then
  alias la="eza -a --oneline"
  alias ll="eza -l --git -g -h"
  alias l="eza -l --git -h --no-user --no-permissions --no-time"
  alias ls="eza"
else
  alias l="ls -l"
  alias ls='ls -GF'
  alias ll='ls -lAF'  # Show long file information
  alias la='ls -AF'   # Show hidden files
fi

if [ -x "$(which gcloud)" ]; then
  PATH=$PATH:$(brew --prefix)/share/google-cloud-sdk/bin
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
fi

#if [ -x "$(which podman)" ]; then
#  alias docker="podman"
#fi

if [ -x "$(which kubectl)" ]; then
  alias k="nocorrect kubectl"
  alias kg="kubectl get "
  alias kgy="kubectl get -o yaml "
  alias kd="kubectl describe "
  source <(kubectl completion zsh)
  complete -o default -F __start_kubectl k
  #RPROMPT='%{$fg[blue]%}($ZSH_KUBECTL_PROMPT)%{$reset_color%}'
fi

#if [ -x "$(which atuin)" ]; then
#  eval "$(atuin init zsh)"
#fi



if [ -x "$(which bat)" ]; then
  alias cat='bat'
fi

if [ -x "$(which gojq)" ]; then
  alias jq='gojq'
  alias yq='gojq --yaml-input --yaml-output'
fi

if [ -x "$(which mise)" ]; then
  eval "$(mise activate zsh)"
fi

if [ -x "$(which tenv)" ]; then
  source "$HOME/.tenv/completion.zsh"
fi

if [ -x "$(which pyenv)" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="${PYENV_ROOT}/bin:$HOME/.local/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
fi

if [ -x "$(which direnv)" ]; then
  eval "$(direnv hook zsh)"
fi

# if [ -e "/opt/homebrew/opt/libpq/bin" ];then
#   export PATH="${PATH}:/opt/homebrew/opt/libpq/bin"
# fi

if [ -e "/opt/homebrew/opt/postgresql@16/bin" ];then
  export PATH="${PATH}:/opt/homebrew/opt/postgresql@16/bin"
fi

if [ -e "~/.local/bin" ]; then
  export PATH="~/.local/bin:$PATH"
fi

if [ -x "$(which fzf)" ]; then
  export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_OPTS='--preview "bat  --color=always --style=header,grid --line-range :100 {}"'
fi

function ghq-fzf() {
  local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
  if [ -n "$src" ]; then
    BUFFER="cd $(ghq root)/$src"
    zle accept-line
  fi
  zle -R -c
}
zle -N ghq-fzf
bindkey '^]' ghq-fzf

# add local settings
if [ -e $HOME/.zshrc-local ]; then
  source ~/.zshrc-local
fi

# prompt
function parse_git_branch() {
  if git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    ref=$(git symbolic-ref HEAD 2>/dev/null) || return 1
    echo "(${ref#refs/heads/})"
  else
    echo ""
  fi
}

function prompt_color() {
  PS1=$'\n'"%F{yellow}%~%f %F{grey}\$(parse_git_branch)%f"$'\n'"→ "
}

if [ -n "$PS1" ]; then
  prompt_color
fi

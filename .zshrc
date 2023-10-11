bindkey -e # emacs bind
export HOMEBREW_ANALYTICS_DEBUG=1
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

setopt no_beep
setopt no_list_beep
setopt no_hist_beep
setopt no_flow_control

# setopt print_exit_value
setopt notify
# zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'

alias g='git'
alias ga='git add -p'
alias gdc='git dc'
alias gcm='git ci -m'
alias gs='git status'
alias gsw='git swtich'
alias gp='git pull -S origin $(git rev-parse --abbrev-ref HEAD)'
alias gps='git push origin HEAD'
alias gpso='gps && gh pr create --web'
alias gl='git log -p'
alias gm='git co $(git main)'
alias gnb='git co -b'
alias gcb='git current-branch'
alias gsee='gh repo view --web'

# sheldon
eval "$(sheldon source)"

if [ -x "$(which go)" ]; then
  export GOROOT=$(go env GOROOT)
  export GOPATH=$HOME/dev
  export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
fi

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


if [ -e $HOME/google-cloud-sdk ]; then
  #zplug "$HOME/gcp/google-cloud-sdk/completion.zsh.inc", from:"local", defer:2
  source $HOME/google-cloud-sdk/completion.zsh.inc
  source $HOME/google-cloud-sdk/path.zsh.inc
  export PATH=$PATH:~/google-cloud-sdk/bin
fi

if [ -x "$(which kubectl)" ]; then
  alias k="nocorrect kubectl"
  alias kg="kubectl get "
  alias kgy="kubectl get -o yaml "
  alias kd="kubectl describe "
  source <(kubectl completion zsh)
  complete -o default -F __start_kubectl k
fi

RPROMPT='%{$fg[blue]%}($ZSH_KUBECTL_PROMPT)%{$reset_color%}'
# KUBE_PS1_SYMBOL_ENABLE='false'
# RPROMPT='$(kube_ps1)'

if [ -x "$(which bat)" ]; then
  alias cat='bat'
fi

if [ -x "$(which dog)" ]; then
  alias dig='dog'
fi

if [ -x "$(which gojq)" ]; then
  alias jq='gojq'
  alias yq='gojq --yaml-input --yaml-output'
fi

if [ -x "$(which fzf)" ]; then
  export FZF_CTRL_T_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
  export FZF_CTRL_T_OPTS='--preview "bat  --color=always --style=header,grid --line-range :100 {}"'
fi

if [ -x "$(which navi)" ]; then
  eval "$(navi widget zsh)" # ctrl-g to launch a widget
fi

if [ -x "$(which zoxide)" ]; then
  eval "$(zoxide init zsh)"
  alias cd='z'
fi

if [ -x "$(which pyenv)" ]; then
  export PYENV_ROOT="$HOME/.pyenv"
  export PATH="$PYENV_ROOT/bin:$HOME/.local/bin:$PATH"
  eval "$(pyenv init --path)"
  eval "$(pyenv init -)"
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

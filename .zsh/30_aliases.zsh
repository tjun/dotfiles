alias p="print -l"

alias ga='git add -p'
alias gdc='git dc'
alias gcm='git ci -m'
alias gs='git status'
alias gsw='git swtich'
alias gp='git pull origin $(git rev-parse --abbrev-ref HEAD)'
alias gps='git push origin HEAD'
alias gpso='gps && gh repo view --web'
alias gl='git log -p'
alias gm='git co master'
alias gnb='git co -b'
alias gcb='git current-branch'
alias gsee='gh repo view --web'

# Common aliases
# alias ..='cd ..'
alias l="ls -l"
alias ls='ls -GF'
alias ld='ls -ld'          # Show info about the directory
alias lla='ls -lAF'        # Show hidden all files
alias ll='ls -lAF'          # Show long file information
alias la='ls -AF'          # Show hidden files
# alias lx='ls -lXB'         # Sort by extension
# alias lk='ls -lSr'         # Sort by size, biggest last
# alias lc='ls -ltcr'        # Sort by and show change time, most recent last
# alias lu='ls -ltur'        # Sort by and show access time, most recent last
# alias lt='ls -ltr'         # Sort by date, most recent last
# alias lr='ls -lR'          # Recursive ls

# The ubiquitous 'll': directories first, with alphanumeric sorting:
#alias ll='ls -lv --group-directories-first'

alias g='git'
#alias cp="${ZSH_VERSION:+nocorrect} cp -i"
#alias mv="${ZSH_VERSION:+nocorrect} mv -i"
#alias mkdir="${ZSH_VERSION:+nocorrect} mkdir"

# autoload -Uz zmv
# alias zmv='noglob zmv -W'

# alias job='jobs -l'
# alias grep='grep --color=auto'
# alias fgrep='fgrep --color=auto'
# alias egrep='egrep --color=auto'

alias diff='diff -u'
alias vi="vim"
alias emacs="TERM=xterm-256color emacs -nw"
alias e='emacs'

# if has "emojify"; then
#     alias -g E='| emojify'
# fi

if [ -x "`which docker`" ]; then
  alias docker-kill-all='docker kill $(docker ps -aq)'
  alias docker-rm-all='docker rm $(docker ps -aq)'
  alias docker-delete-all-volume='docker volume rm $(docker volume ls -qf dangling=true)'
fi

if [ -x "`which kubectl`" ]; then
  alias k="nocorrect kubectl"
  alias kg="kubectl get "
  alias kgy="kubectl get -o yaml "
  alias kd="kubectl describe "
fi

if [ -x "`which bat`" ]; then
  alias cat='bat'
fi

if [ -x "`which gojq`" ]; then
  alias jq='gojq'
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

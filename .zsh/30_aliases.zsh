alias p="print -l"

# For mac, aliases
if is_osx; then
    has "qlmanage" && alias ql='qlmanage -p "$@" >&/dev/null'
    alias gvim="open -a MacVim"
fi

if has 'git'; then
    alias ga='git add -p'
    alias gd='git dc'
    alias gcm='git ci -m'
    alias gs='git status'
    alias gp='git pull origin $(git rev-parse --abbrev-ref HEAD)'
    alias gps='git push origin HEAD'
    alias gpso='gps && g see'
    alias gl='git log -p'
    alias gm='git co master'
    alias gnb='git co -b'
    alias gcb='git current-branch'
fi

if (( $+commands[gls] )); then
    alias ls='gls -F --color --group-directories-first'
elif (( $+commands[ls] )); then
    if is_osx; then
        alias ls='ls -GF'
    else
    alias ls='ls -F --color'
    fi
fi

# Common aliases
alias ..='cd ..'
alias ld='ls -ld'          # Show info about the directory
alias lla='ls -lAF'        # Show hidden all files
alias ll='ls -lAF'          # Show long file information
alias la='ls -AF'          # Show hidden files
alias lx='ls -lXB'         # Sort by extension
alias lk='ls -lSr'         # Sort by size, biggest last
alias lc='ls -ltcr'        # Sort by and show change time, most recent last
alias lu='ls -ltur'        # Sort by and show access time, most recent last
alias lt='ls -ltr'         # Sort by date, most recent last
alias lr='ls -lR'          # Recursive ls

# The ubiquitous 'll': directories first, with alphanumeric sorting:
#alias ll='ls -lv --group-directories-first'

alias g='git'
#alias cp="${ZSH_VERSION:+nocorrect} cp -i"
#alias mv="${ZSH_VERSION:+nocorrect} mv -i"
#alias mkdir="${ZSH_VERSION:+nocorrect} mkdir"

autoload -Uz zmv
alias zmv='noglob zmv -W'

alias job='jobs -l'
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'

# Use if colordiff exists
if has 'colordiff'; then
    alias diff='colordiff -u'
else
    alias diff='diff -u'
fi

alias vi="vim"
alias emacs="TERM=xterm-256color emacs -nw"
alias e='emacs'

# Use plain vim.
alias nvim='vim -N -u NONE -i NONE'

# The first word of each simple command, if unquoted, is checked to see
# if it has an alias. [...] If the last character of the alias value is
# a space or tab character, then the next command word following the
# alias is also checked for alias expansion
alias sudo='sudo '
if is_osx; then
    alias sudo="${ZSH_VERSION:+nocorrect} sudo "
fi

# Global aliases
alias -g G='| grep'
alias -g W='| wc'
alias -g X='| xargs'
alias -g F='| "$(available $INTERACTIVE_FILTER)"'
alias -g S="| sort"
alias -g V="| tovim"
alias -g N=" >/dev/null 2>&1"
alias -g N1=" >/dev/null"
alias -g N2=" 2>/dev/null"
alias -g VI='| xargs -o vim'

multi_grep() {
    local std_in="$(cat <&0)" word

    for word in "$@"
    do
        std_in="$(echo "${std_in}" | command grep "$word")"
    done

    echo "${std_in}"
}

(( $+galiases[H] )) || alias -g H='| head'
(( $+galiases[T] )) || alias -g T='| tail'

if has "emojify"; then
    alias -g E='| emojify'
fi

if has "jq"; then
    alias -g J='| jq .'
fi

if is_osx; then
    alias -g CP='| pbcopy'
    alias -g CC='| tee /dev/tty | pbcopy'
fi


# less
alias -g LL="| less"

alias -g GB='$(git_branch)'

alias t="tree -C"

alias l="ls -l"

if has "docker"; then
  alias docker-kill-all='docker kill $(docker ps -aq)'
  alias docker-rm-all='docker rm $(docker ps -aq)'
  alias docker-delete-all-volume='docker volume rm $(docker volume ls -qf dangling=true)'
fi

if has "kubectl"; then
  alias k=kubectl
  alias kg="kubectl get "
  alias kgy="kubectl get -o yaml "
  alias kd="kubectl describe "
fi

if has "bat"; then
  alias cat='bat'
fi

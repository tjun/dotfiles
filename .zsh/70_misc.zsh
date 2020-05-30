# Important
zstyle ':completion:*:default' menu select=2

# Completing Groping
zstyle ':completion:*:options' description 'yes'
zstyle ':completion:*:descriptions' format '%F{yellow}Completing %B%d%b%f'
zstyle ':completion:*' group-name ''

# Completing misc
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'
zstyle ':completion:*' verbose yes
zstyle ':completion:*' completer _expand _complete _match _prefix _approximate _list _history
zstyle ':completion:*:*files' ignored-patterns '*?.o' '*?~' '*\#'
zstyle ':completion:*' use-cache true
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters
zstyle ':completion:*:sudo:*' command-path /usr/local/sbin /usr/local/bin /usr/sbin /usr/bin /sbin /bin


# Directory
zstyle ':completion:*:cd:*' ignore-parents parent pwd
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}

# default: --
zstyle ':completion:*' list-separator '-->'
zstyle ':completion:*:manuals' separate-sections true

zstyle ':vcs_info:*' enable git
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats '%b'

# peco
zle -N peco-src
bindkey '^]' peco-src

autoload -Uz history-search-end
autoload -Uz modify-current-argument
autoload -Uz smart-insert-last-word
autoload -Uz terminfo
# autoload -Uz vcs_info
# autoload -Uz promptinit; promptinit
# autoload -Uz zcalc
# autoload -Uz zmv
autoload -Uz run-help-git
# autoload -Uz run-help-svk
# autoload -Uz run-help-svn

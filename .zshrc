umask 022
limit coredumpsize 0
bindkey -e

if [[ -z "$TMUX" ]] && [[ -z "$STY" ]]; then
  # tmux が起動していなければ起動します。
  # tmux を起動した場合は tmux.rc.zsh の中で exit を呼ぶので、このコードブロックの外側は実行されません。
  . "${HOME}/.zsh/exports.rc.zsh"
  . "${HOME}/.zsh/tmux.rc.zsh"
fi

### Added by Zinit's installer
if [[ ! -f $HOME/.zinit/bin/zinit.zsh ]]; then
    print -P "%F{33}▓▒░ %F{220}Installing %F{33}DHARMA%F{220} Initiative Plugin Manager (%F{33}zdharma/zinit%F{220})…%f"
    command mkdir -p "$HOME/.zinit" && command chmod g-rwX "$HOME/.zinit"
    command git clone https://github.com/zdharma/zinit "$HOME/.zinit/bin" && \
        print -P "%F{33}▓▒░ %F{34}Installation successful.%f%b" || \
        print -P "%F{160}▓▒░ The clone has failed.%f%b"
fi

# autoload -Uz compinit && compinit -u

source "$HOME/.zinit/bin/zinit.zsh"
autoload -Uz _zinit
(( ${+_comps} )) && _comps[zinit]=_zinit

# autoload -Uz add-zsh-hook
# autoload -Uz cdr
# autoload -Uz chpwd_recent_dirs
# autoload -Uz run-help
autoload -Uz colors && colors
# autoload -Uz is-at-least

# Load a few important annexes, without Turbo
# (this is currently required for annexes)
zinit light-mode for \
    zinit-zsh/z-a-patch-dl \
    zinit-zsh/z-a-as-monitor \
    zinit-zsh/z-a-bin-gem-node

### End of Zinit's installer chunk

# zinit snippet "${HOME}/.zsh/00_variables.zsh"
# zinit snippet "${HOME}/.zsh/10_utils.zsh"
zinit snippet "${HOME}/.zsh/30_aliases.zsh"
zinit snippet "${HOME}/.zsh/50_setopt.zsh"
# zinit snippet "${HOME}/.zsh/70_misc.zsh"

# Two regular plugins loaded without investigating.
zplugin ice wait'0' atload'_zsh_autosuggest_start'
zinit light zsh-users/zsh-autosuggestions

zplugin ice atinit"zpcompinit; zpcdreplay"
zinit light zdharma/fast-syntax-highlighting
zplugin ice blockf; zinit light zsh-users/zsh-completions

# Plugin history-search-multi-word loaded with investigating.
zinit load zdharma/history-search-multi-word

zinit light 'sei40kr/zsh-tmux-rename'

zinit light "superbrothers/zsh-kubectl-prompt"
RPROMPT='%{$fg[blue]%}($ZSH_KUBECTL_PROMPT)%{$reset_color%}'

# Load the pure theme, with zsh-async library that's bundled with it.
# zinit ice compile'(pure|async).zsh' pick'async.zsh' src'pure.zsh'
zinit ice zinit ice pick"async.zsh" src"pure.zsh" atload'!prompt_pure_precmd' lucid nocd
zinit light 'sindresorhus/pure'

# Scripts that are built at install (there's single default make target, "install",
# and it constructs scripts by `cat'ing a few files). The make'' ice could also be:
# `make"install PREFIX=$ZPFX"`, if "install" wouldn't be the only, default target.
# zinit ice as"program" pick"$ZPFX/bin/git-*" make"PREFIX=$ZPFX"
# zinit light tj/git-extras

# Handle completions without loading any plugin, see "clist" command.
# This one is to be ran just once, in interactive session.
# zinit creinstall %HOME/.zsh

if [ -x "`which docker`" ]; then
    zinit ice wait'!0'; zinit light "felixr/docker-zsh-completion"
fi

if [ -x "`which hub`" ]; then
    zinit ice wait'!0'; zinit load "glidenote/hub-zsh-completion"
fi

if [ -x "`which kubectl`" ]; then
  source <(kubectl completion zsh)
  complete -o default -F __start_kubectl k
fi

# zinit load  "chrissicool/zsh-256color"
# 利用可能なエイリアスを使わずにコマンドを実行した際に通知するプラグインです。
zplugin light 'djui/alias-tips'
# fzf を使ったウィジェットが複数バンドルされたプラグインです。
zplugin light 'mollifier/anyframe'
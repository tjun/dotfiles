umask 022
limit coredumpsize 0
bindkey -e

if [[ -f ~/.zplug/init.zsh ]]; then
    export ZPLUG_LOADFILE=~/.zsh/zplug.zsh
    # For development version of zplug
    source ~/.zplug/init.zsh

#    if ! zplug check --verbose; then
#        printf "Install? [y/N]: "
#        if read -q; then
#            echo; zplug install
#        fi
#        echo
#    fi
    zplug load
else
   echo "install zplug with the following command:"
   echo "curl -sL zplug.sh/installer | zsh"
   return
fi

if ! is_tmux_running && shell_has_started_interactively; then
    tmux
fi

ZPLUG_PROTOCOL=ssh

zplug "zplug/zplug", hook-build:'zplug --self-manage'
zplug "mafredri/zsh-async", from:github
PURE_PROMPT_SYMBOL="❯"
zplug sindresorhus/pure, use:pure.zsh, from:github, as:theme

zplug "~/.zsh", from:local, use:"<->_*.zsh"

zplug "chrissicool/zsh-256color"

#zplug "b4b4r07/enhancd", use:init.sh
zplug "zsh-users/zsh-completions", lazy:true
zplug "zsh-users/zsh-history-substring-search", defer:3
zplug "zsh-users/zsh-syntax-highlighting", defer:2

#zplug 'Valodim/zsh-curl-completion'

zplug "superbrothers/zsh-kubectl-prompt", defer:2
RPROMPT='%{$fg[blue]%}($ZSH_KUBECTL_PROMPT)%{$reset_color%}'


if [ -x "`which docker`" ]; then
    zplug "felixr/docker-zsh-completion", lazy:true
fi

if [ -x "`which hub`" ]; then
    zplug "glidenote/hub-zsh-completion", lazy:true
fi

#OEDO_COLORSCHEME=mita
#zplug 'tjun/oedo.zsh', use:"oedo.zsh"


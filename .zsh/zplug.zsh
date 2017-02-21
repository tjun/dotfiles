ZPLUG_SUDO_PASSWORD=
ZPLUG_PROTOCOL=ssh

zplug "zplug/zplug", hook-build:'zplug --self-manage'

zplug "~/.zsh", from:local, use:"<->_*.zsh"

zplug "chrissicool/zsh-256color"

#zplug "b4b4r07/enhancd", use:init.sh
zplug "zsh-users/zsh-completions"
zplug "zsh-users/zsh-history-substring-search", defer:3
zplug "zsh-users/zsh-syntax-highlighting", defer:2

zplug 'Valodim/zsh-curl-completion'

if [ -x "`which docker`" ]; then
    zplug 'felixr/docker-zsh-completion'
fi

if [ -x "`which hub`" ]; then
    zplug "glidenote/hub-zsh-completion"
fi

OEDO_COLORSCHEME=mita
zplug 'tjun/oedo.zsh', use:"oedo.zsh"



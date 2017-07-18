# brew
export PATH=/usr/local/bin:$PATH

if [ -x "`which go`" ]; then
  export GOROOT=`go env GOROOT`
  export GOPATH=$HOME/dev
  export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
fi

if [ -e $HOME/.nodebrew ]; then
  export PATH=$HOME/.nodebrew/current/bin:$PATH
  nodebrew use v6.11.1
fi

if [ -e $HOME/.rbenv ]; then
  export PATH="$HOME/.rbenv/bin:$PATH"
  eval "$(rbenv init -)"
fi

if [ -x "`which pyenv`" ]; then
  eval "$(pyenv init -)"
fi

if [ -e $HOME/gcp/google-cloud-sdk ]; then
  source $HOME/gcp/google-cloud-sdk/completion.zsh.inc
  source $HOME/gcp/google-cloud-sdk/path.zsh.inc
  export PATH=$PATH:~/gcp/google-cloud-sdk/bin
  export PATH=$PATH:~/gcp/google-cloud-sdk/platform/google_appengine
fi

if [ -x "`which kubectl`" ]; then
  source <(kubectl completion zsh)
fi


if [ -e /usr/local/share/git-core/contrib/diff-highlight/diff-highlight ]; then
 export PATH=$PATH:/usr/local/share/git-core/contrib/diff-highlight
fi

export EDITOR='vim'
export LESS='-i -M -R'
export HOMEBREW_ANALYTICS_DEBUG=1

export LANG=ja_JP.UTF-8

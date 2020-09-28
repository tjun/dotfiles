export HOMEBREW_ANALYTICS_DEBUG=1
export EDITOR='vim'

# brew
export PATH=/usr/local/bin:$PATH

if [ -x "`which go`" ]; then
  export GOROOT=`go env GOROOT`
  export GOPATH=$HOME/dev
  export PATH="$GOROOT/bin:$GOPATH/bin:$PATH"
fi

# if [ -e $HOME/.nodebrew ]; then
#   export PATH=$HOME/.nodebrew/current/bin:$PATH
#   nodebrew use v6.17.1
# fi

# if [ -e $HOME/.rbenv ]; then
#   export PATH="$HOME/.rbenv/bin:$PATH"
#   eval "$(rbenv init -)"
# fi

# if [ -e $HOME/.cargo ]; then
#   source $HOME/.cargo/env
#   export RUST_BACKTRACE=1
# fi

# if [ -x "`which python3`" ]; then
#   export PATH=$PATH:/usr/local/lib/python3.6/site-packages
# fi

if [ -e $HOME/gcp/google-cloud-sdk ]; then
  #zplug "$HOME/gcp/google-cloud-sdk/completion.zsh.inc", from:"local", defer:2
  source $HOME/gcp/google-cloud-sdk/completion.zsh.inc
  source $HOME/gcp/google-cloud-sdk/path.zsh.inc
  export PATH=$PATH:~/gcp/google-cloud-sdk/bin
fi

if [ -e $HOME/google-cloud-sdk ]; then
  #zplug "$HOME/gcp/google-cloud-sdk/completion.zsh.inc", from:"local", defer:2
  source $HOME/google-cloud-sdk/completion.zsh.inc
  source $HOME/google-cloud-sdk/path.zsh.inc
  export PATH=$PATH:~/google-cloud-sdk/bin
fi

# if [ -e $HOME/gcp/go_appengine ]; then
#   export PATH=$PATH:~/gcp/go_appengine
# fi

if [ -e $HOME/gcp/google-cloud-sdk/platform/google_appengine ]; then
  export PATH=$HOME/gcp/google-cloud-sdk/platform/google_appengine:$PATH
fi

if [ -e $HOME/gcp/kubernetes/bin ]; then
  export PATH=$PATH:~/gcp/kubernetes/bin
fi

# if [ -e $HOME/.krew/bin ]; then
#   export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"
# fi

# if [ -e /usr/local/share/git-core/contrib/diff-highlight/diff-highlight ]; then
#  export PATH=$PATH:/usr/local/share/git-core/contrib/diff-highlight
# fi

# if [ -e /Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin ]; then
#   export PATH=$PATH:/Library/Internet\ Plug-Ins/JavaAppletPlugin.plugin/Contents/Home/bin
# fi

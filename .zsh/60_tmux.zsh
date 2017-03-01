autoload -Uz vcs_info
zstyle ':vcs_info:*' enable git svn
zstyle ':vcs_info:*' formats '%r'

precmd () {
  LANG=en_US.UTF-8 vcs_info
  if [[ -n ${vcs_info_msg_0_} ]]; then 
	  tmux rename-window $vcs_info_msg_0_
  else
	  tmux rename-window `basename $(pwd)`
  fi
}

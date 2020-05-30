# zstyle ':vcs_info:*' enable git svn
# zstyle ':vcs_info:*' formats '%r'

if [[ "${+commands[tmux]}" == 1 ]]
then
  tmux has-session -t global 2>/dev/null || tmux new-session -ds global \
      && tmux attach-session -t global
  # exit
fi
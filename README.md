# dotfiles

## Setup

Install nanobrew or homebrew first.

- nanobrew: https://github.com/justrach/nanobrew
- homebrew: https://brew.sh/

```console
# download this repo
mkdir -p ~/dev/src/github.com/tjun/
cd ~/dev/src/github.com/tjun/
git clone
cd dotfiles

# Install packages (nanobrew)
nb bundle install Nanobrew
nb bundle install .Nanobrew.local

# or with homebrew
# brew bundle

# set up ssh for github
TBD

# link dotfiles
ln -s ~/dev/src/github.com/tjun/dotfiles/{.zshrc,.zprofile,.inputrc,.vimrc,.gitconfig,.gitignore,.wezterm.lua} ~/
ln -s ~/dev/src/github.com/tjun/dotfiles/karabiner.json ~/.config/karabiner/karabiner.json # after launching karabiner-elements

# Claude Code
mkdir -p ~/.claude
ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/CLAUDE.md ~/.claude/CLAUDE.md
ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/settings.json ~/.claude/settings.json
ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/PLANS.md ~/.claude/PLANS.md
ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/scripts ~/.claude/scripts
ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/skills ~/.claude/skills
ln -sfn ~/dev/src/github.com/tjun/dotfiles/claude/commands ~/.claude/commands
ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/statusline-command.sh ~/.claude/statusline-command.sh

# copy and update files
cp .gitconfig.local ~/ # and add sigining key path
cp .ssh/config ~/.ssh/ # and add ssh key path

# install zsh plugins
sheldon lock
```


## Update

```console
# nanobrew (no brew bundle --cleanup equivalent yet)
nb bundle install Nanobrew
nb bundle install .Nanobrew.local
nb upgrade

# or homebrew
# brew bundle --cleanup

sheldon lock --update
```

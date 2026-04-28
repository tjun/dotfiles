# dotfiles

## Setup

Install homebrew first. `brew bundle` is for macOS.

- homebrew: https://brew.sh/

```console
# download this repo
mkdir -p ~/dev/src/github.com/tjun/
cd ~/dev/src/github.com/tjun/
git clone
cd dotfiles

# Install packages
brew bundle

# Install runtimes and global npm packages
mkdir -p ~/.config/mise
ln -sf ~/dev/src/github.com/tjun/dotfiles/mise/config.toml ~/.config/mise/config.toml
mise install

# cmux
mkdir -p ~/.config/cmux
ln -sf ~/dev/src/github.com/tjun/dotfiles/cmux/settings.json ~/.config/cmux/settings.json

# set up ssh for github
TBD

# link dotfiles
ln -s ~/dev/src/github.com/tjun/dotfiles/{.zshrc,.zprofile,.inputrc,.vimrc,.gitconfig,.gitignore,.wezterm.lua} ~/
ln -s ~/dev/src/github.com/tjun/dotfiles/karabiner.json ~/.config/karabiner/karabiner.json # after launching karabiner-elements

# zsh plugins and abbreviations
mkdir -p ~/.config/sheldon ~/.config/zsh-abbr
ln -sf ~/dev/src/github.com/tjun/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dev/src/github.com/tjun/dotfiles/zsh-abbr/user-abbreviations ~/.config/zsh-abbr/user-abbreviations
sheldon lock

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

```

## Ubuntu

Use Linuxbrew for zsh tools. Do not run `brew bundle` on Ubuntu because this
repo's Brewfile includes macOS casks.

```console
# Install Linuxbrew
sudo apt-get update
sudo apt-get install -y build-essential procps curl file git zsh
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"

# Install zsh runtime dependencies used by this repo
brew tap olets/tap
brew install go sheldon zsh-abbr

# Link zsh dotfiles and abbreviations
ln -s ~/dev/src/github.com/tjun/dotfiles/{.zshrc,.zprofile,.inputrc,.vimrc,.gitconfig,.gitignore} ~/
mkdir -p ~/.config/sheldon ~/.config/zsh-abbr
ln -sf ~/dev/src/github.com/tjun/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dev/src/github.com/tjun/dotfiles/zsh-abbr/user-abbreviations ~/.config/zsh-abbr/user-abbreviations
sheldon lock
```


## Update

```console
brew bundle --cleanup

mise install
mise outdated

sheldon lock --update
```

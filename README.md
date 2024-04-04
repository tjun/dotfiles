# dotfiles

## Setup

Install homebrew first. see https://brew.sh/

```console
# download this repo
mkdir -p ~/dev/src/github.com/tjun/
cd ~/dev/src/github.com/tjun/
git clone
cd dotfiles

# Install brews
brew bundle

# set up ssh for github
TBD

# link dotfiles

# copy and update files
cp .gitconfig.local ~/ # and add sigining key
cp .ssh/config ~/.ssh/ # and add ssh key path

# link files
ln -s ~/dev/src/github.com/tjun/dotfiles/{.zshrc,.zprofile,.inputrc,.vimrc,.gitconfig,.gitignore,.wezterm.lua} ~/
ln -s ~/dev/src/github.com/tjun/dotfiles/karabiner.json ~/.config/karabiner/karabiner.json # after launching karabiner-elements

# install zsh plugins
sheldon lock
```


## Update

```console
brew bundle --cleanup
sheldon lock --update
```

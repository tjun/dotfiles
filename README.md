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
ln -s 


# install zsh plugins
sheldon lock
```


## Update

```console
brew bundle --cleanup
sheldon lock --update
```

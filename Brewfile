tap "homebrew/bundle"
brew "actionlint"
brew "aqua"
brew "atuin"
brew "bat"
brew "curl"
brew "colima"
brew "difftastic"
brew "direnv"
brew "docker"
# need to create a symlink for ~/.docker/cli-plugins/docker-buildx
# to /opt/homebrew/Cellar/docker-buildx/<version>/bin/docker-buildx
# or use `docker buildx install` after installing docker-buildx
# see
brew "docker-buildx"
brew "docker-compose"
brew "duckdb"
brew "eza"
brew "fd"
brew "fzf"
brew "gh"
brew "ghq"
brew "git"
brew "glow"
brew "gnu-sed"
brew "go"
brew "gojq"
brew "hugo"
brew "jnv"
brew "jq"
brew "kubectx"
brew "libpq"
brew "marp-cli"
brew "mise"
brew "mpdecimal" # required by google-cloud-sdk
brew "podman"
brew "readline" # required by google-cloud-sdk
brew "ripgrep"
brew "shellcheck"
brew "sheldon"
brew "sqlite" # required by google-cloud-sdk
brew "tenv"
brew "terraform-docs"
brew "wget"
brew "xh"
brew "zola"
brew "zoxide"
brew "zsh"

cask "1password"
cask "appcleaner"
cask "eul"
cask "karabiner-elements"
# cask "ghostty"
# cask "google-cloud-sdk"
cask "gcloud-cli"
cask "imageoptim"
cask "notion"
cask "qlmarkdown"
cask "raycast"
cask "slack"
cask "visual-studio-code"
cask "wezterm@nightly"
cask "zoom"
# cask "podman-desktop"

if File.exist?(".Brewfile.local")
  instance_eval(File.read(".Brewfile.local"))
end

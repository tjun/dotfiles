# dotfiles

macOS と Ubuntu の両方で使う。共通の設定はリポジトリ直下に置き、OS 固有のものは
`zsh/os-darwin.zsh` / `zsh/os-linux.zsh`、`mise/config.darwin.toml` / `mise/config.linux.toml`
に分けている。マシン固有の値 (署名鍵、サンドボックスのパス等) は gitignore された
`~/.gitconfig-local` `~/.zshrc-local` `codex/config.local.toml` に置く。

パッケージの入手元は OS で異なる。

| | macOS | Ubuntu |
| --- | --- | --- |
| システムパッケージ | Homebrew (`Brewfile`) | apt (`apt-packages.txt`) |
| CLI ツール・ランタイム | Homebrew + mise | mise のみ |

## Setup (macOS)

Install homebrew first: https://brew.sh/

```console
# download this repo
mkdir -p ~/dev/src/github.com/tjun/
cd ~/dev/src/github.com/tjun/
git clone
cd dotfiles

# Install packages
brew bundle

# Install runtimes and global npm packages
mkdir -p ~/.config/mise/conf.d
ln -sf ~/dev/src/github.com/tjun/dotfiles/mise/config.toml ~/.config/mise/config.toml
ln -sf ~/dev/src/github.com/tjun/dotfiles/mise/config.darwin.toml ~/.config/mise/conf.d/darwin.toml
mise install

# cmux
mkdir -p ~/.config/cmux
ln -sf ~/dev/src/github.com/tjun/dotfiles/cmux/settings.json ~/.config/cmux/settings.json

# VS Code
mkdir -p ~/Library/Application\ Support/Code/User/snippets
ln -sf ~/dev/src/github.com/tjun/dotfiles/vscode/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -sf ~/dev/src/github.com/tjun/dotfiles/vscode/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
ln -sf ~/dev/src/github.com/tjun/dotfiles/vscode/mcp.json ~/Library/Application\ Support/Code/User/mcp.json
ln -sf ~/dev/src/github.com/tjun/dotfiles/vscode/snippets/rust.json ~/Library/Application\ Support/Code/User/snippets/rust.json

# set up ssh for github
TBD

# link dotfiles
ln -s ~/dev/src/github.com/tjun/dotfiles/{.zshenv,.zshrc,.zprofile,.inputrc,.vimrc,.gitconfig,.wezterm.lua} ~/
ln -s ~/dev/src/github.com/tjun/dotfiles/gitignore ~/.gitignore
ln -s ~/dev/src/github.com/tjun/dotfiles/karabiner.json ~/.config/karabiner/karabiner.json # after launching karabiner-elements
ln -s ~/dev/src/github.com/tjun/dotfiles/tmux.conf ~/.tmux.conf

# zsh plugins and abbreviations
mkdir -p ~/.config/sheldon ~/.config/zsh-abbr
ln -sf ~/dev/src/github.com/tjun/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dev/src/github.com/tjun/dotfiles/zsh-abbr/user-abbreviations ~/.config/zsh-abbr/user-abbreviations
sheldon lock

# tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source-file ~/.tmux.conf && ~/.tmux/plugins/tpm/bin/install_plugins

# Claude Code
mkdir -p ~/.claude/local
for f in CLAUDE.md settings.json PLANS.md scripts commands statusline-command.sh; do
  ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/$f ~/.claude/$f
done

# skills はディレクトリごとではなくスキルごとに symlink する
# (hunk 同梱のスキルも PATH 上の hunk から解決して同じ場所に並べるため)
zsh ~/dev/src/github.com/tjun/dotfiles/claude/scripts/link-skills.sh

# 外部スキル (claude/skills.txt に列挙したもの) を gh skill install で入れる
zsh ~/dev/src/github.com/tjun/dotfiles/claude/scripts/install-skills.sh

# Codex
mkdir -p ~/.codex/tmp
cp codex/config.local.toml.example codex/config.local.toml # and edit writable_roots
zsh ~/dev/src/github.com/tjun/dotfiles/codex/scripts/sync-home-config.sh

# copy and update files
cp .gitconfig-local ~/ # and add signing key path
cp .ssh/config ~/.ssh/ # and add ssh key path
```

### 既存の macOS 環境からの移行

以前の構成から乗り換えるときは次の 3 点を手で直す。

```console
# 1. mise の macOS 専用ツール (rust, npm:nano-banana-mcp) を conf.d 経由で読み込む
mkdir -p ~/.config/mise/conf.d
ln -sf ~/dev/src/github.com/tjun/dotfiles/mise/config.darwin.toml ~/.config/mise/conf.d/darwin.toml

# 2. グローバル除外ファイルの参照先を .gitignore から gitignore に張り替える
ln -sfn ~/dev/src/github.com/tjun/dotfiles/gitignore ~/.gitignore

# 3. テレメトリのヘッダ生成スクリプトを local/ へ移す
#    (~/.claude/scripts がリポジトリへの symlink になるため、そこには置けない)
mkdir -p ~/.claude/local
mv ~/.claude/scripts/dd-otel-headers.sh ~/.claude/local/dd-otel-headers.sh
```

```console
# 4. ~/.claude/skills をスキルごとの symlink に張り替える
#    (旧構成のディレクトリ symlink はスクリプトが自動で外す)
zsh ~/dev/src/github.com/tjun/dotfiles/claude/scripts/link-skills.sh
```

さらに `codex/config.local.toml` を作り、`config.local.toml.example` のテレメトリ関連 5 行
(`CLAUDE_CODE_ENABLE_TELEMETRY` と `OTEL_*`) のコメントを外す。zsh のテレメトリ設定は
`zsh/os-darwin.zsh` に入っているので追加の作業は要らない。

`zsh/os-darwin.zsh` の gcloud ブロックは `$BREW_PREFIX` を参照する。これはリポジトリ内では
定義していないので、必要なら `~/.zshrc-local` で設定する。

## Setup (Ubuntu)

Homebrew は使わない。システムパッケージは apt、それ以外の CLI とランタイムは mise で入れる。

```console
# download this repo
mkdir -p ~/dev/src/github.com/tjun/
cd ~/dev/src/github.com/tjun/
git clone
cd dotfiles

# System packages
sudo apt-get update
xargs -a apt-packages.txt sudo apt-get install -y

# mise (https://mise.jdx.dev/installing-mise.html)
curl https://mise.run | sh

# Install runtimes and CLI tools (config.linux.toml has what Homebrew provides on macOS)
mkdir -p ~/.config/mise/conf.d
ln -sf ~/dev/src/github.com/tjun/dotfiles/mise/config.toml ~/.config/mise/config.toml
ln -sf ~/dev/src/github.com/tjun/dotfiles/mise/config.linux.toml ~/.config/mise/conf.d/linux.toml
mise install

# set up ssh for github (sheldon が SSH でプラグインを取得するので先に済ませる)
ssh -T git@github.com

# link dotfiles
ln -s ~/dev/src/github.com/tjun/dotfiles/{.zshenv,.zshrc,.zprofile,.inputrc,.vimrc,.gitconfig} ~/
ln -s ~/dev/src/github.com/tjun/dotfiles/gitignore ~/.gitignore
ln -s ~/dev/src/github.com/tjun/dotfiles/tmux.conf ~/.tmux.conf

# zsh plugins and abbreviations
mkdir -p ~/.config/sheldon ~/.config/zsh-abbr
ln -sf ~/dev/src/github.com/tjun/dotfiles/sheldon/plugins.toml ~/.config/sheldon/plugins.toml
ln -sf ~/dev/src/github.com/tjun/dotfiles/zsh-abbr/user-abbreviations ~/.config/zsh-abbr/user-abbreviations
sheldon lock
chsh -s "$(command -v zsh)"

# tmux plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
tmux source-file ~/.tmux.conf && ~/.tmux/plugins/tpm/bin/install_plugins

# Claude Code
mkdir -p ~/.claude
for f in CLAUDE.md settings.json PLANS.md scripts commands statusline-command.sh; do
  ln -sf ~/dev/src/github.com/tjun/dotfiles/claude/$f ~/.claude/$f
done

# skills はディレクトリごとではなくスキルごとに symlink する
# (hunk 同梱のスキルも PATH 上の hunk から解決して同じ場所に並べるため)
zsh ~/dev/src/github.com/tjun/dotfiles/claude/scripts/link-skills.sh

# 外部スキル (claude/skills.txt に列挙したもの) を gh skill install で入れる
zsh ~/dev/src/github.com/tjun/dotfiles/claude/scripts/install-skills.sh

# Codex
mkdir -p ~/.codex/tmp
cp codex/config.local.toml.example codex/config.local.toml # テレメトリ行はコメントのままにする
zsh ~/dev/src/github.com/tjun/dotfiles/codex/scripts/sync-home-config.sh

# machine-local git settings
printf '[user]\n    signingkey = %s/.ssh/id_ed25519\n' "$HOME" > ~/.gitconfig-local
```

Ubuntu で意図的に入れていないもの:

- **Homebrew / Brewfile** — `Brewfile` は macOS の cask を含むので実行しない。
- **rust, npm:nano-banana-mcp** — `mise/config.darwin.toml` にあり、Linux では読み込まない。
- **テレメトリ** — Datadog への送信設定は `zsh/os-darwin.zsh` と `codex/config.local.toml` の
  コメントアウト部分にあり、Ubuntu では有効にならない。
- **cmux, karabiner, wezterm, VS Code** — GUI 前提のため対象外。`hunk` 本体は mise で入る。
  `claude/scripts/hunk-review.sh` / `mo-preview.sh` / `agent-terminal.sh` は Orca か cmux の
  ペイン操作が前提 (`claude/scripts/lib/ui-pane.sh` で切り替える) なので、Orca の中なら Ubuntu でも動く。
  どちらも無い端末では `hunk ... --watch` を自分で実行するよう促して終了する。

既知の注意点: Ubuntu 24.04 は既定で `kernel.apparmor_restrict_unprivileged_userns = 1` のため、
Codex の bubblewrap サンドボックスが警告を出す (動作はする)。

## Update

```console
# macOS のみ
brew bundle --cleanup

mise install
mise outdated

sheldon lock --update

# tmux プラグイン (tmux 内で prefix + U でも可)
~/.tmux/plugins/tpm/bin/update_plugins all

# Codex (config.toml か config.local.toml を変えたとき)
zsh codex/scripts/sync-home-config.sh

# スキルを増やしたとき / hunk を上げたとき
# (`hunk skill path` はバージョン固定のパスを返すのでリンクの張り直しが要る)
zsh claude/scripts/link-skills.sh

# claude/skills.txt に行を足したとき
zsh claude/scripts/install-skills.sh

# 導入済みの外部スキルを最新にする (@version で固定したものは対象外)
gh skill update --all
```

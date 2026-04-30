#!/bin/zsh
# .zshenv — login / interactive / 非対話スクリプト / GUI アプリのサブシェル すべてで読まれる。
# 環境変数と PATH はここに置く。GUI アプリ (Codex.app など) からも参照されるようにするため。
# ※ 非対話シェルでも毎回読まれるので、重い処理や対話前提の設定は書かない。

# PATH の重複を防ぐ
typeset -U PATH path

# ファイル作成時のデフォルトパーミッション設定
umask 022

export EDITOR='hx'
export HOMEBREW_ANALYTICS_DEBUG=1

# Homebrew (macOS)
if [[ -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# mise shims — 非対話シェル / GUI アプリから mise 管理ツール (uv 等) を見えるようにする。
# 対話シェルでは .zshrc 内の `mise activate` が PATH を上書きして優先される。
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

# user-local bin
if [[ -d $HOME/.local/bin ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

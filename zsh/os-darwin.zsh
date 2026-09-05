#!/bin/zsh
# macOS 固有の対話シェル設定。.zshrc から $OSTYPE を見て source される。
# Homebrew や macOS 専用ツール (herdr/cmux, gcloud, postgresql) に依存する設定はここに置く。

# herdr が ctrl+t をプレフィックスとして受け取れるよう解除
stty status undef
bindkey -r '^T'

if type brew &>/dev/null; then
  FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
fi

# gcloud (遅延読み込み)
if (( $+commands[gcloud] )) && [[ -n "$BREW_PREFIX" ]]; then
  PATH=$PATH:${BREW_PREFIX}/share/google-cloud-sdk/bin
  zsh-defer source "${BREW_PREFIX}/share/google-cloud-sdk/path.zsh.inc"
  zsh-defer source "${BREW_PREFIX}/share/google-cloud-sdk/completion.zsh.inc"
fi

# kubectl (completionをキャッシュ化) - 現在未使用
# if (( $+commands[kubectl] )); then
#   alias k="nocorrect kubectl"
#   alias kg="kubectl get "
#   alias kgy="kubectl get -o yaml "
#   alias kd="kubectl describe "
#   _kubectl_cache="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/kubectl_completion.zsh"
#   if [[ ! -f "$_kubectl_cache" ]]; then
#     mkdir -p "${_kubectl_cache:h}"
#     kubectl completion zsh > "$_kubectl_cache"
#   fi
#   zsh-defer source "$_kubectl_cache"
#   zsh-defer complete -o default -F __start_kubectl k
# fi

# if [ -e "/opt/homebrew/opt/libpq/bin" ];then
#   export PATH="${PATH}:/opt/homebrew/opt/libpq/bin"
# fi

if [ -e "/opt/homebrew/opt/postgresql@16/bin" ];then
  export PATH="${PATH}:/opt/homebrew/opt/postgresql@16/bin"
fi

# Claude Code のテレメトリ送信先 (Datadog)。ヘッダ生成スクリプトは
# ~/.claude/local/dd-otel-headers.sh にマシンローカルで置く (リポジトリには含めない)。
export CLAUDE_CODE_ENABLE_TELEMETRY=1
export OTEL_METRICS_EXPORTER=otlp
export OTEL_EXPORTER_OTLP_PROTOCOL=http/protobuf
export OTEL_EXPORTER_OTLP_ENDPOINT=https://otlp.us5.datadoghq.com
export OTEL_EXPORTER_OTLP_METRICS_TEMPORALITY_PREFERENCE=delta

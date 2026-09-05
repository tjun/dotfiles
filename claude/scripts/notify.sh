#!/bin/bash
# Claude Codeの通知をmacOSデスクトップ通知として表示する
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code needs your attention"')
TITLE=$(echo "$INPUT" | jq -r '.title // "Claude Code"')
CWD=$(echo "$INPUT" | jq -r '.cwd // ""')

# macOSデスクトップ通知（terminal-notifierでアイコン付き）。
# terminal-notifier が無いマシンでは端末ベルで代替する。
if command -v terminal-notifier >/dev/null 2>&1; then
  terminal-notifier -title "$TITLE" -message "$MESSAGE" -sound Glass -group "claude-code" \
    -contentImage "$HOME/.claude/claude-icon.png"
else
  printf '\a' >&2
fi

# WezTermタブにアイコンを表示するためのマーカーファイルを書き出す
if [ -n "$CWD" ]; then
  MARKER_DIR="/tmp/claude-code-waiting"
  mkdir -p "$MARKER_DIR"
  SAFE_CWD=$(echo -n "$CWD" | sed 's/[^a-zA-Z0-9]/_/g')
  date +%s > "${MARKER_DIR}/${SAFE_CWD}"
  # 10分以上古いマーカーを掃除
  find "$MARKER_DIR" -type f -mmin +10 -delete 2>/dev/null
fi

exit 0

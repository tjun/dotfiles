#!/bin/bash
# Auto-format files after Edit/Write based on file extension.
# Called by Claude Code PostToolUse hook.
# Input: JSON via stdin with tool_input.file_path

set -euo pipefail

FILE_PATH=$(cat | jq -r '.tool_input.file_path // empty')
[ -z "$FILE_PATH" ] && exit 0
[ ! -f "$FILE_PATH" ] && exit 0

case "$FILE_PATH" in
  *.go)
    command -v gofmt >/dev/null 2>&1 && gofmt -w "$FILE_PATH"
    ;;
  *.py)
    command -v ruff >/dev/null 2>&1 && ruff format --quiet "$FILE_PATH"
    ;;
  # *.js|*.ts|*.jsx|*.tsx|*.json|*.css|*.scss|*.html)
  #   command -v prettier >/dev/null 2>&1 && prettier --write --log-level silent "$FILE_PATH" 2>/dev/null
  #   ;;
  # *.sh|*.bash)
  #   command -v shfmt >/dev/null 2>&1 && shfmt -w "$FILE_PATH"
  #   ;;
esac

exit 0

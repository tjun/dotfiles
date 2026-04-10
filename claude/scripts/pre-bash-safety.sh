#!/bin/bash
# Block dangerous shell commands before execution.
# Called by Claude Code PreToolUse hook.
# Exit code 2 = block the tool call.

set -euo pipefail

COMMAND=$(cat | jq -r '.tool_input.command // empty')
[ -z "$COMMAND" ] && exit 0

# Dangerous patterns to block
DANGEROUS_PATTERNS=(
  'rm -rf /'
  'rm -rf \$HOME'
  'mkfs\.'
  'dd if=.* of=/dev/'
  '> /dev/sd'
  'chmod -R 777 /'
)

for pattern in "${DANGEROUS_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "BLOCKED: dangerous command pattern detected: $pattern" >&2
    exit 2
  fi
done

exit 0

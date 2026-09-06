#!/usr/bin/env bash
# Terminal launcher for `agmsg spawn`, opening the agent in a pane of the
# terminal workspace (Orca or cmux) instead of Terminal.app. Wire it up with:
#
#   AGMSG_TERMINAL='~/.claude/scripts/agent-terminal.sh {cmd}'
#
# agmsg substitutes {cmd} with its generated boot script and runs the result
# through `bash -c`, so this receives one argument: the boot script path.
# Outside a supported workspace it falls back to agmsg's own macOS behaviour.
set -euo pipefail

# shellcheck source=lib/ui-pane.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/ui-pane.sh"

boot="${1:?usage: agent-terminal.sh <boot-script>}"
title="${AGMSG_CMUX_TITLE:-${AGMSG_PANE_TITLE:-agent}}"

# The real codex binary: the first `codex` on PATH that is not agmsg's shim.
# Identified by the marker the shim generator writes, so a copy or a symlink
# under another name is skipped too -- handing the shim itself back as
# AGMSG_REAL_CODEX is what makes it recurse.
resolve_real_codex() {
  local dir candidate
  while IFS= read -r dir; do
    [[ -n "$dir" ]] || dir=.
    candidate="$dir/codex"
    [[ -f "$candidate" && -x "$candidate" ]] || continue
    grep -qs "agmsg monitor mode" "$candidate" && continue
    printf '%s\n' "$candidate"
    return 0
  done < <(printf '%s' "$PATH" | tr ':' '\n')
  return 1
}

if [[ "$(ui_kind)" == none ]]; then
  exec open -g -a Terminal "$boot"
fi

# agmsg's codex shim lives in ~/.agents/bin and only takes effect when it wins
# the PATH lookup, which is what puts a spawned codex into monitor mode. Scoped
# to the spawned agent on purpose: prepending it globally would displace the
# workspace's own codex wrapper for interactive use.
#
# AGMSG_REAL_CODEX is mandatory alongside that PATH entry. Without it the shim
# locates "the real codex" by scanning PATH, finds ~/.agents/bin/codex -- itself
# -- and every internal probe (`codex --version`, `codex app-server`) recurses
# until the machine runs out of processes.
#
# It must name the real binary rather than another wrapper: a wrapper that
# re-resolves `codex` from PATH would land back on the shim and reopen the same
# loop. That costs the spawned agent the workspace's own codex hooks, which is
# the cheaper half of the trade.
prelude=""
if ! grep -qE '(^|[[:space:]]|/)codex([[:space:]]|$)' "$boot"; then
  : # not a codex agent; the shim is irrelevant
elif real_codex=$(resolve_real_codex); then
  prelude="AGMSG_REAL_CODEX=$(printf '%q' "$real_codex") PATH=$(printf '%q' "$HOME/.agents/bin"):\"\$PATH\" "
else
  # Every codex on PATH is a shim, so there is nothing safe to point at. Refuse
  # rather than launch an agent that will fork-bomb the machine on its first probe.
  echo "agent-terminal: cannot resolve a non-shim codex on PATH; refusing to launch" >&2
  exit 1
fi

handle=$(ui_term_start "$title" "${prelude}bash $(printf '%q' "$boot")")
echo "launched in $handle"

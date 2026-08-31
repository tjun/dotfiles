#!/usr/bin/env bash
# Terminal launcher for `agmsg spawn`, opening the agent in a cmux pane instead
# of Terminal.app. Wire it up with:
#
#   AGMSG_TERMINAL='~/.claude/scripts/cmux-agent-terminal.sh {cmd}'
#
# agmsg substitutes {cmd} with its generated boot script and runs the result
# through `bash -c`, so this receives one argument: the boot script path.
# Outside cmux it falls back to agmsg's own macOS behaviour.
set -euo pipefail

boot="${1:?usage: cmux-agent-terminal.sh <boot-script>}"
title="${AGMSG_CMUX_TITLE:-agent}"

# The real codex binary: the first `codex` on PATH that is not agmsg's shim.
# Identified by the marker the shim generator writes, so a copy or a symlink
# under another name is skipped too — handing the shim itself back as
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

if [[ -z "${CMUX_WORKSPACE_ID:-}" ]]; then
  exec open -g -a Terminal "$boot"
fi

# agmsg's codex shim lives in ~/.agents/bin and only takes effect when it wins
# the PATH lookup, which is what puts a spawned codex into monitor mode. Scoped
# to the spawned agent on purpose: prepending it globally would displace cmux's
# own codex wrapper for interactive use.
#
# AGMSG_REAL_CODEX is mandatory alongside that PATH entry. Without it the shim
# locates "the real codex" by scanning PATH, finds ~/.agents/bin/codex — itself —
# and every internal probe (`codex --version`, `codex app-server`) recurses until
# the machine runs out of processes. Pointing it at cmux's own codex wrapper
# breaks the loop and keeps cmux's codex hooks in the chain.
#
# It must name the real binary rather than another wrapper: a wrapper that
# re-resolves `codex` from PATH would land back on the shim and reopen the same
# loop. That costs the spawned agent cmux's own codex hooks, which is the
# cheaper half of the trade.
prelude=""
if ! grep -qE '(^|[[:space:]]|/)codex([[:space:]]|$)' "$boot"; then
  : # not a codex agent; the shim is irrelevant
elif real_codex=$(resolve_real_codex); then
  prelude="AGMSG_REAL_CODEX=$(printf '%q' "$real_codex") PATH=$(printf '%q' "$HOME/.agents/bin"):\"\$PATH\" "
else
  # Every codex on PATH is a shim, so there is nothing safe to point at. Refuse
  # rather than launch an agent that will fork-bomb the machine on its first probe.
  echo "cmux-agent-terminal: cannot resolve a non-shim codex on PATH; refusing to launch" >&2
  exit 1
fi

read -r _ surface _ < <(cmux new-pane --type terminal --direction right --focus false)
cmux rename-tab --surface "$surface" "$title" >/dev/null 2>&1 || true

# A pane accepts input before its shell has finished starting, and anything sent
# in that window is dropped. Wait for the shell to paint something first.
for _ in $(seq 1 40); do
  [[ -n "$(cmux read-screen --surface "$surface" --lines 5 2>/dev/null | tr -d '[:space:]')" ]] && break
  sleep 0.25
done
sleep 0.5

cmd="${prelude}bash $(printf '%q' "$boot")"
cmux send --surface "$surface" "$cmd" >/dev/null

# Confirm the pane actually received the line before pressing Enter; a shell that
# was still starting swallows it, and agmsg would report a successful spawn of an
# agent that never ran.
marker=$(basename "$boot")
echoed=0
for attempt in 1 2 3; do
  sleep 0.7
  # Newlines are stripped so a command wrapped across the pane width still
  # matches the marker.
  if cmux read-screen --surface "$surface" --lines 10 2>/dev/null |
      tr -d '[:space:]' | grep -qF "$marker"; then
    echoed=1
    break
  fi
  ((attempt == 3)) && break
  # Discard whatever fragment did land, so a retry cannot concatenate onto it.
  cmux send-key --surface "$surface" ctrl+u >/dev/null
  cmux send --surface "$surface" "$cmd" >/dev/null
done

if ((!echoed)); then
  echo "cmux-agent-terminal: pane $surface never echoed the launch command" >&2
  exit 1
fi

cmux send-key --surface "$surface" Enter >/dev/null
echo "launched in $surface"

#!/usr/bin/env bash
# Open a hunk (https://github.com/modem-dev/hunk) review TUI in a cmux terminal pane.
#
#   hunk-review.sh                    # working tree changes
#   hunk-review.sh diff --staged
#   hunk-review.sh show HEAD~1
#   hunk-review.sh --focus            # focus the existing review pane
#   hunk-review.sh --close            # quit the TUI and close its pane
#
# The TUI belongs to the user: it must run in its own pane, never in an agent's
# shell. Once running it registers with the hunk daemon, so agents inspect and
# annotate it through `hunk session ...` instead of relaunching it.
set -euo pipefail

action=open
args=()
while (($#)); do
  case "$1" in
    --focus) action=focus ;;
    --close) action=close ;;
    *) args+=("$1") ;;
  esac
  shift
done
((${#args[@]})) || args=(diff)

repo=$(git rev-parse --show-toplevel)

# "<pid> <tty>" for every session the daemon lists for this repo, newest last.
session_candidates() {
  hunk session list --json 2>/dev/null |
    jq -r --arg repo "$repo" '
      .sessions // []
      | map(select(.repoRoot == $repo))
      | .[] as $s
      | "\($s.pid) \(($s.terminal.locations // [] | map(select(.source == "tty")) | .[0].tty // ""))"'
}

# The daemon keeps listing a session whose TUI lost its terminal (pane closed
# under it), and reloading such a session shows the user nothing. Detached
# processes report a tty of "??".
session_alive() {
  [[ -n "$1" ]] || return 1
  local t
  t=$(ps -o tty= -p "$1" 2>/dev/null | tr -d ' ')
  [[ -n "$t" && "$t" != "??" ]]
}

# cmux surface ref whose terminal is on that tty, so the pane can be focused or closed.
surface_for_tty() {
  local tty=${1#/dev/}
  [[ -z "$tty" ]] && return 0
  cmux tree --workspace "$CMUX_WORKSPACE_ID" --json 2>/dev/null |
    jq -r --arg tty "$tty" '[.. | objects | select(.tty? == $tty)] | .[0].ref // empty'
}

# Scan every candidate rather than trusting the first: one orphan at the head of
# the list would otherwise mask a live session and let each call stack up another
# TUI for the same repo.
pid=""
tty=""
while read -r cand_pid cand_tty; do
  if session_alive "$cand_pid"; then
    pid="$cand_pid"
    tty="$cand_tty"
    break
  fi
done < <(session_candidates)

surface=""
[[ -n "${CMUX_WORKSPACE_ID:-}" && -n "$tty" ]] && surface=$(surface_for_tty "$tty")

case "$action" in
  focus)
    [[ -z "$surface" ]] && { echo "no hunk review pane for $repo" >&2; exit 1; }
    cmux focus-pane --pane "$(cmux tree --workspace "$CMUX_WORKSPACE_ID" --json |
      jq -r --arg s "$surface" '[.. | objects | select(.ref? == $s)] | .[0].pane_ref')"
    exit 0
    ;;
  close)
    [[ -z "$surface" ]] && { echo "no hunk review pane for $repo" >&2; exit 1; }
    # Quit the TUI before dropping its pane, otherwise hunk survives detached
    # and keeps advertising a session that can no longer be seen.
    cmux send-key --surface "$surface" q >/dev/null
    for _ in 1 2 3 4 5 6; do
      sleep 0.5
      session_alive "$pid" || break
    done
    session_alive "$pid" && kill -9 "$pid" 2>/dev/null
    cmux close-surface --surface "$surface" --workspace "$CMUX_WORKSPACE_ID"
    exit 0
    ;;
esac

# A live session is reloaded in place: relaunching would leave the user with two
# TUIs competing for the same repo.
if [[ -n "$pid" ]]; then
  hunk session reload --repo "$repo" -- "${args[@]}" >/dev/null
  if [[ -n "$surface" ]]; then
    echo "reloaded hunk session for $repo: ${args[*]}"
  else
    # Reload succeeded but the TUI is on some other window or workspace, so the
    # user sees nothing here. Say so instead of reporting a silent success.
    echo "reloaded hunk session for $repo: ${args[*]} (its TUI is not in this workspace, tty ${tty:-unknown})" >&2
  fi
  exit 0
fi

if [[ -z "${CMUX_WORKSPACE_ID:-}" ]]; then
  echo "not in a cmux workspace; run this in your own terminal:" >&2
  echo "  hunk ${args[*]} --watch" >&2
  exit 1
fi

cmd="cd $(printf '%q' "$repo") && hunk"
for a in "${args[@]}"; do cmd+=" $(printf '%q' "$a")"; done
cmd+=" --watch"

read -r _ surface _ < <(cmux new-pane --type terminal --direction right --focus false)

# A pane accepts input before its shell has finished starting, and anything sent
# in that window is dropped. Wait for the shell to paint something first.
for _ in $(seq 1 40); do
  [[ -n "$(cmux read-screen --surface "$surface" --lines 5 2>/dev/null | tr -d '[:space:]')" ]] && break
  sleep 0.25
done
sleep 0.5

cmux send --surface "$surface" "$cmd" >/dev/null
cmux send-key --surface "$surface" Enter >/dev/null
echo "opened hunk in $surface: ${args[*]} --watch"

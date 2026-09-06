#!/usr/bin/env bash
# Open a hunk (https://github.com/modem-dev/hunk) review TUI in a pane of the
# terminal workspace (Orca or cmux).
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

# shellcheck source=lib/ui-pane.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/ui-pane.sh"

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
title="hunk:$(basename "$repo")"

# "<sessionId> <pid>" for every session the daemon lists for this repo, newest
# first: when several are somehow live, the one just opened is the one on screen.
session_candidates() {
  hunk session list --json 2>/dev/null |
    jq -r --arg repo "$repo" '
      .sessions // []
      | map(select(.repoRoot == $repo))
      | sort_by(.launchedAt) | reverse
      | .[] | "\(.sessionId) \(.pid)"'
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

# Scan every candidate rather than trusting the first: one orphan at the head of
# the list would otherwise mask a live session and let each call stack up another
# TUI for the same repo.
pid=""
session=""
while read -r cand_session cand_pid; do
  if session_alive "$cand_pid"; then
    session="$cand_session"
    pid="$cand_pid"
    break
  fi
done < <(session_candidates)

handle=""
[[ "$(ui_kind)" != none ]] && handle=$(ui_term_find "$title")

case "$action" in
  focus)
    [[ -z "$handle" ]] && { echo "no hunk review pane for $repo" >&2; exit 1; }
    ui_term_focus "$handle"
    exit 0
    ;;
  close)
    [[ -z "$handle" ]] && { echo "no hunk review pane for $repo" >&2; exit 1; }
    # Quit the TUI before dropping its pane, otherwise hunk survives detached
    # and keeps advertising a session that can no longer be seen.
    ui_term_key "$handle" q
    for _ in 1 2 3 4 5 6; do
      sleep 0.5
      session_alive "$pid" || break
    done
    session_alive "$pid" && kill -9 "$pid" 2>/dev/null
    ui_term_close "$handle"
    exit 0
    ;;
esac

# A live session is reloaded in place: relaunching would leave the user with two
# TUIs competing for the same repo.
if [[ -n "$pid" ]]; then
  # Addressed by session id, not --repo: that flag refuses to act when the
  # daemon lists more than one session for the repo.
  hunk session reload "$session" -- "${args[@]}" >/dev/null
  if [[ -n "$handle" ]]; then
    echo "reloaded hunk session for $repo: ${args[*]}"
  else
    # Reload succeeded but the TUI is on some other window or workspace, so the
    # user sees nothing here. Say so instead of reporting a silent success.
    echo "reloaded hunk session for $repo: ${args[*]} (its TUI is not in this workspace)" >&2
  fi
  exit 0
fi

if [[ "$(ui_kind)" == none ]]; then
  echo "no supported terminal workspace; run this in your own terminal:" >&2
  echo "  hunk ${args[*]} --watch" >&2
  exit 1
fi

cmd="cd $(printf '%q' "$repo") && hunk"
for a in "${args[@]}"; do cmd+=" $(printf '%q' "$a")"; done
cmd+=" --watch"

handle=$(ui_term_start "$title" "$cmd")
echo "opened hunk in $handle: ${args[*]} --watch"

#!/bin/bash
# WorktreeCreate hook: replaces Claude Code's default worktree creation.
# Reads {name, cwd} JSON on stdin, creates the worktree, runs mise install
# and make setup inside it, then prints the worktree path to stdout
# (stdout is reserved for the path; all logs go to stderr).
#
# The hook also fires when an existing worktree session is resumed, so it must
# be idempotent: an already-registered worktree is reused as-is and the
# provisioning steps below are skipped.
set -euo pipefail

input=$(cat)
name=$(jq -r '.name' <<<"$input")
cwd=$(jq -r '.cwd' <<<"$input")

if [ -z "$name" ] || [ "$name" = "null" ]; then
  echo "WorktreeCreate hook: missing worktree name" >&2
  exit 1
fi

cd "$cwd"
# Resolve the main checkout even if cwd is itself a worktree
common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
main_root=$(dirname "$common_dir")
# Deliberately not under .claude/: agmsg's SessionStart hook exits early for any
# cwd inside .claude/worktrees, which silently disables monitor-mode delivery.
worktree_path="$main_root/.worktrees/$name"

# True when worktree_path is registered with git as a worktree of this repo.
is_registered_worktree() {
  git -C "$main_root" worktree list --porcelain |
    sed -n 's/^worktree //p' |
    grep -Fxq "$worktree_path"
}

# agmsg delivers messages by (team, agent) alone -- the project path is not part
# of the inbox key -- so worktrees sharing a team read each other's mail. Each
# worktree therefore gets its own team. A brand-new team has no registrations,
# which is also what makes join.sh record the worktree path verbatim instead of
# rewriting it to the main checkout; AGMSG_RESOLVE_PROJECT=0 additionally blocks
# the enclosing session's project marker from doing the same.
#
# Runs on every path that yields a usable worktree, reused ones included: join
# and delivery are idempotent, and a worktree created before this hook existed
# would otherwise never get its own team.
setup_agmsg_team() {
  local scripts="$HOME/.agents/skills/agmsg/scripts"
  [ -d "$scripts" ] || return 0

  # The name alone collides across same-named repos in different locations, and
  # `tr` folds `foo/bar` and `foo-bar` together -- both would silently reunite
  # the inboxes this split exists to separate. A digest of the absolute path
  # keeps distinct worktrees distinct.
  local slug digest team
  slug=$(printf '%s' "$name" | tr -c 'A-Za-z0-9._-' '-')
  digest=$(printf '%s' "$worktree_path" | shasum | cut -c1-6)
  team="$(basename "$main_root")-${slug}-${digest}"

  echo "WorktreeCreate hook: agmsg team $team" >&2
  local failed=0
  AGMSG_RESOLVE_PROJECT=0 "$scripts/join.sh" "$team" claude claude-code "$worktree_path" >&2 || failed=1
  AGMSG_RESOLVE_PROJECT=0 "$scripts/join.sh" "$team" codex codex "$worktree_path" >&2 || failed=1
  "$scripts/delivery.sh" set monitor claude-code "$worktree_path" >&2 || failed=1
  "$scripts/delivery.sh" set monitor codex "$worktree_path" >&2 || failed=1

  # Not fatal -- a worktree without messaging is still a usable worktree -- but
  # never silent: the failure mode is this session quietly sharing another
  # worktree's inbox.
  if [ "$failed" -ne 0 ]; then
    echo "WorktreeCreate hook: WARNING agmsg setup incomplete for $team; this worktree may share another worktree's inbox" >&2
  fi
}

mkdir -p "$main_root/.worktrees"

# Keep the worktrees out of the repo's own status without touching a tracked
# .gitignore, since not every repo wants this path committed.
exclude_file="$common_dir/info/exclude"
if [ -f "$exclude_file" ] && ! grep -qxF '/.worktrees/' "$exclude_file"; then
  printf '/.worktrees/\n' >> "$exclude_file"
fi

if is_registered_worktree; then
  echo "WorktreeCreate hook: reusing existing worktree $worktree_path" >&2
  setup_agmsg_team
  echo "$worktree_path"
  exit 0
fi

if [ -e "$worktree_path" ]; then
  # Directory survives but git lost track of it (e.g. the repo was moved, or
  # the administrative entry under .git/worktrees was pruned). Try to relink
  # before giving up, so a resume does not dead-end on a stale directory.
  echo "WorktreeCreate hook: $worktree_path exists but is not registered; attempting repair" >&2
  git -C "$main_root" worktree prune >&2 || true
  git -C "$main_root" worktree repair "$worktree_path" >&2 || true
  if is_registered_worktree; then
    echo "WorktreeCreate hook: repaired existing worktree $worktree_path" >&2
    setup_agmsg_team
    echo "$worktree_path"
    exit 0
  fi
  echo "WorktreeCreate hook: $worktree_path exists but is not a usable worktree; remove it and retry" >&2
  exit 1
fi

if git -C "$main_root" show-ref --verify --quiet "refs/heads/$name"; then
  git -C "$main_root" worktree add "$worktree_path" "$name" >&2
else
  git -C "$main_root" worktree add -b "$name" "$worktree_path" >&2
fi

cd "$worktree_path"

# Copy gitignored files that .worktreeinclude would handle
# (WorktreeCreate hook bypasses .worktreeinclude processing)
for f in mise.toml .mise.toml .env .env.local .envrc; do
  if [ -f "$main_root/$f" ] && [ ! -f "$worktree_path/$f" ]; then
    cp "$main_root/$f" "$worktree_path/$f"
    echo "WorktreeCreate hook: copied $f" >&2
  fi
done

if [ -f .envrc ] && command -v direnv >/dev/null 2>&1; then
  echo "WorktreeCreate hook: running direnv allow" >&2
  direnv allow >&2 || echo "WorktreeCreate hook: direnv allow failed (continuing)" >&2
fi

if command -v mise >/dev/null 2>&1; then
  echo "WorktreeCreate hook: running mise install" >&2
  mise trust --quiet 2>/dev/null || true
  mise install >&2 || echo "WorktreeCreate hook: mise install failed (continuing)" >&2
fi

if [ -f Makefile ] && grep -qE '^setup:' Makefile; then
  echo "WorktreeCreate hook: running make setup" >&2
  make setup >&2 || echo "WorktreeCreate hook: make setup failed (continuing)" >&2
fi

setup_agmsg_team

echo "$worktree_path"

#!/usr/bin/env bash
# Preview Markdown with mo (https://github.com/k1LoW/mo) in a cmux browser pane.
#
#   mo-preview.sh docs/design.md [more.md ...] [-t GROUP] [-p PORT] [mo flags...]
#   mo-preview.sh --close                     # close the preview pane
#
# mo runs a single background server (default port 6275) and adds files to the
# running session, so repeated calls never block the shell or spawn extra servers.
# Outside cmux this degrades to mo's own browser opening.
set -euo pipefail

port=6275
target=default
close=0
mo_args=()

while (($#)); do
  case "$1" in
    --close) close=1 ;;
    -t|--target) target="$2"; mo_args+=("$1" "$2"); shift ;;
    --target=*) target="${1#*=}"; mo_args+=("$1") ;;
    -p|--port) port="$2"; mo_args+=("$1" "$2"); shift ;;
    --port=*) port="${1#*=}"; mo_args+=("$1") ;;
    *) mo_args+=("$1") ;;
  esac
  shift
done

url="http://localhost:${port}"
[[ "$target" != default ]] && url="${url}/${target}"

# Ref of a browser surface already showing this mo server, so previews reuse one
# pane. Deliberately only matches mo's own URL: reusing an arbitrary browser
# surface would navigate away from — or close — whatever the user was reading.
browser_surface() {
  cmux tree --workspace "$CMUX_WORKSPACE_ID" --json 2>/dev/null |
    jq -r --arg u "http://localhost:${port}" '
      [.. | objects | select(.type? == "browser") | select((.url // "") | startswith($u))]
      | .[0].ref // empty'
}

if [[ -z "${CMUX_WORKSPACE_ID:-}" ]]; then
  ((close)) && exit 0
  exec mo --open "${mo_args[@]}"
fi

if ((close)); then
  surface=$(browser_surface)
  [[ -z "$surface" ]] && { echo "no mo preview pane in this workspace" >&2; exit 1; }
  cmux close-surface --surface "$surface" --workspace "$CMUX_WORKSPACE_ID"
  exit 0
fi

# Jump straight to the first file passed in, so a preview shows what was just
# asked for instead of whatever the session happened to open first.
file_url=$(mo --no-open --json "${mo_args[@]}" | jq -r '.files[0].url // empty')
[[ -n "$file_url" ]] && url="$file_url"

surface=$(browser_surface)
if [[ -n "$surface" ]]; then
  cmux browser "$surface" goto "$url"
else
  cmux browser open-split "$url" --workspace "$CMUX_WORKSPACE_ID"
fi
echo "$url"

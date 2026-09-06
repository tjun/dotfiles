#!/usr/bin/env bash
# Preview Markdown with mo (https://github.com/k1LoW/mo) in a browser pane of the
# terminal workspace (Orca or cmux).
#
#   mo-preview.sh docs/design.md [more.md ...] [-t GROUP] [-p PORT] [mo flags...]
#   mo-preview.sh --close                     # close the preview pane
#
# mo runs a single background server (default port 6275) and adds files to the
# running session, so repeated calls never block the shell or spawn extra servers.
# Outside a supported workspace this degrades to mo's own browser opening.
set -euo pipefail

# shellcheck source=lib/ui-pane.sh
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/lib/ui-pane.sh"

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
server="http://localhost:${port}"

if [[ "$(ui_kind)" == none ]]; then
  ((close)) && exit 0
  exec mo --open "${mo_args[@]}"
fi

# Only ever reuse or close a tab already showing this mo server: taking over an
# arbitrary browser pane would navigate away from -- or close -- whatever the
# user happened to be reading.
if ((close)); then
  handle=$(ui_browser_find "$server")
  [[ -z "$handle" ]] && { echo "no mo preview pane in this workspace" >&2; exit 1; }
  ui_browser_close "$handle"
  exit 0
fi

# Jump straight to the first file passed in, so a preview shows what was just
# asked for instead of whatever the session happened to open first.
file_url=$(mo --no-open --json "${mo_args[@]}" | jq -r '.files[0].url // empty')
[[ -n "$file_url" ]] && url="$file_url"

handle=$(ui_browser_find "$server")
if [[ -n "$handle" ]]; then
  ui_browser_goto "$handle" "$url"
else
  ui_browser_open "$url"
fi
echo "$url"

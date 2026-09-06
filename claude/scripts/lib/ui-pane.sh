# shellcheck shell=bash
# Pane and browser-tab operations for the terminal workspace this session runs
# in. Sourced, never executed.
#
# Supports Orca and cmux; every function returns non-zero under a plain terminal
# so callers can fall back to whatever the underlying tool does on its own.
# Handles are opaque strings -- an Orca terminal handle, a cmux surface ref --
# and are only ever passed back to these functions.
#
# Panes are located by title rather than by process or tty: it is the one
# identifier both backends expose, and it survives a pane outliving whatever
# was first launched in it.

ui_kind() {
  if [[ -n "${ORCA_TERMINAL_HANDLE:-}" || "${TERM_PROGRAM:-}" == "Orca" ]]; then
    echo orca
  elif [[ -n "${CMUX_WORKSPACE_ID:-}" ]]; then
    echo cmux
  else
    echo none
  fi
}

# The Linux package installs the CLI as `orca-ide` because GNOME's screen reader
# already owns `orca`; prefer it whenever present so we never invoke the wrong tool.
_ui_orca() {
  if command -v orca-ide >/dev/null 2>&1; then orca-ide "$@"; else orca "$@"; fi
}

# Orca scopes browser tabs, and optionally terminals, to a worktree.
_ui_orca_wt() {
  [[ -n "${ORCA_WORKTREE_ID:-}" ]] && printf -- '--worktree\n%s\n' "$ORCA_WORKTREE_ID"
}

# ui_term_start <title> <command> -> handle
# Runs command in a new pane beside the current one.
ui_term_start() {
  local title=$1 cmd=$2 out surface
  case "$(ui_kind)" in
    orca)
      mapfile -t wt < <(_ui_orca_wt)
      out=$(_ui_orca terminal create "${wt[@]}" --title "$title" --command "$cmd" 2>&1) || return 1
      # "Created terminal term_xxx (title: ...)"
      printf '%s\n' "$out" | grep -oE 'term_[0-9a-f-]+' | head -1
      ;;
    cmux)
      read -r _ surface _ < <(cmux new-pane --type terminal --direction right --focus false) || return 1
      cmux rename-tab --surface "$surface" "$title" >/dev/null 2>&1 || true
      # cmux has no --command: the pane is a bare shell that accepts input before
      # it can run it, so wait for a prompt, then confirm the line was echoed
      # before pressing Enter. Without this the command is silently swallowed.
      local i
      for ((i = 0; i < 40; i++)); do
        [[ -n "$(cmux read-screen --surface "$surface" --lines 5 2>/dev/null | tr -d '[:space:]')" ]] && break
        sleep 0.25
      done
      sleep 0.5
      local marker attempt echoed=0
      marker=$(printf '%s' "$cmd" | tr -d '[:space:]' | tail -c 24)
      cmux send --surface "$surface" "$cmd" >/dev/null
      for attempt in 1 2 3; do
        sleep 0.7
        if cmux read-screen --surface "$surface" --lines 10 2>/dev/null |
            tr -d '[:space:]' | grep -qF "$marker"; then
          echoed=1
          break
        fi
        ((attempt == 3)) && break
        cmux send-key --surface "$surface" ctrl+u >/dev/null
        cmux send --surface "$surface" "$cmd" >/dev/null
      done
      if ((!echoed)); then
        echo "ui_term_start: pane $surface never echoed the command" >&2
        return 1
      fi
      cmux send-key --surface "$surface" Enter >/dev/null
      printf '%s\n' "$surface"
      ;;
    *) return 1 ;;
  esac
}

# ui_term_find <title> -> handle, empty when no pane carries that title
ui_term_find() {
  local title=$1
  case "$(ui_kind)" in
    orca)
      mapfile -t wt < <(_ui_orca_wt)
      _ui_orca terminal list "${wt[@]}" --json 2>/dev/null |
        jq -r --arg t "$title" '[.result.terminals[]? | select(.title == $t and .connected)] | .[0].handle // empty'
      ;;
    cmux)
      cmux tree --workspace "$CMUX_WORKSPACE_ID" --json 2>/dev/null |
        jq -r --arg t "$title" '[.. | objects | select(.type? == "terminal" and .title? == $t)] | .[0].ref // empty'
      ;;
    *) return 1 ;;
  esac
}

ui_term_read() {
  local handle=$1 lines=${2:-20}
  case "$(ui_kind)" in
    orca) _ui_orca terminal read --terminal "$handle" --screen --limit "$lines" 2>/dev/null ;;
    cmux) cmux read-screen --surface "$handle" --lines "$lines" 2>/dev/null ;;
    *) return 1 ;;
  esac
}

# ui_term_key <handle> <key>  -- a bare keystroke, no newline
ui_term_key() {
  local handle=$1 key=$2
  case "$(ui_kind)" in
    orca) _ui_orca terminal send --terminal "$handle" --text "$key" >/dev/null 2>&1 ;;
    cmux) cmux send-key --surface "$handle" "$key" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

ui_term_close() {
  local handle=$1
  case "$(ui_kind)" in
    orca) _ui_orca terminal close --terminal "$handle" >/dev/null 2>&1 ;;
    cmux) cmux close-surface --surface "$handle" --workspace "$CMUX_WORKSPACE_ID" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

ui_term_focus() {
  local handle=$1 pane
  case "$(ui_kind)" in
    orca) _ui_orca terminal switch --terminal "$handle" >/dev/null 2>&1 ;;
    cmux)
      pane=$(cmux tree --workspace "$CMUX_WORKSPACE_ID" --json 2>/dev/null |
        jq -r --arg s "$handle" '[.. | objects | select(.ref? == $s)] | .[0].pane_ref // empty')
      [[ -n "$pane" ]] || return 1
      cmux focus-pane --pane "$pane" >/dev/null 2>&1
      ;;
    *) return 1 ;;
  esac
}

# ui_browser_find <url prefix> -> handle of a tab already showing that URL
ui_browser_find() {
  local prefix=$1
  case "$(ui_kind)" in
    orca)
      mapfile -t wt < <(_ui_orca_wt)
      _ui_orca tab list "${wt[@]}" --json 2>/dev/null |
        jq -r --arg u "$prefix" '[.result.tabs[]? | select((.url // "") | startswith($u))] | .[0].pageId // .[0].id // empty'
      ;;
    cmux)
      cmux tree --workspace "$CMUX_WORKSPACE_ID" --json 2>/dev/null |
        jq -r --arg u "$prefix" '[.. | objects | select(.type? == "browser") | select((.url // "") | startswith($u))] | .[0].ref // empty'
      ;;
    *) return 1 ;;
  esac
}

ui_browser_open() {
  local url=$1
  case "$(ui_kind)" in
    orca)
      mapfile -t wt < <(_ui_orca_wt)
      _ui_orca tab create "${wt[@]}" --url "$url" >/dev/null 2>&1
      ;;
    cmux) cmux browser open-split "$url" --workspace "$CMUX_WORKSPACE_ID" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

ui_browser_goto() {
  local handle=$1 url=$2
  case "$(ui_kind)" in
    orca)
      mapfile -t wt < <(_ui_orca_wt)
      _ui_orca tab switch "${wt[@]}" --page "$handle" >/dev/null 2>&1 || return 1
      _ui_orca goto "${wt[@]}" --url "$url" >/dev/null 2>&1
      ;;
    cmux) cmux browser "$handle" goto "$url" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

ui_browser_close() {
  local handle=$1
  case "$(ui_kind)" in
    orca)
      mapfile -t wt < <(_ui_orca_wt)
      _ui_orca tab switch "${wt[@]}" --page "$handle" >/dev/null 2>&1 || return 1
      _ui_orca tab close "${wt[@]}" >/dev/null 2>&1
      ;;
    cmux) cmux close-surface --surface "$handle" --workspace "$CMUX_WORKSPACE_ID" >/dev/null 2>&1 ;;
    *) return 1 ;;
  esac
}

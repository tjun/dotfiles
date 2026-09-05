#!/bin/bash
# Claude Code のイベントを stackchan ブリッジへ転送する。
# ブリッジ本体を持たないマシンでは何もせず正常終了する。
set -u
BRIDGE="${HOME}/dev/src/github.com/tjun/stackchan/codexpet/bridge/codex_stackchan_bridge/claude_code_hook.py"
[[ -f "$BRIDGE" ]] || exit 0
command -v python3 >/dev/null 2>&1 || exit 0
exec python3 "$BRIDGE"

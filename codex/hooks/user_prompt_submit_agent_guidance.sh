#!/bin/zsh

set -euo pipefail

cat <<'EOF'
Treat this as a request coming through Codex App.
If any available Skill is relevant, consider activating it even when the user did not explicitly name it; read and follow its SKILL.md when used.
Use subagents when appropriate, especially for large tasks, separable investigation, or work that benefits from parallel execution.
EOF

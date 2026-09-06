#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
CODEX_DIR=${SCRIPT_DIR:h}
RULES_DIR=${CODEX_DIR}/rules
HOOKS_DIR=${CODEX_DIR}/hooks

BASE_CONFIG=${CODEX_DIR}/config.toml
LOCAL_CONFIG=${CODEX_DIR}/config.local.toml
EFFECTIVE_CONFIG=${CODEX_DIR}/config.effective.toml

BASE_RULES=${RULES_DIR}/default.rules
LOCAL_RULES=${RULES_DIR}/default.local.rules
EFFECTIVE_RULES=${RULES_DIR}/default.effective.rules

HOME_CODEX_DIR=${HOME}/.codex
HOME_RULES_DIR=${HOME_CODEX_DIR}/rules
HOME_HOOKS_DIR=${HOME_CODEX_DIR}/hooks
HOME_SKILLS_DIR=${HOME_CODEX_DIR}/skills
CLAUDE_SKILLS_DIR=${HOME}/.claude/skills

# Skills that delegate work to Codex are Claude-only and must not be linked back into Codex.
CLAUDE_ONLY_SKILLS=(codex-cli)

tmp_config=$(mktemp)
cp "${BASE_CONFIG}" "${tmp_config}"
if [[ -f "${LOCAL_CONFIG}" ]]; then
  printf '\n' >> "${tmp_config}"
  cat "${LOCAL_CONFIG}" >> "${tmp_config}"
fi
mv "${tmp_config}" "${EFFECTIVE_CONFIG}"

tmp_rules=$(mktemp)
cp "${BASE_RULES}" "${tmp_rules}"
if [[ -f "${LOCAL_RULES}" ]]; then
  printf '\n' >> "${tmp_rules}"
  cat "${LOCAL_RULES}" >> "${tmp_rules}"
fi
mv "${tmp_rules}" "${EFFECTIVE_RULES}"

mkdir -p "${HOME_RULES_DIR}"
ln -sfn "${EFFECTIVE_RULES}" "${HOME_RULES_DIR}/default.rules"

# ~/.codex/config.toml は Codex 本体と Orca が hooks.state や plugins などの機械状態を
# 書き足しながら丸ごと書き戻す (symlink も実体ファイルに置き換えられる)。そのため
# symlink ではなくコピーを置き、以後は意味差分を見せるだけにして自動では上書きしない。
#   --push で effective を ~/.codex/config.toml に反映する (元はバックアップ)。
# 差分の比較では Codex が管理する状態 (hooks.state, marketplaces, plugins, projects,
# desktop, apps, tui.model_availability_nux) と last_updated / last_revision を除外する。
HOME_CONFIG=${HOME_CODEX_DIR}/config.toml
normalize_toml() {
  python3 - "$1" <<'PY'
import json, sys, tomllib
with open(sys.argv[1], "rb") as f:
    data = tomllib.load(f)
for key in ("marketplaces", "plugins", "projects", "desktop", "apps"):
    data.pop(key, None)
if isinstance(data.get("hooks"), dict):
    data["hooks"].pop("state", None)
if isinstance(data.get("tui"), dict):
    data["tui"].pop("model_availability_nux", None)
def strip(node):
    if isinstance(node, dict):
        return {k: strip(v) for k, v in node.items() if k not in ("last_updated", "last_revision")}
    if isinstance(node, list):
        return [strip(v) for v in node]
    return node
print(json.dumps(strip(data), indent=2, sort_keys=True, ensure_ascii=False))
PY
}
if [[ -L "${HOME_CONFIG}" || ! -e "${HOME_CONFIG}" ]]; then
  rm -f "${HOME_CONFIG}"
  cp "${EFFECTIVE_CONFIG}" "${HOME_CONFIG}"
  echo "installed ${HOME_CONFIG} as a copy of ${EFFECTIVE_CONFIG}"
elif [[ "${1:-}" == "--push" ]]; then
  backup=${HOME_CONFIG}.$(date +%Y%m%d-%H%M%S).bak
  cp "${HOME_CONFIG}" "${backup}"
  cp "${EFFECTIVE_CONFIG}" "${HOME_CONFIG}"
  echo "overwrote ${HOME_CONFIG} (backup: ${backup})"
elif diff -u --label effective <(normalize_toml "${EFFECTIVE_CONFIG}") --label live <(normalize_toml "${HOME_CONFIG}"); then
  echo "in sync: ${HOME_CONFIG}"
else
  echo
  echo "config.effective.toml と ${HOME_CONFIG} に差があります。手で反映するか --push で上書き。"
  config_out_of_sync=1
fi
# hooks ディレクトリは任意。無いまま symlink すると壊れたリンクが残る。
if [[ -d "${HOOKS_DIR}" ]]; then
  ln -sfn "${HOOKS_DIR}" "${HOME_HOOKS_DIR}"
fi

for profile_config in "${CODEX_DIR}"/*.config.toml(N.); do
  ln -sfn "${profile_config}" "${HOME_CODEX_DIR}/${profile_config:t}"
done

if [[ -d "${CLAUDE_SKILLS_DIR}" ]]; then
  mkdir -p "${HOME_SKILLS_DIR}"

  # (-/) は symlink を辿ってディレクトリ判定する。~/.claude/skills の中身は
  # スキルごとの symlink なので、(/) だと 1 つも拾えない。
  for skill_dir in "${CLAUDE_SKILLS_DIR}"/*(N-/); do
    skill_name=${skill_dir:t}
    target=${HOME_SKILLS_DIR}/${skill_name}

    if (( ${CLAUDE_ONLY_SKILLS[(Ie)$skill_name]} )); then
      if [[ -L "${target}" && "${target:A}" == "${skill_dir:A}" ]]; then
        rm "${target}"
      fi
      continue
    fi

    if [[ -e "${skill_dir}/SKILL.md" && ( ! -e "${target}" || -L "${target}" ) ]]; then
      ln -sfn "${skill_dir}" "${target}"
    fi
  done
fi

exit "${config_out_of_sync:-0}"

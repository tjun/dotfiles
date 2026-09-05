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
ln -sfn "${EFFECTIVE_CONFIG}" "${HOME_CODEX_DIR}/config.toml"
ln -sfn "${EFFECTIVE_RULES}" "${HOME_RULES_DIR}/default.rules"
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

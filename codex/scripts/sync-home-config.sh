#!/bin/zsh
# ~/.codex 以下に、リポジトリで管理している Codex 設定 (rules、プロファイル用 config、
# hooks、Claude と共有するスキル) を symlink する。
#
# ~/.codex/config.toml 本体は管理しない。Codex 本体と Orca が hooks.state や plugins、
# projects などの機械状態を書き足しながら丸ごと書き戻すため、リポジトリ側から一方向に
# 流しても取り込む手段が無く、雛形は腐るだけだった。新しいマシンでは既存マシンの
# ~/.codex/config.toml を写して機械依存部分を削る (README 参照)。

set -euo pipefail

SCRIPT_DIR=${0:A:h}
CODEX_DIR=${SCRIPT_DIR:h}
RULES_DIR=${CODEX_DIR}/rules
HOOKS_DIR=${CODEX_DIR}/hooks

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

tmp_rules=$(mktemp)
cp "${BASE_RULES}" "${tmp_rules}"
if [[ -f "${LOCAL_RULES}" ]]; then
  printf '\n' >> "${tmp_rules}"
  cat "${LOCAL_RULES}" >> "${tmp_rules}"
fi
mv "${tmp_rules}" "${EFFECTIVE_RULES}"

mkdir -p "${HOME_RULES_DIR}"
ln -sfn "${EFFECTIVE_RULES}" "${HOME_RULES_DIR}/default.rules"
# hooks ディレクトリは任意。無いまま symlink すると壊れたリンクが残る。
if [[ -d "${HOOKS_DIR}" ]]; then
  ln -sfn "${HOOKS_DIR}" "${HOME_HOOKS_DIR}"
fi

# 旧構成の名残: ~/.codex/config.toml がリポジトリへの symlink なら Codex が書けるよう実体に戻す。
HOME_CONFIG=${HOME_CODEX_DIR}/config.toml
if [[ -L "${HOME_CONFIG}" ]]; then
  cp -L "${HOME_CONFIG}" "${HOME_CONFIG}.tmp" && mv "${HOME_CONFIG}.tmp" "${HOME_CONFIG}"
  echo "replaced symlink ${HOME_CONFIG} with a regular copy"
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

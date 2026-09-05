#!/bin/zsh
# ~/.claude/skills を「実体のディレクトリ + スキルごとの symlink」として組み立てる。
#
# skills ディレクトリ自体をリポジトリへの symlink にすると、hunk のように
# ツール本体が同梱するスキルを追加したときに、マシン依存の絶対パス
# (バージョン番号や OS 名を含む) がリポジトリに入ってしまう。
# スキル単位でリンクすれば、リポジトリ管理のスキルと外部ツール同梱の
# スキルを同じディレクトリに共存させつつ、リポジトリはパスを持たずに済む。

set -euo pipefail

SCRIPT_DIR=${0:A:h}
CLAUDE_DIR=${SCRIPT_DIR:h}
REPO_SKILLS_DIR=${CLAUDE_DIR}/skills
HOME_SKILLS_DIR=${HOME}/.claude/skills

# 旧構成 (skills ディレクトリ全体が symlink) からの移行
if [[ -L "${HOME_SKILLS_DIR}" ]]; then
  rm "${HOME_SKILLS_DIR}"
fi
mkdir -p "${HOME_SKILLS_DIR}"

# 同名の実体ディレクトリ (install-skills.sh が入れた外部スキル) がある場合、
# ln -sfn はそれを置き換えずに中へリンクを作ってしまうので、先に弾く。
link_skill() {
  local target=${HOME_SKILLS_DIR}/${2}
  if [[ -e "${target}" && ! -L "${target}" ]]; then
    print -u2 "skip: ${target} は実体のディレクトリ (skills.txt と名前が衝突している)"
    return
  fi
  ln -sfn "${1}" "${target}"
}

for skill_dir in "${REPO_SKILLS_DIR}"/*(N/); do
  link_skill "${skill_dir}" "${skill_dir:t}"
done

# hunk 同梱のスキル。`hunk skill path` はインストール先の絶対パスを返すので、
# PATH 上の hunk に解決させることでバージョン更新にも追随できる。
if (( $+commands[hunk] )); then
  hunk_skill=$(hunk skill path hunk-review 2>/dev/null) || hunk_skill=""
  if [[ -n "${hunk_skill}" && -f "${hunk_skill}" ]]; then
    link_skill "${hunk_skill:h}" "${hunk_skill:h:t}"
  fi
fi

# 参照先が消えた symlink (アンインストールされたツールなど) を掃除する。
# (N@) は symlink だけを拾うので、gh skill install が置いた実体は触らない。
for link in "${HOME_SKILLS_DIR}"/*(N@); do
  [[ -e "${link}" ]] || rm "${link}"
done

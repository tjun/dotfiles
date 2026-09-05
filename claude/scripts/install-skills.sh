#!/bin/zsh
# claude/skills.txt に列挙した外部スキルを `gh skill install` で導入する。
#
# 自作スキル (リポジトリで管理) と違い、これらはインストールするだけで
# 中身をリポジトリに持たない。持つべきなのは「どれを入れるか」の一覧だけ。
# 導入先は user scope (~/.claude/skills) で、link-skills.sh が張る symlink と
# 同じディレクトリに実体のディレクトリとして並ぶ。

set -euo pipefail

SCRIPT_DIR=${0:A:h}
CLAUDE_DIR=${SCRIPT_DIR:h}
MANIFEST=${CLAUDE_DIR}/skills.txt

if [[ ! -f "${MANIFEST}" ]]; then
  print -u2 "skip: ${MANIFEST} が無い"
  exit 0
fi

if ! (( $+commands[gh] )); then
  print -u2 "skip: gh が無い"
  exit 0
fi

# `gh skill` は preview なので、gh が古いマシンでは黙って諦める
if ! gh skill --help >/dev/null 2>&1; then
  print -u2 "skip: この gh は 'gh skill' に未対応 (${$(gh --version | head -1)})"
  exit 0
fi

# 導入済みスキル名の一覧。取得できなければ空扱いにして install 側の判断に任せる
installed=()
if raw=$(gh skill list --agent claude-code --scope user --json skillName --jq '.[].skillName' 2>/dev/null); then
  installed=(${(f)raw})
fi

while read -r line; do
  line=${line%%\#*}
  line=${line##[[:space:]]##}
  line=${line%%[[:space:]]##}
  [[ -n "${line}" ]] || continue

  entry=(${=line})
  repo=${entry[1]}
  skill=${entry[2]:-}

  if [[ -z "${skill}" ]]; then
    print "installing all skills from ${repo}"
    gh skill install "${repo}" --all --agent claude-code --scope user --force
    continue
  fi

  # 入れ子パスとバージョン指定を落とした最終ディレクトリ名が、導入後のスキル名になる
  name=${${skill%%@*}:t}
  if (( ${installed[(Ie)$name]} )); then
    print "already installed: ${name}"
    continue
  fi

  print "installing ${name} from ${repo}"
  gh skill install "${repo}" "${skill}" --agent claude-code --scope user --force
done < "${MANIFEST}"

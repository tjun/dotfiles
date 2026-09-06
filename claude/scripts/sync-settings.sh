#!/bin/zsh
# ~/.claude/settings.json をリポジトリの claude/settings.json (雛形) と突き合わせる。
#
# settings.json は Claude Code 本体と Orca がキー順や末尾カンマを変えながら書き戻す
# ので、symlink で直結すると git に意味の無い差分が出続ける。そこで実体は ~/.claude に
# コピーして置き、揃えたいときだけこのスクリプトで意味差分 (キーをソートした JSON の
# diff) を見て手で反映する。
#
#   sync-settings.sh          差分を表示するだけ (無ければ "in sync")
#   sync-settings.sh --push   雛形で ~/.claude/settings.json を上書き (元はバックアップ)
#   sync-settings.sh --pull   ~/.claude/settings.json を雛形にコピー (git diff で確認する)
#
# ~/.claude/settings.json が無いか、旧構成の symlink のときは黙ってコピーに置き換える。

set -euo pipefail

SCRIPT_DIR=${0:A:h}
TEMPLATE=${SCRIPT_DIR:h}/settings.json
LIVE=${HOME}/.claude/settings.json
BACKUP_DIR=${HOME}/.claude/backups

mode=${1:-diff}

normalize() {
  python3 -c 'import json,sys; print(json.dumps(json.load(open(sys.argv[1])), indent=2, sort_keys=True, ensure_ascii=False))' "$1"
}

if [[ -L "${LIVE}" || ! -e "${LIVE}" ]]; then
  rm -f "${LIVE}"
  cp "${TEMPLATE}" "${LIVE}"
  echo "installed ${LIVE} as a copy of ${TEMPLATE}"
  exit 0
fi

case "${mode}" in
  --push)
    mkdir -p "${BACKUP_DIR}"
    backup=${BACKUP_DIR}/settings.json.$(date +%Y%m%d-%H%M%S)
    cp "${LIVE}" "${backup}"
    cp "${TEMPLATE}" "${LIVE}"
    echo "overwrote ${LIVE} (backup: ${backup})"
    ;;
  --pull)
    cp "${LIVE}" "${TEMPLATE}"
    echo "copied ${LIVE} -> ${TEMPLATE}; review with: git diff claude/settings.json"
    ;;
  diff)
    if diff -u --label template <(normalize "${TEMPLATE}") --label live <(normalize "${LIVE}"); then
      echo "in sync: ${LIVE}"
    else
      echo
      echo "template と live に差があります。--push で雛形を反映、--pull で live を雛形に取り込み。"
      exit 1
    fi
    ;;
  *)
    echo "usage: $0 [--push|--pull]" >&2
    exit 2
    ;;
esac

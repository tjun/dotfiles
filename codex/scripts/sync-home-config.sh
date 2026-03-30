#!/bin/zsh

set -euo pipefail

SCRIPT_DIR=${0:A:h}
CODEX_DIR=${SCRIPT_DIR:h}
RULES_DIR=${CODEX_DIR}/rules

BASE_CONFIG=${CODEX_DIR}/config.toml
LOCAL_CONFIG=${CODEX_DIR}/config.local.toml
EFFECTIVE_CONFIG=${CODEX_DIR}/config.effective.toml

BASE_RULES=${RULES_DIR}/default.rules
LOCAL_RULES=${RULES_DIR}/default.local.rules
EFFECTIVE_RULES=${RULES_DIR}/default.effective.rules

HOME_CODEX_DIR=${HOME}/.codex
HOME_RULES_DIR=${HOME_CODEX_DIR}/rules

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

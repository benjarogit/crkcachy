#!/usr/bin/env bash
# Structured debug logging – file + optional terminal

set -euo pipefail

CRKCACHY_LOG_DIR="${HOME}/.local/share/crkcachy/logs"
CRKCACHY_DEBUG="${CRKCACHY_DEBUG:-0}"
CRKCACHY_LOG_FILE="${CRKCACHY_LOG_FILE:-}"

crkcachy_init_logging() {
  mkdir -p "$CRKCACHY_LOG_DIR"
  if [[ -z "${CRKCACHY_LOG_FILE:-}" ]]; then
    CRKCACHY_LOG_FILE="${CRKCACHY_LOG_DIR}/crkcachy-$(date +%Y%m%d-%H%M%S).log"
  fi
  export CRKCACHY_LOG_FILE
  _crkcachy_log_write "INFO" "CRKCACHY v${CRKCACHY_VERSION} – log started"
  _crkcachy_log_write "INFO" "User: ${USER:-unknown} | PWD: ${PWD:-}"
}

_crkcachy_log_write() {
  local level="$1"
  shift
  local message="$*"
  local ts

  [[ -n "${CRKCACHY_LOG_FILE:-}" ]] || return 0
  ts="$(date '+%Y-%m-%d %H:%M:%S')"
  printf '[%s] [%s] %s\n' "$ts" "$level" "$message" >> "$CRKCACHY_LOG_FILE"
}

log_debug() {
  _crkcachy_log_write "DEBUG" "$*"
  if [[ "${CRKCACHY_DEBUG}" == 1 ]]; then
    echo -e "${_C_DIM}        [debug] $*${_C_RESET}" >&2
  fi
}

log_trace() {
  _crkcachy_log_write "TRACE" "$*"
}

log_cmd() {
  local cmd="$*"
  log_debug "exec: ${cmd}"
  _crkcachy_log_write "CMD" "${cmd}"
}

crkcachy_log_path() {
  echo "${CRKCACHY_LOG_FILE:-}"
}

#!/usr/bin/env bash
# CRKCACHY common library – logging, prompts, package helpers

set -euo pipefail

CRKCACHY_VERSION="0.1.3"
CRKCACHY_ROOT="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
CRKCACHY_LANG_PRESET="${CRKCACHY_LANG_PRESET:-}"

if [[ -z "${NO_COLOR:-}" ]]; then
  _C_RESET='\033[0m'
  _C_RED='\033[0;31m'
  _C_GREEN='\033[0;32m'
  _C_YELLOW='\033[1;33m'
  _C_BLUE='\033[0;34m'
  _C_CYAN='\033[0;36m'
  _C_DIM='\033[2m'
  _C_BOLD='\033[1m'
else
  _C_RESET= _C_RED= _C_GREEN= _C_YELLOW= _C_BLUE= _C_CYAN= _C_DIM= _C_BOLD=
fi

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
init_i18n

log_info()  { echo -e "${_C_BLUE}[$(msg tag.info)]${_C_RESET} $*"; }
log_ok()    { echo -e "${_C_GREEN}[$(msg tag.ok)]${_C_RESET} $*"; }
log_warn()  { echo -e "${_C_YELLOW}[$(msg tag.warn)]${_C_RESET} $*"; }
log_error() { echo -e "${_C_RED}[$(msg tag.error)]${_C_RESET} $*" >&2; }
log_hint()  { echo -e "${_C_CYAN}        → $*${_C_RESET}"; }

die() {
  log_error "$*"
  exit 1
}

explain_block() {
  echo ""
  echo -e "${_C_BOLD}$1${_C_RESET}"
  local line
  while IFS= read -r line; do
    [[ -n "$line" ]] && echo "  $line"
  done <<< "$2"
  echo ""
}

confirm() {
  local prompt="${1:-}"
  local default_no="${2:-true}"
  local reply suffix

  if [[ "$default_no" == "true" ]]; then
    suffix="$(msg confirm.suffix_no)"
  else
    suffix="$(msg confirm.suffix_yes)"
  fi

  read -r -p "${prompt}${suffix}" reply
  [[ "${reply,,}" == "j" || "${reply,,}" == "y" || "${reply,,}" == "ja" || "${reply,,}" == "yes" ]]
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command_exists "$cmd"; then
    if [[ -n "$hint" ]]; then
      die "$cmd $(msgf cmd.not_found_hint "$hint")"
    else
      die "$cmd $(msg cmd.not_found)"
    fi
  fi
}

pacman_installed() {
  local pkg="$1"
  pacman -Q "$pkg" >/dev/null 2>&1
}

install_packages_paru() {
  local packages=("$@")
  local missing=()

  for pkg in "${packages[@]}"; do
    if ! pacman_installed "$pkg"; then
      missing+=("$pkg")
    fi
  done

  if [[ ${#missing[@]} -eq 0 ]]; then
    log_ok "$(msg paru.all_installed)"
    return 0
  fi

  log_info "$(msgf paru.missing "${missing[*]}")"
  explain_block "$(msg paru.explain_title)" "$(msg paru.explain_body)"

  if confirm "$(msg paru.confirm_install)"; then
    require_command paru "$(msg paru.install_paru_hint)"
    paru -S --needed --noconfirm "${missing[@]}"
    log_ok "$(msg paru.done)"
  else
    log_warn "$(msg paru.skipped)"
    log_hint "$(msgf paru.manual "${missing[*]}")"
    return 1
  fi
}

print_banner() {
  echo -e "${_C_BOLD}CRKCACHY v${CRKCACHY_VERSION}${_C_RESET}"
  echo "$(msg banner.subtitle)"
  echo "https://github.com/benjarogit/crkcachy"
  if [[ -n "$CRKCACHY_LANG_PRESET" ]]; then
    echo -e "${_C_DIM}$(msg lang.override)${_C_RESET}"
  else
    echo -e "${_C_DIM}$(msg lang.detected)${_C_RESET}"
  fi
  echo ""
}

# Tool discovery – see lib/tools.sh

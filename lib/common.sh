#!/usr/bin/env bash
# CRKCACHY common library – logging, prompts, package helpers

set -euo pipefail

CRKCACHY_VERSION="0.1.0"
CRKCACHY_ROOT="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Colors (disabled if NO_COLOR set)
if [[ -z "${NO_COLOR:-}" ]]; then
  _C_RESET='\033[0m'
  _C_RED='\033[0;31m'
  _C_GREEN='\033[0;32m'
  _C_YELLOW='\033[1;33m'
  _C_BLUE='\033[0;34m'
  _C_BOLD='\033[1m'
else
  _C_RESET= _C_RED= _C_GREEN= _C_YELLOW= _C_BLUE= _C_BOLD=
fi

log_info()  { echo -e "${_C_BLUE}[INFO]${_C_RESET} $*"; }
log_ok()    { echo -e "${_C_GREEN}[OK]${_C_RESET} $*"; }
log_warn()  { echo -e "${_C_YELLOW}[WARN]${_C_RESET} $*"; }
log_error() { echo -e "${_C_RED}[ERROR]${_C_RESET} $*" >&2; }

die() {
  log_error "$*"
  exit 1
}

confirm() {
  local prompt="${1:-Continue?}"
  local default_no="${2:-true}"
  local reply

  if [[ "$default_no" == "true" ]]; then
    read -r -p "${prompt} [y/N] " reply
    [[ "${reply,,}" == "y" || "${reply,,}" == "yes" ]]
  else
    read -r -p "${prompt} [Y/n] " reply
    [[ -z "$reply" || "${reply,,}" == "y" || "${reply,,}" == "yes" ]]
  fi
}

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

require_command() {
  local cmd="$1"
  local hint="${2:-}"
  if ! command_exists "$cmd"; then
    if [[ -n "$hint" ]]; then
      die "$cmd not found. $hint"
    else
      die "$cmd not found."
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
    log_ok "All packages already installed: ${packages[*]}"
    return 0
  fi

  log_info "Missing packages: ${missing[*]}"
  if confirm "Install via paru -S --needed?"; then
    require_command paru "Install paru: sudo pacman -S paru"
    paru -S --needed --noconfirm "${missing[@]}"
    log_ok "Package install finished."
  else
    log_warn "Skipped package install. Install manually: paru -S --needed ${missing[*]}"
    return 1
  fi
}

print_banner() {
  echo -e "${_C_BOLD}CRKCACHY v${CRKCACHY_VERSION}${_C_RESET} – CachyOS + Steam tool collection"
  echo "https://github.com/benjarogit/crkcachy"
  echo ""
}

list_tools() {
  local tools_dir="${CRKCACHY_ROOT}/tools"
  local found=0

  if [[ ! -d "$tools_dir" ]]; then
    return 1
  fi

  for tool_install in "$tools_dir"/*/install.sh; do
    [[ -f "$tool_install" ]] || continue
    local name
    name="$(basename "$(dirname "$tool_install")")"
    echo "  - $name"
    found=$((found + 1))
  done

  return "$((found == 0))"
}

run_tool_menu() {
  local tools_dir="${CRKCACHY_ROOT}/tools"
  local tools=()
  local i=1

  for tool_install in "$tools_dir"/*/install.sh; do
    [[ -f "$tool_install" ]] || continue
    tools+=("$tool_install")
    local name
    name="$(basename "$(dirname "$tool_install")")"
    echo "  $i) $name"
    i=$((i + 1))
  done

  if [[ ${#tools[@]} -eq 0 ]]; then
    log_warn "No tools found in tools/"
    return 1
  fi

  echo ""
  read -r -p "Select tool number (or empty to skip): " choice

  if [[ -z "${choice:-}" ]]; then
    log_info "No tool selected."
    return 0
  fi

  if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#tools[@]} )); then
    log_warn "Invalid selection."
    return 1
  fi

  local selected="${tools[$((choice - 1))]}"
  log_info "Running $(basename "$(dirname "$selected")")..."
  bash "$selected"
}

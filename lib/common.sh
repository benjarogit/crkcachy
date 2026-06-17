#!/usr/bin/env bash
# CRKCACHY common library – logging, prompts, package helpers

set -euo pipefail

CRKCACHY_VERSION="0.1.76"
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

command_exists() {
  command -v "$1" >/dev/null 2>&1
}

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
init_i18n

# shellcheck source=lib/platform.sh
source "${CRKCACHY_ROOT}/lib/platform.sh"
platform_detect

_log_file() {
  declare -F _crkcachy_log_write >/dev/null 2>&1 && _crkcachy_log_write "$1" "$2" || true
}

log_info()  { echo -e "${_C_BLUE}[$(msg tag.info)]${_C_RESET} $*";  _log_file "INFO"  "$*"; }
log_ok()    { echo -e "${_C_GREEN}[$(msg tag.ok)]${_C_RESET} $*";   _log_file "OK"    "$*"; }
log_warn()  { echo -e "${_C_YELLOW}[$(msg tag.warn)]${_C_RESET} $*"; _log_file "WARN"  "$*"; }
log_error() { echo -e "${_C_RED}[$(msg tag.error)]${_C_RESET} $*" >&2; _log_file "ERROR" "$*"; }
log_hint()  { echo -e "${_C_CYAN}        → $*${_C_RESET}";          _log_file "HINT"  "$*"; }

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

# shellcheck source=lib/debug.sh
source "${CRKCACHY_ROOT}/lib/debug.sh"
# Logging immer aktiv – Session-Log unter ~/.local/share/crkcachy/logs/
crkcachy_init_logging
if [[ "${CRKCACHY_DEBUG:-0}" == 1 ]]; then
  log_debug "Debug mode active – log: $(crkcachy_log_path)"
fi

# shellcheck source=lib/package_explain.sh
source "${CRKCACHY_ROOT}/lib/package_explain.sh"
# shellcheck source=lib/game_paths.sh
source "${CRKCACHY_ROOT}/lib/game_paths.sh"
# shellcheck source=lib/tool_actions.sh
source "${CRKCACHY_ROOT}/lib/tool_actions.sh"
# shellcheck source=lib/tool_catalog.sh
source "${CRKCACHY_ROOT}/lib/tool_catalog.sh"
# shellcheck source=lib/tool_fetch.sh
source "${CRKCACHY_ROOT}/lib/tool_fetch.sh"
# shellcheck source=lib/tool_hub.sh
source "${CRKCACHY_ROOT}/lib/tool_hub.sh"

# Plain prompt before gum is available (bootstrap only)
bootstrap_confirm() {
  local prompt="${1:-}"
  local default_no="${2:-true}"
  local reply suffix

  suffix="$(msg confirm.suffix)"
  read -r -p "${prompt} ${suffix}" reply

  if [[ -z "${reply:-}" ]]; then
    [[ "$default_no" != "true" ]]
    return
  fi

  case "${reply,,}" in
    j|y|ja|yes) return 0 ;;
    n|no|nein) return 1 ;;
    *) [[ "$default_no" != "true" ]] ;;
  esac
}

# Resolve DE/EN markdown path (README.md ↔ README.en.md, legal.md ↔ legal.en.md).
crkcachy_markdown_path() {
  local rel="$1"
  local en_rel

  if [[ "$CRKCACHY_LANG" == "en" && "$rel" == *.md ]]; then
    en_rel="${rel%.md}.en.md"
    if [[ -f "${CRKCACHY_ROOT}/${en_rel}" ]]; then
      echo "${CRKCACHY_ROOT}/${en_rel}"
      return 0
    fi
  fi

  echo "${CRKCACHY_ROOT}/${rel}"
}

pacman_installed() {
  package_is_installed "$1"
}

# Run a package installer command with optional gum spinner.
_run_package_installer() {
  local use_spin="${1:-true}"
  shift
  local installer=("$1")
  shift
  local packages=("$@")

  if [[ "$use_spin" == "true" ]] && command_exists gum && [[ -t 0 && -t 1 ]]; then
    cui_spin "$(msg paru.installing)" "${installer[@]}" "${packages[@]}"
  else
    log_info "$(msg paru.installing)"
    "${installer[@]}" "${packages[@]}"
  fi
}

# Resolve logical Rosetta names to native packages; pass through unknown names.
_resolve_install_packages() {
  local -a resolved=()
  local arg logical pkgs pkg

  for arg in "$@"; do
    if platform_logical_known "$arg"; then
      pkgs="$(platform_resolve_packages "$arg")"
      if [[ -z "$pkgs" ]]; then
        log_warn "$(msgf platform.rosetta_manual "$arg")"
        continue
      fi
      for pkg in $pkgs; do
        resolved+=("$pkg")
      done
    else
      resolved+=("$arg")
    fi
  done

  if [[ ${#resolved[@]} -eq 0 ]]; then
    return 1
  fi

  printf '%s\0' "${resolved[@]}"
}

# Official-repo packages – uses detected package manager (safe flags only).
install_repo_packages() {
  local use_spin="${1:-true}"
  shift
  local packages=("$@")
  local installer=()
  local -a resolved=()

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 1
  fi

  while IFS= read -r -d '' pkg; do
    resolved+=("$pkg")
  done < <(_resolve_install_packages "${packages[@]}")

  if [[ ${#resolved[@]} -eq 0 ]]; then
    log_error "$(msg pkg.no_installer)"
    return 1
  fi

  if ! platform_build_repo_installer installer; then
    log_error "$(msg pkg.no_installer)"
    return 1
  fi

  _run_package_installer "$use_spin" "${installer[@]}" "${resolved[@]}"
}

# Install one logical package from official repos (gum/glow bootstrap).
_ensure_logical_repo_package() {
  local logical="$1"
  local -a pkgs=()

  if ! platform_logical_has_mapping "$logical"; then
    log_warn "$(msgf platform.rosetta_manual "$logical")"
    return 1
  fi

  read -ra pkgs <<< "$(platform_resolve_packages "$logical")"
  install_repo_packages false "${pkgs[@]}"
}

# Install packages – AUR helper on Arch, native PM elsewhere.
install_system_packages() {
  local use_spin="${1:-true}"
  shift
  local packages=("$@")
  local installer=()
  local -a resolved=()

  if [[ ${#packages[@]} -eq 0 ]]; then
    return 1
  fi

  while IFS= read -r -d '' pkg; do
    resolved+=("$pkg")
  done < <(_resolve_install_packages "${packages[@]}")

  if [[ ${#resolved[@]} -eq 0 ]]; then
    log_error "$(msg pkg.no_installer)"
    return 1
  fi

  if ! platform_build_full_installer installer; then
    log_error "$(msg pkg.no_installer)"
    return 1
  fi

  _run_package_installer "$use_spin" "${installer[@]}" "${resolved[@]}"
}

# Auto-install or show manual command – never hard-block on "no".
offer_package_install() {
  local confirm_msg="$1"
  local manual_hint="$2"
  shift 2
  local packages=("$@")

  if confirm "$confirm_msg"; then
    if install_system_packages true "${packages[@]}"; then
      log_ok "$(msg paru.done)"
      return 0
    fi
    log_warn "$(msg paru.install_failed)"
    log_hint "$manual_hint"
    return 1
  fi

  log_warn "$(msg paru.skipped)"
  log_hint "$(msg offer.manual_label)"
  log_hint "$manual_hint"
  return 1
}

# shellcheck source=lib/ui.sh
source "${CRKCACHY_ROOT}/lib/ui.sh"
# shellcheck source=lib/cui.sh
source "${CRKCACHY_ROOT}/lib/cui.sh"
# shellcheck source=lib/tui.sh
source "${CRKCACHY_ROOT}/lib/tui.sh"

confirm() {
  cui_yes_no "$1" "${2:-true}"
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

install_packages_paru() {
  offer_logical_packages true "$@"
}

install_packages_repo() {
  offer_logical_packages false "$@"
}

ensure_gum() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    die "$(msg gum.no_tty)"
  fi

  if command_exists gum; then
    return 0
  fi

  explain_block "$(msg gum.missing_title)" "$(package_explain_text gum)

$(msg pkg.explain.footer)"

  while ! command_exists gum; do
    echo -e "${_C_BOLD}$(msg gum.pick_title)${_C_RESET}"
    echo "  1) $(msg gum.opt_auto)"
    echo "  2) $(msg gum.opt_manual)"
    echo ""
    read -r -p "$(msg gum.pick_prompt) " gum_choice

    case "${gum_choice:-1}" in
      1|j|y|ja|yes)
        log_hint "$(msg gum.password_hint)"
        if _ensure_logical_repo_package gum; then
          hash -r 2>/dev/null || true
        else
          log_warn "$(msg gum.install_failed)"
        fi
        if command_exists gum; then
          log_ok "$(msg gum.installed)"
          break
        fi
        log_warn "$(msg gum.still_missing)"
        ;;
      2|n|no|nein)
        ;;
      *)
        log_warn "$(msg gum.pick_invalid)"
        continue
        ;;
    esac

    echo ""
    log_hint "$(msg gum.manual_steps_intro)"
    log_hint "$(platform_manual_install_cmd_logical gum)"
    echo ""
    read -r -p "$(msg gum.manual_wait) " _
    hash -r 2>/dev/null || true

    if command_exists gum; then
      log_ok "$(msg gum.installed)"
      break
    fi

    log_warn "$(msg gum.still_missing)"
    echo ""
  done
}

ensure_glow() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    die "$(msg glow.no_tty)"
  fi

  if command_exists glow; then
    return 0
  fi

  if command_exists gum; then
    cui_panel "$(msg glow.missing_title)" "$(package_explain_text glow)

$(msg pkg.explain.footer)"
    echo ""
  else
    explain_block "$(msg glow.missing_title)" "$(package_explain_text glow)

$(msg pkg.explain.footer)"
  fi

  while ! command_exists glow; do
    local glow_choice pick

    if command_exists gum; then
      pick="$(gum choose --selected 0 \
        --header "$(msg glow.pick_title)" \
        --cursor "› " \
        "$(msg glow.opt_auto)" \
        "$(msg glow.opt_manual)")"

      case "$pick" in
        "$(msg glow.opt_auto)") glow_choice=1 ;;
        "$(msg glow.opt_manual)") glow_choice=2 ;;
        *) glow_choice=1 ;;
      esac
    else
      echo -e "${_C_BOLD}$(msg glow.pick_title)${_C_RESET}"
      echo "  1) $(msg glow.opt_auto)"
      echo "  2) $(msg glow.opt_manual)"
      echo ""
      read -r -p "$(msg glow.pick_prompt) " glow_choice
    fi

    case "${glow_choice:-1}" in
      1|j|y|ja|yes|"$(msg glow.opt_auto)")
        log_hint "$(msg glow.password_hint)"
        if _ensure_logical_repo_package glow; then
          hash -r 2>/dev/null || true
        else
          log_warn "$(msg glow.install_failed)"
        fi
        if command_exists glow; then
          log_ok "$(msg glow.installed)"
          break
        fi
        log_warn "$(msg glow.still_missing)"
        ;;
      2|n|no|nein|"$(msg glow.opt_manual)")
        ;;
      *)
        log_warn "$(msg glow.pick_invalid)"
        continue
        ;;
    esac

    echo ""
    log_hint "$(msg glow.manual_steps_intro)"
    log_hint "$(platform_manual_install_cmd_logical glow)"
    echo ""
    if command_exists gum; then
      cui_continue
    else
      read -r -p "$(msg glow.manual_wait) " _
    fi
    hash -r 2>/dev/null || true

    if command_exists glow; then
      log_ok "$(msg glow.installed)"
      break
    fi

    log_warn "$(msg glow.still_missing)"
    echo ""
  done
}

ensure_crkcachy_runtime() {
  if ! command_exists gum || ! command_exists glow; then
    explain_block "$(msg runtime.bootstrap_title)" "$(msg runtime.bootstrap_body)"
    echo ""
    log_hint "$(msg runtime.bootstrap_hint)"
    echo ""
  fi

  ensure_gum
  ensure_glow
}

print_banner() {
  cui_brand_header
}

# Tool discovery – see lib/tools.sh

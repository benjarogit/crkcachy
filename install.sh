#!/usr/bin/env bash
# CRKCACHY master installer – step-by-step wizard

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$SCRIPT_DIR"

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
parse_lang_arg "$@"

# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"
# shellcheck source=lib/tools.sh
source "${CRKCACHY_ROOT}/lib/tools.sh"
# shellcheck source=lib/cachyos.sh
source "${CRKCACHY_ROOT}/lib/cachyos.sh"
# shellcheck source=lib/steam.sh
source "${CRKCACHY_ROOT}/lib/steam.sh"
# shellcheck source=lib/proton.sh
source "${CRKCACHY_ROOT}/lib/proton.sh"

BASE_PACKAGES=(
  protonup-rs-bin
  vkd3d
  lib32-vkd3d
  lib32-gamemode
  gvfs
  winetricks
)

OPTIONAL_PACKAGES=(
  protonup-qt
)

VULKAN_PACKAGES=(
  vulkan-icd-loader
  lib32-vulkan-icd-loader
)

run_system_setup() {
  preflight
  install_base_packages
  setup_proton
  setup_spacewar
  print_overlay_hint
}

preflight() {
  log_info "$(msg install.step1)"
  check_cachyos || true
  check_paru || true
  check_steam || true
  echo ""
}

install_base_packages() {
  log_info "$(msg install.step2)"

  explain_block "$(msg install.packages_explain_title)" "$(msg install.packages_explain_body)"

  install_packages_paru "${BASE_PACKAGES[@]}" || true

  explain_block "$(msg install.qt_title)" "$(msg install.qt_body)"

  if confirm "$(msg install.qt_confirm)"; then
    install_packages_paru "${OPTIONAL_PACKAGES[@]}" || true
  else
    log_ok "$(msg install.qt_skipped)"
  fi

  explain_block "$(msg install.vulkan_title)" "$(msg install.vulkan_body)"

  if confirm "$(msg install.vulkan_confirm)"; then
    install_packages_paru "${VULKAN_PACKAGES[@]}" || true
  else
    log_ok "$(msg install.vulkan_skipped)"
  fi

  if ! pacman_installed steam; then
    log_warn "$(msg install.steam_missing)"
    explain_block "$(msg install.steam_title)" "$(msg install.steam_body)"
    if confirm "$(msg install.steam_confirm)"; then
      install_packages_paru steam || true
    fi
  fi
  echo ""
}

setup_proton() {
  log_info "$(msg install.step3)"

  if ! check_protonup; then
    log_warn "$(msg install.protonup_missing)"
    echo ""
    return
  fi

  if verify_ge_proton; then
    explain_block "$(msg install.ge_present_title)" "$(msg install.ge_present_body)"

    if confirm "$(msg install.ge_update_confirm)"; then
      install_ge_proton || true
    else
      log_ok "$(msg install.ge_kept)"
    fi
  else
    explain_block "$(msg install.ge_missing_title)" "$(msg install.ge_missing_body)"
    install_ge_proton || true
  fi
  echo ""
}

setup_spacewar() {
  log_info "$(msg install.step4)"

  explain_block "$(msg install.spacewar_title)" "$(msg install.spacewar_body)"

  check_spacewar || true
  echo ""
}

run_game_setup() {
  log_info "$(msg install.step5)"
  run_tool_wizard || true
  echo ""
}

print_status() {
  local ok=0 fail=0

  print_banner
  log_info "$(msg install.status_title)"
  echo ""

  if check_cachyos; then ok=$((ok+1)); else fail=$((fail+1)); fi
  if check_paru; then ok=$((ok+1)); else fail=$((fail+1)); fi
  if check_steam; then ok=$((ok+1)); else fail=$((fail+1)); fi
  if check_protonup; then ok=$((ok+1)); else fail=$((fail+1)); fi
  if verify_ge_proton; then ok=$((ok+1)); else fail=$((fail+1)); fi
  if check_spacewar; then ok=$((ok+1)); else fail=$((fail+1)); fi

  echo ""
  log_info "$(msg install.packages_title)"
  for pkg in steam "${BASE_PACKAGES[@]}" "${VULKAN_PACKAGES[@]}"; do
    if pacman_installed "$pkg"; then
      log_ok "$pkg"
      ok=$((ok+1))
    else
      log_warn "$(msgf install.pkg_missing "$pkg")"
      fail=$((fail+1))
    fi
  done

  echo ""
  discover_tools && print_tool_list || true

  echo ""
  if [[ $fail -eq 0 ]]; then
    log_ok "$(msg install.all_ready)"
    log_hint "./install.sh  → Option 3 für nur Spiel"
  else
    log_warn "$(msgf install.points_open "$fail" "$ok")"
    log_hint "./install.sh  → Option 1 oder 2"
  fi
}

show_wizard_menu() {
  explain_block "$(msg wizard.title)" "$(msg wizard.body)"

  echo "  1) $(msg wizard.opt1)"
  echo "  2) $(msg wizard.opt2)"
  echo "  3) $(msg wizard.opt3)"
  echo "  4) $(msg wizard.opt4)"
  echo ""

  read -r -p "$(msg wizard.prompt)" choice

  case "${choice:-}" in
    1)
      run_system_setup
      run_game_setup
      ;;
    2)
      run_system_setup
      ;;
    3)
      run_game_setup
      ;;
    4)
      print_status
      exit 0
      ;;
    *)
      log_warn "$(msg wizard.invalid)"
      return 1
      ;;
  esac

  return 0
}

has_flag() {
  local flag="$1"
  for arg in "$@"; do
    [[ "$arg" == "$flag" ]] && return 0
  done
  return 1
}

main() {
  if has_flag --status "$@" || has_flag -s "$@"; then
    print_status
    exit 0
  fi

  print_banner

  explain_block "$(msg install.legal_title)" "$(msg install.legal_body)"
  explain_block "$(msg install.how_title)" "$(msg install.how_body)"

  if ! show_wizard_menu; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  log_ok "$(msg install.finished)"
  log_info "$(msg install.next_readme)"
  log_hint "tools/<spiel>/README.md"
}

main "$@"

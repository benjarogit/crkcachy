#!/usr/bin/env bash
# CRKCACHY master installer – assessment-driven wizard

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
# shellcheck source=lib/assess.sh
source "${CRKCACHY_ROOT}/lib/assess.sh"
# shellcheck source=lib/preflight.sh
source "${CRKCACHY_ROOT}/lib/preflight.sh"

ASSESS_LOGICAL_BASE=(
  vkd3d
  gamemode
  gvfs
  winetricks
)

ASSESS_LOGICAL_VULKAN=(
  vulkan-loader
)

ASSESS_STEAM_LOGICAL=steam

announce_choice() {
  local choice="${1:-}"

  if [[ -z "$choice" ]]; then
    ui_action "$(msg flow.chose_enter)"
    case "$ASSESS_RECOMMENDED" in
      3) ui_action "$(msg flow.chose_3)" ;;
      2) ui_action "$(msg flow.chose_2)" ;;
      *) ui_action "$(msg flow.chose_1)" ;;
    esac
    return
  fi

  ui_action "$(msgf flow.chose "$choice")"
  case "$choice" in
    1) ui_action "$(msg flow.chose_1)" ;;
    2) ui_action "$(msg flow.chose_2)" ;;
    3) ui_action "$(msg flow.chose_3)" ;;
  esac
}

run_pc_fix() {
  ui_step "$(msg install.step2)"

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    log_ok "$(msg assess.pc_already_ok)"
    print_overlay_hint
    return 0
  fi

  assess_guided_fix
  print_overlay_hint
}

run_game_setup() {
  ui_step "$(msg install.step5)"
  ui_action "$(msg flow.game_tool)"

  if ! assess_ensure_ready; then
    return 1
  fi

  run_tool_wizard || true
  echo ""
  return 0
}

offer_post_install_readme() {
  local readme_rel="README.md"

  if discover_tools && [[ ${#TOOL_SLUGS[@]} -eq 1 ]]; then
    readme_rel="tools/${TOOL_SLUGS[0]}/README.md"
  fi

  cui_offer_markdown "$readme_rel" "$(msg install.show_readme)" || true
}

print_status() {
  ensure_crkcachy_runtime
  print_banner
  preflight_status_only
  echo ""
  assess_run
  tui_assess_panel || true
  echo ""

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    log_ok "$(msg status.ready_next)"
  fi

  ui_divider
  log_hint "$(msg assess.status_hint)"
}

show_wizard_menu() {
  assess_run
  tui_assess_panel || true
  echo ""

  cui_section "$(msg wizard.title)" "$(assess_recommended_hint)"

  local choice
  tui_wizard_pick choice
  echo ""

  announce_choice "${choice:-}"

  case "${choice:-}" in
    1)
      run_pc_fix || true
      run_game_setup || true
      ;;
    2)
      run_pc_fix || true
      ;;
    3)
      if ! run_game_setup; then
        log_warn "$(msg assess.block_game_still)"
      fi
      ;;
    4)
      assess_run
      assess_print_report || true
      print_wizard_options
      assess_print_next_step
      return 0
      ;;
    "")
      case "$ASSESS_RECOMMENDED" in
        3)
          if ! run_game_setup; then
            log_warn "$(msg assess.block_game_still)"
          fi
          ;;
        2) run_pc_fix || true ;;
        *) run_pc_fix || true; run_game_setup || true ;;
      esac
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
  shift
  local arg
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

  ensure_crkcachy_runtime
  print_banner
  preflight_onboard

  if ! show_wizard_menu; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  log_ok "$(msg install.finished)"
  offer_post_install_readme
}

main "$@"

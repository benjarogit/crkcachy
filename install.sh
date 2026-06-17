#!/usr/bin/env bash
# CRKCACHY master installer – assessment-driven wizard

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$SCRIPT_DIR"

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
parse_lang_arg "$@"
parse_cli_arg "$@"
filter_lang_args "$@"
filter_cli_args "${FILTERED_ARGS[@]:-$@}"

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
# shellcheck source=lib/install_log.sh
source "${CRKCACHY_ROOT}/lib/install_log.sh"

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
    5) ui_action "$(msg uninstall.title)" ;;
  esac
}

run_pc_fix() {
  ui_step "$(msg install.step2)"

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    log_ok "$(msg assess.pc_already_ok)"
    print_overlay_hint
    _pc_fix_done_panel
    return 0
  fi

  assess_guided_fix || true
  print_overlay_hint
  _pc_fix_done_panel
}

# Robuster Menü-Picker – Fallback wenn gum nach Steam-Dialog nicht rendert.
_menu_choose() {
  local header="$1"
  shift
  local options=("$@")
  local pick=""

  if command -v gum >/dev/null 2>&1 && [[ -t 0 ]] && [[ -t 1 ]]; then
    pick="$(gum choose \
      --header "$header" \
      --cursor "› " \
      --height "${#options[@]}" \
      "${options[@]}")" || pick=""
  fi

  if [[ -n "$pick" ]]; then
    echo "$pick"
    return 0
  fi

  echo ""
  echo "$header"
  local i=1 opt
  for opt in "${options[@]}"; do
    echo "  $i) $opt"
    i=$((i + 1))
  done
  echo ""
  local reply
  read -r -p "> " reply
  if [[ "$reply" =~ ^[0-9]+$ ]] && [[ "$reply" -ge 1 ]] && [[ "$reply" -le "${#options[@]}" ]]; then
    echo "${options[$((reply - 1))]}"
  fi
}

_pc_fix_done_panel() {
  echo ""
  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    cui_status_chip true "$(msg assess.all_ready)"
  else
    cui_status_chip false "$(msg assess.pc_fix_partial)"
  fi
  echo ""
  cui_continue "$(msg assess.pc_fix_continue)"
}

_after_pc_fix_menu() {
  echo ""
  local pick
  pick="$(_menu_choose "$(msg assess.after_pc_title)" \
    "$(msg assess.after_pc_install)" \
    "$(msg assess.after_pc_menu)" \
    "$(msg assess.after_pc_exit)")"

  echo ""
  case "${pick:-}" in
    "$(msg assess.after_pc_install)")
      run_game_setup || true
      _after_install_menu
      ;;
    "$(msg assess.after_pc_menu)")
      cui_screen_clear
      show_wizard_menu || true
      ;;
    "$(msg assess.after_pc_exit)")
      echo ""
      log_ok "$(msg install.goodbye)"
      ;;
    *)
      log_hint "$(msg assess.after_pc_hint)"
      ;;
  esac
}

run_game_setup() {
  ui_step "$(msg install.step5)"
  ui_action "$(msg flow.game_tool)"

  if ! assess_ensure_ready; then
    return 1
  fi

  tool_hub_interactive || true
  echo ""
  return 0
}

run_game_uninstall() {
  ui_step "$(msg uninstall.title)"
  tool_hub_run_uninstall || true
  echo ""
  return 0
}

_after_uninstall_menu() {
  echo ""
  local pick
  pick="$(gum choose \
    --header "$(msg wizard.after_uninstall_title)" \
    --cursor "› " \
    "$(msg wizard.after_uninstall_menu)" \
    "$(msg wizard.after_uninstall_install)" \
    "$(msg wizard.after_uninstall_exit)")" 2>/dev/null || true

  echo ""
  case "${pick:-}" in
    "$(msg wizard.after_uninstall_menu)")
      show_wizard_menu || true
      ;;
    "$(msg wizard.after_uninstall_install)")
      run_game_setup || true
      ;;
    *)
      exit 0
      ;;
  esac
  exit 0
}

_after_install_menu() {
  echo ""
  local _pick
  _pick="$(_menu_choose "$(msg install.after_title)" \
    "$(msg install.after_menu)" \
    "$(msg install.after_exit)")"

  echo ""
  case "${_pick:-}" in
    "$(msg install.after_menu)")
      show_wizard_menu || true
      ;;
    *)
      echo ""
      log_ok "$(msg install.goodbye)"
      ;;
  esac
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
  cui_screen_clear
  cui_wizard_main_header "$(assess_recommended_hint)"
  tui_assess_panel || true

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
      _after_pc_fix_menu
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
    5)
      run_game_uninstall || true
      _after_uninstall_menu
      ;;
    "")
      case "$ASSESS_RECOMMENDED" in
        3)
          if ! run_game_setup; then
            log_warn "$(msg assess.block_game_still)"
          fi
          ;;
        2) run_pc_fix || true; _after_pc_fix_menu ;;
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

  local action
  action="$(tool_action_from_flag)"

  if [[ -n "$action" ]] || [[ -n "${CRKCACHY_TOOL:-}" ]]; then
    ensure_crkcachy_runtime
    print_banner
    tool_hub_run "$action"
    exit $?
  fi

  if has_flag --tools "$@"; then
    ensure_crkcachy_runtime
    print_banner
    preflight_onboard
    tool_hub_interactive
    exit $?
  fi

  ensure_crkcachy_runtime
  print_banner
  preflight_onboard

  if ! show_wizard_menu; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  _after_install_menu
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

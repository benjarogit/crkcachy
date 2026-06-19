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

# Menü-Picker (@clack/prompts) – gibt gewählten value zurück oder leer bei Abbruch
_menu_choose() {
  local header="$1"
  shift
  local lines=() opt key label
  for opt in "$@"; do
    key="${opt%%|*}"
    label="${opt#*|}"
    if [[ "$key" == "$label" ]]; then
      lines+=("${opt}|${opt}")
    else
      lines+=("${key}|${label}")
    fi
  done
  crk_select "$header" "" "${lines[@]}" || return 1
  return 0
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
  local pick=""
  pick="$(_menu_choose "$(msg assess.after_pc_title)" \
    "install|$(msg assess.after_pc_install)" \
    "menu|$(msg assess.after_pc_menu)" \
    "exit|$(msg assess.after_pc_exit)")" || pick=""

  echo ""
  case "${pick:-}" in
    install)
      if run_game_setup; then
        _after_install_menu
      fi
      ;;
    menu)
      cui_screen_clear
      show_wizard_menu || true
      ;;
    exit)
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

  tool_hub_interactive
  echo ""
}

run_game_uninstall() {
  ui_step "$(msg uninstall.title)"
  tool_hub_run_uninstall
  echo ""
}

_after_uninstall_menu() {
  echo ""
  local pick=""
  pick="$(_menu_choose "$(msg wizard.after_uninstall_title)" \
    "menu|$(msg wizard.after_uninstall_menu)" \
    "install|$(msg wizard.after_uninstall_install)" \
    "exit|$(msg wizard.after_uninstall_exit)")" || pick=""

  echo ""
  case "${pick:-}" in
    menu)
      show_wizard_menu || true
      ;;
    install)
      if run_game_setup; then
        _after_install_menu
      fi
      ;;
    exit)
      exit 0
      ;;
    *)
      log_info "$(msg install.cancelled)"
      exit 0
      ;;
  esac
  exit 0
}

_after_install_menu() {
  echo ""
  local _pick=""
  _pick="$(_menu_choose "$(msg install.after_title)" \
    "menu|$(msg install.after_menu)" \
    "exit|$(msg install.after_exit)")" || _pick=""

  echo ""
  case "${_pick:-}" in
    menu)
      show_wizard_menu || true
      ;;
    exit)
      echo ""
      log_ok "$(msg install.goodbye)"
      ;;
    *)
      log_info "$(msg install.cancelled)"
      show_wizard_menu || true
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
  local redraw=false
  local first=true
  local note marker

  while true; do
    assess_run

    if [[ "$first" == true || "$redraw" == true ]]; then
      cui_screen_clear
      first=false
      redraw=false
    fi

    if [[ "${ASSESS_SYSTEM_READY:-false}" == true ]]; then
      crk_intro "$(msgf wizard.intro "v${CRKCACHY_VERSION}")"
      note="$(assess_recommended_hint)"
      marker="${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/.deps_hint_v${CRKCACHY_VERSION}"
      if [[ ! -f "$marker" ]]; then
        note="${note}

$(msg runtime.deps_cleanup_short)"
        mkdir -p "$(dirname "$marker")"
        touch "$marker"
      fi
      crk_note "$note"
    else
      tui_wizard_show_header
    fi

    local choice=""
    tui_wizard_pick choice

    if [[ -z "${choice:-}" ]]; then
      die "$(msg wizard.pick_failed)"
    fi

    echo ""
    announce_choice "${choice}"
    redraw=true

    case "${choice}" in
      1)
        run_pc_fix || true
        if run_game_setup; then
          _after_install_menu
          return 0
        fi
        ;;
      2)
        run_pc_fix || true
        _after_pc_fix_menu
        return 0
        ;;
      3)
        if run_game_setup; then
          _after_install_menu
          return 0
        fi
        ;;
      4)
        redraw=false
        first=true
        assess_run
        assess_print_report || true
        print_wizard_options
        assess_print_next_step
        ;;
      5)
        if run_game_uninstall; then
          _after_uninstall_menu
          return 0
        fi
        ;;
      *)
        log_warn "$(msg wizard.invalid)"
        ;;
    esac
  done
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

  show_wizard_menu || true
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

#!/usr/bin/env bash
# House of Ashes – entry point: action menu (install / uninstall / reset / validate / check)

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"

dispatch_action() {
  local action="$1"
  action="$(tool_action_normalize "$action")"

  case "$action" in
    install) run_ha_install ;;
    uninstall) exec bash "${TOOL_DIR}/uninstall.sh" "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}" ;;
    reset) exec bash "${TOOL_DIR}/reset.sh" "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}" ;;
    check) exec bash "${TOOL_DIR}/check.sh" "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}" ;;
    back|"") log_info "$(msg install.cancelled)"; exit 0 ;;
    *) die "$(msgf action.unknown "$action")" ;;
  esac
}

ha_show_plan() {
  cui_step_screen 1 4 "$(msg ha.plan_title)" "$(msg ha.plan_body)" "$(msg ha.plan_next)"
}

ha_show_pc_meaning() {
  cui_step_screen 2 4 "$(msg ha.pc_meaning_title)" "$(msg ha.pc_meaning_body)" "$(msg ha.pc_meaning_next)"
}

ha_show_folder_meaning() {
  cui_step_screen 3 4 "$(msg ha.folder_meaning_title)" "$(msg ha.folder_meaning_body)" "$(msg ha.folder_meaning_next)"
}

ha_show_finish_summary() {
  cui_step_screen 4 4 "$(msg ha.finish_title)" "$(msg ha.finish_body)" "$(msg ha.finish_next)"
}

print_steam_manual_steps() {
  local exe_path="$1"
  local launch_opts="$2"

  ui_step "$(msg ha.steam_manual_title)"
  echo "$(msg ha.steam_step1)"
  echo "$(msg ha.steam_step1_detail)"
  echo "   ${exe_path}"
  echo ""
  echo "$(msg ha.steam_step2)"
  echo "$(msg ha.steam_step2_detail)"
  echo ""
  steam_print_manual_launch_options "$launch_opts"
  echo "$(msg ha.steam_step4)"
  echo "$(msg ha.steam_step4_detail)"
  echo ""
  echo "$(msg ha.steam_step5)"
  echo ""
  log_hint "$(msg repair.manual_after_hint)"
}

ha_show_manual_proton_overlay() {
  echo ""
  cui_heading "$(msg ha.manual_left_title)"
  echo ""
  echo "$(msg ha.steam_step2)"
  echo "$(msg ha.steam_step2_detail)"
  echo ""
  echo "$(msg ha.steam_step4)"
  echo "$(msg ha.steam_step4_detail)"
  echo ""
}

offer_desktop_and_validate() {
  local exe_path="$1"
  local game_dir="$2"
  local launch_opts="$3"

  if ! steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
    return 0
  fi

  steam_offer_desktop_launcher \
    "$exe_path" "$HA_GAME_EXE" "$HA_GAME_STEAM_NAME" "$game_dir" "$HA_SLUG"

  steam_offer_repair_after_validate \
    "$exe_path" "$HA_GAME_EXE" "$game_dir" \
    "$HA_GAME_STEAM_NAME" "$launch_opts" "$HA_SLUG" \
    "print_steam_manual_steps" || true
}

run_steam_auto_or_manual() {
  local exe_path="$1"
  local game_dir="$2"
  local launch_opts="$3"

  cui_step_screen 1 2 "$(msg ha.steam_phase_title)" "$(msg ha.steam_phase_body)" "$(msg ha.steam_phase_next)"

  if ! steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
    local add_result
    steam_offer_add_shortcut "$exe_path" "$HA_GAME_EXE" "$HA_GAME_STEAM_NAME" "$launch_opts"
    add_result=$?

    if [[ $add_result -eq 2 ]]; then
      # manual chosen
      explain_block "$(msg ha.steam_add_first_title)" "$(msg ha.steam_add_first_body)"
      echo "   ${exe_path}"
      echo ""
      if ! cui_yes_no "$(msg ha.steam_added_confirm)" false; then
        print_steam_manual_steps "$exe_path" "$launch_opts"
        return 0
      fi
    fi

    if ! steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
      log_warn "$(msg ha.steam_still_missing)"
      print_steam_manual_steps "$exe_path" "$launch_opts"
      return 0
    fi
  fi

  echo ""
  explain_block "$(msg action.install_mode_title)" "$(msg action.install_mode_body)"

  if cui_yes_no "$(msg ha.steam_auto_confirm)" false; then
    if steam_configure_shortcut \
      "$exe_path" "$HA_GAME_EXE" "$game_dir" "$HA_GAME_STEAM_NAME" "$launch_opts"; then
      ha_show_manual_proton_overlay
      offer_desktop_and_validate "$exe_path" "$game_dir" "$launch_opts"
      return 0
    fi

    log_warn "$(msg ha.steam_auto_failed)"
    if cui_yes_no "$(msg ha.steam_manual_fallback)" false; then
      print_steam_manual_steps "$exe_path" "$launch_opts"
    fi
    offer_desktop_and_validate "$exe_path" "$game_dir" "$launch_opts"
    return 0
  fi

  print_steam_manual_steps "$exe_path" "$launch_opts"
  if cui_yes_no "$(msg repair.recheck_confirm)" false; then
    offer_desktop_and_validate "$exe_path" "$game_dir" "$launch_opts"
  fi
}

run_ha_install() {
  ha_load_runtime
  ensure_crkcachy_runtime

  ha_show_plan

  ui_step "$(msg ha.intro_title)"
  explain_block "$(msg ha.intro_title)" "$(msg ha.intro_body)"

  ha_show_pc_meaning
  ui_action "$(msg ha.pc_check)"
  check_steam || true
  check_spacewar || true
  verify_ge_proton || true
  echo ""

  ha_show_folder_meaning
  ui_step "$(msg ha.folder_title)"
  explain_block "$(msg ha.folder_title)" "$(msg ha.folder_body)"

  local game_dir
  game_dir="$(ha_prompt_game_dir)"
  ui_action "$(msgf ha.using_path "$game_dir")"

  if [[ ! -d "$game_dir" ]]; then
    die "$(msgf ha.dir_missing "$game_dir")"
  fi

  ui_step "$(msg ha.check_folder)"
  ui_running "$(msg ha.check_folder)"
  bash "${TOOL_DIR}/checks.sh" "$game_dir" || log_warn "$(msg ha.fix_missing)"
  ui_done "$(msg ha.check_folder)"
  echo ""

  local exe_path launch_opts
  exe_path="$(ha_resolve_exe_path "$game_dir")"
  launch_opts="$(ha_read_launch_options)"

  run_steam_auto_or_manual "$exe_path" "$game_dir" "$launch_opts"

  ha_show_finish_summary

  if cui_yes_no "$(msg ha.show_readme)" false; then
    echo ""
    cui_show_markdown "$(crkcachy_markdown_path "tools/house-of-ashes/README.md")" "$(msg ha.readme_title)" false
  fi

  ui_wait_enter
}

main() {
  ha_load_runtime
  ensure_crkcachy_runtime

  local action
  action="$(tool_action_from_flag)"

  if [[ -z "$action" ]]; then
    tool_action_pick_menu "$HA_GAME_STEAM_NAME"
    action="$TOOL_ACTION_PICKED"
  fi

  dispatch_action "$action"
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

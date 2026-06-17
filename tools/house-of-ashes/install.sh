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

  # Protokoll initialisieren (wird am Ende gespeichert)
  install_log_init "$HA_SLUG"
  # Sicherheitsnetz: Log auch bei unerwartetem Abbruch speichern
  trap 'install_log_save 2>/dev/null || true' EXIT

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

  ha_prompt_game_dir
  local game_dir="$TOOL_GAME_DIR"

  if [[ ! -d "$game_dir" ]]; then
    die "$(msgf ha.dir_missing "$game_dir")"
  fi

  # Spielpfade sofort protokollieren
  install_log_set "game_dir"          "$game_dir"
  install_log_set "steam_display_name" "$HA_GAME_STEAM_NAME"

  ui_step "$(msg ha.check_folder)"
  echo ""
  local checks_ok=true
  bash "${TOOL_DIR}/checks.sh" "$game_dir" || checks_ok=false

  if [[ "$checks_ok" == false ]]; then
    echo ""
    cui_status_chip false "$(msg ha.fix_check_failed)"
    echo ""
    gum style --foreground "$CUI_C_MUTED" "$(msg ha.fix_guide_body)"
    echo ""
    gum style --border rounded --padding "0 2" \
      "$(msg ha.fix_guide_steps)"
    echo ""
    if cui_yes_no "$(msg ha.fix_guide_done)" true; then
      echo ""
      log_info "$(msg ha.fix_recheck_running)"
      if bash "${TOOL_DIR}/checks.sh" "$game_dir" 2>/dev/null; then
        echo ""
        cui_status_chip true "$(msg ha.fix_recheck_ok)"
      else
        echo ""
        cui_status_chip false "$(msg ha.fix_recheck_fail)"
        echo ""
        log_hint "$(msg ha.fix_recheck_hint)"
      fi
    fi
  else
    echo ""
    cui_status_chip true "$(msg ha.fix_check_ok)"
  fi
  echo ""

  local exe_path launch_opts
  exe_path="$(ha_resolve_exe_path "$game_dir")"
  launch_opts="$(ha_read_launch_options)"

  install_log_set "exe_path"         "$exe_path"
  install_log_set "steam_launch_opts" "$launch_opts"

  run_steam_auto_or_manual "$exe_path" "$game_dir" "$launch_opts"

  # ── Was wurde tatsächlich eingerichtet? ──────────────────────────────────
  # Steam-Shortcut
  if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    install_log_set "steam_shortcut_added" "1"
    install_log_set "steam_mode" "auto"
  else
    install_log_set "steam_shortcut_added" "0"
    install_log_set "steam_mode" "manual"
  fi

  # Desktop-Einträge (Pfade sind deterministisch)
  local _app_file _desk_file _icon_file
  _app_file="$(xdg_applications_dir)/crkcachy-${HA_SLUG}.desktop"
  _desk_file="$(xdg_desktop_dir)/crkcachy-${HA_SLUG}.desktop"
  _icon_file="${CRKCACHY_ICONS}/${HA_SLUG}.png"

  if [[ -f "$_app_file" ]]; then
    install_log_set "desktop_app_file" "$_app_file"
    install_log_set "desktop_mode"    "auto"
  fi
  if [[ -f "$_desk_file" ]]; then
    install_log_set "desktop_desktop_file" "$_desk_file"
  fi
  if [[ -f "$_icon_file" ]]; then
    install_log_set "icon_file" "$_icon_file"
  fi

  # Spacewar: wurde es von CRKCACHY während des Onboardings installiert?
  local _sw_marker="${HOME}/.local/share/crkcachy/.spacewar_crkcachy_pending"
  if [[ -f "$_sw_marker" ]]; then
    install_log_set "spacewar_installed_by_crkcachy" "1"
    rm -f "$_sw_marker" 2>/dev/null || true
  fi

  # Protokoll auf Disk speichern
  install_log_save
  trap - EXIT  # Trap entfernen (save ist erledigt)

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

#!/usr/bin/env bash
# House of Ashes – full system + game + Steam check (read-only)

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

run_ha_full_check() {
  local game_dir="$1"
  local exe_path launch_opts
  local pc_ok=true folder_ok=true steam_ok=true

  exe_path="$(ha_resolve_exe_path "$game_dir")"
  launch_opts="$(ha_read_launch_options)"

  echo ""
  cui_heading "$(msg check.section_pc)"
  echo ""
  check_steam || pc_ok=false
  check_spacewar || pc_ok=false
  verify_ge_proton || pc_ok=false
  echo ""

  cui_heading "$(msg check.section_folder)"
  echo ""
  if [[ ! -d "$game_dir" ]]; then
    log_error "$(msgf ha.dir_missing "$game_dir")"
    folder_ok=false
  elif [[ ! -f "$exe_path" ]]; then
    log_error "$(msgf ha.exe_missing "$exe_path")"
    folder_ok=false
  else
    bash "${TOOL_DIR}/checks.sh" "$game_dir" || folder_ok=false
  fi
  echo ""

  cui_heading "$(msg check.section_steam)"
  echo ""
  if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
    if steam_validate_shortcut_setup \
      "$exe_path" "$HA_GAME_EXE" "$HA_GAME_STEAM_NAME" "$launch_opts" "$HA_SLUG"; then
      steam_ok=true
    else
      steam_ok=false
    fi
  else
    log_warn "$(msg steam.shortcut_not_found)"
    log_hint "$(msg check.steam_not_added)"
    steam_ok=false
  fi

  echo ""
  cui_heading "$(msg check.summary_title)"
  echo ""

  if [[ "$pc_ok" == true ]]; then
    cui_result_line ok "$(msg check.summary_pc)"
  else
    cui_result_line fail "$(msg check.summary_pc)" "$(msg check.summary_pc_fail)"
  fi

  if [[ "$folder_ok" == true ]]; then
    cui_result_line ok "$(msg check.summary_folder)"
  else
    cui_result_line fail "$(msg check.summary_folder)" "$(msg check.summary_folder_fail)"
  fi

  if [[ "$steam_ok" == true ]]; then
    cui_result_line ok "$(msg check.summary_steam)"
  else
    cui_result_line fail "$(msg check.summary_steam)" "$(msg check.summary_steam_fail)"
  fi

  echo ""

  if [[ "$pc_ok" == true && "$folder_ok" == true && "$steam_ok" == true ]]; then
    log_ok "$(msg check.all_ok)"
    return 0
  fi

  log_warn "$(msg check.some_failed)"
  return 1
}

print_ha_manual_steam_steps() {
  local exe_path="$1"
  local launch_opts="$2"

  ui_step "$(msg ha.steam_manual_title)"
  echo "$(msg ha.steam_step1)"
  echo "$(msg ha.steam_step1_detail)"
  echo "   ${exe_path}"
  echo ""
  steam_print_manual_launch_options "$launch_opts"
  echo "$(msg ha.steam_step2)"
  echo "$(msg ha.steam_step2_detail)"
  echo ""
  echo "$(msg ha.steam_step4)"
  echo "$(msg ha.steam_step4_detail)"
}

main() {
  cui_step_screen 1 1 "$(msg check.title)" "$(msg check.body)" "$(msg check.next)"

  local game_dir
  game_dir="$(ha_prompt_game_dir)"

  if ! run_ha_full_check "$game_dir"; then
    local exe_path launch_opts
    exe_path="$(ha_resolve_exe_path "$game_dir")"
    launch_opts="$(ha_read_launch_options)"

    if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
      steam_offer_repair_after_validate \
        "$exe_path" "$HA_GAME_EXE" "$game_dir" \
        "$HA_GAME_STEAM_NAME" "$launch_opts" "$HA_SLUG" \
        "print_ha_manual_steam_steps" || true
    elif cui_yes_no "$(msg check.offer_install)" false; then
      exec bash "${TOOL_DIR}/install.sh" --install
    fi
  fi

  if [[ -n "$(crkcachy_log_path)" ]]; then
    log_hint "$(msgf debug.log_path "$(crkcachy_log_path)")"
  fi

  ui_wait_enter
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

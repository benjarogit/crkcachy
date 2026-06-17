#!/usr/bin/env bash
# House of Ashes – reset for re-testing

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

main() {
  local game_dir exe_path deep=false

  cui_step_screen 1 1 "$(msg ha.reset_title)" "$(msg ha.reset_body)" "$(msg ha.reset_next)"
  echo ""

  ha_prompt_game_dir
  game_dir="$TOOL_GAME_DIR"
  exe_path="$(ha_resolve_exe_path "$game_dir")"

  if [[ ! -f "$exe_path" ]]; then
    die "$(msgf ha.exe_missing "$exe_path")"
  fi

  if ! steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
    log_warn "$(msg steam.shortcut_not_found)"
    log_hint "$(msg ha.steam_add_first_body)"
    echo "   ${exe_path}"
    exit 1
  fi

  echo ""
  cui_heading "$(msg ha.reset_mode_title)"
  echo ""
  gum style --foreground "${CUI_MUTED}" "$(msg ha.reset_mode_body)"
  echo ""

  local mode
  mode="$(cui_choose "$(msg ha.reset_mode_pick)" 0 \
    "$(msg ha.reset_mode_full)" \
    "$(msg ha.reset_mode_meta)" \
    "$(msg action.opt_back)")"

  case "$mode" in
    "$(msg ha.reset_mode_full)") deep=true ;;
    "$(msg ha.reset_mode_meta)") deep=false ;;
    *) log_info "$(msg install.cancelled)"; exit 0 ;;
  esac

  echo ""
  if [[ "$deep" == true ]]; then
    explain_block "$(msg ha.reset_what_title)" "$(msg ha.reset_what_body_full)"
  else
    explain_block "$(msg ha.reset_what_title)" "$(msg ha.reset_what_body)"
  fi

  if ! cui_yes_no "$(msg ha.reset_confirm)" false; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  steam_reset_shortcut_setup "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" "$HA_GAME_STEAM_NAME"

  if [[ "$deep" == true ]]; then
    log_info "$(msg ha.reset_removing_shortcut)"
    steam_remove_shortcut_from_library "$exe_path" "$HA_GAME_EXE" || \
      log_warn "$(msg ha.reset_shortcut_not_removed)"

    local saved_dir
    saved_dir="$(crkcachy_saved_game_dir_file "$HA_SLUG")"
    if [[ -f "$saved_dir" ]]; then
      rm -f "$saved_dir"
      log_ok "$(msg ha.reset_saved_dir_cleared)"
    fi

    echo ""
    log_ok "$(msg ha.reset_full_done)"
    echo ""

    local launch_opts
    launch_opts="$(ha_read_launch_options)"

    local add_result
    steam_offer_add_shortcut "$exe_path" "$HA_GAME_EXE" "$HA_GAME_STEAM_NAME" "$launch_opts"
    add_result=$?

    if [[ $add_result -eq 2 ]]; then
      log_hint "$(msg ha.reset_full_next)"
    elif [[ $add_result -eq 0 ]]; then
      log_hint "$(msg ha.reset_readd_done)"
    fi
  fi

  if [[ -n "$(crkcachy_log_path)" ]]; then
    log_hint "$(msgf debug.log_path "$(crkcachy_log_path)")"
  fi

  ui_wait_enter
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

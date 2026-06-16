#!/usr/bin/env bash
# House of Ashes – deinstall CRKCACHY setup

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

main() {
  cui_step_screen 1 1 "$(msg uninstall.title)" "$(msg uninstall.body)" "$(msg uninstall.next)"
  echo ""

  local game_dir exe_path remove_steam=false
  game_dir="$(ha_prompt_game_dir)"
  exe_path="$(ha_resolve_exe_path "$game_dir")"

  if [[ ! -f "$exe_path" ]] && ! steam_shortcut_exists "$exe_path" "$HA_GAME_EXE"; then
    log_warn "$(msg steam.shortcut_not_found)"
    explain_block "$(msg uninstall.no_setup_title)" "$(msg uninstall.no_setup_body)"
    steam_remove_crkcachy_launchers "$HA_SLUG" "$HA_GAME_EXE"
    steam_remove_cached_icon "$HA_SLUG" || true
    ui_wait_enter
    exit 0
  fi

  explain_block "$(msg uninstall.what_title)" "$(msg uninstall.what_body)"

  if cui_yes_no "$(msg uninstall.remove_from_steam)" false; then
    remove_steam=true
  fi

  if ! cui_yes_no "$(msg uninstall.confirm)" false; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  steam_uninstall_crkcachy_setup \
    "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" "$remove_steam"

  if [[ -n "$(crkcachy_log_path)" ]]; then
    log_hint "$(msgf debug.log_path "$(crkcachy_log_path)")"
  fi

  ui_wait_enter
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

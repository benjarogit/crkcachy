#!/usr/bin/env bash
# House of Ashes – deinstall CRKCACHY setup
#
# Liest das Install-Protokoll (~/.local/share/crkcachy/installs/<slug>.log)
# und entfernt exakt das, was bei der Installation eingerichtet wurde –
# egal ob automatisch, manuell oder gemischt.

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

main() {
  local game_dir exe_path remove_steam=false log_available=false

  # ── Protokoll laden ────────────────────────────────────────────────────────
  if install_log_load "$HA_SLUG" 2>/dev/null; then
    log_available=true
    log_ok "$(msg install_log.loaded)"
    install_log_print_summary "$HA_SLUG"
  else
    log_hint "$(msg install_log.no_log_hint)"
    echo ""
  fi

  # ── Schritt-Screen ─────────────────────────────────────────────────────────
  cui_step_screen 1 1 "$(msg uninstall.title)" "$(msg uninstall.body)" "$(msg uninstall.next)"
  echo ""

  # ── Spielordner: aus Protokoll vorausfüllen oder manuell ──────────────────
  if [[ "$log_available" == true ]]; then
    local log_game_dir
    log_game_dir="$(install_log_get game_dir)"
    local log_exe_path
    log_exe_path="$(install_log_get exe_path)"

    if [[ -n "$log_exe_path" ]]; then
      exe_path="$log_exe_path"
      game_dir="$(dirname "$exe_path")"
      log_info "$(msgf ha.using_path "$game_dir")"
    elif [[ -n "$log_game_dir" ]]; then
      game_dir="$log_game_dir"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
      log_info "$(msgf ha.using_path "$game_dir")"
    else
      game_dir="$(ha_prompt_game_dir)"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
    fi
  else
    game_dir="$(ha_prompt_game_dir)"
    exe_path="$(ha_resolve_exe_path "$game_dir")"
  fi

  # ── Was wird entfernt? (aus Protokoll oder Fallback) ───────────────────────
  if [[ "$log_available" == true ]]; then
    install_log_print_uninstall_plan "$HA_SLUG"
  else
    explain_block "$(msg uninstall.what_title)" "$(msg uninstall.what_body)"
  fi

  # ── Optionen ───────────────────────────────────────────────────────────────
  if cui_yes_no "$(msg uninstall.remove_from_steam)" false; then
    remove_steam=true
  fi

  if ! cui_yes_no "$(msg uninstall.confirm)" false; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  # ── Deinstallation ausführen ───────────────────────────────────────────────
  if [[ "$log_available" == true ]]; then
    _uninstall_from_log "$exe_path" "$remove_steam"
  else
    _uninstall_fallback "$exe_path" "$remove_steam"
  fi

  # ── Protokoll löschen ─────────────────────────────────────────────────────
  if [[ "$log_available" == true ]]; then
    install_log_clear "$HA_SLUG"
    log_ok "$(msg install_log.cleared)"
  fi

  if [[ -n "$(crkcachy_log_path 2>/dev/null || true)" ]]; then
    log_hint "$(msgf debug.log_path "$(crkcachy_log_path)")"
  fi

  ui_wait_enter
}

# Präzise Deinstallation anhand des Protokolls
_uninstall_from_log() {
  local exe_path="$1"
  local remove_steam="$2"

  # Steam-Shortcut & Startoptionen
  local steam_added
  steam_added="$(install_log_get steam_shortcut_added)"
  if [[ "$steam_added" == "1" ]] && steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    if ! steam_ensure_closed_for_edit; then
      log_warn "$(msg steam.shortcut_not_found)"
    else
      steam_reset_shortcut_setup "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" || true
      if [[ "$remove_steam" == true ]]; then
        steam_remove_shortcut_from_library "$exe_path" "$HA_GAME_EXE" || \
          log_warn "$(msg steam.uninstall_steam_not_removed)"
      fi
    fi
  fi

  # Desktop-App-Eintrag
  local app_file
  app_file="$(install_log_get desktop_app_file)"
  if [[ -n "$app_file" && -f "$app_file" ]]; then
    rm -f "$app_file"
    log_ok "$(msgf steam.desktop_removed "$app_file")"
  fi

  # Desktop-Icon
  local desk_file
  desk_file="$(install_log_get desktop_desktop_file)"
  if [[ -n "$desk_file" && -f "$desk_file" ]]; then
    rm -f "$desk_file"
    log_ok "$(msgf steam.desktop_removed "$desk_file")"
  fi

  # Icon-Cache
  local icon_file
  icon_file="$(install_log_get icon_file)"
  if [[ -n "$icon_file" && -f "$icon_file" ]]; then
    rm -f "$icon_file"
    log_ok "$(msgf steam.reset_icon_cache "$icon_file")"
  fi

  steam_refresh_desktop_cache 2>/dev/null || true
  _print_uninstall_summary "$remove_steam"
}

# Fallback ohne Protokoll (bisheriges Verhalten)
_uninstall_fallback() {
  local exe_path="$1"
  local remove_steam="$2"

  if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    steam_uninstall_crkcachy_setup \
      "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" "$remove_steam"
  else
    log_warn "$(msg steam.shortcut_not_found)"
    steam_remove_crkcachy_launchers "$HA_SLUG" "$HA_GAME_EXE"
    steam_remove_cached_icon "$HA_SLUG" || true
    _print_uninstall_summary "$remove_steam"
  fi
}

_print_uninstall_summary() {
  local remove_steam="${1:-false}"
  echo ""
  cui_heading "$(msg steam.uninstall_summary_title)"
  echo ""
  cui_result_line ok "$(msg steam.uninstall_summary_desktop)"
  cui_result_line ok "$(msg steam.uninstall_summary_cache)"
  if [[ "$remove_steam" == true ]]; then
    cui_result_line ok "$(msg steam.uninstall_summary_steam)"
  else
    cui_result_line ok "$(msg steam.uninstall_summary_steam_kept)"
  fi
  echo ""
  log_hint "$(msg steam.uninstall_next)"
  echo ""
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

#!/usr/bin/env bash
# House of Ashes – deinstall CRKCACHY setup
#
# Liest das Install-Protokoll (~/.local/share/crkcachy/installs/<slug>.log)
# und entfernt exakt das, was bei der Installation eingerichtet wurde.
# Danach wird verifiziert ob wirklich alles entfernt wurde.

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

# ── Zähler für tatsächlich entfernte Elemente ────────────────────────────────
_REMOVED_COUNT=0
_SKIPPED_COUNT=0

_track_removed() { _REMOVED_COUNT=$((_REMOVED_COUNT + 1)); }
_track_skipped() { _SKIPPED_COUNT=$((_SKIPPED_COUNT + 1)); }

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
    local log_exe; log_exe="$(install_log_get exe_path)"
    local log_dir; log_dir="$(install_log_get game_dir)"

    if [[ -n "$log_exe" ]]; then
      exe_path="$log_exe"
      game_dir="$(dirname "$exe_path")"
      log_info "$(msgf ha.using_path "$game_dir")"
    elif [[ -n "$log_dir" ]]; then
      game_dir="$log_dir"
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

  # ── Was wird entfernt? ─────────────────────────────────────────────────────
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

  # ── Verifikation: Wurde wirklich alles entfernt? ──────────────────────────
  echo ""
  _verify_uninstall "$exe_path" "$log_available" "$remove_steam"

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

# ── Präzise Deinstallation anhand des Protokolls ─────────────────────────────
_uninstall_from_log() {
  local exe_path="$1"
  local remove_steam="$2"

  # Steam-Shortcut & Startoptionen
  local steam_added; steam_added="$(install_log_get steam_shortcut_added)"
  if [[ "$steam_added" == "1" ]]; then
    if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
      if steam_ensure_closed_for_edit; then
        steam_reset_shortcut_setup "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" || true
        if [[ "$remove_steam" == true ]]; then
          steam_remove_shortcut_from_library "$exe_path" "$HA_GAME_EXE" || \
            log_warn "$(msg steam.uninstall_steam_not_removed)"
        fi
        _track_removed
      else
        log_warn "$(msg steam.shortcut_not_found)"
        _track_skipped
      fi
    else
      log_hint "$(msg steam.shortcut_not_found)"
      _track_skipped
    fi
  fi

  # Desktop-App-Eintrag
  local app_file; app_file="$(install_log_get desktop_app_file)"
  if [[ -n "$app_file" ]]; then
    if [[ -f "$app_file" ]]; then
      rm -f "$app_file"
      log_ok "$(msgf steam.desktop_removed "$app_file")"
      _track_removed
    fi
  fi

  # Desktop-Icon
  local desk_file; desk_file="$(install_log_get desktop_desktop_file)"
  if [[ -n "$desk_file" ]]; then
    if [[ -f "$desk_file" ]]; then
      rm -f "$desk_file"
      log_ok "$(msgf steam.desktop_removed "$desk_file")"
      _track_removed
    fi
  fi

  # Icon-Cache
  local icon_file; icon_file="$(install_log_get icon_file)"
  if [[ -n "$icon_file" ]]; then
    if [[ -f "$icon_file" ]]; then
      rm -f "$icon_file"
      log_ok "$(msgf steam.reset_icon_cache "$icon_file")"
      _track_removed
    fi
  fi

  steam_refresh_desktop_cache 2>/dev/null || true
}

# ── Fallback ohne Protokoll (bisheriges Verhalten) ───────────────────────────
_uninstall_fallback() {
  local exe_path="$1"
  local remove_steam="$2"

  if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    if steam_ensure_closed_for_edit; then
      steam_reset_shortcut_setup "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" || true
      if [[ "$remove_steam" == true ]]; then
        steam_remove_shortcut_from_library "$exe_path" "$HA_GAME_EXE" || \
          log_warn "$(msg steam.uninstall_steam_not_removed)"
      fi
      _track_removed
    fi
  else
    log_hint "$(msg steam.shortcut_not_found)"
    _track_skipped
  fi

  # Desktop-Einträge immer aufräumen (unabhängig ob Shortcut da war)
  local apps_dir; apps_dir="$(xdg_applications_dir)"
  local desktop_dir; desktop_dir="$(xdg_desktop_dir)"
  local app_file="${apps_dir}/crkcachy-${HA_SLUG}.desktop"
  local desk_file="${desktop_dir}/crkcachy-${HA_SLUG}.desktop"
  local icon_file="${CRKCACHY_ICONS}/${HA_SLUG}.png"

  if [[ -f "$app_file" ]]; then
    rm -f "$app_file"
    log_ok "$(msgf steam.desktop_removed "$app_file")"
    _track_removed
  fi
  if [[ -f "$desk_file" ]]; then
    rm -f "$desk_file"
    log_ok "$(msgf steam.desktop_removed "$desk_file")"
    _track_removed
  fi
  if [[ -f "$icon_file" ]]; then
    rm -f "$icon_file"
    log_ok "$(msgf steam.reset_icon_cache "$icon_file")"
    _track_removed
  fi

  steam_refresh_desktop_cache 2>/dev/null || true
}

# ── Post-Deinstallations-Verifikation ─────────────────────────────────────────
# Prüft ob wirklich alles entfernt wurde und zeigt präzise Ergebniszeilen.
_verify_uninstall() {
  local exe_path="$1"
  local log_available="$2"
  local remove_steam="$3"

  local all_ok=true

  echo ""
  cui_check_category "$(msg uninstall.verify_title)"

  # Steam-Shortcut
  if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    cui_check_row fail "$(msg uninstall.verify_steam_shortcut)" "$(msg uninstall.verify_still_there)"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_steam_shortcut)" "$(msg uninstall.verify_removed)"
  fi

  # Desktop-App-Eintrag
  local app_file="${CRKCACHY_ICONS%icons}../../.local/share/applications/crkcachy-${HA_SLUG}.desktop"
  app_file="$(xdg_applications_dir)/crkcachy-${HA_SLUG}.desktop"
  if [[ -f "$app_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_desktop_app)" "$(msg uninstall.verify_still_there)" "$(basename "$app_file")"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_desktop_app)" "$(msg uninstall.verify_removed)"
  fi

  # Desktop-Icon
  local desk_file
  desk_file="$(xdg_desktop_dir)/crkcachy-${HA_SLUG}.desktop"
  if [[ -f "$desk_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_desktop_icon)" "$(msg uninstall.verify_still_there)" "$(basename "$desk_file")"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_desktop_icon)" "$(msg uninstall.verify_removed)"
  fi

  # Icon-Cache
  local icon_file="${CRKCACHY_ICONS}/${HA_SLUG}.png"
  if [[ -f "$icon_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_icon_cache)" "$(msg uninstall.verify_still_there)"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_icon_cache)" "$(msg uninstall.verify_removed)"
  fi

  echo ""

  if [[ "$all_ok" == true ]]; then
    cui_status_chip true "$(msg uninstall.verify_all_ok)"
  else
    cui_status_chip false "$(msg uninstall.verify_incomplete)"
    echo ""
    log_hint "$(msg uninstall.verify_hint)"
  fi

  echo ""
  log_hint "$(msg steam.uninstall_next)"
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

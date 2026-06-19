#!/usr/bin/env bash
# House of Ashes – deinstall CRKCACHY setup
#
# Spielordner-Priorität:
#   1. Install-Protokoll (exe_path / game_dir)
#   2. Gespeicherter Pfad – direkt aus Datei, OHNE -d-Check
#   3. Kein Pfad: nur slug-basierter Cleanup (Desktop/Icons)
#
# Cleanup via steam_uninstall_crkcachy_setup (kein doppelter Steam-Close-Dialog),
# oder bei leerem exe_path direkt über slug-basierte Hilfsfunktionen.

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

main() {
  local exe_path="" game_dir="" remove_steam=false log_available=false

  # ── 1. Protokoll laden ────────────────────────────────────────────────────
  if install_log_load "$HA_SLUG" 2>/dev/null; then
    log_available=true
  fi

  if [[ "$log_available" == true ]]; then
    local log_exe log_dir
    log_exe="$(install_log_get exe_path)"
    log_dir="$(install_log_get game_dir)"
    if [[ -n "$log_exe" ]]; then
      exe_path="$log_exe"
      game_dir="$(dirname "$exe_path")"
    elif [[ -n "$log_dir" ]]; then
      game_dir="$log_dir"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
    fi
  fi

  # ── 2. Fallback: gespeicherter Pfad (ohne -d-Check) ─────────────────────
  if [[ -z "$exe_path" ]]; then
    local saved_file
    saved_file="$(crkcachy_saved_game_dir_file "$HA_SLUG" 2>/dev/null || true)"
    if [[ -n "$saved_file" && -f "$saved_file" ]]; then
      game_dir="$(crkcachy_expand_user_path "$(tr -d '\n' < "$saved_file")")"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
    fi
  fi

  # ── 3. Schritt-Screen ─────────────────────────────────────────────────────
  echo ""
  cui_step_screen 1 1 "$(msg uninstall.title)" "$(msg uninstall.body)"

  # ── 4. Spielordner-Status anzeigen ────────────────────────────────────────
  echo ""
  cui_section "$(msg uninstall.path_section)"
  echo ""

  if [[ -n "$exe_path" ]]; then
    local src
    if [[ "$log_available" == true ]]; then
      src="$(msg install_log.loaded)"
    else
      src="$(msg uninstall.path_source_saved)"
    fi
    cui_check_row ok "$src" "" "$game_dir"
    if [[ "$log_available" == true ]]; then
      install_log_print_uninstall_plan "$HA_SLUG"
    fi
  else
    cui_check_row warn "$(msg uninstall.path_unknown)" "$(msg uninstall.path_unknown_hint)"
    echo ""
    cui_muted_block "$(msg uninstall.path_unknown_body)"
  fi

  echo ""

  # ── 5. Optionen ───────────────────────────────────────────────────────────
  if [[ -n "$exe_path" ]]; then
    if cui_yes_no "$(msg uninstall.remove_from_steam)" false; then
      remove_steam=true
    fi
    echo ""
  fi

  if ! cui_yes_no "$(msg uninstall.confirm)" false; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  echo ""

  # ── 6. Deinstallation ─────────────────────────────────────────────────────
  if [[ -n "$exe_path" ]]; then
    # Pfad bekannt: volle Deinstallation (Shortcut + Desktop + Icons)
    # steam_uninstall_crkcachy_setup: Steam schließen, Shortcut-Reset,
    # optional aus Bibliothek entfernen, slug-basierte Launcher + Icon löschen.
    steam_uninstall_crkcachy_setup \
      "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" "$remove_steam" || true
  else
    # Kein Pfad: nur slug-basierter Cleanup (kein Steam-Shortcut-Check)
    steam_remove_crkcachy_launchers "$HA_SLUG" "$HA_GAME_EXE" || true
    steam_remove_cached_icon "$HA_SLUG" || true
    steam_refresh_desktop_cache 2>/dev/null || true
  fi

  # ── 7. Verifikation ───────────────────────────────────────────────────────
  _verify_uninstall "$exe_path"

  # ── 8. Spacewar-Flag aus Protokoll lesen (vor dem Löschen!) ───────────────
  local spacewar_by_crkcachy="0"
  if [[ "$log_available" == true ]]; then
    local _sw_val
    _sw_val="$(install_log_get spacewar_installed_by_crkcachy 2>/dev/null || true)"
    spacewar_by_crkcachy="${_sw_val:-0}"
  fi

  # ── 9. Protokoll löschen ──────────────────────────────────────────────────
  if [[ "$log_available" == true ]]; then
    install_log_clear "$HA_SLUG" 2>/dev/null || true
  fi

  # ── 10. Spacewar optional entfernen ────────────────────────────────────────
  _maybe_remove_spacewar "$spacewar_by_crkcachy"
}

# ── Post-Deinstallations-Verifikation ─────────────────────────────────────────
_verify_uninstall() {
  local exe_path="$1"
  local all_ok=true

  echo ""
  cui_check_category "$(msg uninstall.verify_title)"

  # Steam-Shortcut (nur prüfbar wenn Pfad bekannt)
  if [[ -n "$exe_path" ]]; then
    if steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
      cui_check_row fail "$(msg uninstall.verify_steam_shortcut)" "$(msg uninstall.verify_still_there)"
      all_ok=false
    else
      cui_check_row ok "$(msg uninstall.verify_steam_shortcut)" "$(msg uninstall.verify_removed)"
    fi
  else
    cui_check_row warn "$(msg uninstall.verify_steam_shortcut)" "$(msg uninstall.verify_skipped)"
  fi

  # Desktop-Einträge + Icon (slug-basiert – immer prüfbar)
  local app_file; app_file="$(xdg_applications_dir)/crkcachy-${HA_SLUG}.desktop"
  if [[ -f "$app_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_desktop_app)" "$(msg uninstall.verify_still_there)"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_desktop_app)" "$(msg uninstall.verify_removed)"
  fi

  local desk_file; desk_file="$(xdg_desktop_dir)/crkcachy-${HA_SLUG}.desktop"
  if [[ -f "$desk_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_desktop_icon)" "$(msg uninstall.verify_still_there)"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_desktop_icon)" "$(msg uninstall.verify_removed)"
  fi

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
}

# ── Spacewar optional deinstallieren ─────────────────────────────────────────
# $1: "1" = CRKCACHY hat Spacewar installiert (aus Protokoll)
#     "0" = unbekannt / nicht von CRKCACHY (trotzdem anbieten mit Hinweis)
_maybe_remove_spacewar() {
  local by_crkcachy="${1:-0}"

  find_steam_root 2>/dev/null || true
  if [[ ! -f "${SPACEWAR_MANIFEST:-/dev/null}" ]]; then
    return 0
  fi

  echo ""
  cui_section "Spacewar" "App 480"
  echo ""

  if [[ "$by_crkcachy" == "1" ]]; then
    cui_muted_block "$(msg uninstall.spacewar_info_tracked)"
  else
    cui_muted_block "$(msg uninstall.spacewar_info_unknown)"
  fi

  echo ""

  local choice
  choice="$(crk_select "$(msg uninstall.spacewar_how)" "" \
    "auto|$(msg uninstall.spacewar_opt_auto)" \
    "manual|$(msg uninstall.spacewar_opt_manual)" \
    "skip|$(msg uninstall.spacewar_opt_skip)")" || choice=""

  echo ""

  case "${choice:-}" in
    auto)
      _spacewar_remove_auto
      ;;
    manual)
      _spacewar_remove_manual
      ;;
    *)
      log_info "$(msg uninstall.spacewar_skipped)"
      return 0
      ;;
  esac

  _spacewar_verify
}

_spacewar_remove_auto() {
  if ! command -v steam >/dev/null 2>&1; then
    log_warn "$(msg uninstall.spacewar_no_steam)"
    _spacewar_remove_manual
    return 0
  fi

  log_info "$(msg uninstall.spacewar_launching)"
  steam steam://uninstall/480 >/dev/null 2>&1 &
  disown 2>/dev/null || true
  echo ""

  cui_warning_box "$(msg uninstall.spacewar_auto_hint)"
  echo ""

  # Warte auf Benutzer-Bestätigung NACHDEM Spacewar im Steam-Dialog bestätigt wurde
  cui_continue "$(msg uninstall.spacewar_wait_continue)"
}

_spacewar_remove_manual() {
  cui_info_box "$(msg uninstall.spacewar_manual_steps)"
  echo ""

  cui_continue "$(msg uninstall.spacewar_wait_continue)"
}

_spacewar_verify() {
  echo ""
  cui_spin "$(msg uninstall.spacewar_verify_waiting)" sleep 3
  find_steam_root 2>/dev/null || true

  echo ""
  cui_check_category "Spacewar – Check"
  if [[ ! -f "${SPACEWAR_MANIFEST:-/dev/null}" ]]; then
    cui_check_row ok "Spacewar" "App 480" "$(msg uninstall.spacewar_verify_ok)"
    echo ""
    return 0
  fi

  cui_check_row warn "Spacewar" "App 480" "$(msg uninstall.spacewar_verify_still)"
  echo ""
  cui_muted_block "$(msg uninstall.spacewar_verify_hint)"
  echo ""

  cui_continue "$(msg uninstall.spacewar_retry_continue)"
  echo ""
  cui_spin "$(msg uninstall.spacewar_verify_waiting)" sleep 3

  echo ""
  cui_check_category "Spacewar – Check"
  if [[ ! -f "${SPACEWAR_MANIFEST:-/dev/null}" ]]; then
    cui_check_row ok "Spacewar" "App 480" "$(msg uninstall.spacewar_verify_ok)"
  else
    cui_check_row warn "Spacewar" "App 480" "$(msg uninstall.spacewar_verify_still)"
    echo ""
    log_hint "$(msg uninstall.spacewar_verify_hint)"
  fi
  echo ""
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

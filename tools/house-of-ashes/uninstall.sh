#!/usr/bin/env bash
# House of Ashes – deinstall CRKCACHY setup
#
# Priorität für Spielordner:
#   1. Install-Protokoll (exe_path)
#   2. Gespeicherter Pfad (auch wenn Ordner nicht mehr da)
#   3. Ohne Pfad: Desktop/Icons werden entfernt, Steam-Shortcut übersprungen

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

  # ── 2. Spielordner ermitteln (kein Prompt, kein Hänger) ──────────────────
  if [[ "$log_available" == true ]]; then
    local log_exe; log_exe="$(install_log_get exe_path)"
    local log_dir; log_dir="$(install_log_get game_dir)"
    if [[ -n "$log_exe" ]]; then
      exe_path="$log_exe"
      game_dir="$(dirname "$exe_path")"
    elif [[ -n "$log_dir" ]]; then
      game_dir="$log_dir"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
    fi
  fi

  if [[ -z "$exe_path" ]]; then
    # Gespeicherter Pfad – direkt lesen ohne -d-Check (Ordner muss nicht existieren)
    local saved_file
    saved_file="$(crkcachy_saved_game_dir_file "$HA_SLUG" 2>/dev/null || true)"
    if [[ -n "$saved_file" && -f "$saved_file" ]]; then
      game_dir="$(crkcachy_expand_user_path "$(tr -d '\n' < "$saved_file")")"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
    fi
  fi

  # ── 3. Schritt-Screen ─────────────────────────────────────────────────────
  echo ""
  cui_step_screen 1 1 "$(msg uninstall.title)" "$(msg uninstall.body)" "$(msg uninstall.next)"

  # ── 4. Bekannten Pfad anzeigen oder Hinweis bei fehlendem Pfad ────────────
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
    gum style --foreground "$CUI_C_MUTED" "$(msg uninstall.path_unknown_body)"
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
  if [[ "$log_available" == true ]]; then
    _uninstall_from_log "$exe_path" "$remove_steam"
  else
    _uninstall_fallback "$exe_path" "$remove_steam"
  fi

  # ── 7. Verifikation ───────────────────────────────────────────────────────
  _verify_uninstall "$exe_path"

  # ── 8. Protokoll löschen ──────────────────────────────────────────────────
  [[ "$log_available" == true ]] && install_log_clear "$HA_SLUG" 2>/dev/null || true

  # ── 9. Abschluss ──────────────────────────────────────────────────────────
  echo ""
  gum style --foreground "$CUI_C_MUTED" "$(msg steam.uninstall_next)"
  echo ""
  read -r -p $'  \033[2m→ Enter zum Beenden …\033[0m ' _ 2>/dev/null || true
  echo ""
}

# ── Präzise Deinstallation anhand des Protokolls ──────────────────────────────
_uninstall_from_log() {
  local exe_path="$1"
  local remove_steam="$2"

  local steam_added; steam_added="$(install_log_get steam_shortcut_added)"
  if [[ "$steam_added" == "1" ]] && steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    if steam_ensure_closed_for_edit; then
      steam_reset_shortcut_setup "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" || true
      if [[ "$remove_steam" == true ]]; then
        steam_remove_shortcut_from_library "$exe_path" "$HA_GAME_EXE" || \
          log_warn "$(msg steam.uninstall_steam_not_removed)"
      fi
    fi
  fi

  local f
  for f in \
    "$(install_log_get desktop_app_file)" \
    "$(install_log_get desktop_desktop_file)" \
    "$(install_log_get icon_file)"; do
    [[ -n "$f" && -f "$f" ]] && rm -f "$f" && \
      log_ok "$(msgf steam.desktop_removed "$(basename "$f")")"
  done

  steam_refresh_desktop_cache 2>/dev/null || true
}

# ── Fallback ohne Protokoll ───────────────────────────────────────────────────
_uninstall_fallback() {
  local exe_path="$1"
  local remove_steam="$2"

  # Steam-Shortcut nur wenn Pfad bekannt
  if [[ -n "$exe_path" ]] && steam_shortcut_exists "$exe_path" "$HA_GAME_EXE" 2>/dev/null; then
    if steam_ensure_closed_for_edit; then
      steam_reset_shortcut_setup "$exe_path" "$HA_GAME_EXE" "$HA_GAME_EXE" "$HA_SLUG" || true
      if [[ "$remove_steam" == true ]]; then
        steam_remove_shortcut_from_library "$exe_path" "$HA_GAME_EXE" || \
          log_warn "$(msg steam.uninstall_steam_not_removed)"
      fi
    fi
  elif [[ -n "$exe_path" ]]; then
    log_hint "$(msg steam.shortcut_not_found)"
  fi

  # Desktop-Einträge + Icons – immer, da slug-basiert (kein Pfad nötig)
  local f
  for f in \
    "$(xdg_applications_dir)/crkcachy-${HA_SLUG}.desktop" \
    "$(xdg_desktop_dir)/crkcachy-${HA_SLUG}.desktop" \
    "${CRKCACHY_ICONS}/${HA_SLUG}.png"; do
    [[ -f "$f" ]] && rm -f "$f" && \
      log_ok "$(msgf steam.desktop_removed "$(basename "$f")")"
  done

  steam_refresh_desktop_cache 2>/dev/null || true
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

  # Desktop-Einträge + Icon (slug-basiert, immer prüfbar)
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

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

#!/usr/bin/env bash
# House of Ashes – deinstall CRKCACHY setup
#
# Liest das Install-Protokoll für präzise Deinstallation.
# Fallback: gespeicherter Pfad vom letzten Install auf diesem PC.
# Danach: Verifikation ob wirklich alles entfernt wurde.

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=tools/house-of-ashes/lib.sh
source "${TOOL_DIR}/lib.sh"

ha_parse_tool_args "$@"
ha_load_runtime
ensure_crkcachy_runtime

main() {
  local game_dir exe_path remove_steam=false log_available=false

  # ── 1. Protokoll laden (wenn vorhanden) ────────────────────────────────────
  if install_log_load "$HA_SLUG" 2>/dev/null; then
    log_available=true
  fi

  # ── 2. Schritt-Screen: Übersicht ───────────────────────────────────────────
  echo ""
  cui_step_screen 1 1 "$(msg uninstall.title)" "$(msg uninstall.body)" "$(msg uninstall.next)"

  # ── 3. Spielordner ermitteln – OHNE Prompt wenn möglich ───────────────────
  echo ""
  cui_section "$(msg uninstall.path_section)"

  if [[ "$log_available" == true ]]; then
    # Aus Protokoll
    local log_exe; log_exe="$(install_log_get exe_path)"
    local log_dir; log_dir="$(install_log_get game_dir)"
    if [[ -n "$log_exe" ]]; then
      exe_path="$log_exe"
      game_dir="$(dirname "$exe_path")"
    elif [[ -n "$log_dir" ]]; then
      game_dir="$log_dir"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
    fi
    install_log_print_summary "$HA_SLUG"
  fi

  if [[ -z "${game_dir:-}" ]]; then
    # Gespeicherter Pfad vom letzten Install (kein Protokoll nötig)
    local saved_dir
    saved_dir="$(crkcachy_load_saved_game_dir "$HA_SLUG" 2>/dev/null || true)"
    if [[ -n "$saved_dir" && -d "$saved_dir" ]]; then
      game_dir="$saved_dir"
      exe_path="$(ha_resolve_exe_path "$game_dir")"
      cui_check_row ok "$(msg uninstall.path_source_saved)" "" "$game_dir"
    fi
  fi

  if [[ -z "${game_dir:-}" ]]; then
    # Letzter Fallback: manuell eingeben
    gum style --foreground "$CUI_C_MUTED" "$(msg uninstall.path_ask)"
    game_dir="$(gum input \
      --placeholder "$(msg ha.folder_prompt)" \
      --width 72 \
      --prompt "  › ")"
    [[ -z "$game_dir" ]] && { log_warn "$(msg ha.dir_missing "")"; exit 1; }
    game_dir="$(crkcachy_expand_user_path "$game_dir")"
    exe_path="$(ha_resolve_exe_path "$game_dir")"
  fi

  echo ""
  cui_check_row ok "$(msg uninstall.path_using)" "" "$game_dir"
  echo ""

  # ── 4. Was wird entfernt? ──────────────────────────────────────────────────
  if [[ "$log_available" == true ]]; then
    install_log_print_uninstall_plan "$HA_SLUG"
  else
    explain_block "$(msg uninstall.what_title)" "$(msg uninstall.what_body)"
    echo ""
  fi

  # ── 5. Optionen + Bestätigung ─────────────────────────────────────────────
  if cui_yes_no "$(msg uninstall.remove_from_steam)" false; then
    remove_steam=true
  fi

  echo ""
  if ! cui_yes_no "$(msg uninstall.confirm)" false; then
    log_info "$(msg install.cancelled)"
    exit 0
  fi

  echo ""

  # ── 6. Deinstallation ausführen ───────────────────────────────────────────
  if [[ "$log_available" == true ]]; then
    _uninstall_from_log "$exe_path" "$remove_steam"
  else
    _uninstall_fallback "$exe_path" "$remove_steam"
  fi

  # ── 7. Verifikation ────────────────────────────────────────────────────────
  _verify_uninstall "$exe_path"

  # ── 8. Protokoll löschen ──────────────────────────────────────────────────
  if [[ "$log_available" == true ]]; then
    install_log_clear "$HA_SLUG" 2>/dev/null || true
  fi

  # ── 9. Sauberer Abschluss – kein gum choose am Ende ──────────────────────
  echo ""
  gum style --foreground "$CUI_C_MUTED" "$(msg steam.uninstall_next)"
  echo ""
  # Einfaches read statt gum choose (zuverlässiger als "Enter to continue")
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
    else
      log_hint "$(msg steam.shortcut_not_found)"
    fi
  fi

  local app_file; app_file="$(install_log_get desktop_app_file)"
  [[ -n "$app_file" && -f "$app_file" ]] && rm -f "$app_file" && \
    log_ok "$(msgf steam.desktop_removed "$(basename "$app_file")")"

  local desk_file; desk_file="$(install_log_get desktop_desktop_file)"
  [[ -n "$desk_file" && -f "$desk_file" ]] && rm -f "$desk_file" && \
    log_ok "$(msgf steam.desktop_removed "$(basename "$desk_file")")"

  local icon_file; icon_file="$(install_log_get icon_file)"
  [[ -n "$icon_file" && -f "$icon_file" ]] && rm -f "$icon_file" && \
    log_ok "$(msgf steam.reset_icon_cache "$(basename "$icon_file")")"

  steam_refresh_desktop_cache 2>/dev/null || true
}

# ── Fallback ohne Protokoll ───────────────────────────────────────────────────
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
    fi
  fi

  # Desktop-Einträge + Icons (deterministische Pfade)
  local apps_dir desktop_dir
  apps_dir="$(xdg_applications_dir)"
  desktop_dir="$(xdg_desktop_dir)"

  local f
  for f in \
    "${apps_dir}/crkcachy-${HA_SLUG}.desktop" \
    "${desktop_dir}/crkcachy-${HA_SLUG}.desktop" \
    "${CRKCACHY_ICONS}/${HA_SLUG}.png"; do
    [[ -f "$f" ]] && rm -f "$f" && log_ok "$(msgf steam.desktop_removed "$(basename "$f")")"
  done

  steam_refresh_desktop_cache 2>/dev/null || true
}

# ── Post-Deinstallations-Verifikation ─────────────────────────────────────────
_verify_uninstall() {
  local exe_path="$1"
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
  local app_file
  app_file="$(xdg_applications_dir)/crkcachy-${HA_SLUG}.desktop"
  if [[ -f "$app_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_desktop_app)" "$(msg uninstall.verify_still_there)"
    all_ok=false
  else
    cui_check_row ok "$(msg uninstall.verify_desktop_app)" "$(msg uninstall.verify_removed)"
  fi

  # Desktop-Icon
  local desk_file
  desk_file="$(xdg_desktop_dir)/crkcachy-${HA_SLUG}.desktop"
  if [[ -f "$desk_file" ]]; then
    cui_check_row fail "$(msg uninstall.verify_desktop_icon)" "$(msg uninstall.verify_still_there)"
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
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

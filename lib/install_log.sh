#!/usr/bin/env bash
# CRKCACHY Install-Protokoll
#
# Zweck: Haargenau aufzeichnen was CRKCACHY bei der Installation getan hat –
#        automatisch, manuell oder gemischt. Das Protokoll wird beim
#        Deinstallieren geladen, sodass exakt die richtigen Dateien/Einträge
#        entfernt werden können.
#
# Speicherort: ~/.local/share/crkcachy/installs/<slug>.log
# Format: bash-sourceable KEY="value" Zeilen (leicht lesbar + robust)
#
# Verwendung:
#   install_log_init "house-of-ashes"          # Neues Protokoll starten
#   install_log_set "game_dir" "/path/to/game" # Eintrag setzen
#   install_log_set "steam_shortcut_added" "1"
#   install_log_save                           # Auf Disk schreiben
#
#   install_log_load "house-of-ashes"          # Für Deinstallation laden
#   game_dir="$(install_log_get "game_dir")"
#   install_log_clear "house-of-ashes"         # Nach Deinstallation löschen

set -euo pipefail

# ── Bekannte Protokoll-Felder ─────────────────────────────────────────────────
#
# game_dir              Absoluter Pfad zum Spielordner
# exe_path              Absoluter Pfad zur .exe-Datei
# steam_display_name    Anzeigename in Steam
# steam_launch_opts     Steam-Startoptionen (PROTON_... %command%)
# steam_shortcut_added  1 = Shortcut wurde hinzugefügt, 0 = nicht
# steam_mode            auto | manual | skipped
# desktop_app_file      Pfad zur .desktop-Datei in ~/.local/share/applications
# desktop_desktop_file  Pfad zur .desktop-Datei auf dem Desktop (oder leer)
# desktop_mode          auto | skipped
# icon_file             Pfad zum kopierten Icon (oder leer)
# crkcachy_version      Version bei der Installation
# timestamp             ISO-8601 Zeitstempel der Installation
#
# ─────────────────────────────────────────────────────────────────────────────

# Globaler State – nur ein Protokoll gleichzeitig aktiv
INSTALL_LOG_SLUG=""
declare -gA _INSTALL_LOG=()

install_log_dir() {
  echo "${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/installs"
}

install_log_path() {
  local slug="${1:-$INSTALL_LOG_SLUG}"
  echo "$(install_log_dir)/${slug}.log"
}

# Neues Protokoll starten (überschreibt evt. altes im Speicher, NICHT auf Disk)
install_log_init() {
  local slug="$1"
  INSTALL_LOG_SLUG="$slug"
  _INSTALL_LOG=()
  _INSTALL_LOG["slug"]="$slug"
  _INSTALL_LOG["crkcachy_version"]="${CRKCACHY_VERSION:-}"
  _INSTALL_LOG["timestamp"]="$(date -Iseconds 2>/dev/null || date '+%Y-%m-%dT%H:%M:%S')"
  # Defaults
  _INSTALL_LOG["steam_shortcut_added"]="0"
  _INSTALL_LOG["steam_mode"]="skipped"
  _INSTALL_LOG["desktop_mode"]="skipped"
  _INSTALL_LOG["desktop_app_file"]=""
  _INSTALL_LOG["desktop_desktop_file"]=""
  _INSTALL_LOG["icon_file"]=""
}

# Feld setzen
install_log_set() {
  local key="$1"
  local value="$2"
  _INSTALL_LOG["$key"]="$value"
}

# Feld lesen (leerer String wenn nicht gesetzt)
install_log_get() {
  local key="$1"
  echo "${_INSTALL_LOG[$key]:-}"
}

# Auf Disk schreiben (atomisch via temp-Datei)
install_log_save() {
  local slug="${INSTALL_LOG_SLUG}"
  [[ -n "$slug" ]] || return 1

  local dir path tmp
  dir="$(install_log_dir)"
  mkdir -p "$dir"
  path="$(install_log_path "$slug")"
  tmp="${path}.tmp.$$"

  {
    echo "# CRKCACHY Install-Protokoll"
    echo "# Spiel: ${slug}"
    echo "# Erstellt: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "# Dieses File wird von CRKCACHY für die Deinstallation genutzt."
    echo "# Nicht manuell bearbeiten."
    echo ""
    # Feste Reihenfolge für bessere Lesbarkeit
    local ordered_keys=(
      slug crkcachy_version timestamp
      game_dir exe_path
      steam_display_name steam_launch_opts
      steam_shortcut_added steam_mode
      desktop_app_file desktop_desktop_file desktop_mode
      icon_file
    )
    local key
    for key in "${ordered_keys[@]}"; do
      if [[ -v "_INSTALL_LOG[$key]" ]]; then
        printf 'LOG_%s=%q\n' "${key^^}" "${_INSTALL_LOG[$key]}"
      fi
    done
    # Alle übrigen Felder die nicht in ordered_keys sind
    for key in "${!_INSTALL_LOG[@]}"; do
      local found=false
      local k
      for k in "${ordered_keys[@]}"; do [[ "$k" == "$key" ]] && found=true && break; done
      [[ "$found" == false ]] && printf 'LOG_%s=%q\n' "${key^^}" "${_INSTALL_LOG[$key]}"
    done
  } > "$tmp"

  mv -f "$tmp" "$path"
  log_debug "install_log_save → $path"
}

# Protokoll von Disk laden → befüllt _INSTALL_LOG
install_log_load() {
  local slug="$1"
  local path
  path="$(install_log_path "$slug")"

  if [[ ! -f "$path" ]]; then
    return 1
  fi

  INSTALL_LOG_SLUG="$slug"
  _INSTALL_LOG=()

  local line key value
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ "$line" =~ ^# ]] && continue
    [[ -z "$line" ]] && continue
    # Parst LOG_GAME_DIR='/path with spaces' oder LOG_GAME_DIR=/simple
    if [[ "$line" =~ ^LOG_([A-Z_]+)=(.*)$ ]]; then
      key="${BASH_REMATCH[1],,}"   # GAME_DIR → game_dir
      value="${BASH_REMATCH[2]}"
      # printf %q escaping aufheben: eval in subshell
      value="$(eval "printf '%s' ${value}" 2>/dev/null || echo "${value}")"
      _INSTALL_LOG["$key"]="$value"
    fi
  done < "$path"

  return 0
}

# Prüfen ob Protokoll existiert
install_log_exists() {
  local slug="$1"
  [[ -f "$(install_log_path "$slug")" ]]
}

# Protokoll nach erfolgreicher Deinstallation löschen
install_log_clear() {
  local slug="$1"
  local path
  path="$(install_log_path "$slug")"
  if [[ -f "$path" ]]; then
    rm -f "$path"
    log_debug "install_log_clear → $path"
  fi
}

# Gibt einen lesbaren Statusblock aus (für UI)
install_log_print_summary() {
  local slug="${1:-$INSTALL_LOG_SLUG}"

  if ! install_log_exists "$slug"; then
    return 1
  fi
  install_log_load "$slug" 2>/dev/null || return 1

  local game_dir exe_path ts version mode_steam mode_desktop

  game_dir="$(install_log_get game_dir)"
  exe_path="$(install_log_get exe_path)"
  ts="$(install_log_get timestamp)"
  version="$(install_log_get crkcachy_version)"
  mode_steam="$(install_log_get steam_mode)"
  mode_desktop="$(install_log_get desktop_mode)"

  echo ""
  cui_check_category "$(msg install_log.summary_title)"
  [[ -n "$ts" ]]      && cui_check_row ok "$(msg install_log.field_timestamp)"   "$ts"
  [[ -n "$version" ]] && cui_check_row ok "$(msg install_log.field_version)"     "$version"
  [[ -n "$game_dir" ]] && cui_check_row ok "$(msg install_log.field_game_dir)"   "" "$game_dir"
  [[ -n "$exe_path" ]] && cui_check_row ok "$(msg install_log.field_exe)"        "" "$(basename "$exe_path")"

  local shortcut; shortcut="$(install_log_get steam_shortcut_added)"
  if [[ "$shortcut" == "1" ]]; then
    cui_check_row ok "$(msg install_log.field_steam_shortcut)" "$(msg install_log.val_done)" "$mode_steam"
  else
    cui_check_row warn "$(msg install_log.field_steam_shortcut)" "$(msg install_log.val_manual)"
  fi

  local app_file; app_file="$(install_log_get desktop_app_file)"
  if [[ -n "$app_file" ]]; then
    if [[ -f "$app_file" ]]; then
      cui_check_row ok "$(msg install_log.field_desktop)" "$mode_desktop" "$(basename "$app_file")"
    else
      cui_check_row warn "$(msg install_log.field_desktop)" "$(msg install_log.val_file_gone)"
    fi
  fi

  echo ""
}

# Was würde die Deinstallation entfernen (für Bestätigungs-Dialog)
# Nutzt den aktuellen _INSTALL_LOG-State – kein erneutes Laden nötig wenn vorher
# install_log_load aufgerufen wurde. Falls nicht geladen: lade aus Datei.
install_log_print_uninstall_plan() {
  local slug="${1:-$INSTALL_LOG_SLUG}"
  # Nur neu laden wenn _INSTALL_LOG leer oder slug stimmt nicht überein
  if [[ "${#_INSTALL_LOG[@]}" -eq 0 || "${_INSTALL_LOG[slug]:-}" != "$slug" ]]; then
    install_log_load "$slug" 2>/dev/null || return 1
  fi

  echo ""
  cui_check_category "$(msg install_log.uninstall_plan_title)"

  local shortcut; shortcut="$(install_log_get steam_shortcut_added)"
  [[ "$shortcut" == "1" ]] && \
    cui_check_row ok "$(msg install_log.uninstall_steam_shortcut)" "$(msg install_log.val_will_remove)"

  local app_file; app_file="$(install_log_get desktop_app_file)"
  [[ -n "$app_file" && -f "$app_file" ]] && \
    cui_check_row ok "$(msg install_log.uninstall_desktop_app)" "$(msg install_log.val_will_remove)" "$(basename "$app_file")"

  local desk_file; desk_file="$(install_log_get desktop_desktop_file)"
  [[ -n "$desk_file" && -f "$desk_file" ]] && \
    cui_check_row ok "$(msg install_log.uninstall_desktop_icon)" "$(msg install_log.val_will_remove)" "$(basename "$desk_file")"

  local icon_file; icon_file="$(install_log_get icon_file)"
  [[ -n "$icon_file" && -f "$icon_file" ]] && \
    cui_check_row ok "$(msg install_log.uninstall_icon_cache)" "$(msg install_log.val_will_remove)"

  echo ""
}

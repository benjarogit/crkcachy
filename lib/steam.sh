#!/usr/bin/env bash
# Steam paths and Spacewar checks

set -euo pipefail

STEAM_ROOT="${STEAM_ROOT:-${HOME}/.local/share/Steam}"
STEAM_APPS="${STEAM_ROOT}/steamapps"
SPACEWAR_APPID="480"
SPACEWAR_MANIFEST="${STEAM_APPS}/appmanifest_${SPACEWAR_APPID}.acf"

steam_installed() {
  pacman_installed steam
}

find_steam_root() {
  local candidates=(
    "${HOME}/.local/share/Steam"
    "${HOME}/.steam/steam"
    "${HOME}/.var/app/com.valvesoftware.Steam/data/Steam"
  )

  for dir in "${candidates[@]}"; do
    if [[ -d "$dir/steamapps" ]]; then
      STEAM_ROOT="$dir"
      STEAM_APPS="${STEAM_ROOT}/steamapps"
      SPACEWAR_MANIFEST="${STEAM_APPS}/appmanifest_${SPACEWAR_APPID}.acf"
      return 0
    fi
  done

  return 1
}

check_steam() {
  if steam_installed; then
    log_ok "Steam package installed (pacman -Q steam)."
  else
    log_warn "Steam not installed via pacman. Install: paru -S steam"
    return 1
  fi

  if find_steam_root; then
    log_ok "Steam data directory: ${STEAM_ROOT}"
  else
    log_warn "Could not find Steam steamapps folder. Launch Steam once."
    return 1
  fi

  return 0
}

check_spacewar() {
  if [[ -f "$SPACEWAR_MANIFEST" ]]; then
    log_ok "Spacewar (App ${SPACEWAR_APPID}) is installed."
    return 0
  fi

  log_warn "Spacewar (App ${SPACEWAR_APPID}) not found."
  log_info "Install via Steam: steam://install/${SPACEWAR_APPID}"
  log_info "Or: Library → search 'Spacewar' → Install (free, hidden title)."
  return 1
}

print_overlay_hint() {
  log_info "Steam overlay: Settings → In-Game → Enable Steam Overlay."
  log_info "Test in game with Shift+Tab (required for invites in many fixes)."
}

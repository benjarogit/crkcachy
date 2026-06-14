#!/usr/bin/env bash
# Steam paths and Spacewar

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
    log_ok "$(msg steam.ok)"
  else
    log_warn "$(msg steam.missing_warn)"
    log_hint "$(msg steam.install_hint)"
    return 1
  fi

  if find_steam_root; then
    log_ok "$(msgf steam.data_ok "$STEAM_ROOT")"
  else
    log_warn "$(msg steam.data_missing)"
    log_hint "$(msg steam.data_hint)"
    return 1
  fi

  return 0
}

check_spacewar() {
  if [[ -f "$SPACEWAR_MANIFEST" ]]; then
    log_ok "$(msgf spacewar.ok "$SPACEWAR_APPID")"
    return 0
  fi

  log_warn "$(msg spacewar.missing)"
  log_hint "$(msg spacewar.hint1)"
  log_hint "$(msg spacewar.hint2)"
  return 1
}

print_overlay_hint() {
  explain_block "$(msg overlay.title)" "$(msg overlay.body)"
}

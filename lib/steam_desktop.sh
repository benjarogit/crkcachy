#!/usr/bin/env bash
# Desktop / start menu launchers that start games via Steam (steam://rungameid/…)

set -euo pipefail

CRKCACHY_ICONS="${HOME}/.local/share/crkcachy/icons"

steam_slugify() {
  local raw="${1:-game}"
  local slug
  slug="$(echo "$raw" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-z0-9]+/-/g; s/^-+|-+$//g')"
  [[ -n "$slug" ]] || slug="game"
  echo "$slug"
}

steam_command_path() {
  command -v steam 2>/dev/null || echo "steam"
}

xdg_desktop_dir() {
  local dirs_file="${HOME}/.config/user-dirs.dirs"
  local desktop_dir="${HOME}/Desktop"

  if [[ -f "$dirs_file" ]]; then
    local line dir
    line="$(grep -E '^XDG_DESKTOP_DIR=' "$dirs_file" | head -n1 || true)"
    if [[ "$line" =~ \"(.*)\" ]]; then
      dir="${BASH_REMATCH[1]}"
      dir="${dir/#\$HOME/"$HOME"}"
      [[ -d "$dir" ]] && desktop_dir="$dir"
    fi
  fi

  if [[ ! -d "$desktop_dir" && -d "${HOME}/Schreibtisch" ]]; then
    desktop_dir="${HOME}/Schreibtisch"
  fi

  echo "$desktop_dir"
}

xdg_applications_dir() {
  local data_home="${XDG_DATA_HOME:-${HOME}/.local/share}"
  echo "${data_home}/applications"
}

steam_fetch_shortcut_line() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local config_dir line

  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  while IFS= read -r config_dir; do
    line="$(python3 "$STEAM_ARTWORK_PY" "${config_dir}/shortcuts.vdf" \
      --exe "$exe_linux_path" --basename "$exe_basename" 2>/dev/null | head -n1 || true)"
    if [[ -n "$line" ]]; then
      echo "$line"
      return 0
    fi
  done < <(steam_userdata_config_dirs)

  return 1
}

steam_resolve_launcher_icon() {
  local game_dir="$1"
  local exe_path="$2"
  local slug="$3"
  local unsigned="$4"
  local config_dir grid_icon icon_dest tmp_png

  icon_dest="${CRKCACHY_ICONS}/${slug}.png"
  mkdir -p "$CRKCACHY_ICONS"

  while IFS= read -r config_dir; do
    grid_icon="${config_dir}/grid/${unsigned}.png"
    if [[ -f "$grid_icon" ]]; then
      cp -f "$grid_icon" "$icon_dest"
      echo "$icon_dest"
      return 0
    fi
  done < <(steam_userdata_config_dirs)

  if [[ -f "$icon_dest" ]]; then
    echo "$icon_dest"
    return 0
  fi

  tmp_png="$(mktemp --suffix=.crkcachy-icon.png)"
  if steam_prepare_icon_png "$game_dir" "$exe_path" "$tmp_png"; then
    cp -f "$tmp_png" "$icon_dest"
    rm -f "$tmp_png"
    echo "$icon_dest"
    return 0
  fi
  rm -f "$tmp_png"

  return 1
}

steam_write_desktop_entry() {
  local dest="$1"
  local display_name="$2"
  local rungameid="$3"
  local icon_path="${4:-}"
  local steam_cmd
  steam_cmd="$(steam_command_path)"

  {
    echo "[Desktop Entry]"
    echo "Version=1.0"
    echo "Type=Application"
    echo "Name=${display_name}"
    echo "Comment=Play this game on Steam"
    echo "Exec=${steam_cmd} steam://rungameid/${rungameid}"
    if [[ -n "$icon_path" && -f "$icon_path" ]]; then
      echo "Icon=${icon_path}"
    fi
    echo "Terminal=false"
    echo "Categories=Game;"
    echo "StartupNotify=true"
  } > "$dest"
}

steam_trust_desktop_file() {
  local path="$1"
  chmod +x "$path"
  if command_exists gio; then
    gio set "$path" "metadata::trusted" true 2>/dev/null || true
  fi
}

steam_refresh_desktop_cache() {
  if command_exists update-desktop-database; then
    update-desktop-database "${HOME}/.local/share/applications" 2>/dev/null || true
  fi
}

steam_remove_stale_desktop_launchers() {
  local desktop_dir="$1"
  local slug="$2"
  local exe_basename="$3"
  local new_file="${desktop_dir}/crkcachy-${slug}.desktop"
  local old

  for old in \
    "${desktop_dir}/${exe_basename}.desktop" \
    "${desktop_dir}/HouseOfAshes.exe.desktop"; do
    [[ -f "$old" ]] || continue
    [[ "$old" == "$new_file" ]] && continue
    if cui_yes_no "$(msgf steam.desktop_remove_old "$old")" true; then
      rm -f "$old"
      log_ok "$(msgf steam.desktop_removed "$old")"
    fi
  done
}

# Install ~/.local/share/applications + optional desktop icon.
steam_install_desktop_launcher() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local display_name="$3"
  local game_dir="${4:-$(dirname "$exe_linux_path")}"
  local slug="${5:-$(steam_slugify "$display_name")}"
  local line signed unsigned _legacy name _exe rungameid
  local apps_dir desktop_dir app_file desktop_file icon_path

  line="$(steam_fetch_shortcut_line "$exe_linux_path" "$exe_basename")" || {
    log_warn "$(msg steam.shortcut_not_found)"
    return 1
  }

  IFS=$'\t' read -r signed unsigned _legacy name _exe rungameid <<< "$line"
  [[ -n "${rungameid:-}" ]] || return 1

  if [[ -z "${display_name:-}" ]]; then
    display_name="$name"
  fi

  icon_path="$(steam_resolve_launcher_icon "$game_dir" "$exe_linux_path" "$slug" "$unsigned" || true)"

  if [[ -z "${icon_path:-}" ]]; then
    log_warn "$(msg steam.desktop_no_icon)"
  fi

  apps_dir="$(xdg_applications_dir)"
  mkdir -p "$apps_dir"
  app_file="${apps_dir}/crkcachy-${slug}.desktop"
  steam_write_desktop_entry "$app_file" "$display_name" "$rungameid" "${icon_path:-}"
  log_ok "$(msgf steam.desktop_apps "$app_file")"

  desktop_dir="$(xdg_desktop_dir)"
  if [[ -d "$desktop_dir" ]]; then
    desktop_file="${desktop_dir}/crkcachy-${slug}.desktop"
    steam_write_desktop_entry "$desktop_file" "$display_name" "$rungameid" "${icon_path:-}"
    steam_trust_desktop_file "$desktop_file"
    log_ok "$(msgf steam.desktop_desktop "$desktop_file")"
    steam_remove_stale_desktop_launchers "$desktop_dir" "$slug" "$exe_basename"
  fi

  steam_refresh_desktop_cache
  log_hint "$(msg steam.desktop_hint)"
  return 0
}

steam_offer_desktop_launcher() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local display_name="$3"
  local game_dir="${4:-$(dirname "$exe_linux_path")}"
  local slug="${5:-$(steam_slugify "$display_name")}"

  if ! steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    return 1
  fi

  echo ""
  explain_block "$(msg steam.desktop_title)" "$(msg steam.desktop_body)"
  if ! cui_yes_no "$(msg steam.desktop_confirm)" false; then
    return 0
  fi

  steam_install_desktop_launcher \
    "$exe_linux_path" "$exe_basename" "$display_name" "$game_dir" "$slug"
}

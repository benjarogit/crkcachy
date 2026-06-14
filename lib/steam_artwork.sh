#!/usr/bin/env bash
# Steam shortcuts – name, launch options, grid icons

set -euo pipefail

CRKCACHY_ROOT="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STEAM_ARTWORK_PY="${CRKCACHY_ROOT}/lib/steam_shortcut_id.py"

steam_userdata_config_dirs() {
  find_steam_root || return 1
  local dir
  for dir in "$STEAM_ROOT/userdata"/*/config; do
    [[ -d "$dir" ]] || continue
    [[ -f "${dir}/shortcuts.vdf" ]] || continue
    echo "$dir"
  done
}

steam_is_running() {
  pgrep -x steam >/dev/null 2>&1 || pgrep -f '[/]steam($| )' >/dev/null 2>&1
}

# Required for automatic shortcut editing (vdf + icon extraction).
ensure_steam_shortcut_tooling() {
  local missing=()

  if ! python3 -c "import vdf" 2>/dev/null; then
    missing+=(python-vdf)
  fi
  if ! command_exists wrestool; then
    missing+=(icoutils)
  fi
  if ! command_exists magick && ! command_exists convert; then
    missing+=(imagemagick)
  fi

  if [[ ${#missing[@]} -eq 0 ]]; then
    return 0
  fi

  package_explain_block "$(msg steam.tooling_title)" "${missing[@]}"
  if install_repo_packages true "${missing[@]}"; then
    hash -r 2>/dev/null || true
    return 0
  fi

  log_warn "$(msg steam.tooling_failed)"
  return 1
}

steam_shortcut_exists() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local config_dir

  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  while IFS= read -r config_dir; do
    if python3 "$STEAM_ARTWORK_PY" "${config_dir}/shortcuts.vdf" \
      --exe "$exe_linux_path" --basename "$exe_basename" >/dev/null 2>&1; then
      return 0
    fi
  done < <(steam_userdata_config_dirs)

  return 1
}

# Block until Steam is closed – UI explains why.
steam_ensure_closed_for_edit() {
  if ! steam_is_running; then
    return 0
  fi

  explain_block "$(msg steam.close_title)" "$(msg steam.close_body)"

  while steam_is_running; do
    if ! cui_yes_no "$(msg steam.close_confirm)" false; then
      log_warn "$(msg steam.close_abort)"
      return 1
    fi

    if ! steam_is_running; then
      log_ok "$(msg steam.close_ok)"
      return 0
    fi

    log_warn "$(msg steam.close_still_running)"
  done

  return 0
}

steam_prepare_icon_png() {
  local game_dir="$1"
  local exe_path="$2"
  local out_png="$3"
  local candidate tmpdir

  if [[ -f "$out_png" ]]; then
    rm -f "$out_png"
  fi

  for candidate in \
    "${game_dir}/icon.png" \
    "${game_dir}/Icon.png" \
    "${game_dir}"/*.ico; do
    [[ -f "$candidate" ]] || continue
    if steam_convert_to_png "$candidate" "$out_png"; then
      return 0
    fi
  done

  if command_exists wrestool && [[ -f "$exe_path" ]]; then
    tmpdir="$(mktemp -d)"
    if wrestool -x -o "$tmpdir" -t 0 "$exe_path" 2>/dev/null; then
      for ico in "$tmpdir"/*.ico; do
        [[ -f "$ico" ]] || continue
        if steam_convert_to_png "$ico" "$out_png"; then
          rm -rf "$tmpdir"
          return 0
        fi
      done
    fi
    rm -rf "$tmpdir"
  fi

  return 1
}

steam_convert_to_png() {
  local src="$1"
  local dst="$2"

  case "${src,,}" in
    *.png)
      cp "$src" "$dst"
      return 0
    ;;
  esac

  if command_exists magick; then
    magick convert "$src" -resize 512x512 "$dst" 2>/dev/null && return 0
  fi
  if command_exists convert; then
    convert "$src" -resize 512x512 "$dst" 2>/dev/null && return 0
  fi
  if command_exists icotool; then
    icotool -x -o "${dst%.png}.part.png" "$src" 2>/dev/null && \
      mv "${dst%.png}.part.png" "$dst" 2>/dev/null && return 0
  fi

  return 1
}

steam_copy_grid_icon() {
  local grid_dir="$1"
  local appid_unsigned="$2"
  local icon_png="$3"

  mkdir -p "$grid_dir"
  cp -f "$icon_png" "${grid_dir}/${appid_unsigned}.png"
  cp -f "$icon_png" "${grid_dir}/${appid_unsigned}p.png"
}

steam_apply_shortcut_name() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local display_name="$3"
  local config_dir shortcuts_path output applied=false

  [[ -n "$display_name" ]] || return 1
  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    shortcuts_path="${config_dir}/shortcuts.vdf"
    output="$(python3 "$STEAM_ARTWORK_PY" "$shortcuts_path" \
      --exe "$exe_linux_path" \
      --basename "$exe_basename" \
      --set-name "$display_name" 2>&1)" || true

    if grep -qE '^(renamed|unchanged-name)' <<< "$output"; then
      applied=true
      while IFS= read -r line; do
        case "$line" in
          renamed*)
            log_ok "$(msgf steam.name_renamed \
              "$(awk -F'\t' '{print $2}' <<< "$line")" \
              "$(awk -F'\t' '{print $3}' <<< "$line")")"
            ;;
          unchanged-name*)
            log_ok "$(msgf steam.name_ok "$display_name")"
            ;;
        esac
      done <<< "$output"
    fi
  done < <(steam_userdata_config_dirs)

  [[ "$applied" == true ]]
}

steam_apply_shortcut_launch_options() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local launch_opts="$3"
  local config_dir shortcuts_path output applied=false

  [[ -n "$launch_opts" ]] || return 1
  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    shortcuts_path="${config_dir}/shortcuts.vdf"
    output="$(python3 "$STEAM_ARTWORK_PY" "$shortcuts_path" \
      --exe "$exe_linux_path" \
      --basename "$exe_basename" \
      --set-launch-options "$launch_opts" 2>&1)" || true

    if grep -qE '^(launch-updated|unchanged-launch)' <<< "$output"; then
      applied=true
      if grep -q '^launch-updated' <<< "$output"; then
        log_ok "$(msg steam.launch_ok)"
      else
        log_ok "$(msg steam.launch_already)"
      fi
    fi
  done < <(steam_userdata_config_dirs)

  [[ "$applied" == true ]]
}

steam_apply_shortcut_icon() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local game_dir="${3:-$(dirname "$exe_linux_path")}"
  local icon_png tmp_png config_dir grid_dir applied=false

  [[ -f "$exe_linux_path" ]] || return 1
  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  tmp_png="$(mktemp --suffix=.crkcachy-icon.png)"
  if ! steam_prepare_icon_png "$game_dir" "$exe_linux_path" "$tmp_png"; then
    rm -f "$tmp_png"
    log_warn "$(msg steam.icon_extract_failed)"
    return 1
  fi
  icon_png="$tmp_png"

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    grid_dir="${config_dir}/grid"

    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      local _signed _unsigned _legacy _name _exe
      IFS=$'\t' read -r _signed _unsigned _legacy _name _exe <<< "$line"

      steam_copy_grid_icon "$grid_dir" "$_unsigned" "$icon_png"
      if [[ "$_legacy" != "$_unsigned" ]]; then
        steam_copy_grid_icon "$grid_dir" "$_legacy" "$icon_png"
      fi
      applied=true
      log_ok "$(msgf steam.icon_applied "$_name")"
    done < <(python3 "$STEAM_ARTWORK_PY" "${config_dir}/shortcuts.vdf" \
      --exe "$exe_linux_path" --basename "$exe_basename" 2>/dev/null || true)
  done < <(steam_userdata_config_dirs)

  rm -f "$tmp_png"
  [[ "$applied" == true ]]
}

# Auto: name + launch options + icon (Steam must be closed).
steam_configure_shortcut() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local game_dir="${3:-$(dirname "$exe_linux_path")}"
  local display_name="$4"
  local launch_opts="${5:-}"
  local name_ok=false launch_ok=false icon_ok=false

  if ! ensure_steam_shortcut_tooling; then
    return 1
  fi

  if ! steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    log_warn "$(msg steam.shortcut_not_found)"
    return 1
  fi

  if ! steam_ensure_closed_for_edit; then
    return 1
  fi

  if steam_apply_shortcut_name "$exe_linux_path" "$exe_basename" "$display_name"; then
    name_ok=true
  fi

  if [[ -n "$launch_opts" ]]; then
    if steam_apply_shortcut_launch_options "$exe_linux_path" "$exe_basename" "$launch_opts"; then
      launch_ok=true
    fi
  fi

  if steam_apply_shortcut_icon "$exe_linux_path" "$exe_basename" "$game_dir"; then
    icon_ok=true
  fi

  if [[ "$name_ok" == true || "$launch_ok" == true || "$icon_ok" == true ]]; then
    log_hint "$(msg steam.restart_steam)"
    return 0
  fi

  return 1
}

steam_print_manual_launch_options() {
  local launch_opts="$1"
  ui_step "$(msg steam.manual_launch_title)"
  echo "$(msg steam.manual_launch_body)"
  echo ""
  echo -e "${_C_GREEN}${launch_opts}${_C_RESET}"
  echo ""
  log_hint "$(msg steam.manual_launch_hint)"
}

# Legacy alias
steam_fix_shortcut_presentation() {
  steam_configure_shortcut "$@"
}

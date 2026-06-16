#!/usr/bin/env bash
# Reset Steam shortcut + desktop launcher for re-testing automated setup

set -euo pipefail

steam_clear_shortcut_launch_options() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local config_dir shortcuts_path output applied=false

  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    shortcuts_path="${config_dir}/shortcuts.vdf"
    output="$(python3 "$STEAM_ARTWORK_PY" "$shortcuts_path" \
      --exe "$exe_linux_path" \
      --basename "$exe_basename" \
      --clear-launch-options 2>&1)" || true

    if grep -qE '^(launch-cleared|unchanged-launch)' <<< "$output"; then
      applied=true
      if grep -q '^launch-cleared' <<< "$output"; then
        log_ok "$(msg steam.reset_launch_cleared)"
      else
        log_ok "$(msg steam.reset_launch_already)"
      fi
    fi
  done < <(steam_userdata_config_dirs)

  [[ "$applied" == true ]]
}

steam_remove_grid_icons() {
  local unsigned="$1"
  local legacy="${2:-}"
  local config_dir grid_dir removed=false

  while IFS= read -r config_dir; do
    grid_dir="${config_dir}/grid"
    [[ -d "$grid_dir" ]] || continue

    for id in "$unsigned" "$legacy"; do
      [[ -n "$id" ]] || continue
      if [[ -f "${grid_dir}/${id}.png" ]]; then
        rm -f "${grid_dir}/${id}.png"
        removed=true
        log_debug "removed grid icon ${grid_dir}/${id}.png"
      fi
      if [[ -f "${grid_dir}/${id}p.png" ]]; then
        rm -f "${grid_dir}/${id}p.png"
        removed=true
        log_debug "removed grid icon ${grid_dir}/${id}p.png"
      fi
    done
  done < <(steam_userdata_config_dirs)

  [[ "$removed" == true ]]
}

steam_remove_crkcachy_launchers() {
  local slug="$1"
  local exe_basename="${2:-}"
  local apps_dir desktop_dir app_file desktop_file removed=false

  apps_dir="$(xdg_applications_dir)"
  app_file="${apps_dir}/crkcachy-${slug}.desktop"
  if [[ -f "$app_file" ]]; then
    rm -f "$app_file"
    removed=true
    log_ok "$(msgf steam.reset_removed_apps "$app_file")"
  fi

  desktop_dir="$(xdg_desktop_dir)"
  if [[ -d "$desktop_dir" ]]; then
    desktop_file="${desktop_dir}/crkcachy-${slug}.desktop"
    if [[ -f "$desktop_file" ]]; then
      rm -f "$desktop_file"
      removed=true
      log_ok "$(msgf steam.reset_removed_desktop "$desktop_file")"
    fi

    for old in \
      "${desktop_dir}/${exe_basename}.desktop" \
      "${desktop_dir}/HouseOfAshes.exe.desktop"; do
      [[ -f "$old" ]] || continue
      rm -f "$old"
      removed=true
      log_ok "$(msgf steam.reset_removed_stale "$old")"
    done
  fi

  if [[ "$removed" == true ]]; then
    steam_refresh_desktop_cache
  fi

  return 0
}

steam_remove_cached_icon() {
  local slug="$1"
  local icon_path="${CRKCACHY_ICONS}/${slug}.png"

  if [[ -f "$icon_path" ]]; then
    rm -f "$icon_path"
    log_ok "$(msgf steam.reset_icon_cache "$icon_path")"
    return 0
  fi

  return 1
}

# Reset name, launch options, grid icons, desktop – shortcut stays in Steam library.
steam_reset_shortcut_setup() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local original_name="${3:-$exe_basename}"
  local slug="${4:-$(steam_slugify "$original_name")}"
  local configured_name="${5:-$original_name}"
  local line signed unsigned legacy _name _exe _run _launch
  local launch_cleared=false name_reset=false icons_removed=false

  log_debug "steam_reset_shortcut_setup exe=$exe_linux_path basename=$exe_basename slug=$slug"

  if ! steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    log_warn "$(msg steam.shortcut_not_found)"
    return 1
  fi

  steam_clear_target_profiles
  if ! steam_prompt_target_profiles \
    "$exe_linux_path" "$exe_basename" "$configured_name" "$original_name"; then
    log_warn "$(msg steam.profile_missing)"
    return 1
  fi

  if ! steam_ensure_closed_for_edit; then
    return 1
  fi

  line="$(steam_fetch_shortcut_line "$exe_linux_path" "$exe_basename")" || true
  if [[ -n "${line:-}" ]]; then
    IFS=$'\t' read -r signed unsigned legacy _name _exe _run _launch <<< "$line"
    log_debug "reset shortcut: unsigned=$unsigned legacy=$legacy name=$_name"
  fi

  if steam_apply_shortcut_name "$exe_linux_path" "$exe_basename" "$original_name"; then
    name_reset=true
    log_ok "$(msgf steam.reset_name_ok "$original_name")"
  fi

  if steam_clear_shortcut_launch_options "$exe_linux_path" "$exe_basename"; then
    launch_cleared=true
  fi

  if [[ -n "${unsigned:-}" ]]; then
    if steam_remove_grid_icons "$unsigned" "$legacy"; then
      icons_removed=true
      log_ok "$(msg steam.reset_grid_ok)"
    else
      log_hint "$(msg steam.reset_grid_none)"
    fi
  fi

  steam_remove_crkcachy_launchers "$slug" "$exe_basename"
  steam_remove_cached_icon "$slug" || true

  echo ""
  cui_heading "$(msg steam.reset_summary_title)"
  echo ""

  if [[ "$name_reset" == true ]]; then
    cui_result_line ok "$(msg steam.reset_summary_name)"
  else
    cui_result_line warn "$(msg steam.reset_summary_name)" "$(msg steam.summary_not_done)"
  fi

  if [[ "$launch_cleared" == true ]]; then
    cui_result_line ok "$(msg steam.reset_summary_launch)"
  else
    cui_result_line warn "$(msg steam.reset_summary_launch)" "$(msg steam.summary_not_done)"
  fi

  if [[ "$icons_removed" == true ]]; then
    cui_result_line ok "$(msg steam.reset_summary_icon)"
  else
    cui_result_line warn "$(msg steam.reset_summary_icon)" "$(msg steam.reset_grid_none)"
  fi

  cui_result_line ok "$(msg steam.reset_summary_desktop)"
  echo ""
  log_hint "$(msg steam.reset_next)"
  echo ""

  return 0
}

steam_remove_shortcut_from_library() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local config_dir shortcuts_path output removed=false

  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    shortcuts_path="${config_dir}/shortcuts.vdf"
    output="$(python3 "$STEAM_ARTWORK_PY" "$shortcuts_path" \
      --exe "$exe_linux_path" \
      --basename "$exe_basename" \
      --remove-shortcut 2>&1)" || true

    if grep -q '^removed' <<< "$output"; then
      removed=true
      log_ok "$(msg steam.uninstall_steam_removed)"
    fi
  done < <(steam_userdata_config_dirs)

  [[ "$removed" == true ]]
}

# Deinstall: reset + optional remove from Steam library.
steam_uninstall_crkcachy_setup() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local original_name="${3:-$exe_basename}"
  local slug="${4:-$(steam_slugify "$original_name")}"
  local remove_from_steam="${5:-false}"

  log_debug "uninstall exe=$exe_linux_path remove_from_steam=$remove_from_steam"

  if steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    if ! steam_ensure_closed_for_edit; then
      return 1
    fi
    steam_reset_shortcut_setup "$exe_linux_path" "$exe_basename" "$original_name" "$slug" || true

    if [[ "$remove_from_steam" == true ]]; then
      steam_remove_shortcut_from_library "$exe_linux_path" "$exe_basename" || \
        log_warn "$(msg steam.uninstall_steam_not_removed)"
    fi
  else
    log_warn "$(msg steam.shortcut_not_found)"
    steam_remove_crkcachy_launchers "$slug" "$exe_basename"
    steam_remove_cached_icon "$slug" || true
  fi

  echo ""
  cui_heading "$(msg steam.uninstall_summary_title)"
  echo ""
  cui_result_line ok "$(msg steam.uninstall_summary_desktop)"
  cui_result_line ok "$(msg steam.uninstall_summary_cache)"
  if [[ "$remove_from_steam" == true ]]; then
    cui_result_line ok "$(msg steam.uninstall_summary_steam)"
  else
    cui_result_line ok "$(msg steam.uninstall_summary_steam_kept)"
  fi
  echo ""
  log_hint "$(msg steam.uninstall_next)"
  echo ""

  return 0
}

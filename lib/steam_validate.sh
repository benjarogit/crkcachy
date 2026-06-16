#!/usr/bin/env bash
# Validate Steam shortcut + desktop launcher after automated setup

set -euo pipefail

steam_normalize_launch_opts() {
  local raw="${1:-}"
  echo "$raw" | tr -s ' ' | sed -e 's/^ //' -e 's/ $//'
}

steam_icon_file_valid() {
  local path="$1"
  local size

  [[ -f "$path" ]] || return 1
  size="$(stat -c%s "$path" 2>/dev/null || echo 0)"
  [[ "${size:-0}" -gt 200 ]]
}

steam_check_grid_icon() {
  local unsigned="$1"
  local legacy="${2:-}"
  local config_dir grid_dir path

  while IFS= read -r config_dir; do
    grid_dir="${config_dir}/grid"
    for id in "$unsigned" "$legacy"; do
      [[ -n "$id" ]] || continue
      path="${grid_dir}/${id}.png"
      if steam_icon_file_valid "$path"; then
        log_debug "grid icon ok: $path"
        return 0
      fi
      path="${grid_dir}/${id}p.png"
      if steam_icon_file_valid "$path"; then
        log_debug "grid icon ok: $path"
        return 0
      fi
    done
  done < <(steam_userdata_config_dirs)

  return 1
}

steam_read_desktop_icon_path() {
  local desktop_file="$1"
  local line

  [[ -f "$desktop_file" ]] || return 1
  line="$(grep -E '^Icon=' "$desktop_file" | head -n1 || true)"
  [[ -n "$line" ]] || return 1
  echo "${line#Icon=}"
}

steam_validate_desktop_launcher() {
  local slug="$1"
  local display_name="$2"
  local apps_dir desktop_dir app_file desktop_file icon_path name_line failures=0

  apps_dir="$(xdg_applications_dir)"
  app_file="${apps_dir}/crkcachy-${slug}.desktop"

  if [[ ! -f "$app_file" ]]; then
    log_debug "validate: missing app file $app_file"
    return 1
  fi

  name_line="$(grep -E '^Name=' "$app_file" | head -n1 || true)"
  if [[ "$name_line" != "Name=${display_name}" ]]; then
    failures=$((failures + 1))
    log_debug "validate: app name mismatch $name_line"
  fi

  icon_path="$(steam_read_desktop_icon_path "$app_file" || true)"
  if ! steam_icon_file_valid "${icon_path:-}"; then
    failures=$((failures + 1))
    log_debug "validate: app icon invalid ${icon_path:-empty}"
  fi

  desktop_dir="$(xdg_desktop_dir)"
  desktop_file="${desktop_dir}/crkcachy-${slug}.desktop"
  if [[ -d "$desktop_dir" && ! -f "$desktop_file" ]]; then
    failures=$((failures + 1))
    log_debug "validate: missing desktop file $desktop_file"
  fi

  [[ "$failures" -eq 0 ]]
}

steam_print_validate_report() {
  local name_ok="$1"
  local launch_ok="$2"
  local grid_ok="$3"
  local desktop_ok="$4"
  local issues="${5:-}"

  echo ""
  cui_heading "$(msg validate.report_title)"
  echo ""

  if [[ "$name_ok" == true ]]; then
    cui_result_line ok "$(msg validate.check_name)"
  else
    cui_result_line fail "$(msg validate.check_name)" "$(msg validate.fail_name)"
  fi

  if [[ "$launch_ok" == true ]]; then
    cui_result_line ok "$(msg validate.check_launch)"
  else
    cui_result_line fail "$(msg validate.check_launch)" "$(msg validate.fail_launch)"
  fi

  if [[ "$grid_ok" == true ]]; then
    cui_result_line ok "$(msg validate.check_steam_icon)"
  else
    cui_result_line fail "$(msg validate.check_steam_icon)" "$(msg validate.fail_steam_icon)"
  fi

  if [[ "$desktop_ok" == true ]]; then
    cui_result_line ok "$(msg validate.check_desktop)"
  else
    cui_result_line fail "$(msg validate.check_desktop)" "$(msg validate.fail_desktop)"
  fi

  if [[ -n "${issues:-}" ]]; then
    echo ""
    log_hint "$(msg validate.details_title)"
    local line
    while IFS= read -r line; do
      [[ -n "$line" ]] && log_hint "$line"
    done <<< "$issues"
  fi

  echo ""

  if [[ "$name_ok" == true && "$launch_ok" == true && "$grid_ok" == true && "$desktop_ok" == true ]]; then
    log_ok "$(msg validate.all_ok)"
    return 0
  fi

  log_warn "$(msg validate.some_failed)"
  return 1
}

# Returns 0 when all checks pass.
steam_validate_shortcut_setup() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local expected_name="$3"
  local expected_launch="${4:-}"
  local slug="${5:-$(steam_slugify "$expected_name")}"
  local line signed unsigned legacy actual_name _exe _run actual_launch
  local name_ok=false launch_ok=false grid_ok=false desktop_ok=false
  local issues=""

  log_debug "validate setup exe=$exe_linux_path expected_name=$expected_name slug=$slug"

  if ! steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    log_warn "$(msg steam.shortcut_not_found)"
    issues="$(msg validate.no_shortcut)"
    steam_print_validate_report false false false false "$issues"
    return 1
  fi

  steam_clear_target_profiles
  if ! steam_prompt_target_profiles \
    "$exe_linux_path" "$exe_basename" "$expected_name" "$exe_basename"; then
    issues="$(msg steam.profile_missing)"
    steam_print_validate_report false false false false "$issues"
    return 1
  fi

  line="$(steam_fetch_shortcut_line "$exe_linux_path" "$exe_basename")" || {
    issues="$(msg validate.read_failed)"
    steam_print_validate_report false false false false "$issues"
    return 1
  }

  IFS=$'\t' read -r signed unsigned legacy actual_name _exe _run actual_launch <<< "$line"
  log_debug "validate: name=$actual_name launch=${actual_launch:-empty}"

  if [[ "$actual_name" == "$expected_name" ]]; then
    name_ok=true
  else
    issues+="$(msgf validate.issue_name "$actual_name" "$expected_name")"$'\n'
  fi

  if [[ -n "$expected_launch" ]]; then
    if [[ "$(steam_normalize_launch_opts "$actual_launch")" == \
      "$(steam_normalize_launch_opts "$expected_launch")" ]]; then
      launch_ok=true
    else
      issues+="$(msg validate.issue_launch)"$'\n'
    fi
  else
    launch_ok=true
  fi

  if steam_check_grid_icon "$unsigned" "$legacy"; then
    grid_ok=true
  else
    issues+="$(msg validate.issue_grid)"$'\n'
  fi

  if steam_validate_desktop_launcher "$slug" "$expected_name"; then
    desktop_ok=true
  else
    issues+="$(msg validate.issue_desktop)"$'\n'
  fi

  steam_print_validate_report "$name_ok" "$launch_ok" "$grid_ok" "$desktop_ok" "$issues"
}

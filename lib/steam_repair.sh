#!/usr/bin/env bash
# Offer auto or manual repair after validation failures

set -euo pipefail

steam_repair_shortcut_setup() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local game_dir="${3:-$(dirname "$exe_linux_path")}"
  local display_name="$4"
  local launch_opts="${5:-}"
  local slug="${6:-$(steam_slugify "$display_name")}"

  if ! steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    log_warn "$(msg steam.shortcut_not_found)"
    explain_block "$(msg ha.steam_add_first_title)" "$(msg ha.steam_add_first_body)"
    echo "   ${exe_linux_path}"
    return 1
  fi

  steam_clear_target_profiles
  if ! steam_prompt_target_profiles \
    "$exe_linux_path" "$exe_basename" "$display_name" "$exe_basename"; then
    log_warn "$(msg steam.profile_missing)"
    return 1
  fi

  if ! steam_ensure_closed_for_edit; then
    return 1
  fi

  steam_apply_shortcut_name "$exe_linux_path" "$exe_basename" "$display_name" || true
  if [[ -n "$launch_opts" ]]; then
    steam_apply_shortcut_launch_options "$exe_linux_path" "$exe_basename" "$launch_opts" || true
  fi
  steam_apply_shortcut_icon "$exe_linux_path" "$exe_basename" "$game_dir" || true
  steam_install_desktop_launcher \
    "$exe_linux_path" "$exe_basename" "$display_name" "$game_dir" "$slug" || true

  steam_validate_shortcut_setup \
    "$exe_linux_path" "$exe_basename" "$display_name" "$launch_opts" "$slug"
}

steam_offer_repair_after_validate() {
  local exe_linux_path="$1"
  local exe_basename="$2"
  local game_dir="$3"
  local display_name="$4"
  local launch_opts="$5"
  local slug="$6"
  local manual_fn="${7:-}"

  if steam_validate_shortcut_setup \
    "$exe_linux_path" "$exe_basename" "$display_name" "$launch_opts" "$slug"; then
    return 0
  fi

  echo ""
  explain_block "$(msg repair.title)" "$(msg repair.body)"

  if cui_yes_no "$(msg repair.auto_confirm)" false; then
    steam_repair_shortcut_setup \
      "$exe_linux_path" "$exe_basename" "$game_dir" "$display_name" "$launch_opts" "$slug"
    return $?
  fi

  if [[ -n "$manual_fn" ]] && cui_yes_no "$(msg repair.manual_confirm)" false; then
    "$manual_fn" "$exe_linux_path" "$launch_opts"
    echo ""
    if cui_yes_no "$(msg repair.recheck_confirm)" false; then
      steam_validate_shortcut_setup \
        "$exe_linux_path" "$exe_basename" "$display_name" "$launch_opts" "$slug" || true
    fi
  fi

  return 1
}

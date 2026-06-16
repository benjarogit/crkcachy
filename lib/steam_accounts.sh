#!/usr/bin/env bash
# Steam userdata profiles – multi-account selection + per-account setup status

set -euo pipefail

STEAM_ARTWORK_PY="${CRKCACHY_ROOT}/lib/steam_shortcut_id.py"

# Config dirs chosen for the current operation (empty = all with shortcuts.vdf).
STEAM_TARGET_CONFIG_DIRS=()

steam_account_id_from_config_dir() {
  local config_dir="$1"
  basename "$(dirname "$config_dir")"
}

steam_profile_label_for_config() {
  local config_dir="$1"
  local account_id
  account_id="$(steam_account_id_from_config_dir "$config_dir")"

  find_steam_root || {
    echo "$account_id"
    return 0
  }

  python3 - "$STEAM_ROOT/config/loginusers.vdf" "$account_id" <<'PY'
import sys

path, account_id = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8", errors="replace") as handle:
        lines = handle.readlines()
except OSError:
    print(account_id)
    raise SystemExit

want = str(int(account_id))
current = None
persona = ""
account = ""
label = account_id
for raw in lines:
    line = raw.strip()
    if not line or line in ("users", "{", "}"):
        continue
    if line.startswith('"') and line.endswith('"') and "\t" not in line:
        key = line.strip('"')
        if key.isdigit():
            current = str(int(key) & 0xFFFFFFFF)
            persona = ""
            account = ""
        continue
    if current != want or "\t" not in line:
        continue
    key, _, val = line.partition("\t")
    key = key.strip().strip('"')
    val = val.strip().strip('"')
    if key == "PersonaName":
        persona = val
    elif key == "AccountName":
        account = val
    if persona or account:
        label = persona or account
        if persona and account and persona != account:
            label = f"{persona} ({account})"

print(label)
PY
}

steam_list_profile_config_dirs() {
  find_steam_root || return 1
  local userdata dir

  for userdata in "$STEAM_ROOT/userdata"/*/; do
    [[ -d "$userdata" ]] || continue
    dir="${userdata}config"
    [[ -d "$dir" ]] || continue
    echo "$dir"
  done
}

steam_userdata_all_config_dirs() {
  find_steam_root || return 1
  local dir

  for dir in "$STEAM_ROOT/userdata"/*/config; do
    [[ -d "$dir" ]] || continue
    [[ -f "${dir}/shortcuts.vdf" ]] || continue
    echo "$dir"
  done
}

steam_clear_target_profiles() {
  STEAM_TARGET_CONFIG_DIRS=()
}

steam_target_profiles_active() {
  [[ ${#STEAM_TARGET_CONFIG_DIRS[@]} -gt 0 ]]
}

steam_fetch_shortcut_line_for_config() {
  local config_dir="$1"
  local exe_linux_path="$2"
  local exe_basename="$3"

  [[ -f "${config_dir}/shortcuts.vdf" ]] || return 1
  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  python3 "$STEAM_ARTWORK_PY" "${config_dir}/shortcuts.vdf" \
    --exe "$exe_linux_path" --basename "$exe_basename" 2>/dev/null | head -n1
}

steam_profile_grid_ok_for_config() {
  local config_dir="$1"
  local unsigned="$2"
  local legacy="$3"
  local grid_dir="${config_dir}/grid"
  local id path

  for id in "$unsigned" "$legacy"; do
    [[ -n "$id" ]] || continue
    for path in "${grid_dir}/${id}.png" "${grid_dir}/${id}p.png"; do
      if steam_icon_file_valid "$path" 2>/dev/null; then
        return 0
      fi
    done
  done

  return 1
}

# stdout: configured|default|none + tab + detail key list
steam_profile_setup_state() {
  local config_dir="$1"
  local exe_linux_path="$2"
  local exe_basename="$3"
  local configured_name="$4"
  local default_name="$5"
  local line signed unsigned legacy name _exe _run launch
  local -a parts=()

  line="$(steam_fetch_shortcut_line_for_config "$config_dir" "$exe_linux_path" "$exe_basename" || true)"
  if [[ -z "$line" ]]; then
    echo "none"
    return 0
  fi

  IFS=$'\t' read -r signed unsigned legacy name _exe _run launch <<< "$line"

  if [[ "$name" == "$configured_name" ]]; then
    parts+=("name")
  elif [[ "$name" != "$default_name" ]]; then
    parts+=("name_custom")
  fi

  if [[ -n "${launch:-}" ]]; then
    parts+=("launch")
  fi

  if steam_profile_grid_ok_for_config "$config_dir" "$unsigned" "$legacy"; then
    parts+=("icon")
  fi

  if [[ ${#parts[@]} -gt 0 ]]; then
    echo "configured$(printf '\t%s' "${parts[*]}")"
  else
    echo "default$(printf '\t%s' "$name")"
  fi
}

steam_profile_status_text() {
  local state="$1"
  local detail="${2:-}"

  case "$state" in
    none) echo "$(msg steam.profile_status_none)" ;;
    configured)
      local text="" key
      for key in ${detail//|/ }; do
        case "$key" in
          name) text+="${text:+, }$(msg steam.profile_status_name)" ;;
          name_custom) text+="${text:+, }$(msg steam.profile_status_name_custom)" ;;
          launch) text+="${text:+, }$(msg steam.profile_status_launch)" ;;
          icon) text+="${text:+, }$(msg steam.profile_status_icon)" ;;
        esac
      done
      echo "$(msgf steam.profile_status_configured "$text")"
      ;;
    default) echo "$(msgf steam.profile_status_default "$detail")" ;;
    *) echo "$detail" ;;
  esac
}

steam_print_profile_scan() {
  local exe_linux_path="$1"
  local exe_basename="$2"
  local configured_name="$3"
  local default_name="$4"
  local config_dir label state detail state_name status

  echo ""
  cui_heading "$(msg steam.profile_scan_title)"
  echo ""

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    label="$(steam_profile_label_for_config "$config_dir")"
    IFS=$'\t' read -r state detail <<< "$(steam_profile_setup_state \
      "$config_dir" "$exe_linux_path" "$exe_basename" "$configured_name" "$default_name")"
    detail="${detail//	/ }"
    status="$(steam_profile_status_text "$state" "$detail")"

    case "$state" in
      none) cui_result_line warn "$label" "$status" ;;
      configured) cui_result_line ok "$label" "$status" ;;
      *) cui_result_line warn "$label" "$status" ;;
    esac
  done < <(steam_list_profile_config_dirs)

  echo ""
}

# Game-aware profile picker – shows per-account CRKCACHY status.
steam_prompt_target_profiles_for_game() {
  local exe_linux_path="$1"
  local exe_basename="$2"
  local configured_name="$3"
  local default_name="${4:-$exe_basename}"
  local -a all_dirs=() with_game=() configured_dirs=() labels=() pick_dirs=()
  local config_dir label state detail pick i

  if steam_target_profiles_active; then
    return 0
  fi

  mapfile -t all_dirs < <(steam_list_profile_config_dirs)
  if [[ ${#all_dirs[@]} -eq 0 ]]; then
    return 1
  fi

  for config_dir in "${all_dirs[@]}"; do
    IFS=$'\t' read -r state detail <<< "$(steam_profile_setup_state \
      "$config_dir" "$exe_linux_path" "$exe_basename" "$configured_name" "$default_name")"
    if [[ "$state" != "none" ]]; then
      with_game+=("$config_dir")
      if [[ "$state" == "configured" ]]; then
        configured_dirs+=("$config_dir")
      fi
    fi
  done

  if [[ ${#with_game[@]} -eq 0 ]]; then
    log_warn "$(msg steam.shortcut_not_found)"
    return 1
  fi

  if [[ ${#all_dirs[@]} -eq 1 && ${#with_game[@]} -eq 1 ]]; then
    STEAM_TARGET_CONFIG_DIRS=("${with_game[0]}")
    label="$(steam_profile_label_for_config "${with_game[0]}")"
    IFS=$'\t' read -r state detail <<< "$(steam_profile_setup_state \
      "${with_game[0]}" "$exe_linux_path" "$exe_basename" "$configured_name" "$default_name")"
    log_ok "$(msgf steam.profile_one_ok "$label") – $(steam_profile_status_text "$state" "${detail//	/ }")"
    return 0
  fi

  steam_print_profile_scan "$exe_linux_path" "$exe_basename" "$configured_name" "$default_name"

  explain_block "$(msg steam.profile_title)" "$(msg steam.profile_body)"

  labels=()
  if [[ ${#configured_dirs[@]} -gt 0 ]]; then
    labels+=("$(msgf steam.profile_opt_configured "${#configured_dirs[@]}")")
    pick_dirs+=("__configured__")
  fi
  if [[ ${#with_game[@]} -gt 0 ]]; then
    labels+=("$(msgf steam.profile_opt_with_game "${#with_game[@]}")")
    pick_dirs+=("__with_game__")
  fi
  labels+=("$(msg steam.profile_all)")
  pick_dirs+=("__all__")

  for config_dir in "${with_game[@]}"; do
    label="$(steam_profile_label_for_config "$config_dir")"
    IFS=$'\t' read -r state detail <<< "$(steam_profile_setup_state \
      "$config_dir" "$exe_linux_path" "$exe_basename" "$configured_name" "$default_name")"
    labels+=("${label} · $(steam_profile_status_text "$state" "${detail//	/ }")")
    pick_dirs+=("$config_dir")
  done

  pick="$(cui_choose "$(msg steam.profile_pick)" 0 "${labels[@]}")"

  for i in "${!labels[@]}"; do
    [[ "${labels[$i]}" == "$pick" ]] || continue
    case "${pick_dirs[$i]}" in
      __configured__)
        STEAM_TARGET_CONFIG_DIRS=("${configured_dirs[@]}")
        log_ok "$(msgf steam.profile_configured_ok "${#configured_dirs[@]}")"
        return 0
        ;;
      __with_game__)
        STEAM_TARGET_CONFIG_DIRS=("${with_game[@]}")
        log_ok "$(msgf steam.profile_with_game_ok "${#with_game[@]}")"
        return 0
        ;;
      __all__)
        STEAM_TARGET_CONFIG_DIRS=("${all_dirs[@]}")
        log_ok "$(msg steam.profile_all_ok)"
        return 0
        ;;
      *)
        STEAM_TARGET_CONFIG_DIRS=("${pick_dirs[$i]}")
        log_ok "$(msgf steam.profile_one_ok "$(steam_profile_label_for_config "${pick_dirs[$i]}")")"
        return 0
        ;;
    esac
  done

  STEAM_TARGET_CONFIG_DIRS=("${with_game[@]}")
  return 0
}

# Generic fallback when no game context is available.
steam_prompt_target_profiles() {
  local -a config_dirs=() labels=() pick i label

  if steam_target_profiles_active; then
    return 0
  fi

  if [[ $# -ge 2 ]]; then
    steam_prompt_target_profiles_for_game "$@"
    return $?
  fi

  mapfile -t config_dirs < <(steam_list_profile_config_dirs)
  if [[ ${#config_dirs[@]} -eq 0 ]]; then
    return 1
  fi

  if [[ ${#config_dirs[@]} -eq 1 ]]; then
    STEAM_TARGET_CONFIG_DIRS=("${config_dirs[0]}")
    return 0
  fi

  explain_block "$(msg steam.profile_title)" "$(msg steam.profile_body)"

  labels+=("$(msg steam.profile_all)")
  for dir in "${config_dirs[@]}"; do
    labels+=("$(steam_profile_label_for_config "$dir")")
  done

  pick="$(cui_choose "$(msg steam.profile_pick)" 0 "${labels[@]}")"

  if [[ "$pick" == "$(msg steam.profile_all)" ]]; then
    STEAM_TARGET_CONFIG_DIRS=("${config_dirs[@]}")
    log_ok "$(msg steam.profile_all_ok)"
    return 0
  fi

  for i in "${!config_dirs[@]}"; do
    label="${labels[$((i + 1))]}"
    if [[ "$pick" == "$label" ]]; then
      STEAM_TARGET_CONFIG_DIRS=("${config_dirs[$i]}")
      log_ok "$(msgf steam.profile_one_ok "$pick")"
      return 0
    fi
  done

  STEAM_TARGET_CONFIG_DIRS=("${config_dirs[@]}")
  return 0
}

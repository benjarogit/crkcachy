#!/usr/bin/env bash
# Steam shortcuts – name, launch options, grid icons

set -euo pipefail

CRKCACHY_ROOT="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
STEAM_ARTWORK_PY="${CRKCACHY_ROOT}/lib/steam_shortcut_id.py"

steam_icon_file_valid() {
  local path="$1"
  local size

  [[ -f "$path" ]] || return 1
  size="$(stat -c%s "$path" 2>/dev/null || echo 0)"
  [[ "${size:-0}" -gt 200 ]]
}

steam_userdata_config_dirs() {
  local dir

  if steam_target_profiles_active; then
    printf '%s\n' "${STEAM_TARGET_CONFIG_DIRS[@]}"
    return 0
  fi

  steam_userdata_all_config_dirs
}

steam_is_running() {
  pgrep -x steam >/dev/null 2>&1 || pgrep -f '[/]steam($| )' >/dev/null 2>&1
}

# Required for automatic shortcut editing (vdf + icon extraction).
ensure_steam_shortcut_tooling() {
  local missing=()
  local -a steam_tooling=(python-vdf icoutils imagemagick)

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

  explain_block "$(msg steam.tooling_title)" "$(msg steam.tooling_why)"
  package_install_plan_block "$(msg steam.tooling_plan_title)" "${missing[@]}"

  if ! confirm "$(msg steam.tooling_confirm)"; then
    log_warn "$(msg steam.tooling_skipped)"
    log_hint "$(msg steam.tooling_manual_hint)"
    return 1
  fi

  if install_repo_packages true "${missing[@]}"; then
    hash -r 2>/dev/null || true
    return 0
  fi

  log_warn "$(msg steam.tooling_failed)"
  return 1
}

steam_offer_icon_tooling_retry() {
  local -a need=()

  if ! command_exists wrestool; then
    need+=(icoutils)
  fi
  if ! command_exists magick && ! command_exists convert; then
    need+=(imagemagick)
  fi

  [[ ${#need[@]} -eq 0 ]] && return 1

  explain_block "$(msg steam.icon_retry_title)" "$(msg steam.icon_retry_body)"
  package_install_plan_block "$(msg steam.tooling_plan_title)" "${need[@]}"

  if confirm "$(msg steam.icon_retry_confirm)"; then
    install_repo_packages true "${need[@]}" && hash -r 2>/dev/null || true
  fi

  return 0
}

steam_print_setup_summary() {
  local name_ok="$1"
  local launch_ok="$2"
  local icon_ok="$3"
  local compat_ok="${4:-false}"
  local compat_name="${5:-}"

  echo ""
  cui_heading "$(msg steam.summary_title)"
  echo ""

  if [[ "$name_ok" == true ]]; then
    cui_result_line ok "$(msg steam.summary_name)"
  else
    cui_result_line warn "$(msg steam.summary_name)" "$(msg steam.summary_not_done)"
  fi

  if [[ "$launch_ok" == true ]]; then
    cui_result_line ok "$(msg steam.summary_launch)"
  else
    cui_result_line warn "$(msg steam.summary_launch)" "$(msg steam.summary_not_done)"
  fi

  if [[ "$icon_ok" == true ]]; then
    cui_result_line ok "$(msg steam.summary_icon)"
  else
    cui_result_line warn "$(msg steam.summary_icon)" "$(msg steam.summary_icon_fail)"
  fi

  if [[ "$compat_ok" == true ]]; then
    cui_result_line ok "$(msg steam.summary_compat)" \
      "$(if [[ -n "$compat_name" ]]; then echo "$compat_name"; fi)"
  else
    cui_result_line warn "$(msg steam.summary_compat)" "$(msg steam.summary_compat_manual)"
  fi

  echo ""
  log_hint "$(msg steam.summary_restart)"
  echo ""
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
  done < <(steam_userdata_all_config_dirs)

  return 1
}

steam_try_shutdown() {
  local steam_cmd waited=0

  if ! steam_is_running; then
    return 0
  fi

  steam_cmd="$(steam_command_path)"
  log_info "$(msg steam.close_shutting_down)"

  if ! "$steam_cmd" -shutdown 2>/dev/null; then
    log_debug "steam -shutdown failed, trying steam steam://exit"
    "$steam_cmd" steam://exit 2>/dev/null || true
  fi

  while steam_is_running && [[ "$waited" -lt 45 ]]; do
    sleep 1
    waited=$((waited + 1))
  done

  ! steam_is_running
}

# Block until Steam is closed – offers steam -shutdown.
steam_ensure_closed_for_edit() {
  local pick

  if ! steam_is_running; then
    return 0
  fi

  explain_block "$(msg steam.close_title)" "$(msg steam.close_body)"

  while steam_is_running; do
    pick="$(cui_choose "$(msg steam.close_pick)" 0 \
      "$(msg steam.close_opt_shutdown)" \
      "$(msg steam.close_opt_manual)" \
      "$(msg action.opt_back)")"

    case "$pick" in
      "$(msg steam.close_opt_shutdown)")
        if steam_try_shutdown; then
          log_ok "$(msg steam.close_ok)"
          return 0
        fi
        log_warn "$(msg steam.close_still_running)"
        ;;
      "$(msg steam.close_opt_manual)")
        if ! steam_is_running; then
          log_ok "$(msg steam.close_ok)"
          return 0
        fi
        log_warn "$(msg steam.close_still_running)"
        ;;
      *)
        log_warn "$(msg steam.close_abort)"
        return 1
        ;;
    esac
  done

  return 0
}

steam_wrestool_resource_usable() {
  local path="$1"
  local fsize mime

  [[ -f "$path" ]] || return 1
  fsize="$(stat -c%s "$path" 2>/dev/null || echo 0)"
  [[ "${fsize:-0}" -ge 200 ]] || return 1

  mime="$(file -b "$path" 2>/dev/null || true)"
  [[ -n "$mime" ]] || return 1
  [[ "$mime" == data ]] && return 1
  [[ "$mime" == *"image size 0"* ]] && return 1

  grep -qiE 'PNG|ICO|icon|bitmap|MS Windows icon' <<< "$mime"
}

steam_wrestool_pick_best_resource() {
  local tmpdir="$1"
  local prefer_png="$2"
  local f fsize best size mime

  best=""
  size=0

  for f in "$tmpdir"/*; do
    [[ -f "$f" ]] || continue
    steam_wrestool_resource_usable "$f" || continue
    mime="$(file -b "$f" 2>/dev/null || true)"
    if [[ "$prefer_png" == true && "$mime" != *PNG* ]]; then
      continue
    fi
    fsize="$(stat -c%s "$f" 2>/dev/null || echo 0)"
    if [[ "${fsize:-0}" -gt "$size" ]]; then
      size="$fsize"
      best="$f"
    fi
  done

  [[ -n "$best" ]] && echo "$best"
}

steam_wrestool_best_icon() {
  local exe_path="$1"
  local out_png="$2"
  local tmpdir best

  [[ -f "$exe_path" ]] || return 1
  command_exists wrestool || return 1

  tmpdir="$(mktemp -d)"
  best=""

  if wrestool --raw -x -o "$tmpdir" "$exe_path" 2>/dev/null; then
    best="$(steam_wrestool_pick_best_resource "$tmpdir" true || true)"
    [[ -z "$best" ]] && best="$(steam_wrestool_pick_best_resource "$tmpdir" false || true)"
    if [[ -n "$best" ]] && steam_convert_to_png "$best" "$out_png" && steam_icon_file_valid "$out_png"; then
      log_debug "icon from wrestool --raw: $best"
      rm -rf "$tmpdir"
      return 0
    fi
  fi

  rm -rf "$tmpdir"
  return 1
}

steam_prepare_icon_png() {
  local game_dir="$1"
  local exe_path="$2"
  local out_png="$3"
  local candidate tmpdir t ico

  log_debug "prepare icon: game_dir=$game_dir exe=$exe_path"

  if [[ -f "$out_png" ]]; then
    rm -f "$out_png"
  fi

  for candidate in \
    "${game_dir}/icon.png" \
    "${game_dir}/Icon.png" \
    "${game_dir}"/*.ico; do
    [[ -f "$candidate" ]] || continue
    if steam_convert_to_png "$candidate" "$out_png" && steam_icon_file_valid "$out_png"; then
      log_debug "icon from file: $candidate"
      return 0
    fi
  done

  if steam_wrestool_best_icon "$exe_path" "$out_png"; then
    return 0
  fi

  if command_exists wrestool && [[ -f "$exe_path" ]]; then
    log_debug "wrestool --raw failed – HouseOfAshes.exe needs --raw for embedded PNG"
    tmpdir="$(mktemp -d)"
    if wrestool --raw -x -o "$tmpdir" "$exe_path" 2>/dev/null; then
      for ico in "$tmpdir"/*; do
        [[ -f "$ico" ]] || continue
        steam_wrestool_resource_usable "$ico" || continue
        if steam_convert_to_png "$ico" "$out_png" && steam_icon_file_valid "$out_png"; then
          log_debug "icon from wrestool --raw fallback: $ico"
          rm -rf "$tmpdir"
          return 0
        fi
      done
    fi
    rm -rf "$tmpdir"

    log_debug "wrestool could not extract icon from $exe_path"
  fi

  return 1
}

steam_normalize_png_output() {
  local src="$1"
  local dst="$2"

  if command_exists magick; then
    magick "$src" -resize 512x512 "$dst" 2>/dev/null && steam_icon_file_valid "$dst" && return 0
    magick convert "$src" -resize 512x512 "$dst" 2>/dev/null && steam_icon_file_valid "$dst" && return 0
  elif command_exists convert; then
    convert "$src" -resize 512x512 "$dst" 2>/dev/null && steam_icon_file_valid "$dst" && return 0
  fi

  cp "$src" "$dst" 2>/dev/null || return 1
  steam_icon_file_valid "$dst"
}

steam_convert_to_png() {
  local src="$1"
  local dst="$2"
  local tmp_dst=""

  [[ -f "$src" ]] || return 1

  case "${src,,}" in
    *.png)
      steam_normalize_png_output "$src" "$dst"
      return $?
      ;;
    *)
      if file -b "$src" 2>/dev/null | grep -qi 'PNG'; then
        steam_normalize_png_output "$src" "$dst"
        return $?
      elif command_exists magick; then
        magick "$src" -resize 512x512 "$dst" 2>/dev/null || \
          magick convert "$src" -resize 512x512 "$dst" 2>/dev/null || true
      elif command_exists convert; then
        convert "$src" -resize 512x512 "$dst" 2>/dev/null || true
      elif command_exists icotool; then
        icotool -x -o "${dst%.png}.part.png" "$src" 2>/dev/null || true
        if [[ -f "${dst%.png}.part.png" ]]; then
          tmp_dst="${dst%.png}.part.png"
          steam_normalize_png_output "$tmp_dst" "$dst" || mv "$tmp_dst" "$dst" 2>/dev/null || true
          rm -f "$tmp_dst"
        else
          local part
          for part in "${dst%.png}.part.png"*; do
            [[ -f "$part" ]] || continue
            steam_normalize_png_output "$part" "$dst" && break
          done
        fi
      fi
      ;;
  esac

  steam_icon_file_valid "$dst"
}

steam_copy_grid_icon() {
  local grid_dir="$1"
  local appid_unsigned="$2"
  local icon_png="$3"

  [[ -f "$icon_png" ]] || {
    log_debug "copy grid icon: source missing $icon_png"
    return 1
  }

  mkdir -p "$grid_dir"
  cp -f "$icon_png" "${grid_dir}/${appid_unsigned}.png" 2>/dev/null || return 1
  cp -f "$icon_png" "${grid_dir}/${appid_unsigned}p.png" 2>/dev/null || return 1
  steam_icon_file_valid "${grid_dir}/${appid_unsigned}.png" && \
    steam_icon_file_valid "${grid_dir}/${appid_unsigned}p.png"
}

steam_add_shortcut_to_profile() {
  local config_dir="$1"
  local exe_linux_path="$2"
  local display_name="$3"
  local launch_opts="${4:-}"
  local shortcuts_path output start_dir

  [[ -f "$STEAM_ARTWORK_PY" ]] || return 1

  start_dir="$(dirname "$exe_linux_path")"
  shortcuts_path="${config_dir}/shortcuts.vdf"

  if [[ ! -f "$shortcuts_path" ]]; then
    mkdir -p "$config_dir"
    # python-vdf will create fresh file; bootstrap with empty structure
    python3 - "$shortcuts_path" <<'PY'
import sys, pathlib
try:
    import vdf
    pathlib.Path(sys.argv[1]).write_bytes(vdf.binary_dumps({"shortcuts": {}}))
except Exception:
    pass
PY
  fi

  output="$(python3 "$STEAM_ARTWORK_PY" "$shortcuts_path" \
    --exe "$exe_linux_path" \
    --add-shortcut "$display_name" \
    --start-dir "$start_dir" \
    --launch-options-add "$launch_opts" 2>&1)" || return 1

  if grep -qE '^(added|already-present)' <<< "$output"; then
    local line
    while IFS= read -r line; do
      case "$line" in
        added*)
          log_ok "$(msgf steam.shortcut_added "$display_name")"
          ;;
        already-present*)
          log_ok "$(msgf steam.shortcut_already_present "$display_name")"
          ;;
      esac
    done <<< "$output"
    return 0
  fi

  log_debug "add_shortcut output: $output"
  return 1
}

steam_add_shortcut() {
  local exe_linux_path="$1"
  local display_name="$2"
  local launch_opts="${3:-}"
  local config_dir added=false

  if ! ensure_steam_shortcut_tooling; then
    return 1
  fi

  steam_clear_target_profiles
  if ! steam_prompt_target_profiles; then
    log_warn "$(msg steam.profile_missing)"
    return 1
  fi

  if ! steam_ensure_closed_for_edit; then
    return 1
  fi

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    if steam_add_shortcut_to_profile "$config_dir" "$exe_linux_path" "$display_name" "$launch_opts"; then
      added=true
    fi
  done < <(steam_userdata_config_dirs)

  [[ "$added" == true ]]
}

steam_offer_add_shortcut() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local display_name="$3"
  local launch_opts="${4:-}"

  echo ""
  cui_section "$(msg steam.add_title)" "$(msgf steam.add_body "$exe_linux_path")"
  echo ""

  local pick
  pick="$(cui_choose "$(msg steam.add_pick)" 0 \
    "$(msg steam.add_opt_auto)" \
    "$(msg steam.add_opt_manual)" \
    "$(msg action.opt_back)")"

  case "$pick" in
    "$(msg steam.add_opt_auto)")
      if steam_add_shortcut "$exe_linux_path" "$display_name" "$launch_opts"; then
        log_ok "$(msg steam.add_done)"
        return 0
      fi
      log_warn "$(msg steam.add_failed)"
      return 1
      ;;
    "$(msg steam.add_opt_manual)")
      return 2
      ;;
    *)
      return 1
      ;;
  esac
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
    [[ -f "${config_dir}/shortcuts.vdf" ]] || continue
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
    [[ -f "${config_dir}/shortcuts.vdf" ]] || continue
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
    [[ -f "${config_dir}/shortcuts.vdf" ]] || continue
    grid_dir="${config_dir}/grid"

    while IFS= read -r line; do
      [[ -n "$line" ]] || continue
      local _signed _unsigned _legacy _name _exe _run _launch copied=false
      IFS=$'\t' read -r _signed _unsigned _legacy _name _exe _run _launch <<< "$line"

      if steam_copy_grid_icon "$grid_dir" "$_unsigned" "$icon_png"; then
        copied=true
      fi
      if [[ "$_legacy" != "$_unsigned" ]]; then
        steam_copy_grid_icon "$grid_dir" "$_legacy" "$icon_png" || true
      fi
      if [[ "$copied" == true ]]; then
        applied=true
        log_ok "$(msgf steam.icon_applied "$_name")"
      fi
    done < <(python3 "$STEAM_ARTWORK_PY" "${config_dir}/shortcuts.vdf" \
      --exe "$exe_linux_path" --basename "$exe_basename" 2>/dev/null || true)
  done < <(steam_userdata_config_dirs)

  rm -f "$tmp_png"
  [[ "$applied" == true ]]
}

# Setzt das Proton-Compat-Tool für einen Non-Steam-Shortcut in config.vdf.
# Args: exe_linux_path exe_basename tool_name
steam_apply_compat_tool() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local tool_name="${3:-}"

  [[ -n "$tool_name" ]] || return 1

  local _steam_root
  _steam_root="$(find_steam_root 2>/dev/null || echo "${HOME}/.local/share/Steam")"
  local _config_vdf="${_steam_root}/config/config.vdf"
  [[ -f "$_config_vdf" ]] || { log_warn "$(msg steam.config_not_found)"; return 1; }

  # Unsigned App-ID aus dem Shortcut ermitteln
  local _line _unsigned
  _line="$(steam_fetch_shortcut_line "$exe_linux_path" "$exe_basename" 2>/dev/null || true)"
  [[ -n "${_line:-}" ]] || { log_warn "$(msg steam.shortcut_not_found)"; return 1; }
  _unsigned="$(echo "$_line" | cut -f2)"
  [[ -n "${_unsigned:-}" ]] || { log_warn "$(msg steam.compat_no_appid)"; return 1; }

  log_debug "steam_apply_compat_tool: appid=$_unsigned tool=$tool_name"

  # Compat-Tool in config.vdf schreiben
  local _out _rc
  _out="$(python3 "$STEAM_ARTWORK_PY" \
    --config-vdf "$_config_vdf" \
    --set-compat-tool "$tool_name" \
    --app-unsigned-id "$_unsigned" 2>&1)"
  _rc=$?

  if [[ "$_rc" -eq 0 ]]; then
    log_ok "$(msgf steam.compat_tool_set "$tool_name")"
    return 0
  else
    log_warn "$(msgf steam.compat_tool_failed "$tool_name")"
    log_debug "steam_apply_compat_tool output: $_out"
    return 1
  fi
}

# Verifiziert ob das Compat-Tool in config.vdf gesetzt ist.
steam_verify_compat_tool() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local expected_tool="${3:-}"

  local _steam_root
  _steam_root="$(find_steam_root 2>/dev/null || echo "${HOME}/.local/share/Steam")"
  local _config_vdf="${_steam_root}/config/config.vdf"
  [[ -f "$_config_vdf" ]] || return 1

  local _line _unsigned
  _line="$(steam_fetch_shortcut_line "$exe_linux_path" "$exe_basename" 2>/dev/null || true)"
  [[ -n "${_line:-}" ]] || return 1
  _unsigned="$(echo "$_line" | cut -f2)"
  [[ -n "${_unsigned:-}" ]] || return 1

  python3 - "$_config_vdf" "$_unsigned" "$expected_tool" <<'PYEOF' 2>/dev/null
import sys
try:
    import vdf
    config_path, app_id, expected = sys.argv[1], sys.argv[2], sys.argv[3]
    with open(config_path) as f:
        data = vdf.load(f)
    compat_map = (data.get("InstallConfigStore", {})
                      .get("Software", {})
                      .get("Valve", {})
                      .get("Steam", {})
                      .get("CompatToolMapping", {}))
    entry = compat_map.get(app_id, {})
    name = entry.get("name", "")
    if not expected or name == expected:
        sys.exit(0)
    sys.exit(1)
except Exception:
    sys.exit(2)
PYEOF
}

# Auto: name + launch options + icon + compat tool (Steam must be closed).
steam_configure_shortcut() {
  local exe_linux_path="$1"
  local exe_basename="${2:-$(basename "$exe_linux_path")}"
  local game_dir="${3:-$(dirname "$exe_linux_path")}"
  local display_name="$4"
  local launch_opts="${5:-}"
  local name_ok=false launch_ok=false icon_ok=false compat_ok=false

  if ! ensure_steam_shortcut_tooling; then
    return 1
  fi

  if ! steam_shortcut_exists "$exe_linux_path" "$exe_basename"; then
    log_warn "$(msg steam.shortcut_not_found)"
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
    local _line _signed _unsigned _legacy _name _exe _run _launch
    _line="$(steam_fetch_shortcut_line "$exe_linux_path" "$exe_basename" || true)"
    if [[ -n "${_line:-}" ]]; then
      IFS=$'\t' read -r _signed _unsigned _legacy _name _exe _run _launch <<< "$_line"
      if ! steam_check_grid_icon "$_unsigned" "$_legacy"; then
        icon_ok=false
        log_warn "$(msg validate.fail_steam_icon)"
      fi
    fi
  fi

  # ── Proton Compat-Tool automatisch setzen ────────────────────────────
  local _ge_tool
  if declare -F ge_proton_latest_name >/dev/null 2>&1; then
    _ge_tool="$(ge_proton_latest_name 2>/dev/null || true)"
  fi
  if [[ -n "${_ge_tool:-}" ]]; then
    if steam_apply_compat_tool "$exe_linux_path" "$exe_basename" "$_ge_tool"; then
      compat_ok=true
    fi
  else
    log_warn "$(msg steam.compat_no_ge_proton)"
  fi

  if [[ "$name_ok" == true || "$launch_ok" == true || "$icon_ok" == true || "$compat_ok" == true ]]; then
    steam_print_setup_summary "$name_ok" "$launch_ok" "$icon_ok" "${compat_ok}" "${_ge_tool:-}"
    if [[ "$icon_ok" != true ]]; then
      steam_offer_icon_tooling_retry || true
      if steam_apply_shortcut_icon "$exe_linux_path" "$exe_basename" "$game_dir"; then
        icon_ok=true
        log_ok "$(msg steam.icon_retry_ok)"
        steam_print_setup_summary "$name_ok" "$launch_ok" "$icon_ok" "${compat_ok}" "${_ge_tool:-}"
      fi
    fi

    # Wenn Compat-Tool nicht automatisch gesetzt – manuelle Anleitung
    if [[ "$compat_ok" != true ]]; then
      echo ""
      cui_check_row false "$(msg steam.compat_chip_fail)" \
        "$(msgf steam.compat_tool_manual "${_ge_tool:-GE-Proton}")"
    else
      echo ""
      cui_check_row true "$(msgf steam.compat_chip_ok "${_ge_tool:-}")" ""
    fi

    log_debug "configure complete name=$name_ok launch=$launch_ok icon=$icon_ok compat=$compat_ok"
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

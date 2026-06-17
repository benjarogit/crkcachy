#!/usr/bin/env bash
# Dynamic game folder paths – per user, no hardcoded locations

set -euo pipefail

# Portabler timeout-Wrapper: nutzt 'timeout' wenn verfügbar, sonst plain find
_crk_find_timed() {
  local secs="$1"; shift
  if command -v timeout >/dev/null 2>&1; then
    timeout "$secs" find "$@" 2>/dev/null || true
  else
    find "$@" 2>/dev/null || true
  fi
}

crkcachy_state_root() {
  echo "${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}"
}

crkcachy_expand_user_path() {
  local path="${1:-}"
  path="${path//\$HOME/$HOME}"
  path="${path/#\~/$HOME}"
  path="${path%/}"
  echo "$path"
}

crkcachy_saved_game_dir_file() {
  local slug="$1"
  echo "$(crkcachy_state_root)/tools/${slug}/last_game_dir"
}

crkcachy_load_saved_game_dir() {
  local slug="$1"
  local file path

  file="$(crkcachy_saved_game_dir_file "$slug")"
  [[ -f "$file" ]] || return 1
  path="$(tr -d '\n' < "$file")"
  [[ -n "$path" ]] || return 1
  path="$(crkcachy_expand_user_path "$path")"
  [[ -d "$path" ]] || return 1
  echo "$path"
}

crkcachy_save_game_dir() {
  local slug="$1"
  local path="$2"
  local dir file

  [[ -n "$slug" && -n "$path" ]] || return 0
  path="$(crkcachy_expand_user_path "$path")"
  dir="$(dirname "$(crkcachy_saved_game_dir_file "$slug")")"
  file="$(crkcachy_saved_game_dir_file "$slug")"
  mkdir -p "$dir"
  printf '%s\n' "$path" > "$file"
}

tool_read_json_scalar() {
  local tool_dir="$1"
  local field="$2"
  python3 - "${tool_dir}/tool.json" "$field" <<'PY'
import json, sys
path, field = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    val = data.get(field, "")
    if val is None:
        val = ""
    print(val if isinstance(val, (str, int, float)) else "")
except (OSError, json.JSONDecodeError):
    pass
PY
}

tool_path_has_game_exe() {
  local game_dir="$1"
  local game_exe="$2"
  [[ -n "$game_dir" && -n "$game_exe" && -f "${game_dir%/}/${game_exe}" ]]
}

tool_discover_mount_roots() {
  local m
  shopt -s nullglob
  for m in \
    "$HOME/Games" "$HOME/Spiele" "$HOME/Downloads" "$HOME/Dokumente" \
    /mnt/* /media/"$USER"/* /run/media/"$USER"/*; do
    [[ -d "$m" ]] || continue
    echo "$m"
  done
  shopt -u nullglob
}

# Shallow search for game_exe under common user folders (maxdepth 6) – first result only.
tool_discover_game_dir_search() {
  local game_exe="$1"
  local root found

  [[ -n "$game_exe" ]] || return 1

  while IFS= read -r root; do
    [[ -n "$root" && -d "$root" ]] || continue
    found="$(_crk_find_timed 5 "$root" -maxdepth 6 -type f -iname "$game_exe" | head -n1)"
    if [[ -n "$found" && -f "$found" ]]; then
      dirname "$found"
      return 0
    fi
  done < <(tool_discover_mount_roots)

  return 1
}

# Search ALL roots and return ALL matching parent dirs as "search|/full/path" lines.
tool_discover_all_game_dirs_search() {
  local game_exe="$1"
  local root found d
  local -A _local_seen=()

  [[ -n "$game_exe" ]] || return 0

  while IFS= read -r root; do
    [[ -n "$root" && -d "$root" ]] || continue
    while IFS= read -r found; do
      [[ -n "$found" && -f "$found" ]] || continue
      d="$(dirname "$found")"
      if [[ -z "${_local_seen[$d]:-}" ]]; then
        echo "search|$d"
        _local_seen["$d"]=1
      fi
    done < <(_crk_find_timed 5 "$root" -maxdepth 6 -type f -iname "$game_exe" | head -n8)
  done < <(tool_discover_mount_roots)
}

# Discover ALL candidate game dirs.  Each line: "SOURCE_TAG|/full/path"
# SOURCE_TAG: saved | steam | hint | search
tool_discover_all_game_dirs() {
  local game_exe="${1:-}"
  local slug="${2:-}"
  local json_hint="${3:-}"
  local -A _seen=()
  local p

  # 1. Saved / last path
  if [[ -n "$slug" ]]; then
    p="$(crkcachy_load_saved_game_dir "$slug" 2>/dev/null || true)"
    if [[ -n "$p" && -d "$p" && -z "${_seen[$p]:-}" ]]; then
      echo "saved|$p"
      _seen["$p"]=1
    fi
  fi

  # 2. Steam non-Steam shortcut
  p="$(tool_discover_game_dir_from_steam "$game_exe" 2>/dev/null || true)"
  if [[ -n "$p" && -d "$p" && -z "${_seen[$p]:-}" ]]; then
    echo "steam|$p"
    _seen["$p"]=1
  fi

  # 3. tool.json hint
  if [[ -n "$json_hint" ]]; then
    p="$(crkcachy_expand_user_path "$json_hint")"
    if [[ -d "$p" && -z "${_seen[$p]:-}" ]]; then
      echo "hint|$p"
      _seen["$p"]=1
    fi
  fi

  # 4. Full filesystem search across all roots
  local tag path
  while IFS='|' read -r tag path; do
    [[ -n "$path" && -z "${_seen[$path]:-}" ]] || continue
    echo "${tag}|${path}"
    _seen["$path"]=1
  done < <(tool_discover_all_game_dirs_search "$game_exe")
}

# Read install path from existing Steam non-Steam shortcuts (any profile).
tool_discover_game_dir_from_steam() {
  local game_exe="$1"
  local config_dir line exe path

  [[ -n "$game_exe" ]] || return 1
  declare -F steam_fetch_shortcut_line_for_config >/dev/null 2>&1 || return 1
  find_steam_root 2>/dev/null || return 1

  while IFS= read -r config_dir; do
    [[ -n "$config_dir" ]] || continue
    line="$(steam_fetch_shortcut_line_for_config "$config_dir" "" "$game_exe" 2>/dev/null || true)"
    [[ -n "$line" ]] || continue
    IFS=$'\t' read -r _ _ _ _ exe _ _ <<< "$line"
    exe="${exe//\"/}"
    path="$(dirname "$exe")"
    path="$(crkcachy_expand_user_path "$path")"
    if tool_path_has_game_exe "$path" "$game_exe"; then
      echo "$path"
      return 0
    fi
  done < <(steam_userdata_all_config_dirs 2>/dev/null || true)

  return 1
}

# Priority: CLI/env → saved → Steam shortcut → tool.json hint → shallow search → empty (user types).
tool_resolve_default_game_dir() {
  local slug="${1:-}"
  local json_hint="${2:-}"
  local game_exe="${3:-}"
  local path source=""

  if [[ -n "${CRKCACHY_GAME_DIR:-}" ]]; then
    path="$(crkcachy_expand_user_path "$CRKCACHY_GAME_DIR")"
    if tool_path_has_game_exe "$path" "$game_exe" || [[ -d "$path" ]]; then
      echo "$path"
      return 0
    fi
  fi

  if [[ -n "$slug" ]]; then
    path="$(crkcachy_load_saved_game_dir "$slug" 2>/dev/null || true)"
    if [[ -n "$path" ]]; then
      echo "$path"
      return 0
    fi
  fi

  path="$(tool_discover_game_dir_from_steam "$game_exe" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then
    echo "$path"
    return 0
  fi

  if [[ -n "$json_hint" ]]; then
    path="$(crkcachy_expand_user_path "$json_hint")"
    if [[ -d "$path" ]]; then
      echo "$path"
      return 0
    fi
  fi

  path="$(tool_discover_game_dir_search "$game_exe" 2>/dev/null || true)"
  if [[ -n "$path" ]]; then
    echo "$path"
    return 0
  fi

  echo ""
  return 0
}

tool_default_dir_source_label() {
  local slug="$1"
  local json_hint="$2"
  local game_exe="$3"
  local resolved

  if [[ -n "${CRKCACHY_GAME_DIR:-}" ]]; then
    msg game_dir.source_cli
    return 0
  fi

  resolved="$(crkcachy_load_saved_game_dir "$slug" 2>/dev/null || true)"
  if [[ -n "$resolved" ]]; then
    msg game_dir.source_saved
    return 0
  fi

  if tool_discover_game_dir_from_steam "$game_exe" >/dev/null 2>&1; then
    msg game_dir.source_steam
    return 0
  fi

  if [[ -n "$json_hint" ]]; then
    resolved="$(crkcachy_expand_user_path "$json_hint")"
    [[ -d "$resolved" ]] && msg game_dir.source_hint && return 0
  fi

  if tool_discover_game_dir_search "$game_exe" >/dev/null 2>&1; then
    msg game_dir.source_search
    return 0
  fi

  msg game_dir.source_manual
}

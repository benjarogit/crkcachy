#!/usr/bin/env bash
# House of Ashes – shared constants and helpers

set -euo pipefail

HA_TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}")" && pwd)"

ha_json_field() {
  local field="$1"
  local lang="${CRKCACHY_LANG:-de}"
  python3 - "${HA_TOOL_DIR}/tool.json" "$field" "$lang" <<'PY'
import json, sys
path, field, lang = sys.argv[1:4]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
except (OSError, json.JSONDecodeError):
    sys.exit(0)
val = data.get(field, "")
if isinstance(val, dict):
    print(val.get(lang, val.get("en", "")))
elif val is not None:
    print(val)
PY
}

ha_resolve_crkcachy_root() {
  local dir

  if [[ -n "${CRKCACHY_ROOT:-}" && -f "${CRKCACHY_ROOT}/lib/common.sh" ]]; then
    echo "$CRKCACHY_ROOT"
    return 0
  fi

  dir="$HA_TOOL_DIR"
  while [[ "$dir" != "/" ]]; do
    if [[ -f "${dir}/install.sh" && -f "${dir}/lib/common.sh" ]]; then
      echo "$dir"
      return 0
    fi
    dir="$(dirname "$dir")"
  done

  local cache="${CRKCACHY_TOOLS_CACHE:-${HOME}/.local/share/crkcachy/repo}"
  if [[ -f "${cache}/lib/common.sh" ]]; then
    echo "$cache"
    return 0
  fi

  return 1
}

HA_CRKCACHY_ROOT="$(ha_resolve_crkcachy_root || true)"
HA_CRKCACHY_ROOT="${HA_CRKCACHY_ROOT:-$(cd "${HA_TOOL_DIR}/../../" && pwd)}"

HA_SLUG="$(ha_json_field slug)"
HA_SLUG="${HA_SLUG:-house-of-ashes}"
HA_GAME_EXE="$(ha_json_field game_exe)"
HA_GAME_EXE="${HA_GAME_EXE:-HouseOfAshes.exe}"
HA_GAME_STEAM_NAME="$(ha_json_field steam_display_name)"
HA_GAME_STEAM_NAME="${HA_GAME_STEAM_NAME:-House of Ashes}"
HA_DEFAULT_GAME_DIR="$(ha_json_field default_game_dir)"
HA_DEFAULT_GAME_DIR="${HA_DEFAULT_GAME_DIR:-}"

ha_prompt_game_dir() {
  tool_prompt_game_dir "$HA_DEFAULT_GAME_DIR" "$HA_SLUG" "$HA_GAME_EXE"
}

ha_read_launch_options() {
  tr -d '\n' < "${HA_TOOL_DIR}/launch-options.txt"
}

ha_load_runtime() {
  export CRKCACHY_ROOT="$HA_CRKCACHY_ROOT"
  # shellcheck source=lib/common.sh
  source "${HA_CRKCACHY_ROOT}/lib/common.sh"
  # shellcheck source=lib/steam.sh
  source "${HA_CRKCACHY_ROOT}/lib/steam.sh"
  # shellcheck source=lib/proton.sh
  source "${HA_CRKCACHY_ROOT}/lib/proton.sh"
}

ha_parse_tool_args() {
  # shellcheck source=lib/i18n.sh
  source "${HA_CRKCACHY_ROOT}/lib/i18n.sh"
  parse_lang_arg "$@"
  parse_cli_arg "$@"
  filter_lang_args "$@"
  filter_cli_args "${FILTERED_ARGS[@]:-$@}"
}

ha_resolve_exe_path() {
  local game_dir="$1"
  if declare -F crkcachy_expand_user_path >/dev/null 2>&1; then
    game_dir="$(crkcachy_expand_user_path "$game_dir")"
  else
    game_dir="${game_dir/#\~/$HOME}"
    game_dir="${game_dir%/}"
  fi
  echo "${game_dir}/${HA_GAME_EXE}"
}


#!/usr/bin/env bash
# House of Ashes – read-only folder validation

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$(cd "${TOOL_DIR}/../../" && pwd)"

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
parse_lang_arg "$@"
# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"

GAME_EXE="HouseOfAshes.exe"
REAL_APPID="1281590"
FAKE_APPID="480"

ha_check_meta() {
  python3 - "${TOOL_DIR}/tool.json" "$1" <<'PY'
import json, sys
path, key = sys.argv[1], sys.argv[2]
try:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    fix = data.get("tested_fix", {})
    if key == "id":
        print(fix.get("id", ""))
    elif key == "archive":
        print(fix.get("archive", ""))
except (OSError, json.JSONDecodeError):
    pass
PY
}

TESTED_FIX_ID="$(ha_check_meta id)"
TESTED_FIX_ID="${TESTED_FIX_ID:-TDPAHOA_Fix_Repair_Steam_Generic}"
TESTED_FIX_ARCHIVE="$(ha_check_meta archive)"
TESTED_FIX_ARCHIVE="${TESTED_FIX_ARCHIVE:-TDPAHOA_Fix_Repair_Steam_Generic.rar}"

WIN64_REL="SMG025/Binaries/Win64"
STEAM_API_REL="Engine/Binaries/ThirdParty/Steamworks/Steamv147/Win64/steam_api64.dll"

REQUIRED_WIN64=(
  OnlineFix64.dll
  OnlineFix.ini
  winmm.dll
  StubDRM64.dll
  dlllist.txt
)

FLT_CONFLICT_FILES=(
  flt.ini
  steamclient64.dll
)

usage() {
  echo "$(msgf ha.check.usage "$0")"
  echo "$(msg ha.check.usage_desc)"
  exit "${1:-0}"
}

check_ini_appids() {
  local ini="$1"
  local has_fake=false
  local has_real=false

  if grep -qE "FakeAppId=${FAKE_APPID}" "$ini"; then
    has_fake=true
  fi
  if grep -qE "RealAppId=${REAL_APPID}" "$ini"; then
    has_real=true
  fi

  if [[ "$has_fake" == "true" && "$has_real" == "true" ]]; then
    log_ok "$(msgf ha.check.ini_ok "$FAKE_APPID" "$REAL_APPID")"
    return 0
  fi

  log_warn "$(msg ha.check.ini_bad)"
  log_hint "$(msgf ha.check.ini_hint "$FAKE_APPID" "$REAL_APPID")"
  return 1
}

run_checks() {
  local game_dir="${1%/}"
  local errors=0
  local fix_ok=true

  if [[ ! -d "$game_dir" ]]; then
    die "$(msgf ha.check.dir_not_found "$game_dir")"
  fi

  log_info "$(msgf ha.check.checking "$game_dir")"
  log_info "$(msgf ha.check.fix_stack "$TESTED_FIX_ID")"
  log_hint "$(msgf ha.check.fix_archive "$TESTED_FIX_ARCHIVE")"
  log_hint "$(msg ha.check.fix_policy)"

  if [[ -f "${game_dir}/${GAME_EXE}" ]]; then
    log_ok "$(msg ha.check.exe_ok)"
  else
    log_error "$(msg ha.check.exe_missing)"
    errors=$((errors + 1))
    fix_ok=false
  fi

  local win64="${game_dir}/${WIN64_REL}"
  if [[ ! -d "$win64" ]]; then
    log_error "$(msgf ha.check.dir_missing "$WIN64_REL")"
    errors=$((errors + 1))
    fix_ok=false
  else
    for f in "${REQUIRED_WIN64[@]}"; do
      if [[ -f "${win64}/${f}" ]]; then
        log_ok "$(msgf ha.check.file_ok "${WIN64_REL}/${f}")"
      else
        log_error "$(msgf ha.check.file_missing "${WIN64_REL}/${f}")"
        errors=$((errors + 1))
        fix_ok=false
      fi
    done

    if [[ -f "${win64}/OnlineFix.ini" ]]; then
      check_ini_appids "${win64}/OnlineFix.ini" || errors=$((errors + 1))
    fi
  fi

  local steam_api="${game_dir}/${STEAM_API_REL}"
  if [[ -f "$steam_api" ]]; then
    log_ok "$(msg ha.check.steam_api_ok)"
  else
    log_warn "$(msgf ha.check.steam_api_missing "$STEAM_API_REL")"
    log_hint "$(msg ha.check.steam_api_hint)"
    errors=$((errors + 1))
    fix_ok=false
  fi

  for f in "${FLT_CONFLICT_FILES[@]}"; do
    if [[ -f "${win64}/${f}" ]]; then
      log_warn "$(msgf ha.check.flt_warn "$WIN64_REL" "$f")"
    fi
  done

  if [[ -f "${game_dir}/steam_appid.txt" ]]; then
    log_warn "$(msg ha.check.appid_warn)"
  fi

  echo ""
  if [[ "$fix_ok" == true && $errors -eq 0 ]]; then
    log_ok "$(msgf ha.check.fix_applied_ok "$TESTED_FIX_ID")"
    log_ok "$(msg ha.check.all_ok)"
    return 0
  fi

  if [[ $errors -eq 0 ]]; then
    return 0
  fi

  log_error "$(msgf ha.check.errors "$errors")"
  log_hint "$(msgf ha.check.fix_apply_hint "$TESTED_FIX_ARCHIVE" "$TESTED_FIX_ID")"
  return 1
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage 0
fi

filter_lang_args "$@"
set -- "${FILTERED_ARGS[@]}"

if [[ $# -lt 1 ]]; then
  usage 1
fi

run_checks "$1"

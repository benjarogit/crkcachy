#!/usr/bin/env bash
# House of Ashes – read-only validation of game folder and online-fix layout

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$(cd "${TOOL_DIR}/../../" && pwd)"

# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"

GAME_EXE="HouseOfAshes.exe"
REAL_APPID="1281590"
FAKE_APPID="480"

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
  echo "Usage: $0 <game_directory>"
  echo "  Validates House of Ashes extract folder (read-only)."
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
    log_ok "OnlineFix.ini: FakeAppId=${FAKE_APPID}, RealAppId=${REAL_APPID}"
    return 0
  fi

  log_warn "OnlineFix.ini missing expected App IDs."
  log_warn "Expected FakeAppId=${FAKE_APPID} and RealAppId=${REAL_APPID}"
  return 1
}

run_checks() {
  local game_dir="${1%/}"
  local errors=0

  if [[ ! -d "$game_dir" ]]; then
    die "Directory not found: $game_dir"
  fi

  log_info "Checking: $game_dir"

  if [[ -f "${game_dir}/${GAME_EXE}" ]]; then
    log_ok "Found ${GAME_EXE}"
  else
    log_error "Missing ${GAME_EXE} in game root"
    errors=$((errors + 1))
  fi

  local win64="${game_dir}/${WIN64_REL}"
  if [[ ! -d "$win64" ]]; then
    log_error "Missing directory: ${WIN64_REL}"
    errors=$((errors + 1))
  else
    for f in "${REQUIRED_WIN64[@]}"; do
      if [[ -f "${win64}/${f}" ]]; then
        log_ok "Found ${WIN64_REL}/${f}"
      else
        log_error "Missing ${WIN64_REL}/${f}"
        errors=$((errors + 1))
      fi
    done

    if [[ -f "${win64}/OnlineFix.ini" ]]; then
      check_ini_appids "${win64}/OnlineFix.ini" || errors=$((errors + 1))
    fi
  fi

  local steam_api="${game_dir}/${STEAM_API_REL}"
  if [[ -f "$steam_api" ]]; then
    log_ok "Found steam_api64.dll (user-applied fix expected here)"
  else
    log_warn "Missing ${STEAM_API_REL} – online-fix usually replaces this file"
    errors=$((errors + 1))
  fi

  for f in "${FLT_CONFLICT_FILES[@]}"; do
    if [[ -f "${win64}/${f}" ]]; then
      log_warn "Found ${WIN64_REL}/${f} – may conflict with Online-Fix (FLT vs Online-Fix)"
    fi
  done

  if [[ -f "${game_dir}/steam_appid.txt" ]]; then
    log_warn "steam_appid.txt present in game root – usually not needed for Steam launch with SteamAppId=480"
  fi

  echo ""
  if [[ $errors -eq 0 ]]; then
    log_ok "All critical checks passed."
    return 0
  else
    log_error "$errors check(s) failed."
    return 1
  fi
}

if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
  usage 0
fi

if [[ $# -lt 1 ]]; then
  usage 1
fi

run_checks "$1"

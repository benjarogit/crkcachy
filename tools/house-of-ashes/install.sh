#!/usr/bin/env bash
# House of Ashes – game folder check + Steam guide

set -euo pipefail

TOOL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$(cd "${TOOL_DIR}/../../" && pwd)"

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
parse_lang_arg "$@"
# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"
# shellcheck source=lib/steam.sh
source "${CRKCACHY_ROOT}/lib/steam.sh"
# shellcheck source=lib/proton.sh
source "${CRKCACHY_ROOT}/lib/proton.sh"

GAME_EXE="HouseOfAshes.exe"
DEFAULT_GAME_DIR="${HOME}/Downloads/extracted/The Dark Pictures Anthology - House of Ashes"

print_steam_checklist() {
  local exe_path="$1"
  local launch_opts
  launch_opts="$(tr -d '\n' < "${TOOL_DIR}/launch-options.txt")"

  echo ""
  echo -e "${_C_BOLD}══════════════════════════════════════════════════════════${_C_RESET}"
  echo -e "${_C_BOLD}$(msg ha.steam_title)${_C_RESET}"
  echo -e "${_C_BOLD}══════════════════════════════════════════════════════════${_C_RESET}"
  echo ""
  echo "$(msg ha.steam_step1)"
  echo "$(msg ha.steam_step1_detail)"
  echo "   ${exe_path}"
  echo ""
  echo "$(msg ha.steam_step2)"
  echo "$(msg ha.steam_step2_detail)"
  echo ""
  echo "$(msg ha.steam_step3)"
  echo ""
  echo -e "${_C_GREEN}${launch_opts}${_C_RESET}"
  echo ""
  echo "$(msg ha.steam_step3_warn)"
  echo ""
  echo "$(msg ha.steam_step4)"
  echo "$(msg ha.steam_step4_detail)"
  echo ""
  echo "$(msg ha.steam_step5)"
  echo ""
  echo -e "${_C_BOLD}══════════════════════════════════════════════════════════${_C_RESET}"
}

main() {
  print_banner

  explain_block "$(msg ha.intro_title)" "$(msg ha.intro_body)"

  log_info "$(msg ha.pc_check)"
  check_steam || true
  check_spacewar || true
  verify_ge_proton || true
  echo ""

  explain_block "$(msg ha.folder_title)" "$(msg ha.folder_body)"

  log_hint "$(msg ha.default_path)"
  log_hint "${DEFAULT_GAME_DIR}"
  read -r -p "$(msg ha.folder_prompt)" game_dir

  if [[ -z "${game_dir:-}" ]]; then
    game_dir="$DEFAULT_GAME_DIR"
    log_info "$(msgf ha.using_path "$game_dir")"
  fi

  game_dir="${game_dir/#\~/$HOME}"
  game_dir="${game_dir%/}"

  if [[ ! -d "$game_dir" ]]; then
    die "$(msgf ha.dir_missing "$game_dir")"
  fi

  echo ""
  log_info "$(msg ha.check_folder)"
  bash "${TOOL_DIR}/checks.sh" "$game_dir" || log_warn "$(msg ha.fix_missing)"
  echo ""

  local exe_path="${game_dir}/${GAME_EXE}"
  print_steam_checklist "$exe_path"

  log_info "$(msg ha.readme_hint)"
  log_ok "$(msg ha.done)"
}

main "$@"

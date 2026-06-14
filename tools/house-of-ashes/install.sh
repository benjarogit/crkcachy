#!/usr/bin/env bash
# House of Ashes – game folder check + Steam setup

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
GAME_STEAM_NAME="House of Ashes"
DEFAULT_GAME_DIR="${HOME}/Downloads/extracted/The Dark Pictures Anthology - House of Ashes"

read_launch_options() {
  tr -d '\n' < "${TOOL_DIR}/launch-options.txt"
}

print_steam_manual_steps() {
  local exe_path="$1"
  local launch_opts="$2"

  ui_step "$(msg ha.steam_manual_title)"
  echo "$(msg ha.steam_step1)"
  echo "$(msg ha.steam_step1_detail)"
  echo "   ${exe_path}"
  echo ""
  echo "$(msg ha.steam_step2)"
  echo "$(msg ha.steam_step2_detail)"
  echo ""
  steam_print_manual_launch_options "$launch_opts"
  echo "$(msg ha.steam_step4)"
  echo "$(msg ha.steam_step4_detail)"
  echo ""
  echo "$(msg ha.steam_step5)"
  echo ""
}

offer_desktop_launcher_if_ready() {
  local exe_path="$1"
  local game_dir="$2"

  if steam_shortcut_exists "$exe_path" "$GAME_EXE"; then
    steam_offer_desktop_launcher \
      "$exe_path" "$GAME_EXE" "$GAME_STEAM_NAME" "$game_dir" "house-of-ashes"
  fi
}

run_steam_auto_or_manual() {
  local exe_path="$1"
  local game_dir="$2"
  local launch_opts="$3"

  cui_section "$(msg ha.steam_auto_title)" "$(msg ha.steam_auto_body)"
  echo ""

  if ! steam_shortcut_exists "$exe_path" "$GAME_EXE"; then
    explain_block "$(msg ha.steam_add_first_title)" "$(msg ha.steam_add_first_body)"
    echo "   ${exe_path}"
    echo ""

    if ! cui_yes_no "$(msg ha.steam_added_confirm)" false; then
      print_steam_manual_steps "$exe_path" "$launch_opts"
      return 0
    fi

    if ! steam_shortcut_exists "$exe_path" "$GAME_EXE"; then
      log_warn "$(msg ha.steam_still_missing)"
      print_steam_manual_steps "$exe_path" "$launch_opts"
      return 0
    fi
  fi

  if cui_yes_no "$(msg ha.steam_auto_confirm)" false; then
    if steam_configure_shortcut \
      "$exe_path" "$GAME_EXE" "$game_dir" "$GAME_STEAM_NAME" "$launch_opts"; then
      log_ok "$(msg ha.steam_auto_done)"
      echo ""
      echo "$(msg ha.steam_step2)"
      echo "$(msg ha.steam_step2_detail)"
      echo ""
      echo "$(msg ha.steam_step4)"
      echo "$(msg ha.steam_step4_detail)"
      offer_desktop_launcher_if_ready "$exe_path" "$game_dir"
      return 0
    fi

    log_warn "$(msg ha.steam_auto_failed)"
    if cui_yes_no "$(msg ha.steam_manual_fallback)" false; then
      print_steam_manual_steps "$exe_path" "$launch_opts"
    fi
    offer_desktop_launcher_if_ready "$exe_path" "$game_dir"
    return 0
  fi

  print_steam_manual_steps "$exe_path" "$launch_opts"
  offer_desktop_launcher_if_ready "$exe_path" "$game_dir"
}

main() {
  ensure_crkcachy_runtime

  ui_step "$(msg ha.intro_title)"
  explain_block "$(msg ha.intro_title)" "$(msg ha.intro_body)"

  ui_action "$(msg ha.pc_check)"
  check_steam || true
  check_spacewar || true
  verify_ge_proton || true
  echo ""

  ui_step "$(msg ha.folder_title)"
  explain_block "$(msg ha.folder_title)" "$(msg ha.folder_body)"

  log_hint "$(msg ha.default_path)"
  log_hint "${DEFAULT_GAME_DIR}"
  game_dir="$(tui_input "$(msg ha.folder_prompt)" "$DEFAULT_GAME_DIR")"

  if [[ -z "${game_dir:-}" ]]; then
    game_dir="$DEFAULT_GAME_DIR"
  fi
  ui_action "$(msgf ha.using_path "$game_dir")"

  game_dir="${game_dir/#\~/$HOME}"
  game_dir="${game_dir%/}"

  if [[ ! -d "$game_dir" ]]; then
    die "$(msgf ha.dir_missing "$game_dir")"
  fi

  ui_step "$(msg ha.check_folder)"
  ui_running "$(msg ha.check_folder)"
  bash "${TOOL_DIR}/checks.sh" "$game_dir" || log_warn "$(msg ha.fix_missing)"
  ui_done "$(msg ha.check_folder)"
  echo ""

  local exe_path="${game_dir}/${GAME_EXE}"
  local launch_opts
  launch_opts="$(read_launch_options)"

  run_steam_auto_or_manual "$exe_path" "$game_dir" "$launch_opts"

  echo ""
  log_ok "$(msg ha.done)"
  echo ""
  cui_offer_markdown "tools/house-of-ashes/README.md" "$(msg ha.show_readme)" || true
  ui_wait_enter
}

main "$@"

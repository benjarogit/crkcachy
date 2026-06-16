#!/usr/bin/env bash
# Shared game-tool actions – install, uninstall, check, reset

set -euo pipefail

tool_action_normalize() {
  case "${1:-}" in
    validate|validate-only) echo "check" ;;
    install|uninstall|check|reset) echo "$1" ;;
    *) echo "$1" ;;
  esac
}

tool_action_from_flag() {
  if [[ "${CRKCACHY_UNINSTALL:-0}" == 1 ]]; then
    echo "uninstall"
    return 0
  fi
  if [[ "${CRKCACHY_RESET:-0}" == 1 ]]; then
    echo "reset"
    return 0
  fi
  if [[ "${CRKCACHY_VALIDATE_ONLY:-0}" == 1 ]]; then
    echo "check"
    return 0
  fi
  if [[ "${CRKCACHY_CHECK_ONLY:-0}" == 1 ]]; then
    echo "check"
    return 0
  fi
  if [[ "${CRKCACHY_INSTALL:-0}" == 1 ]]; then
    echo "install"
    return 0
  fi
  if [[ -n "${CRKCACHY_ACTION:-}" ]]; then
    tool_action_normalize "$CRKCACHY_ACTION"
    return 0
  fi
  echo ""
}

tool_action_pick_menu() {
  local tool_name="$1"
  local selected

  echo ""
  cui_section "$(msg action.menu_title)" "$(msgf action.menu_teaser "$tool_name")"
  echo ""

  selected="$(cui_choose "$(msg action.menu_hint)" 0 \
    "$(msg action.opt_install)" \
    "$(msg action.opt_uninstall)" \
    "$(msg action.opt_check)" \
    "$(msg action.opt_reset)" \
    "$(msg action.opt_back)")"

  case "$selected" in
    "$(msg action.opt_install)") echo "install" ;;
    "$(msg action.opt_uninstall)") echo "uninstall" ;;
    "$(msg action.opt_check)") echo "check" ;;
    "$(msg action.opt_reset)") echo "reset" ;;
    *) echo "back" ;;
  esac
}

tool_action_label() {
  case "${1:-}" in
    install) msg action.name_install ;;
    uninstall) msg action.name_uninstall ;;
    check) msg action.name_check ;;
    reset) msg action.name_reset ;;
    *) echo "$1" ;;
  esac
}

tool_prompt_game_dir() {
  local json_hint="${1:-}"
  local slug="${2:-}"
  local game_exe="${3:-}"
  local prompt="${4:-$(msg ha.folder_prompt)}"
  local game_dir default_dir source_label

  default_dir="$(tool_resolve_default_game_dir "$slug" "$json_hint" "$game_exe")"

  if [[ -n "${CRKCACHY_GAME_DIR:-}" ]]; then
    game_dir="$(crkcachy_expand_user_path "$CRKCACHY_GAME_DIR")"
    echo "$game_dir"
    return 0
  fi

  if [[ -z "$default_dir" ]]; then
    default_dir="$HOME"
  fi

  default_dir="$(crkcachy_expand_user_path "$default_dir")"

  source_label="$(tool_default_dir_source_label "$slug" "$json_hint" "$game_exe")"
  {
    log_hint "$(msg game_dir.prompt_intro)"
    log_hint "$(msgf game_dir.source "$source_label")"
    log_hint "$(msg ha.default_path)"
    log_hint "${default_dir}"
    if [[ -n "$game_exe" ]]; then
      log_hint "$(msgf game_dir.exe_expected "$game_exe")"
    fi
  } >&2

  game_dir="$(tui_input "$prompt" "$default_dir")"
  [[ -z "${game_dir:-}" ]] && game_dir="$default_dir"
  game_dir="$(crkcachy_expand_user_path "$game_dir")"

  if [[ -n "$slug" ]]; then
    crkcachy_save_game_dir "$slug" "$game_dir"
  fi

  echo "$game_dir"
}

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

# Result variable – avoids stdout capture bugs when called from subshells
TOOL_ACTION_PICKED=""

tool_action_pick_menu() {
  TOOL_ACTION_PICKED=""
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
    "$(msg action.opt_install)") TOOL_ACTION_PICKED="install" ;;
    "$(msg action.opt_uninstall)") TOOL_ACTION_PICKED="uninstall" ;;
    "$(msg action.opt_check)") TOOL_ACTION_PICKED="check" ;;
    "$(msg action.opt_reset)") TOOL_ACTION_PICKED="reset" ;;
    *) TOOL_ACTION_PICKED="back" ;;
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

# Global result – avoids stdout-capture bugs (do NOT call tool_prompt_game_dir in $(...))
TOOL_GAME_DIR=""

# Shorten a path for display (replace $HOME with ~, trim trailing slash)
_tool_short_path() {
  local p="${1%/}"
  local h="${HOME%/}"
  echo "${p/#$h/~}"
}

# Source label for a single discovered entry
_tool_game_dir_source_label() {
  local src="$1"
  local path="$2"
  case "$src" in
    saved)  msg game_dir.label_saved ;;
    steam)  msg game_dir.label_steam ;;
    hint)   msg game_dir.label_hint  ;;
    search)
      if [[ "$path" == /mnt/* || "$path" == /media/* || "$path" == /run/media/* ]]; then
        local mnt_root
        mnt_root="/$(echo "$path" | cut -d'/' -f2-3)"
        msgf game_dir.label_search_mnt "$mnt_root"
      elif [[ "$path" == "$HOME/Downloads"* || "$path" == "$HOME/downloads"* ]]; then
        msg game_dir.label_search_downloads
      elif [[ "$path" == "$HOME/Games"* || "$path" == "$HOME/Spiele"* ]]; then
        msg game_dir.label_search_games
      else
        msg game_dir.label_search
      fi
      ;;
    *) echo "$src" ;;
  esac
}

# Interactive game-folder picker.
# Result is stored in TOOL_GAME_DIR (global) – do NOT call in $(...).
tool_prompt_game_dir() {
  local json_hint="${1:-}"
  local slug="${2:-}"
  local game_exe="${3:-}"

  TOOL_GAME_DIR=""

  # CLI override: skip picker entirely
  if [[ -n "${CRKCACHY_GAME_DIR:-}" ]]; then
    TOOL_GAME_DIR="$(crkcachy_expand_user_path "$CRKCACHY_GAME_DIR")"
    return 0
  fi

  echo ""
  cui_section "$(msg game_dir.picker_title)" \
    "$(if [[ -n "$game_exe" ]]; then msgf game_dir.picker_subtitle "$game_exe"; fi)"
  echo ""
  log_info "$(msg game_dir.searching)"
  echo ""

  # ── Discover all candidate paths ───────────────────────────────────
  local -a _tags=() _paths=() _has_exe=()
  local _tag _path

  while IFS='|' read -r _tag _path; do
    [[ -n "$_path" ]] || continue
    _tags+=("$_tag")
    _paths+=("$_path")
    if tool_path_has_game_exe "$_path" "$game_exe"; then
      _has_exe+=("true")
    else
      _has_exe+=("false")
    fi
  done < <(tool_discover_all_game_dirs "$game_exe" "$slug" "$json_hint")

  # ── Show discovered paths ──────────────────────────────────────────
  if [[ ${#_paths[@]} -gt 0 ]]; then
    cui_sub "$(msg game_dir.found_title)"
    local i
    for i in "${!_paths[@]}"; do
      local _src_lbl _short
      _src_lbl="$(_tool_game_dir_source_label "${_tags[$i]}" "${_paths[$i]}")"
      _short="$(_tool_short_path "${_paths[$i]}")"
      if [[ "${_has_exe[$i]}" == "true" ]]; then
        cui_check_row true  "$_short" "$_src_lbl"
      else
        cui_check_row false "$_short" "$(msgf game_dir.no_exe "$game_exe") · $_src_lbl"
      fi
    done
    echo ""
  else
    log_warn "$(msg game_dir.none_found)"
    echo ""
  fi

  # ── Build picker options ────────────────────────────────────────────
  local -a lines=()
  local i _manual_opt
  _manual_opt="$(msg game_dir.opt_manual)"
  for i in "${!_paths[@]}"; do
    local _src_lbl _short
    _src_lbl="$(_tool_game_dir_source_label "${_tags[$i]}" "${_paths[$i]}")"
    _short="$(_tool_short_path "${_paths[$i]}")"
    lines+=("${_paths[$i]}|${_short}   [${_src_lbl}]")
  done
  lines+=("manual|${_manual_opt}")

  local _selected
  _selected="$(crk_select "$(msg game_dir.picker_prompt)" "" "${lines[@]}")"

  local _chosen_path=""

  if [[ -z "$_selected" || "$_selected" == "manual" ]]; then
    _tool_prompt_game_dir_manual "$game_exe"
    _chosen_path="$TOOL_GAME_DIR"
    TOOL_GAME_DIR=""
  else
    _chosen_path="$_selected"
  fi

  _chosen_path="$(crkcachy_expand_user_path "${_chosen_path:-$HOME}")"

  # ── Copy offer: exe not in chosen path but found elsewhere ─────────
  if [[ -n "$game_exe" ]] && ! tool_path_has_game_exe "$_chosen_path" "$game_exe"; then
    local _copy_src=""
    for i in "${!_paths[@]}"; do
      if [[ "${_has_exe[$i]}" == "true" ]]; then
        _copy_src="${_paths[$i]}"
        break
      fi
    done
    if [[ -n "$_copy_src" ]]; then
      _tool_offer_copy_game "$_copy_src" "$_chosen_path" "$game_exe"
      # _tool_offer_copy_game may update _chosen_path via TOOL_GAME_DIR
      [[ -n "$TOOL_GAME_DIR" ]] && _chosen_path="$TOOL_GAME_DIR"
      TOOL_GAME_DIR=""
    fi
  fi

  # ── Save & expose result ──────────────────────────────────────────
  if [[ -n "$slug" && -n "$_chosen_path" ]]; then
    crkcachy_save_game_dir "$slug" "$_chosen_path"
  fi

  echo ""
  log_ok "$(msgf game_dir.using "$_chosen_path")"
  TOOL_GAME_DIR="$_chosen_path"
}

# Called directly (not in $()) – outputs UI to terminal, stores result in TOOL_GAME_DIR.
_tool_prompt_game_dir_manual() {
  local game_exe="${1:-}"

  TOOL_GAME_DIR=""
  echo ""
  cui_sub "$(msg game_dir.manual_title)"
  if [[ -n "$game_exe" ]]; then
    log_hint "$(msgf game_dir.manual_hint "$game_exe")"
  fi
  log_hint "$(msg game_dir.manual_tip)"
  echo ""

  local _path
  _path="$(tui_input "$(msg game_dir.manual_prompt)" "")" 2>/dev/null || true
  [[ -z "$_path" ]] && _path="$HOME"
  _path="$(crkcachy_expand_user_path "$_path")"
  TOOL_GAME_DIR="$_path"
}

# Offer to copy game files from src to dst.  Updates TOOL_GAME_DIR when copied.
_tool_offer_copy_game() {
  local src="$1"
  local dst="$2"
  local game_exe="${3:-}"

  echo ""
  cui_section "$(msg game_dir.copy_title)" "$(msg game_dir.copy_subtitle)"
  echo ""
  log_warn "$(msgf game_dir.no_exe_in_chosen "$game_exe")"
  echo ""
  cui_info_box "$(msgf game_dir.copy_from "$src")$(printf '\n')$(msgf game_dir.copy_to "$dst")"
  echo ""

  local _choice
  _choice="$(crk_select "$(msg game_dir.copy_prompt)" "" \
    "yes|$(msg game_dir.copy_opt_yes)" \
    "manual|$(msg game_dir.copy_opt_manual)" \
    "no|$(msg game_dir.copy_opt_no)")"

  case "${_choice:-}" in
    yes)
      _tool_do_copy_game "$src" "$dst" "$game_exe"
      ;;
    manual)
      _tool_prompt_game_dir_manual "$game_exe"
      ;;
    *)
      log_hint "$(msg game_dir.copy_skipped)"
      TOOL_GAME_DIR=""
      ;;
  esac
}

# Perform the actual file copy (rsync preferred, cp fallback) with spinner + verify.
_tool_do_copy_game() {
  local src="$1"
  local dst="$2"
  local game_exe="${3:-}"

  echo ""
  mkdir -p "$dst"

  if command -v rsync >/dev/null 2>&1; then
    cui_spin "$(msgf game_dir.copy_running "$dst") …" \
      rsync -a --no-inc-recursive "${src%/}/" "${dst%/}/" 2>/dev/null \
    || { log_error "$(msg game_dir.copy_failed)"; TOOL_GAME_DIR=""; return 1; }
  else
    cui_spin "$(msgf game_dir.copy_running "$dst") …" \
      cp -r "${src%/}/." "${dst%/}/" 2>/dev/null \
    || { log_error "$(msg game_dir.copy_failed)"; TOOL_GAME_DIR=""; return 1; }
  fi

  echo ""
  if [[ -n "$game_exe" ]] && tool_path_has_game_exe "$dst" "$game_exe"; then
    cui_status_chip true  "$(msg game_dir.copy_ok)"
    TOOL_GAME_DIR="$dst"
  else
    cui_status_chip false "$(msg game_dir.copy_failed)"
    if [[ -n "$game_exe" ]]; then
      log_hint "$(msgf game_dir.copy_no_exe "$game_exe")"
    fi
    TOOL_GAME_DIR="$dst"
  fi
}

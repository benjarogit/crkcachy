#!/usr/bin/env bash
# Visual step helpers for interactive installer UX

set -euo pipefail

ui_divider() {
  echo -e "${_C_DIM}────────────────────────────────────────────────────────${_C_RESET}"
}

ui_step() {
  echo ""
  ui_divider
  echo -e "${_C_BOLD}${_C_CYAN}  $*${_C_RESET}"
  ui_divider
  echo ""
}

ui_action() {
  log_info "▸ $*"
}

ui_running() {
  log_info "▸ $(msgf ui.running "$1")"
}

ui_done() {
  log_ok "$(msgf ui.done "$1")"
}

ui_wait_enter() {
  echo ""
  cui_continue
  echo ""
}

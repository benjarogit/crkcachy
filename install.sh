#!/usr/bin/env bash
# CRKCACHY master installer – TypeScript wizard + CLI tool paths

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CRKCACHY_ROOT="$SCRIPT_DIR"

# shellcheck source=lib/i18n.sh
source "${CRKCACHY_ROOT}/lib/i18n.sh"
parse_lang_arg "$@"
parse_cli_arg "$@"
filter_lang_args "$@"
filter_cli_args "${FILTERED_ARGS[@]:-$@}"

# shellcheck source=lib/common.sh
source "${CRKCACHY_ROOT}/lib/common.sh"
# shellcheck source=lib/tools.sh
source "${CRKCACHY_ROOT}/lib/tools.sh"
# shellcheck source=lib/cachyos.sh
source "${CRKCACHY_ROOT}/lib/cachyos.sh"
# shellcheck source=lib/steam.sh
source "${CRKCACHY_ROOT}/lib/steam.sh"
# shellcheck source=lib/proton.sh
source "${CRKCACHY_ROOT}/lib/proton.sh"
# shellcheck source=lib/assess.sh
source "${CRKCACHY_ROOT}/lib/assess.sh"
# shellcheck source=lib/preflight.sh
source "${CRKCACHY_ROOT}/lib/preflight.sh"
# shellcheck source=lib/install_log.sh
source "${CRKCACHY_ROOT}/lib/install_log.sh"

ASSESS_LOGICAL_BASE=(
  vkd3d
  gamemode
  gvfs
  winetricks
)

ASSESS_LOGICAL_VULKAN=(
  vulkan-loader
)

ASSESS_STEAM_LOGICAL=steam

print_status() {
  ensure_crkcachy_runtime
  print_banner
  preflight_status_only
  echo ""
  assess_run
  tui_assess_panel || true
  echo ""

  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    log_ok "$(msg status.ready_next)"
  fi

  ui_divider
  log_hint "$(msg assess.status_hint)"
}

has_flag() {
  local flag="$1"
  shift
  local arg
  for arg in "$@"; do
    [[ "$arg" == "$flag" ]] && return 0
  done
  return 1
}

main() {
  if has_flag --status "$@" || has_flag -s "$@"; then
    print_status
    exit 0
  fi

  local action
  action="$(tool_action_from_flag)"

  if [[ -n "$action" ]] || [[ -n "${CRKCACHY_TOOL:-}" ]]; then
    ensure_crkcachy_runtime
    print_banner
    tool_hub_run "$action"
    exit $?
  fi

  if has_flag --tools "$@"; then
    ensure_crkcachy_runtime
    print_banner
    preflight_onboard
    tool_hub_interactive
    exit $?
  fi

  # Interactive wizard – OpenClaw-style Node/TypeScript (@clack/prompts)
  local wizard_js="${CRKCACHY_ROOT}/lib/prompter/dist/wizard.js"

  if ! command -v node >/dev/null 2>&1; then
    ensure_node
  fi

  if [[ ! -f "$wizard_js" ]]; then
    die "$(msg node.prompter_missing)"
  fi

  local -a wiz_args=(--root "$CRKCACHY_ROOT")
  if [[ -n "${CRKCACHY_LANG:-}" ]]; then
    wiz_args+=(--lang "$CRKCACHY_LANG")
  fi

  node "$wizard_js" "${wiz_args[@]}"
  exit $?
}

main "${FILTERED_CLI_ARGS[@]:-${FILTERED_ARGS[@]}}"

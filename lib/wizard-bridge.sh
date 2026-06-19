#!/usr/bin/env bash
# JSON bridge for lib/prompter wizard.ts – no Clack UI here, only data + actions.

set -euo pipefail

BRIDGE_ROOT="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export CRKCACHY_ROOT="$BRIDGE_ROOT"

# shellcheck source=lib/i18n.sh
source "${BRIDGE_ROOT}/lib/i18n.sh"
init_i18n

# shellcheck source=lib/common.sh
source "${BRIDGE_ROOT}/lib/common.sh"
# shellcheck source=lib/tools.sh
source "${BRIDGE_ROOT}/lib/tools.sh"
# shellcheck source=lib/cachyos.sh
source "${BRIDGE_ROOT}/lib/cachyos.sh"
# shellcheck source=lib/steam.sh
source "${BRIDGE_ROOT}/lib/steam.sh"
# shellcheck source=lib/proton.sh
source "${BRIDGE_ROOT}/lib/proton.sh"
# shellcheck source=lib/assess.sh
source "${BRIDGE_ROOT}/lib/assess.sh"
# shellcheck source=lib/preflight.sh
source "${BRIDGE_ROOT}/lib/preflight.sh"
# shellcheck source=lib/install_log.sh
source "${BRIDGE_ROOT}/lib/install_log.sh"
# shellcheck source=lib/tool_hub.sh
source "${BRIDGE_ROOT}/lib/tool_hub.sh"

ASSESS_LOGICAL_BASE=(vkd3d gamemode gvfs winetricks)
ASSESS_LOGICAL_VULKAN=(vulkan-loader)
ASSESS_STEAM_LOGICAL=steam

_wizard_msg_keys() {
  cat <<'KEYS'
wizard.intro
wizard.choose_hint
wizard.title
wizard.hint_ready
wizard.hint_fix
wizard.hint_full
wizard.opt1
wizard.opt2
wizard.opt3
wizard.opt4
wizard.opt5
wizard.after_uninstall_title
wizard.after_uninstall_menu
wizard.after_uninstall_install
wizard.after_uninstall_exit
install.after_title
install.after_menu
install.after_exit
install.goodbye
install.cancelled
assess.after_pc_title
assess.after_pc_install
assess.after_pc_menu
assess.after_pc_exit
assess.after_pc_hint
runtime.bootstrap_title
runtime.bootstrap_body
runtime.bootstrap_hint
runtime.deps_cleanup
runtime.deps_cleanup_short
runtime.fix_recommended
runtime.cannot_continue
runtime.legal_abort
glow.missing_title
glow.pick_title
glow.opt_auto
glow.opt_manual
glow.password_hint
glow.manual_steps_intro
glow.manual_wait
glow.installed
glow.still_missing
glow.install_failed
pkg.explain.footer
ui.badge_recommended
banner.subtitle
banner.version_ok
banner.update_available
ui.ok_label
legal.step1_title
legal.step1_body
legal.step2_title
legal.step2_body
legal.step3_title
legal.step3_body
legal.step4_title
legal.step4_body
install.legal_summary
ui.legal_confirm
tools.hub_pick_hint
tools.hub_search_hint
tools.hub_refresh
tools.hub_uninstall_pick_title
tools.none
action.opt_back
action.menu_title
action.menu_hint
action.menu_teaser
action.opt_install
action.opt_uninstall
action.opt_check
action.opt_reset
wizard.checks_body
assess.all_ready
assess.not_ready
assess.title
assess.next_title
assess.next_ready_body
assess.next_fix_body
assess.next_full_body
assess.status_hint
assess.block_game
assess.fix_now
flow.chose_enter
flow.chose_1
flow.chose_2
flow.chose_3
uninstall.title
node.no_tty
KEYS
}

_wizard_emit_json() {
  python3 - "$@" <<'PY'
import json, sys

def emit(obj):
    json.dump(obj, sys.stdout, ensure_ascii=False)
    sys.stdout.write("\n")

if len(sys.argv) > 1 and sys.argv[1] == "--raw":
    emit(json.loads(sys.argv[2]))
else:
    emit(json.loads(sys.stdin.read()))
PY
}

_wizard_msgs_json() {
  local keys=()
  while IFS= read -r line; do
    [[ -n "$line" ]] && keys+=("$line")
  done < <(_wizard_msg_keys)

  python3 - "${keys[@]}" <<'PY'
import json, os, sys

keys = sys.argv[1:]
msgs = {}
for key in keys:
    val = os.environ.get(f"MSG_{key.replace('.', '_')}", "")
    msgs[key] = val
json.dump(msgs, sys.stdout, ensure_ascii=False)
PY
}

_wizard_export_msgs_env() {
  local key env_key
  while IFS= read -r key; do
    [[ -n "$key" ]] || continue
    env_key="MSG_${key//./_}"
    export "$env_key"="$(msg "$key")"
  done < <(_wizard_msg_keys)
}

_wizard_deps_marker() {
  echo "${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/.deps_hint_v${CRKCACHY_VERSION}"
}

_wizard_runtime_json() {
  local node_ok=false glow_ok=false node_ver="" marker
  if command -v node >/dev/null 2>&1; then
    node_ver="$(node --version 2>/dev/null | sed 's/^v//' || echo "")"
    local major
    major="$(node -p "process.versions.node.split('.').map(Number)[0]" 2>/dev/null || echo 0)"
    [[ "${major:-0}" -ge 18 ]] && node_ok=true
  fi
  command_exists glow && glow_ok=true
  marker="$(_wizard_deps_marker)"
  python3 -c 'import json,sys; json.dump({"nodeOk":sys.argv[1]=="true","glowOk":sys.argv[2]=="true","nodeVersion":sys.argv[3],"depsHintShown":sys.argv[4]=="true","version":sys.argv[5]},sys.stdout)' \
    "$node_ok" "$glow_ok" "$node_ver" "$([[ -f "$marker" ]] && echo true || echo false)" "$CRKCACHY_VERSION"
}

_wizard_assess_issues_json() {
  local labels=()
  local issue
  for issue in "${ASSESS_ISSUES[@]:-}"; do
    labels+=("$(assess_issue_label "$issue")")
  done
  python3 - "${labels[@]}" <<'PY'
import json, sys
print(json.dumps(sys.argv[1:]))
PY
}

wizard_bridge_context() {
  assess_run
  _wizard_export_msgs_env

  local hint score issues_json msgs_json runtime_json
  hint="$(assess_recommended_hint)"
  score="$(msgf assess.score "$ASSESS_OK" "$ASSESS_FAIL")"
  issues_json="$(_wizard_assess_issues_json)"
  msgs_json="$(_wizard_msgs_json)"
  runtime_json="$(_wizard_runtime_json)"

  python3 - "$hint" "$score" "$issues_json" "$msgs_json" "$runtime_json" \
    "$ASSESS_SYSTEM_READY" "$ASSESS_RECOMMENDED" "$ASSESS_OK" "$ASSESS_FAIL" <<'PY'
import json, sys

hint, score, issues_json, msgs_json, runtime_json, sys_ready, rec, ok, fail = sys.argv[1:10]
issues = json.loads(issues_json)
msgs = json.loads(msgs_json)
runtime = json.loads(runtime_json)

ctx = {
    "messages": msgs,
    "runtime": runtime,
    "assess": {
        "systemReady": sys_ready == "true",
        "recommended": int(rec),
        "ok": int(ok),
        "fail": int(fail),
        "hint": hint,
        "score": score,
        "issues": issues,
    },
}
json.dump(ctx, sys.stdout, ensure_ascii=False)
PY
}

wizard_bridge_mark_deps_hint() {
  mkdir -p "$(dirname "$(_wizard_deps_marker)")"
  touch "$(_wizard_deps_marker)"
}

wizard_bridge_install_glow() {
  local mode="${1:-auto}"
  case "$mode" in
    auto)
      log_hint "$(msg glow.password_hint)"
      if _ensure_logical_repo_package glow; then
        hash -r 2>/dev/null || true
      else
        log_warn "$(msg glow.install_failed)"
        return 1
      fi
      command_exists glow
      ;;
    manual)
      log_hint "$(msg glow.manual_steps_intro)"
      log_hint "$(platform_manual_install_cmd_logical glow)"
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

wizard_bridge_preflight_state() {
  preflight_run
  _preflight_count_silent
  python3 -c 'import json,sys; json.dump({"requiredFail":int(sys.argv[1]),"recommendedFail":int(sys.argv[2]),"skipLegal":sys.argv[3]=="true"},sys.stdout)' \
    "${PREFLIGHT_REQUIRED_FAIL:-0}" "${PREFLIGHT_RECOMMENDED_FAIL:-0}" \
    "$(cui_onboard_should_skip && echo true || echo false)"
}

wizard_bridge_preflight_fix_recommended() {
  preflight_fix_recommended || true
}

wizard_bridge_legal_accept() {
  cui_onboard_mark_done
}

wizard_bridge_run_pc_fix() {
  ui_step "$(msg install.step2)"
  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    log_ok "$(msg assess.pc_already_ok)"
    print_overlay_hint
    return 0
  fi
  assess_guided_fix || true
  print_overlay_hint
}

wizard_bridge_assess_ensure_ready() {
  assess_ensure_ready
}

wizard_bridge_tools_list() {
  tool_fetch_update_catalog 2>/dev/null || true
  if ! discover_tools; then
    echo '[]'
    return 0
  fi

  local -a json_parts=()
  local i slug source name status label
  json_parts+=('[')
  for i in "${!TOOL_SLUGS[@]}"; do
    slug="${TOOL_SLUGS[$i]}"
    source="${TOOL_SOURCES[$i]}"
    name="$(get_tool_name "$slug")"
    status="$(tool_catalog_status_label "$source")"
    label="${name}  [${status}]"
    json_parts+=("$(python3 -c 'import json,sys; print(json.dumps({"slug":sys.argv[1],"label":sys.argv[2],"name":sys.argv[3]}))' "$slug" "$label" "$name")")
    json_parts+=(',')
  done
  if [[ ${#json_parts[@]} -gt 1 ]]; then
    unset 'json_parts[-1]'
  fi
  json_parts+=(']')
  printf '%s' "${json_parts[@]}"
  printf '\n'
}

wizard_bridge_tools_refresh() {
  tool_fetch_update_catalog 2>/dev/null || true
  if tool_fetch_ensure_repo 2>/dev/null; then
    log_ok "$(msg tools.catalog_updated)"
  fi
  discover_tools || true
}

wizard_bridge_tool_dispatch() {
  local slug="${1:-}" action="${2:-}"
  [[ -n "$slug" && -n "$action" ]] || return 1
  tool_hub_dispatch "$slug" "$action"
}

wizard_bridge_print_status() {
  print_overlay_hint 2>/dev/null || true
  assess_run
  assess_print_report || true
  print_wizard_options
  assess_print_next_step
  echo ""
  log_hint "$(msg assess.status_hint)"
}

wizard_bridge_announce_choice() {
  local choice="${1:-}"
  if [[ -z "$choice" ]]; then
    ui_action "$(msg flow.chose_enter)"
    case "$ASSESS_RECOMMENDED" in
      3) ui_action "$(msg flow.chose_3)" ;;
      2) ui_action "$(msg flow.chose_2)" ;;
      *) ui_action "$(msg flow.chose_1)" ;;
    esac
    return
  fi
  ui_action "$(msgf flow.chose "$choice")"
  case "$choice" in
    1) ui_action "$(msg flow.chose_1)" ;;
    2) ui_action "$(msg flow.chose_2)" ;;
    3) ui_action "$(msg flow.chose_3)" ;;
    5) ui_action "$(msg uninstall.title)" ;;
  esac
}

cmd="${1:-}"
shift || true

case "$cmd" in
  context)
    wizard_bridge_context
    ;;
  mark-deps-hint)
    wizard_bridge_mark_deps_hint
    ;;
  runtime)
    _wizard_runtime_json
    ;;
  install-glow)
    wizard_bridge_install_glow "${1:-auto}"
    ;;
  preflight-state)
    wizard_bridge_preflight_state
    ;;
  preflight-fix-recommended)
    wizard_bridge_preflight_fix_recommended
    ;;
  legal-accept)
    wizard_bridge_legal_accept
    ;;
  run-pc-fix)
    assess_run
    wizard_bridge_run_pc_fix
    ;;
  assess-ensure-ready)
    wizard_bridge_assess_ensure_ready
    ;;
  tools-list)
    wizard_bridge_tools_list
    ;;
  tools-refresh)
    wizard_bridge_tools_refresh
    ;;
  tool-dispatch)
    wizard_bridge_tool_dispatch "${1:-}" "${2:-}"
    ;;
  print-status)
    wizard_bridge_print_status
    ;;
  announce-choice)
    wizard_bridge_announce_choice "${1:-}"
    ;;
  *)
    echo "unknown bridge command: ${cmd:-}" >&2
    exit 2
    ;;
esac

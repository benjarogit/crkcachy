#!/usr/bin/env bash
# Master tool hub – pick game tool + action, dispatch to tools/*/install.sh

set -euo pipefail

tool_action_to_flag() {
  case "${1:-}" in
    install) echo "--install" ;;
    uninstall) echo "--uninstall" ;;
    check) echo "--check" ;;
    reset) echo "--reset" ;;
    *) echo "--action=${1}" ;;
  esac
}

# Result variable – avoids stdout capture bugs when called from subshells
TOOL_HUB_PICKED_SLUG=""

tool_hub_pick_tool_slug() {
  TOOL_HUB_PICKED_SLUG=""
  local slug="" selected labels=() slugs=() i desc name status source

  tool_fetch_update_catalog 2>/dev/null || true

  if ! discover_tools; then
    die "$(msg tools.none)"
  fi

  echo ""
  cui_section "$(msg tools.hub_pick_title)" "$(msg tools.hub_pick_body)"
  echo ""

  for i in "${!TOOL_SLUGS[@]}"; do
    slug="${TOOL_SLUGS[$i]}"
    source="${TOOL_SOURCES[$i]}"
    name="$(get_tool_name "$slug")"
    desc="$(get_tool_desc "$slug")"
    status="$(tool_catalog_status_label "$source")"
    if [[ -n "$desc" ]]; then
      labels+=("$((i + 1))) $name – $desc · $status")
    else
      labels+=("$((i + 1))) $name · $status")
    fi
    slugs+=("$slug")
  done

  labels+=("$(msg tools.hub_refresh)")
  slugs+=("__refresh__")
  labels+=("$(msg action.opt_back)")
  slugs+=("")

  selected="$(cui_choose_searchable "$(msg tools.hub_pick_hint)" "$(msg tools.hub_search_hint)" "${labels[@]}")" || true

  for i in "${!labels[@]}"; do
    if [[ "${labels[$i]}" == "$selected" ]]; then
      TOOL_HUB_PICKED_SLUG="${slugs[$i]}"
      return 0
    fi
  done

  TOOL_HUB_PICKED_SLUG=""
}

tool_hub_dispatch() {
  local slug="$1"
  local action="$2"
  local tool_install flag extra=()

  action="$(tool_action_normalize "$action")"

  if ! tool_ensure_ready "$slug"; then
    return 1
  fi

  tool_install="$(tool_resolve_install_path "$slug")" || die "$(msgf tools.hub_missing "$slug")"

  flag="$(tool_action_to_flag "$action")"
  extra=("$flag")

  if [[ "${CRKCACHY_DEBUG:-0}" == 1 ]]; then
    extra+=(--debug)
  fi

  if [[ -n "${CRKCACHY_LANG:-}" ]]; then
    extra+=(--lang "$CRKCACHY_LANG")
  fi

  export CRKCACHY_ROOT
  log_info "$(msgf tools.hub_starting "$(get_tool_name "$slug")" "$(tool_action_label "$action")")"
  log_debug "tool install: $tool_install"
  bash "$tool_install" "${extra[@]}" "${FILTERED_CLI_ARGS[@]:-}"
}

tool_hub_resolve_slug() {
  local slug="${CRKCACHY_TOOL:-}"

  if [[ -n "$slug" ]]; then
    TOOL_HUB_PICKED_SLUG="$slug"
    return 0
  fi

  tool_hub_pick_tool_slug
  slug="$TOOL_HUB_PICKED_SLUG"

  if [[ "$slug" == "__refresh__" ]]; then
    tool_fetch_update_catalog || true
    if tool_fetch_ensure_repo 2>/dev/null; then
      log_ok "$(msg tools.catalog_updated)"
    fi
    discover_tools || true
    tool_hub_pick_tool_slug
  fi
}

# action empty → pick action after tool
tool_hub_run() {
  local action="${1:-}"
  local slug

  action="$(tool_action_normalize "$action")"

  tool_hub_resolve_slug
  slug="$TOOL_HUB_PICKED_SLUG"

  [[ -n "$slug" && "$slug" != "__refresh__" ]] || {
    log_info "$(msg install.cancelled)"
    return 0
  }

  if [[ "$(tool_source_for_slug "$slug")" == "remote" ]] \
    || ! tool_resolve_install_path "$slug" >/dev/null 2>&1; then
    if ! tool_ensure_ready "$slug"; then
      return 1
    fi
  fi

  if [[ -z "$action" ]]; then
    action="$(tool_action_pick_menu "$(get_tool_name "$slug")")"
    [[ "$action" != "back" && -n "$action" ]] || {
      log_info "$(msg install.cancelled)"
      return 0
    }
  fi

  tool_hub_dispatch "$slug" "$action"
}

tool_hub_interactive() {
  tool_hub_run ""
}

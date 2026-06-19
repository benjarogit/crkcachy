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

TOOL_HUB_PICKED_SLUG=""

tool_hub_pick_tool_slug() {
  TOOL_HUB_PICKED_SLUG=""
  local slug="" selected="" label lines=() i name status source

  tool_fetch_update_catalog 2>/dev/null || true

  if ! discover_tools; then
    die "$(msg tools.none)"
  fi

  echo ""
  cui_section "$(msg tools.hub_pick_title)" "$(msg tools.hub_pick_body)"
  echo ""

  lines=()
  for i in "${!TOOL_SLUGS[@]}"; do
    slug="${TOOL_SLUGS[$i]}"
    source="${TOOL_SOURCES[$i]}"
    name="$(get_tool_name "$slug")"
    status="$(tool_catalog_status_label "$source")"
    label="$((i + 1))) $name  [$status]"
    lines+=("${slug}|${label}")
  done

  lines+=("__refresh__|$(msg tools.hub_refresh)")
  lines+=("|$(msg action.opt_back)")

  selected="$(crk_autocomplete "$(msg tools.hub_pick_hint)" "$(msg tools.hub_search_hint)" "" "${lines[@]}")" || selected=""

  if [[ -z "$selected" ]]; then
    TOOL_HUB_PICKED_SLUG=""
    return 0
  fi

  TOOL_HUB_PICKED_SLUG="$selected"
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
    slug="$TOOL_HUB_PICKED_SLUG"
  fi
}

tool_hub_run() {
  local action="${1:-}"
  local slug

  action="$(tool_action_normalize "$action")"

  tool_hub_resolve_slug
  slug="$TOOL_HUB_PICKED_SLUG"

  [[ -n "$slug" && "$slug" != "__refresh__" ]] || {
    log_info "$(msg install.cancelled)"
    return 1
  }

  if [[ "$(tool_source_for_slug "$slug")" == "remote" ]] \
    || ! tool_resolve_install_path "$slug" >/dev/null 2>&1; then
    if ! tool_ensure_ready "$slug"; then
      return 1
    fi
  fi

  if [[ -z "$action" ]]; then
    tool_action_pick_menu "$(get_tool_name "$slug")"
    action="$TOOL_ACTION_PICKED"
    [[ "$action" != "back" && -n "$action" ]] || {
      log_info "$(msg install.cancelled)"
      return 1
    }
  fi

  tool_hub_dispatch "$slug" "$action"
}

tool_hub_interactive() {
  tool_hub_run ""
}

tool_hub_run_uninstall() {
  discover_tools 2>/dev/null || true

  local slug="" lines=() selected="" i name desc label

  if [[ "${#TOOL_SLUGS[@]}" -eq 1 ]]; then
    slug="${TOOL_SLUGS[0]}"
    log_info "$(msgf tools.hub_auto_pick "$(get_tool_name "$slug")")"
  elif [[ "${#TOOL_SLUGS[@]}" -gt 1 ]]; then
    echo ""
    cui_section "$(msg tools.hub_uninstall_pick_title)"
    echo ""

    lines=()
    for i in "${!TOOL_SLUGS[@]}"; do
      slug="${TOOL_SLUGS[$i]}"
      name="$(get_tool_name "$slug")"
      desc="$(get_tool_desc "$slug")"
      if [[ -n "$desc" ]]; then
        label="$((i + 1))) $name – $desc"
      else
        label="$((i + 1))) $name"
      fi
      lines+=("${slug}|${label}")
    done
    lines+=("|$(msg action.opt_back)")

    selected="$(crk_select "$(msg wizard.choose_hint)" "" "${lines[@]}")" || selected=""
    slug="${selected:-}"
  fi

  if [[ -z "$slug" ]]; then
    log_info "$(msg install.cancelled)"
    return 1
  fi

  tool_hub_dispatch "$slug" "uninstall"
}

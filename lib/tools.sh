#!/usr/bin/env bash
# Dynamic tool discovery – local bundle, cache, GitHub catalog

set -euo pipefail

# Populated by discover_tools / tool_catalog_refresh
TOOL_SLUGS=()
TOOL_INSTALLS=()
TOOL_SOURCES=()

tool_msg_key() {
  local slug="$1"
  local field="$2"
  echo "tool.${slug}.${field}"
}

get_tool_name() {
  local slug="$1"
  if declare -F tool_catalog_get_name >/dev/null 2>&1; then
    tool_catalog_get_name "$slug"
    return 0
  fi
  local key val
  key="$(tool_msg_key "$slug" name)"
  val="${_MSG[$key]:-}"
  if [[ -n "$val" ]]; then
    echo "$val"
  else
    echo "$slug"
  fi
}

get_tool_desc() {
  local slug="$1"
  if declare -F tool_catalog_get_desc >/dev/null 2>&1; then
    tool_catalog_get_desc "$slug"
    return 0
  fi
  local key
  key="$(tool_msg_key "$slug" desc)"
  echo "${_MSG[$key]:-}"
}

discover_tools() {
  TOOL_SLUGS=()
  TOOL_INSTALLS=()
  TOOL_SOURCES=()

  tool_fetch_update_catalog 2>/dev/null || true

  if ! tool_catalog_refresh; then
    return 1
  fi

  TOOL_SLUGS=("${TOOL_CATALOG_SLUGS[@]}")
  TOOL_INSTALLS=("${TOOL_CATALOG_INSTALLS[@]}")
  TOOL_SOURCES=("${TOOL_CATALOG_SOURCES[@]}")

  [[ ${#TOOL_SLUGS[@]} -gt 0 ]]
}

print_tool_list() {
  local i=1
  local slug desc status

  if ! discover_tools; then
    log_warn "$(msg tools.none)"
    return 1
  fi

  log_info "$(msg tools.list_title)"
  log_hint "$(msg tools.list_dynamic)"
  echo ""

  for slug in "${TOOL_SLUGS[@]}"; do
    desc="$(get_tool_desc "$slug")"
    status="$(tool_catalog_status_label "${TOOL_SOURCES[$((i - 1))]}")"
    if [[ -n "$desc" ]]; then
      echo "  $i) $(get_tool_name "$slug") – $desc [$status]"
    else
      echo "  $i) $(get_tool_name "$slug") [$status]"
    fi
    i=$((i + 1))
  done

  echo ""
  return 0
}

run_single_tool() {
  local index="$1"
  local slug="${TOOL_SLUGS[$((index - 1))]}"
  local action="${2:-}"

  if ! tool_ensure_ready "$slug"; then
    return 1
  fi

  discover_tools
  if [[ -n "$action" ]]; then
    tool_hub_dispatch "$slug" "$action"
  else
    log_info "$(msgf tools.starting "$(get_tool_name "$slug")")"
    bash "$(tool_resolve_install_path "$slug")"
  fi
}

run_all_tools() {
  local slug
  for slug in "${TOOL_SLUGS[@]}"; do
    if tool_ensure_ready "$slug"; then
      log_info "$(msgf tools.starting "$(get_tool_name "$slug")")"
      bash "$(tool_resolve_install_path "$slug")"
      echo ""
    fi
  done
}

run_tool_wizard() {
  tool_hub_interactive
}

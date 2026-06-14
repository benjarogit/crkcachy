#!/usr/bin/env bash
# Dynamic tool discovery – scans tools/*/install.sh

set -euo pipefail

# Populated by discover_tools
TOOL_SLUGS=()
TOOL_INSTALLS=()

tool_msg_key() {
  local slug="$1"
  local field="$2"
  echo "tool.${slug}.${field}"
}

get_tool_name() {
  local slug="$1"
  local key
  key="$(tool_msg_key "$slug" name)"
  local val="${_MSG[$key]:-}"
  if [[ -n "$val" ]]; then
    echo "$val"
  else
    echo "$slug"
  fi
}

get_tool_desc() {
  local slug="$1"
  local key
  key="$(tool_msg_key "$slug" desc)"
  echo "${_MSG[$key]:-}"
}

discover_tools() {
  local tools_dir="${CRKCACHY_ROOT}/tools"
  TOOL_SLUGS=()
  TOOL_INSTALLS=()

  if [[ ! -d "$tools_dir" ]]; then
    return 1
  fi

  local tool_install slug
  for tool_install in "$tools_dir"/*/install.sh; do
    [[ -f "$tool_install" ]] || continue
    slug="$(basename "$(dirname "$tool_install")")"
    TOOL_SLUGS+=("$slug")
    TOOL_INSTALLS+=("$tool_install")
  done

  [[ ${#TOOL_SLUGS[@]} -gt 0 ]]
}

print_tool_list() {
  local i=1
  local slug desc

  if ! discover_tools; then
    log_warn "$(msg tools.none)"
    return 1
  fi

  log_info "$(msg tools.list_title)"
  log_hint "$(msg tools.list_dynamic)"
  echo ""

  for slug in "${TOOL_SLUGS[@]}"; do
    desc="$(get_tool_desc "$slug")"
    if [[ -n "$desc" ]]; then
      echo "  $i) $(get_tool_name "$slug") – $desc"
    else
      echo "  $i) $(get_tool_name "$slug")"
    fi
    i=$((i + 1))
  done

  if [[ ${#TOOL_SLUGS[@]} -gt 1 ]]; then
    echo "  a) $(msg tools.opt_all)"
  fi
  echo ""

  return 0
}

run_single_tool() {
  local index="$1"
  local install_path="${TOOL_INSTALLS[$((index - 1))]}"
  local slug="${TOOL_SLUGS[$((index - 1))]}"

  log_info "$(msgf tools.starting "$(get_tool_name "$slug")")"
  bash "$install_path"
}

run_all_tools() {
  local i=1
  for install_path in "${TOOL_INSTALLS[@]}"; do
    local slug="${TOOL_SLUGS[$((i - 1))]}"
    log_info "$(msgf tools.starting "$(get_tool_name "$slug")")"
    bash "$install_path"
    echo ""
    i=$((i + 1))
  done
}

run_tool_wizard() {
  if ! discover_tools; then
    return 1
  fi

  # Ein Spiel → direkt starten (kein zweites Menü)
  if [[ ${#TOOL_SLUGS[@]} -eq 1 ]]; then
    ui_action "$(msgf tools.starting "$(get_tool_name "${TOOL_SLUGS[0]}")")"
    bash "${TOOL_INSTALLS[0]}"
    return 0
  fi

  while true; do
    cui_section "$(msg tools.setup_title)" "$(msg tools.list_title)"

    if ! discover_tools; then
      return 1
    fi

    local choice
    tui_tool_pick choice

    if [[ -z "${choice:-}" ]]; then
      log_info "$(msg tools.none_selected)"
      return 0
    fi

    if [[ "${choice,,}" == "a" || "${choice,,}" == "all" ]]; then
      if [[ ${#TOOL_SLUGS[@]} -le 1 ]]; then
        run_single_tool 1
      else
        run_all_tools
      fi
    elif [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#TOOL_SLUGS[@]} )); then
      run_single_tool "$choice"
    else
      log_warn "$(msg tools.invalid)"
      continue
    fi

    echo ""
    if ! confirm "$(msg tools.another)"; then
      log_ok "$(msg tools.done)"
      return 0
    fi
    echo ""
  done
}

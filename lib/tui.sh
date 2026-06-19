#!/usr/bin/env bash
# Domain menus – built on lib/cui.sh (loaded from common.sh)

set -euo pipefail

tui_section() { cui_section "$@"; }
tui_panel() { cui_panel "$@"; }
tui_spacer() { cui_spacer "$@"; }
tui_checklist() { cui_checklist "$@"; }
tui_header() { cui_section "$@"; }
tui_input() { cui_input "$@"; }
tui_run_spin() { cui_spin "$@"; }
tui_press_enter() { cui_continue; }

tui_wizard_pick() {
  local _out="${1:-}"
  local lines=() i selected result idx val label

  label="$(msg ui.badge_recommended)  $(msg wizard.opt"$ASSESS_RECOMMENDED")"
  lines+=("${ASSESS_RECOMMENDED}|${label}")

  for i in 1 2 3; do
    [[ "$i" == "$ASSESS_RECOMMENDED" ]] && continue
    lines+=("${i}|$(msg wizard.opt$i)")
  done

  if [[ "$ASSESS_RECOMMENDED" != 4 ]]; then
    lines+=("4|$(msg wizard.opt4)")
  fi

  lines+=("5|$(msg wizard.opt5)")

  selected="$(crk_select "$(msg wizard.choose_hint)" "${ASSESS_RECOMMENDED}" "${lines[@]}")" || selected=""

  result="${selected:-}"

  if [[ -n "$_out" ]]; then
    printf -v "$_out" '%s' "$result"
  else
    echo "$result"
  fi
}

tui_tool_pick() {
  local _out="${1:-}"
  local lines=() i slug desc name selected result idx val

  for i in "${!TOOL_SLUGS[@]}"; do
    slug="${TOOL_SLUGS[$i]}"
    name="$(get_tool_name "$slug")"
    desc="$(get_tool_desc "$slug")"
    if [[ -n "$desc" ]]; then
      lines+=("$((i + 1))|$((i + 1))) $name – $desc")
    else
      lines+=("$((i + 1))|$((i + 1))) $name")
    fi
  done

  if [[ ${#TOOL_SLUGS[@]} -gt 1 ]]; then
    lines+=("a|a) $(msg tools.opt_all)")
  fi

  lines+=("|$(msg tools.opt_skip)")

  selected="$(crk_autocomplete "$(msg tools.choose_hint)" "$(msg tools.hub_search_hint)" "" "${lines[@]}")" || selected=""

  result="${selected:-}"

  if [[ -n "$_out" ]]; then
    printf -v "$_out" '%s' "$result"
  else
    echo "$result"
  fi
}

#!/usr/bin/env bash
# Domain menus – built on lib/cui.sh (loaded from common.sh)

set -euo pipefail

# Backward-compatible aliases
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
  local labels=() values=() i selected result idx

  labels+=("$(msg ui.badge_recommended)  $(msg wizard.opt"$ASSESS_RECOMMENDED")")
  values+=("$ASSESS_RECOMMENDED")

  for i in 1 2 3 4; do
    [[ "$i" == "$ASSESS_RECOMMENDED" || "$i" == 4 ]] && continue
    labels+=("$(msg wizard.opt$i)")
    values+=("$i")
  done

  if [[ "$ASSESS_RECOMMENDED" != 4 ]]; then
    labels+=("$(msg wizard.opt4)")
    values+=("4")
  fi

  selected="$(cui_choose "$(msg wizard.choose_hint)" 0 "${labels[@]}")"

  result="$ASSESS_RECOMMENDED"
  for idx in "${!labels[@]}"; do
    if [[ "${labels[$idx]}" == "$selected" ]]; then
      result="${values[$idx]}"
      break
    fi
  done

  if [[ -n "$_out" ]]; then
    printf -v "$_out" '%s' "$result"
  else
    echo "$result"
  fi
}

tui_tool_pick() {
  local _out="${1:-}"
  local labels=() values=() i slug desc name selected result idx

  for i in "${!TOOL_SLUGS[@]}"; do
    slug="${TOOL_SLUGS[$i]}"
    name="$(get_tool_name "$slug")"
    desc="$(get_tool_desc "$slug")"
    if [[ -n "$desc" ]]; then
      labels+=("$((i + 1))) $name – $desc")
    else
      labels+=("$((i + 1))) $name")
    fi
    values+=("$((i + 1))")
  done

  if [[ ${#TOOL_SLUGS[@]} -gt 1 ]]; then
    labels+=("a) $(msg tools.opt_all)")
    values+=("a")
  fi

  labels+=("$(msg tools.opt_skip)")
  values+=("")

  selected="$(cui_choose "$(msg tools.choose_hint)" 0 "${labels[@]}")"

  result=""
  for idx in "${!labels[@]}"; do
    if [[ "${labels[$idx]}" == "$selected" ]]; then
      result="${values[$idx]}"
      break
    fi
  done

  if [[ -n "$_out" ]]; then
    printf -v "$_out" '%s' "$result"
  else
    echo "$result"
  fi
}

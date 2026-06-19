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

# Statischer Wizard-Kopf (kein Clack intro/note – die können die Konsole leeren)
tui_wizard_show_header() {
  echo ""
  ui_divider
  cui_heading "$(msg wizard.title)"
  echo ""
  if [[ "${ASSESS_SYSTEM_READY:-false}" == true ]]; then
    cui_sub "$(assess_recommended_hint)"
  else
    cui_sub "$(msgf wizard.status_fix "$(msgf assess.score "${ASSESS_OK:-0}" "${ASSESS_FAIL:-1}")")"
    tui_assess_panel || true
  fi
  echo ""
}

tui_wizard_build_lines() {
  WIZARD_PICK_LINES=()
  local i label
  label="$(msg ui.badge_recommended)  $(msg wizard.opt"$ASSESS_RECOMMENDED")"
  WIZARD_PICK_LINES+=("${ASSESS_RECOMMENDED}|${label}")
  for i in 1 2 3; do
    [[ "$i" == "$ASSESS_RECOMMENDED" ]] && continue
    WIZARD_PICK_LINES+=("${i}|$(msg wizard.opt$i)")
  done
  if [[ "$ASSESS_RECOMMENDED" != 4 ]]; then
    WIZARD_PICK_LINES+=("4|$(msg wizard.opt4)")
  fi
  WIZARD_PICK_LINES+=("5|$(msg wizard.opt5)")
}

tui_wizard_pick() {
  local _out="${1:-}"
  local selected="" result=""
  local -a lines=()

  tui_wizard_build_lines
  lines=("${WIZARD_PICK_LINES[@]}")

  selected="$(crk_select "$(msg wizard.choose_hint)" "${ASSESS_RECOMMENDED}" "${lines[@]}")"
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

  selected="$(crk_autocomplete "$(msg tools.choose_hint)" "$(msg tools.hub_search_hint)" "" "${lines[@]}")"
  result="${selected:-}"

  if [[ -n "$_out" ]]; then
    printf -v "$_out" '%s' "$result"
  else
    echo "$result"
  fi
}

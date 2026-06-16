#!/usr/bin/env bash
# CRKCACHY UI – schlicht, kompakt, modern

set -euo pipefail

CUI_ACCENT="${CUI_ACCENT:-212}"
CUI_MUTED="${CUI_MUTED:-245}"
CUI_OK="${CUI_OK:-86}"

cui_brand_header() {
  gum style --bold "CRKCACHY v${CRKCACHY_VERSION}"
  gum style --foreground "$CUI_MUTED" "$(msg banner.subtitle)"
  echo ""
}

cui_rule() {
  gum style --foreground 238 "────────────────────────────────────────"
}

cui_heading() {
  gum style --bold --margin "0" "$1"
}

cui_sub() {
  [[ -n "${1:-}" ]] && gum style --foreground "$CUI_MUTED" "$1"
}

cui_list() {
  local line
  for line in "$@"; do
    echo "  $line"
  done
}

cui_spacer() {
  echo ""
}

cui_section() {
  cui_heading "$1"
  cui_sub "${2:-}"
}

cui_panel() {
  local title="$1"
  local body="$2"
  cui_heading "$title"
  cui_sub "$body"
}

cui_checklist() {
  local title="$1"
  shift
  cui_heading "$title"
  cui_list "$@"
}

cui_yes_no() {
  local prompt="$1"
  local default_no="${2:-true}"
  local selected=0
  [[ "$default_no" == "true" ]] && selected=1

  local pick
  pick="$(gum choose --selected "$selected" \
    --header "$prompt" \
    --cursor "› " \
    "$(msg cui.choice_yes)" \
    "$(msg cui.choice_no)")"

  [[ "$pick" == "$(msg cui.choice_yes)" ]]
}

cui_show_markdown() {
  local file="$1"
  local title="${2:-}"
  local show_scroll_hint="${3:-true}"
  local width tmp_md

  if [[ ! -f "$file" ]]; then
    log_warn "$(msg glow.file_missing)"
    return 1
  fi

  width="$(tput cols 2>/dev/null || echo 80)"
  width=$((width - 2))
  [[ "$width" -lt 52 ]] && width=52
  [[ "$width" -gt 96 ]] && width=96

  if [[ -n "$title" ]]; then
    cui_heading "$title"
    echo ""
  fi

  if [[ "$show_scroll_hint" == true ]]; then
    log_hint "$(msg ui.markdown_scroll_hint)"
    echo ""
  fi

  tmp_md="$(mktemp --suffix=.crkcachy.md)"
  sed -E \
    -e 's/\[([^\]]+)\]\([^)]+\)/\1/g' \
    -e 's@[[:space:]]*/[^[:space:]]*README(\.en)?\.md[^[:space:]]*@@g' \
    -e 's@[[:space:]]*\.\./[^[:space:]]*README(\.en)?\.md[^[:space:]]*@@g' \
    -e 's@[[:space:]]*\.\./[^[:space:]]*docs/[^[:space:]]*@@g' \
    -e 's@[[:space:]]*/docs/[^[:space:]]*@@g' \
    -e 's@[[:space:]]*/tmp/[^[:space:]]+\.md@@g' \
    -e 's/  +/ /g' \
    "$file" > "$tmp_md"
  GLOW_PAGER=cat glow -s auto -w "$width" "$tmp_md"
  rm -f "$tmp_md"
  echo ""
}

cui_result_line() {
  local state="$1"
  local label="$2"
  local detail="${3:-}"

  case "$state" in
    ok)
      echo -e "${_C_GREEN}  ✓${_C_RESET} ${label}${detail:+ – ${detail}}"
      ;;
    warn)
      echo -e "${_C_YELLOW}  ○${_C_RESET} ${label}${detail:+ – ${detail}}"
      ;;
    fail)
      echo -e "${_C_RED}  ✗${_C_RESET} ${label}${detail:+ – ${detail}}"
      ;;
    *)
      echo "  • ${label}${detail:+ – ${detail}}"
      ;;
  esac
}

cui_summary_panel() {
  local title="$1"
  local body="$2"

  echo ""
  gum style --bold "$title"
  echo ""
  while IFS= read -r line || [[ -n "$line" ]]; do
    [[ -z "$line" ]] && echo "" && continue
    echo "  $line"
  done <<< "$body"
  echo ""
}

cui_install_plan() {
  local title="$1"
  local intro="${2:-}"
  shift 2
  local line

  echo ""
  gum style --bold "$title"
  [[ -n "$intro" ]] && echo "" && echo "  $intro" && echo ""
  for line in "$@"; do
    echo "  $line"
  done
  echo ""
}

cui_offer_markdown() {
  local rel_path="$1"
  local prompt="$2"
  local file

  file="$(crkcachy_markdown_path "$rel_path")"
  if [[ ! -f "$file" ]]; then
    return 1
  fi

  if cui_yes_no "$prompt" false; then
    echo ""
    cui_show_markdown "$file"
    echo ""
  fi
}

cui_progress_track() {
  local step="$1"
  local total="$2"
  local bar="" i token

  for ((i = 1; i <= total; i++)); do
    if (( i < step )); then
      token="●"
    elif (( i == step )); then
      token="◉"
    else
      token="○"
    fi
    bar+="${token} "
  done

  gum style --foreground "$CUI_MUTED" "$(msgf ui.wizard_track "$step" "$total")"
  gum style --foreground "$CUI_ACCENT" "$bar"
}

cui_status_chip() {
  local ok="$1"
  local text="$2"

  if [[ "$ok" == true ]]; then
    gum style --border rounded --border-foreground "$CUI_OK" --foreground "$CUI_OK" --padding "0 1" "✓ ${text}"
  else
    gum style --border rounded --border-foreground "$CUI_ACCENT" --foreground "$CUI_ACCENT" --padding "0 1" "○ ${text}"
  fi
}

cui_wizard_screen() {
  local step_num="$1"
  local step_total="$2"
  local title="$3"
  local body="$4"

  echo ""
  cui_progress_track "$step_num" "$step_total"
  echo ""
  gum style --bold "$title"
  echo ""
  gum style --foreground "$CUI_MUTED" "$body"
  echo ""
  cui_continue
}

cui_wizard_intro() {
  echo ""
  echo ""
  ui_divider
  gum style --bold "$(msg install.legal_title)"
  echo ""
  gum style --foreground "$CUI_MUTED" "$(msg install.legal_teaser)"
  echo ""
}

cui_legal_gate() {
  local total=4

  if cui_onboard_should_skip; then
    log_debug "intro skipped – already accepted"
    return 0
  fi

  cui_wizard_intro

  cui_wizard_screen 1 "$total" "$(msg legal.step1_title)" "$(msg legal.step1_body)"
  cui_wizard_screen 2 "$total" "$(msg legal.step2_title)" "$(msg legal.step2_body)"
  cui_wizard_screen 3 "$total" "$(msg legal.step3_title)" "$(msg legal.step3_body)"
  cui_wizard_screen 4 "$total" "$(msg legal.step4_title)" "$(msg legal.step4_body)"

  echo ""
  gum style --border rounded --padding "1 2" --foreground "$CUI_MUTED" "$(msg install.legal_summary)"
  echo ""
  if ! cui_yes_no "$(msg ui.legal_confirm)" false; then
    die "$(msg runtime.legal_abort)"
  fi

  cui_onboard_mark_done
}

# ── ARCHITEKTUR-REGEL: stdout-Capture-Sicherheit ─────────────────────────────
#
# cui_choose / cui_filter / cui_choose_searchable / cui_input:
#   → Diese Primitiven sind SICHER mit selected="$(cui_choose ...)"
#   → Sie geben NUR den ausgewählten Wert via stdout aus (gum nutzt /dev/tty)
#
# WRAPPER-FUNKTIONEN die ZUSÄTZLICH echo/log_*/cui_section ausgeben:
#   → NIEMALS mit var="$(wrapper_func)" aufrufen → UI-Text landet im Wert!
#   → Stattdessen: globale Variable nutzen (z.B. TOOL_ACTION_PICKED)
#     Muster:
#       wrapper_func   # setzt WRAPPER_RESULT
#       var="$WRAPPER_RESULT"
#
# Bekannte Wrapper mit globaler Variable:
#   tool_hub_pick_tool_slug  → TOOL_HUB_PICKED_SLUG
#   tool_hub_resolve_slug    → TOOL_HUB_PICKED_SLUG
#   tool_action_pick_menu    → TOOL_ACTION_PICKED
#
# ─────────────────────────────────────────────────────────────────────────────

cui_choose_searchable() {
  cui_filter "$@"
}

cui_input() {
  local placeholder="${1:-}"
  local default="${2:-}"
  gum input --placeholder "$placeholder" --value "$default" --width 70 \
    --prompt "$(msg cui.input_prompt) "
}

cui_choose() {
  local header="$1"
  local selected_idx="$2"
  shift 2
  gum choose --height "$#" --selected "$selected_idx" \
    --header "$header" \
    --cursor "› " \
    "$@"
}

cui_filter() {
  local header="$1"
  local placeholder="$2"
  shift 2
  local count="${#@}"
  local height=8
  [[ "$count" -gt "$height" ]] && height="$count"
  [[ "$height" -lt 6 ]] && height=6
  gum filter --height "$height" \
    --header "$header" \
    --placeholder "$placeholder" \
    --indicator "› " \
    --prompt "🔍 " \
    "$@"
}

crkcachy_onboard_file() {
  echo "${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/onboard.accepted"
}

cui_onboard_done() {
  [[ -f "$(crkcachy_onboard_file)" ]]
}

cui_onboard_mark_done() {
  local dir
  dir="$(dirname "$(crkcachy_onboard_file)")"
  mkdir -p "$dir"
  echo "${CRKCACHY_VERSION}" > "$(crkcachy_onboard_file)"
}

cui_onboard_should_skip() {
  [[ "${CRKCACHY_FORCE_INTRO:-0}" == 1 ]] && return 1
  [[ "${CRKCACHY_SKIP_INTRO:-0}" == 1 ]] && return 0
  cui_onboard_done
}

cui_wizard_main_header() {
  local hint="$1"

  echo ""
  ui_divider
  gum style --bold "$(msg wizard.title)"
  echo ""
  if [[ "$ASSESS_SYSTEM_READY" == true ]]; then
    gum style --foreground "$CUI_MUTED" "$hint"
  else
    cui_status_chip false "$(msgf wizard.status_fix "$(msgf assess.score "$ASSESS_OK" "$ASSESS_FAIL")")"
    gum style --foreground "$CUI_MUTED" "$hint"
  fi
  echo ""
}

cui_spin() {
  local title="$1"
  shift
  gum spin --spinner dot --title "$title" -- "$@"
}

cui_continue() {
  gum choose --selected 0 --height 1 \
    --header "$(msg ui.press_enter)" \
    "$(msg ui.ok_label)"
}

# One screen: title + text, then Weiter (game-tool flows).
cui_step_screen() {
  local step_num="$1"
  local step_total="$2"
  local title="$3"
  local body="$4"
  local _next_hint="${5:-}"

  cui_wizard_screen "$step_num" "$step_total" "$title" "$body"
}

# Legacy aliases
cui_divider() { cui_rule; echo ""; }
cui_columns() { cui_section "$1"; cui_sub "$2"; }

#!/usr/bin/env bash
# CRKCACHY Design System – @clack/prompts via lib/crk_prompter.sh (OpenClaw-style)
#
# Interaktion: Node + @clack/prompts (kein gum)
# Statisches Styling: ANSI
#
set -euo pipefail

# ── Farbtokens (ANSI 256) ─────────────────────────────────────────────────────

CUI_C_BRAND=99
CUI_C_SUCCESS=76
CUI_C_WARNING=214
CUI_C_ERROR=196
CUI_C_INFO=117
CUI_C_MUTED=245
CUI_C_DIM=238
CUI_C_STEP=147

CUI_ACCENT="${CUI_C_BRAND}"
CUI_MUTED="${CUI_C_MUTED}"
CUI_OK="${CUI_C_SUCCESS}"

CUI_ICON_OK="✓"
CUI_ICON_WARN="○"
CUI_ICON_FAIL="✗"
CUI_ICON_ARROW="›"
CUI_ICON_BULLET="•"
CUI_ICON_STEP="◆"

_cui_box_lines() {
  local color="$1"
  local body="$2"
  local line
  echo ""
  printf '  %b╭────────────────────────────────────────╮%b\n' "$(_cui_fg "$color")" "${_C_RESET}"
  while IFS= read -r line || [[ -n "$line" ]]; do
  printf '  %b│%b  %s\n' "$(_cui_fg "$color")" "${_C_RESET}" "$line"
  done <<< "$body"
  printf '  %b╰────────────────────────────────────────╯%b\n' "$(_cui_fg "$color")" "${_C_RESET}"
  echo ""
}

cui_muted_block() {
  local body="$1"
  while IFS= read -r line || [[ -n "$line" ]]; do
    _cui_echo "$CUI_C_MUTED" "  $line"
  done <<< "$body"
}

cui_warning_box() {
  _cui_box_lines "$CUI_C_WARNING" "$1"
}

cui_info_box() {
  _cui_box_lines "$CUI_C_BRAND" "$1"
}

_cui_fg() {
  printf '\033[38;5;%sm' "$1"
}

_cui_echo() {
  local color="$1"
  shift
  printf '%b%b%b\n' "$(_cui_fg "$color")" "$*" "${_C_RESET}"
}

_cui_echo_bold() {
  printf '%b%b%b\n' "${_C_BOLD}" "$*" "${_C_RESET}"
}

# ── Primitive ─────────────────────────────────────────────────────────────────

cui_heading() {
  _cui_echo_bold "$1"
}

cui_sub() {
  if [[ -n "${1:-}" ]]; then
    _cui_echo "$CUI_C_MUTED" "$1"
  fi
}

cui_rule() {
  local width line
  width="$(tput cols 2>/dev/null || echo 72)"
  if [[ "$width" -gt 72 ]]; then width=72; fi
  line="$(python3 -c "print('─'*${width})" 2>/dev/null || printf '%0.s─' $(seq 1 "$width"))"
  _cui_echo "$CUI_C_DIM" "$line"
}

cui_spacer() { echo ""; }
cui_divider() { echo ""; cui_rule; echo ""; }

cui_brand_header() {
  echo ""
  printf '  %b╔══════════════════════════════════╗%b\n' "$(_cui_fg "$CUI_C_BRAND")" "${_C_RESET}"
  printf '  %b║   C R K C A C H Y   %b║\n' "$(_cui_fg "$CUI_C_BRAND")" "${_C_RESET}"
  printf '  %b╚══════════════════════════════════╝%b\n' "$(_cui_fg "$CUI_C_BRAND")" "${_C_RESET}"
  echo ""
  _cui_echo "$CUI_C_MUTED" "  v${CRKCACHY_VERSION}  ·  $(msg banner.subtitle)"
  echo ""
  _cui_github_version_check
  echo ""
}

_cui_github_version_check() {
  command -v curl >/dev/null 2>&1 || return 0
  command -v grep >/dev/null 2>&1 || return 0

  local _latest
  _latest="$(curl -fsSL --connect-timeout 3 --max-time 5 \
    "https://api.github.com/repos/benjarogit/crkcachy/releases/latest" \
    2>/dev/null \
    | grep -m1 '"tag_name"' \
    | sed 's/.*"v\([^"]*\)".*/\1/' \
    2>/dev/null || true)"

  [[ -n "$_latest" ]] || return 0

  if [[ "$_latest" == "$CRKCACHY_VERSION" ]]; then
    _cui_echo "$CUI_C_SUCCESS" "  ✓ $(msgf banner.version_ok "v${CRKCACHY_VERSION}")"
  elif [[ "$(printf '%s\n' "$_latest" "$CRKCACHY_VERSION" | sort -V | tail -1)" == "$_latest" ]]; then
    _cui_echo "$CUI_C_WARNING" "  ↑ $(msgf banner.update_available "v${CRKCACHY_VERSION}" "v${_latest}")"
    _cui_echo "$CUI_C_MUTED" "    github.com/benjarogit/crkcachy/releases/latest"
  fi
}

cui_section() {
  local title="$1"
  local sub="${2:-}"
  echo ""
  _cui_echo_bold "$title"
  if [[ -n "$sub" ]]; then
    _cui_echo "$CUI_C_MUTED" "$sub"
  fi
}

cui_panel() { cui_section "$@"; }

cui_check_row() {
  local state="$1"
  local name="$2"
  local value="${3:-}"
  local detail="${4:-}"

  local icon esc_color
  case "$state" in
    ok)   icon="$CUI_ICON_OK";   esc_color="$_C_GREEN"  ;;
    warn) icon="$CUI_ICON_WARN"; esc_color="$_C_YELLOW" ;;
    fail) icon="$CUI_ICON_FAIL"; esc_color="$_C_RED"    ;;
    *)    icon="$CUI_ICON_BULLET"; esc_color=""          ;;
  esac

  local name_w=24 val_w=28
  if [[ -n "$detail" ]]; then
    printf "  %b%-2s%b  %-${name_w}s %-${val_w}s %b%s%b\n" \
      "$esc_color" "$icon" "$_C_RESET" \
      "$name" "$value" \
      "$_C_DIM" "$detail" "$_C_RESET"
  else
    printf "  %b%-2s%b  %-${name_w}s %s\n" \
      "$esc_color" "$icon" "$_C_RESET" \
      "$name" "$value"
  fi
}

cui_check_category() {
  echo ""
  printf '%b%b  %s%b\n' "${_C_BOLD}" "$(_cui_fg "$CUI_C_STEP")" "$1" "${_C_RESET}"
}

cui_status_chip() {
  local ok="$1"
  local text="$2"
  echo ""
  if [[ "$ok" == true ]]; then
    printf '  %b%s%b  %s\n' "$_C_GREEN" "$CUI_ICON_OK" "$_C_RESET" "$text"
  else
    printf '  %b%s%b  %s\n' "$_C_YELLOW" "$CUI_ICON_WARN" "$_C_RESET" "$text"
  fi
  echo ""
}

cui_progress_track() {
  local step="$1"
  local total="$2"
  local bar="" i token
  for ((i = 1; i <= total; i++)); do
    if   (( i < step ));  then token="●"
    elif (( i == step )); then token="◉"
    else                       token="○"
    fi
    bar+="${token} "
  done
  echo ""
  printf '%b  %s   %s%b\n' "$(_cui_fg "$CUI_C_STEP")" "$(msgf ui.wizard_track "$step" "$total")" "$bar" "${_C_RESET}"
  cui_rule
}

cui_card() {
  local body="$1"
  local _color="${2:-$CUI_C_MUTED}"
  echo ""
  crk_note "$body"
}

cui_screen_clear() {
  if [[ -t 1 ]] && [[ "${CRKCACHY_NO_CLEAR:-0}" != "1" ]]; then
    tput clear 2>/dev/null || clear 2>/dev/null || true
  fi
}

cui_wizard_screen() {
  local step_num="$1"
  local step_total="$2"
  local title="$3"
  local body="$4"

  cui_screen_clear
  cui_progress_track "$step_num" "$step_total"
  echo ""
  _cui_echo_bold "$title"
  echo ""
  crk_note "$body"
  echo ""
  crk_continue "$(msg ui.press_enter)" "$(msg ui.ok_label)"
}

cui_step_screen() { cui_wizard_screen "$@"; }

cui_wizard_intro() {
  echo ""
  cui_rule
  echo ""
  _cui_echo_bold "$(msg install.legal_title)"
  echo ""
  _cui_echo "$CUI_C_MUTED" "$(msg install.legal_teaser)"
  echo ""
}

cui_wizard_main_header() {
  local hint="$1"
  echo ""
  cui_rule
  _cui_echo_bold "$(msg wizard.title)"
  echo ""
  if [[ "${ASSESS_SYSTEM_READY:-false}" == true ]]; then
    _cui_echo "$CUI_C_MUTED" "$hint"
  else
    cui_status_chip false \
      "$(msgf wizard.status_fix "$(msgf assess.score "${ASSESS_OK:-0}" "${ASSESS_FAIL:-1}")")"
    echo ""
    _cui_echo "$CUI_C_MUTED" "$hint"
  fi
  echo ""
}

cui_summary_panel() {
  local title="$1"
  local body="$2"
  echo ""
  _cui_echo_bold "$title"
  echo ""
  while IFS= read -r line || [[ -n "$line" ]]; do
    if [[ -z "$line" ]]; then echo ""; continue; fi
    echo "  $line"
  done <<< "$body"
  echo ""
}

# ── Interaktion (@clack) ──────────────────────────────────────────────────────

cui_yes_no() {
  local prompt="$1"
  local default_no="${2:-true}"
  local default_yes=false
  if [[ "$default_no" != true ]]; then default_yes=true; fi
  crk_confirm "$prompt" "$default_yes"
}

cui_continue() {
  crk_continue "${1:-$(msg ui.press_enter)}" "${2:-$(msg ui.ok_label)}"
}

cui_choose_searchable() { cui_filter "$@"; }

cui_input() {
  local placeholder="${1:-}"
  local default="${2:-}"
  crk_text "$(msg cui.input_prompt)" "$placeholder" "$default"
}

cui_choose() {
  local header="$1"
  local selected_idx="$2"
  shift 2
  local i=0 initial="" lines=() val
  for opt in "$@"; do
    lines+=("${opt}|${opt}")
    if [[ "$i" -eq "$selected_idx" ]]; then initial="$opt"; fi
    i=$((i + 1))
  done
  val="$(crk_select "$header" "$initial" "${lines[@]}")" || val=""
  printf '%s' "$val"
}

cui_filter() {
  local header="$1"
  local placeholder="$2"
  shift 2
  local lines=() val
  for opt in "$@"; do
    lines+=("${opt}|${opt}")
  done
  val="$(crk_autocomplete "$header" "$placeholder" "" "${lines[@]}")" || val=""
  printf '%s' "$val"
}

cui_spin() {
  local title="$1"
  shift
  crk_spin "$title" "$*"
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
  if [[ "$width" -lt 52 ]]; then width=52; fi
  if [[ "$width" -gt 96 ]]; then width=96; fi

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

crkcachy_onboard_file() {
  echo "${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/onboard.accepted"
}

cui_onboard_done()      { [[ -f "$(crkcachy_onboard_file)" ]]; }
cui_onboard_should_skip() {
  [[ "${CRKCACHY_FORCE_INTRO:-0}" == 1 ]] && return 1
  [[ "${CRKCACHY_SKIP_INTRO:-0}"  == 1 ]] && return 0
  cui_onboard_done
}
cui_onboard_mark_done() {
  local dir
  dir="$(dirname "$(crkcachy_onboard_file)")"
  mkdir -p "$dir"
  echo "${CRKCACHY_VERSION}" > "$(crkcachy_onboard_file)"
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
  crk_note "$(msg install.legal_summary)"
  echo ""
  if ! cui_yes_no "$(msg ui.legal_confirm)" false; then
    die "$(msg runtime.legal_abort)"
  fi

  cui_onboard_mark_done
}

cui_result_line() {
  local state="$1" label="$2" detail="${3:-}"
  case "$state" in
    ok)   cui_check_row ok   "$label" "$detail" ;;
    warn) cui_check_row warn "$label" "$detail" ;;
    fail) cui_check_row fail "$label" "$detail" ;;
    *)    echo "  $CUI_ICON_BULLET $label${detail:+ – $detail}" ;;
  esac
}

cui_install_plan() {
  local title="$1"
  local intro="${2:-}"
  shift 2
  local line
  echo ""
  _cui_echo_bold "$title"
  if [[ -n "$intro" ]]; then echo ""; echo "  $intro"; echo ""; fi
  for line in "$@"; do echo "  $line"; done
  echo ""
}

cui_list() {
  local line
  for line in "$@"; do echo "  $line"; done
}

cui_checklist() {
  local title="$1"; shift
  cui_heading "$title"
  cui_list "$@"
}

cui_columns() { cui_section "$1"; cui_sub "$2"; }

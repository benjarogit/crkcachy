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
  local width

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

  GLOW_PAGER=cat glow -s auto -w "$width" "$file"
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

cui_legal_gate() {
  local legal_file
  legal_file="$(crkcachy_markdown_path "docs/legal.md")"

  cui_section "$(msg install.legal_title)" "$(msg install.legal_teaser)"
  echo ""
  cui_show_markdown "$legal_file" "" false
  log_hint "$(msg ui.markdown_scroll_hint)"
  echo ""

  if ! cui_yes_no "$(msg ui.legal_confirm)" false; then
    die "$(msg runtime.legal_abort)"
  fi
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

cui_input() {
  local placeholder="${1:-}"
  local default="${2:-}"
  gum input --placeholder "$placeholder" --value "$default" --width 70 \
    --prompt "$(msg cui.input_prompt) "
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

# Legacy aliases
cui_divider() { cui_rule; echo ""; }
cui_columns() { cui_section "$1"; cui_sub "$2"; }

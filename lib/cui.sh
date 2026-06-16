#!/usr/bin/env bash
# CRKCACHY Design System
#
# Inspiriert von: create-next-app, Volta, Bun, Charm/gum demos
# Prinzipien:
#   1. Semantische Farbtokens – keine Magic Numbers im Code
#   2. Konsistente Komponenten – ein Konzept, eine Funktion
#   3. Ausgerichtete Tabellen für Checklisten (wie Volta "Your toolchain:")
#   4. stdout-Capture-Sicherheit: cui_choose/filter sind $()-safe;
#      Wrapper mit UI-Output nutzen globale Variablen (→ siehe ARCHITEKTUR unten)
#
set -euo pipefail

# ── Farbtokens ────────────────────────────────────────────────────────────────
# 256-Color-Codes die gum --foreground/--border-foreground akzeptiert

CUI_C_BRAND=99       # violet   – CRKCACHY Markenfarbe
CUI_C_SUCCESS=76     # green    – ✓ Alles OK
CUI_C_WARNING=214    # amber    – ○ Empfohlen, fehlt
CUI_C_ERROR=196      # red      – ✗ Pflicht, fehlt
CUI_C_INFO=117       # blue     – Info
CUI_C_MUTED=245      # gray     – Subtexte, Hints
CUI_C_DIM=238        # dark     – Trennlinien
CUI_C_STEP=147       # lavender – Schrittnummern

# Legacy-Aliases (werden von altem Code benutzt)
CUI_ACCENT="${CUI_C_BRAND}"
CUI_MUTED="${CUI_C_MUTED}"
CUI_OK="${CUI_C_SUCCESS}"

# ── Icon-Tokens ───────────────────────────────────────────────────────────────
CUI_ICON_OK="✓"
CUI_ICON_WARN="○"
CUI_ICON_FAIL="✗"
CUI_ICON_ARROW="›"
CUI_ICON_BULLET="•"
CUI_ICON_STEP="◆"

# ── Primitive: Text-Ausgabe ───────────────────────────────────────────────────

# Überschrift (fett)
cui_heading() {
  gum style --bold --margin "0" "${1}"
}

# Untertitel / muted body
cui_sub() {
  [[ -n "${1:-}" ]] && gum style --foreground "$CUI_C_MUTED" "${1}"
}

# Schwache Trennlinie (wie Volta)
cui_rule() {
  local width line
  width="$(tput cols 2>/dev/null || echo 72)"
  [[ "$width" -gt 72 ]] && width=72
  line="$(python3 -c "print('─'*${width})" 2>/dev/null || printf '%0.s─' $(seq 1 "$width"))"
  gum style --foreground "$CUI_C_DIM" "$line"
}

cui_spacer() { echo ""; }
cui_divider() { echo ""; cui_rule; echo ""; }

# ── Banner ────────────────────────────────────────────────────────────────────
# Nur einmal pro Session, ganz oben

cui_brand_header() {
  echo ""
  gum style \
    --bold \
    --foreground "$CUI_C_BRAND" \
    "CRKCACHY v${CRKCACHY_VERSION}"
  gum style --foreground "$CUI_C_MUTED" "$(msg banner.subtitle)"
  echo ""
}

# ── Section-Header (wie create-next-app Kategorien) ──────────────────────────

cui_section() {
  local title="$1"
  local sub="${2:-}"
  echo ""
  gum style --bold "$title"
  [[ -n "$sub" ]] && gum style --foreground "$CUI_C_MUTED" "$sub"
}

cui_panel() { cui_section "$@"; }

# ── Check-Tabellenzeile (wie Volta "Your toolchain:") ────────────────────────
# Argumente: state(ok|warn|fail) name value [detail]
# Ausgabe:   ✓  Steam               installiert     /home/.../Steam
#            ○  Spacewar (App 480)  fehlt           in Steam installieren

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

# Kategorie-Label (eingerückt, klein)
cui_check_category() {
  echo ""
  gum style --bold --foreground "$CUI_C_STEP" "  ${1}"
}

# ── Status-Chip ───────────────────────────────────────────────────────────────
# Abgerundete Box – nur für Gesamt-Ergebnis

cui_status_chip() {
  local ok="$1"
  local text="$2"
  echo ""
  if [[ "$ok" == true ]]; then
    gum style \
      --border rounded \
      --border-foreground "$CUI_C_SUCCESS" \
      --foreground "$CUI_C_SUCCESS" \
      --padding "0 1" \
      "$CUI_ICON_OK  ${text}"
  else
    gum style \
      --border rounded \
      --border-foreground "$CUI_C_WARNING" \
      --foreground "$CUI_C_WARNING" \
      --padding "0 1" \
      "$CUI_ICON_WARN  ${text}"
  fi
}

# ── Fortschrittsanzeige (wie create-next-app "Step 1 of 4") ──────────────────

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
  gum style --foreground "$CUI_C_STEP" \
    "  $(msgf ui.wizard_track "$step" "$total")   ${bar}"
  cui_rule
}

# ── Karte / Info-Box ─────────────────────────────────────────────────────────

cui_card() {
  local body="$1"
  local color="${2:-$CUI_C_MUTED}"
  gum style \
    --border rounded \
    --padding "1 2" \
    --foreground "$color" \
    "$body"
}

# ── Wizard-Screen (Info-Seite mit Weiter) ─────────────────────────────────────

cui_wizard_screen() {
  local step_num="$1"
  local step_total="$2"
  local title="$3"
  local body="$4"

  cui_progress_track "$step_num" "$step_total"
  echo ""
  gum style --bold "$title"
  echo ""
  cui_card "$body"
  echo ""
  cui_continue
}

cui_step_screen() { cui_wizard_screen "$@"; }

# ── Wizard-Intro (Trennlinie vor Intro-Screens) ───────────────────────────────

cui_wizard_intro() {
  echo ""
  cui_rule
  echo ""
  gum style --bold "$(msg install.legal_title)"
  echo ""
  gum style --foreground "$CUI_C_MUTED" "$(msg install.legal_teaser)"
  echo ""
}

# ── Haupt-Menü-Header ─────────────────────────────────────────────────────────
# Kompakt – kein doppelter Status-Chip wenn System bereit

cui_wizard_main_header() {
  local hint="$1"
  echo ""
  cui_rule
  gum style --bold "$(msg wizard.title)"
  echo ""
  if [[ "${ASSESS_SYSTEM_READY:-false}" == true ]]; then
    gum style --foreground "$CUI_C_MUTED" "$hint"
  else
    cui_status_chip false \
      "$(msgf wizard.status_fix "$(msgf assess.score "${ASSESS_OK:-0}" "${ASSESS_FAIL:-1}")")"
    echo ""
    gum style --foreground "$CUI_C_MUTED" "$hint"
  fi
  echo ""
}

# ── Zusammenfassung (Ende eines Flows) ───────────────────────────────────────
# Wie Volta/Bun: was wurde gemacht, was ist offen

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

# ── Interaktion ───────────────────────────────────────────────────────────────

cui_yes_no() {
  local prompt="$1"
  local default_no="${2:-true}"
  local selected=0
  [[ "$default_no" == "true" ]] && selected=1

  local pick
  pick="$(gum choose \
    --selected "$selected" \
    --header "$prompt" \
    --cursor "› " \
    "$(msg cui.choice_yes)" \
    "$(msg cui.choice_no)")"

  [[ "$pick" == "$(msg cui.choice_yes)" ]]
}

cui_continue() {
  gum choose \
    --selected 0 \
    --height 1 \
    --header "$(msg ui.press_enter)" \
    "$(msg ui.ok_label)"
}

# ── ARCHITEKTUR-REGEL: stdout-Capture-Sicherheit ─────────────────────────────
#
# SICHER mit selected="$(...)":
#   cui_choose, cui_filter, cui_choose_searchable, cui_input
#   → Nur der Auswahlwert geht an stdout; gum nutzt /dev/tty für das UI
#
# NIEMALS mit var="$(wrapper_func ...)" wenn die Funktion echo/log_*/
# cui_section o.ä. enthält → UI-Text landet im Wert!
#
# Muster für Wrapper-Funktionen:
#   wrapper_func args    # setzt globale Variable
#   var="$WRAPPER_VAR"
#
# Bekannte Wrapper → globale Variable:
#   tool_hub_pick_tool_slug  → TOOL_HUB_PICKED_SLUG
#   tool_hub_resolve_slug    → TOOL_HUB_PICKED_SLUG
#   tool_action_pick_menu    → TOOL_ACTION_PICKED
#
# ─────────────────────────────────────────────────────────────────────────────

cui_choose_searchable() { cui_filter "$@"; }

cui_input() {
  local placeholder="${1:-}"
  local default="${2:-}"
  gum input \
    --placeholder "$placeholder" \
    --value "$default" \
    --width 70 \
    --prompt "$(msg cui.input_prompt) "
}

cui_choose() {
  local header="$1"
  local selected_idx="$2"
  shift 2
  gum choose \
    --height "$#" \
    --selected "$selected_idx" \
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
  gum filter \
    --height "$height" \
    --header "$header" \
    --placeholder "$placeholder" \
    --indicator "› " \
    --prompt "🔍 " \
    "$@"
}

cui_spin() {
  local title="$1"
  shift
  gum spin --spinner dot --title "$title" -- "$@"
}

# ── Markdown ──────────────────────────────────────────────────────────────────

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

# ── Onboard-Gate ─────────────────────────────────────────────────────────────

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
  cui_card "$(msg install.legal_summary)" "$CUI_C_MUTED"
  echo ""
  if ! cui_yes_no "$(msg ui.legal_confirm)" false; then
    die "$(msg runtime.legal_abort)"
  fi

  cui_onboard_mark_done
}

# ── Sonstige Helper ───────────────────────────────────────────────────────────

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
  gum style --bold "$title"
  [[ -n "$intro" ]] && echo "" && echo "  $intro" && echo ""
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

# Legacy
cui_columns() { cui_section "$1"; cui_sub "$2"; }

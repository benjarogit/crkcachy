#!/usr/bin/env bash
# CRKCACHY prompter – Bash bridge to @clack/prompts (Node/TypeScript).
# Kein gum. Alle interaktiven Menüs laufen über lib/prompter/dist/cli.js

set -euo pipefail

CRK_PROMPTER_JS="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/prompter/dist/cli.js"

_crk_prompter_json() {
  python3 -c 'import json,sys; json.dump(json.loads(sys.argv[1]), sys.stdout)' "$1"
}

_crk_prompter_run() {
  local cmd="$1"
  local json="$2"
  local out rc tmp

  [[ -f "$CRK_PROMPTER_JS" ]] || {
    log_error "$(msg node.prompter_missing)"
    return 1
  }

  # JSON per Datei – stdin bleibt TTY für @clack/prompts (Pipe würde Eingabe kaputt machen)
  tmp="$(mktemp "${TMPDIR:-/tmp}/crkcachy.prompt.XXXXXX")"
  printf '%s' "$json" > "$tmp"

  if [[ "${CRKCACHY_DEBUG:-0}" == 1 ]]; then
    out="$(node "$CRK_PROMPTER_JS" "$cmd" --file "$tmp")" || rc=$?
  else
    out="$(node "$CRK_PROMPTER_JS" "$cmd" --file "$tmp" 2>/dev/null)" || rc=$?
  fi
  rm -f "$tmp"
  rc="${rc:-0}"

  if [[ "$rc" -ne 0 ]]; then
    return "$rc"
  fi

  printf '%s' "$out"
}

_crk_prompter_value() {
  local cmd="$1"
  local json="$2"
  local out val

  out="$(_crk_prompter_run "$cmd" "$json")" || return 1
  val="$(python3 -c 'import json,sys; d=json.loads(sys.argv[1]); v=d.get("value"); print("true" if v is True else "false" if v is False else v)' "$out" 2>/dev/null || true)"
  printf '%s' "$val"
}

crk_intro() {
  _crk_prompter_run intro "$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1]}))' "$1")" >/dev/null || true
}

crk_outro() {
  _crk_prompter_run outro "$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1]}))' "$1")" >/dev/null || true
}

crk_note() {
  local body="$1"
  local title="${2:-}"
  local json
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"title":sys.argv[2] or None}))' "$body" "$title")"
  _crk_prompter_run note "$json" >/dev/null || true
}

# Optionen: value|label|hint (hint optional)
crk_select() {
  local message="$1"
  local initial_value="${2:-}"
  shift 2
  local json
  json="$(python3 - "$message" "$initial_value" "$@" <<'PY'
import json, sys
message, initial, *rest = sys.argv[1:]
opts = []
for line in rest:
    parts = line.split("|", 2)
    if not parts:
        continue
    o = {"value": parts[0], "label": parts[1] if len(parts) > 1 else parts[0]}
    if len(parts) > 2 and parts[2]:
        o["hint"] = parts[2]
    opts.append(o)
payload = {"message": message, "options": opts}
if initial:
    payload["initialValue"] = initial
print(json.dumps(payload))
PY
)"
  _crk_prompter_value select "$json"
}

crk_autocomplete() {
  local message="$1"
  local initial_value="${2:-}"
  shift 2
  local json
  json="$(python3 - "$message" "$initial_value" "$@" <<'PY'
import json, sys
message, initial, *rest = sys.argv[1:]
opts = []
for line in rest:
    parts = line.split("|", 2)
    if not parts:
        continue
    o = {"value": parts[0], "label": parts[1] if len(parts) > 1 else parts[0]}
    if len(parts) > 2 and parts[2]:
        o["hint"] = parts[2]
    opts.append(o)
payload = {"message": message, "options": opts}
if initial:
    payload["initialValue"] = initial
print(json.dumps(payload))
PY
)"
  _crk_prompter_value autocomplete "$json"
}

crk_confirm() {
  local message="$1"
  local default_yes="${2:-false}"
  local json val
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"initialValueConfirm": sys.argv[2] in ("true","1","yes")}))' "$message" "$default_yes")"
  val="$(_crk_prompter_value confirm "$json")"
  [[ "$val" == "True" || "$val" == "true" ]]
}

crk_text() {
  local message="$1"
  local placeholder="${2:-}"
  local default="${3:-}"
  local json
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"placeholder":sys.argv[2],"defaultValue":sys.argv[3]}))' "$message" "$placeholder" "$default")"
  _crk_prompter_value text "$json"
}

crk_continue() {
  local message="${1:-$(msg ui.press_enter)}"
  local label="${2:-$(msg ui.ok_label)}"
  local json
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"title":sys.argv[2]}))' "$message" "$label")"
  _crk_prompter_run continue "$json" >/dev/null || true
}

# Gate-Menü: Titel + Body + crk_select (Werte: auto|manual|skip oder open|manual|skip)
crk_gate_menu() {
  local title="$1"
  local body="$2"
  local prompt="$3"
  shift 3
  echo ""
  cui_heading "$title"
  cui_sub "$body"
  echo ""
  crk_select "$prompt" "" "$@"
}

crk_spin() {
  local title="$1"
  shift
  local cmd="$*"
  local json
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"command":sys.argv[2]}))' "$title" "$cmd")"
  _crk_prompter_run spin "$json" >/dev/null
}

ensure_node() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    die "$(msg node.no_tty)"
  fi

  if command -v node >/dev/null 2>&1; then
    local ver
    ver="$(node -p "process.versions.node.split('.').map(Number)[0]" 2>/dev/null || echo 0)"
    if [[ "${ver:-0}" -ge 18 ]]; then
      return 0
    fi
    log_warn "$(msg node.version_old)"
  fi

  explain_block "$(msg node.missing_title)" "$(package_explain_text node)

$(msg pkg.explain.footer)"

  while ! command -v node >/dev/null 2>&1; do
    echo -e "${_C_BOLD}$(msg node.pick_title)${_C_RESET}"
    echo "  1) $(msg node.opt_auto)"
    echo "  2) $(msg node.opt_manual)"
    echo ""
    read -r -p "$(msg node.pick_prompt) " node_choice

    case "${node_choice:-1}" in
      1|j|y|ja|yes)
        log_hint "$(msg node.password_hint)"
        if _ensure_logical_repo_package nodejs; then
          hash -r 2>/dev/null || true
        else
          log_warn "$(msg node.install_failed)"
        fi
        if command -v node >/dev/null 2>&1; then
          log_ok "$(msg node.installed)"
          break
        fi
        log_warn "$(msg node.still_missing)"
        ;;
      2|n|no|nein)
        ;;
      *)
        log_warn "$(msg node.pick_invalid)"
        continue
        ;;
    esac

    echo ""
    log_hint "$(msg node.manual_steps_intro)"
    log_hint "$(platform_manual_install_cmd_logical nodejs)"
    echo ""
    read -r -p "$(msg node.manual_wait) " _
    hash -r 2>/dev/null || true

    if command -v node >/dev/null 2>&1; then
      log_ok "$(msg node.installed)"
      break
    fi

    log_warn "$(msg node.still_missing)"
    echo ""
  done
}

ensure_prompter() {
  ensure_node
  if [[ ! -f "$CRK_PROMPTER_JS" ]]; then
    die "$(msg node.prompter_missing)"
  fi
}

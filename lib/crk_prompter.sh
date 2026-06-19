#!/usr/bin/env bash
# CRKCACHY prompter – Bash bridge to @clack/prompts (Node/TypeScript). Kein Bash-Fallback.

set -euo pipefail

CRK_PROMPTER_JS="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/prompter/dist/cli.js"

_crk_prompter_prepare() {
  tput cnorm 2>/dev/null || true
  printf '\n'
}

_crk_has_interactive() {
  [[ -t 0 && -t 1 ]] && return 0
  [[ -t 1 && -r /dev/tty ]] && return 0
  [[ -r /dev/tty && -w /dev/tty ]] && return 0
  return 1
}

_crk_prompter_fail() {
  log_error "$(msg wizard.pick_failed)"
  return 1
}

_crk_prompter_parse_result() {
  local raw="$1"
  python3 -c '
import json, sys
raw = sys.argv[1].strip()
if not raw:
    sys.exit(2)
try:
    d = json.loads(raw)
except json.JSONDecodeError:
    sys.exit(3)
if not d.get("ok"):
    sys.exit(4)
v = d.get("value")
if v is True:
    print("true")
elif v is False:
    print("false")
elif v is None:
    print("")
else:
    print(v)
' "$raw"
}

_crk_prompter_run() {
  local cmd="$1"
  local json="$2"
  local rc=0 tmp err_file out

  [[ -f "$CRK_PROMPTER_JS" ]] || {
    log_error "$(msg node.prompter_missing)"
    return 1
  }

  if ! _crk_has_interactive; then
    log_error "$(msg node.no_tty)"
    return 1
  fi

  tmp="$(mktemp "${TMPDIR:-/tmp}/crkcachy.prompt.XXXXXX")"
  err_file="${tmp}.err"
  printf '%s' "$json" > "$tmp"

  if [[ -t 0 && -t 1 ]]; then
    node "$CRK_PROMPTER_JS" "$cmd" --file "$tmp" 2>"$err_file" || rc=$?
  else
    node "$CRK_PROMPTER_JS" "$cmd" --file "$tmp" 0</dev/tty > /dev/tty 2>"$err_file" || rc=$?
  fi
  tput cnorm 2>/dev/null || true
  out="$(cat "$err_file" 2>/dev/null || true)"
  rm -f "$tmp" "$err_file"

  if [[ "$rc" -ne 0 ]]; then
    if [[ "${CRKCACHY_DEBUG:-0}" == 1 && -n "$out" ]]; then
      log_debug "prompter: $out"
    fi
    return "$rc"
  fi

  if [[ -z "$out" ]]; then
    return 1
  fi

  printf '%s' "$out"
  return 0
}

_crk_prompter_value() {
  local cmd="$1"
  local json="$2"
  local out val rc=0

  _crk_prompter_prepare
  out="$(_crk_prompter_run "$cmd" "$json")" || rc=$?
  if [[ "$rc" -ne 0 || -z "$out" ]]; then
    return 1
  fi

  val="$(_crk_prompter_parse_result "$out")" || return 1
  printf '%s' "$val"
}

_crk_build_select_json() {
  local message="$1"
  local placeholder="${2:-}"
  local initial_value="${3:-}"
  shift 3
  python3 - "$message" "$placeholder" "$initial_value" "$@" <<'PY'
import json, sys
message, placeholder, initial, *rest = sys.argv[1:]
opts = []
for line in rest:
    parts = line.split("|", 2)
    if not parts:
        continue
    label = parts[1] if len(parts) > 1 and parts[1] else parts[0]
    o = {"value": parts[0], "label": label}
    if len(parts) > 2 and parts[2]:
        o["hint"] = parts[2]
    opts.append(o)
payload = {"message": message, "options": opts}
if placeholder:
    payload["placeholder"] = placeholder
if initial:
    payload["initialValue"] = initial
print(json.dumps(payload))
PY
}

crk_intro() {
  local json
  _crk_prompter_prepare
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1]}))' "$1")"
  _crk_prompter_run intro "$json" >/dev/null || _crk_prompter_fail
}

crk_outro() {
  local json
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1]}))' "$1")"
  _crk_prompter_run outro "$json" >/dev/null || _crk_prompter_fail
}

crk_note() {
  local body="$1"
  local title="${2:-}"
  local json
  _crk_prompter_prepare
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"title":sys.argv[2] or None}))' "$body" "$title")"
  _crk_prompter_run note "$json" >/dev/null || _crk_prompter_fail
}

crk_select() {
  local message="$1"
  local initial_value="${2:-}"
  shift 2
  local json val

  json="$(_crk_build_select_json "$message" "" "$initial_value" "$@")"
  val="$(_crk_prompter_value select "$json")" || _crk_prompter_fail || return 1
  printf '%s' "$val"
}

crk_autocomplete() {
  local message="$1"
  local placeholder="${2:-}"
  local initial_value="${3:-}"
  shift 3
  local json val

  json="$(_crk_build_select_json "$message" "$placeholder" "$initial_value" "$@")"
  val="$(_crk_prompter_value autocomplete "$json")" || _crk_prompter_fail || return 1
  printf '%s' "$val"
}

crk_confirm() {
  local message="$1"
  local default_yes="${2:-false}"
  local json val

  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"initialValueConfirm": sys.argv[2] in ("true","1","yes")}))' "$message" "$default_yes")"
  val="$(_crk_prompter_value confirm "$json")" || _crk_prompter_fail || return 1
  [[ "$val" == "true" ]]
}

crk_text() {
  local message="$1"
  local placeholder="${2:-}"
  local default="${3:-}"
  local json val

  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"placeholder":sys.argv[2],"defaultValue":sys.argv[3]}))' "$message" "$placeholder" "$default")"
  val="$(_crk_prompter_value text "$json")" || _crk_prompter_fail || return 1
  printf '%s' "$val"
}

crk_continue() {
  local message="${1:-$(msg ui.press_enter)}"
  local label="${2:-$(msg ui.ok_label)}"
  local json

  _crk_prompter_prepare
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"title":sys.argv[2]}))' "$message" "$label")"
  _crk_prompter_run continue "$json" >/dev/null || _crk_prompter_fail
}

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
  _crk_prompter_run spin "$json" >/dev/null || _crk_prompter_fail
}

crk_print_deps_hint() {
  local marker="${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/.deps_hint_v${CRKCACHY_VERSION}"
  [[ -f "$marker" ]] && return 0
  mkdir -p "$(dirname "$marker")"
  touch "$marker"
}

ensure_node() {
  if ! _crk_has_interactive; then
    die "$(msg node.no_tty)"
  fi

  if command -v node >/dev/null 2>&1; then
    local ver
    ver="$(node -p "process.versions.node.split('.').map(Number)[0]" 2>/dev/null || echo 0)"
    if [[ "${ver:-0}" -ge 18 ]]; then
      return 0
    fi
    die "$(msg node.version_old)"
  fi

  explain_block "$(msg node.missing_title)" "$(package_explain_text nodejs)

$(msg pkg.explain.footer)"
  echo ""
  log_hint "$(msg node.password_hint)"

  if _ensure_logical_repo_package nodejs; then
    hash -r 2>/dev/null || true
  else
    log_warn "$(msg node.install_failed)"
  fi

  if command -v node >/dev/null 2>&1; then
    local ver
    ver="$(node -p "process.versions.node.split('.').map(Number)[0]" 2>/dev/null || echo 0)"
    if [[ "${ver:-0}" -ge 18 ]]; then
      log_ok "$(msg node.installed)"
      return 0
    fi
  fi

  die "$(msg node.still_missing)

$(msg node.manual_steps_intro)
$(platform_manual_install_cmd_logical nodejs)"
}

ensure_prompter() {
  ensure_node
  if [[ ! -f "$CRK_PROMPTER_JS" ]]; then
    die "$(msg node.prompter_missing)"
  fi
}

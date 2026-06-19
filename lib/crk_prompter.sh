#!/usr/bin/env bash
# CRKCACHY prompter – Bash bridge to @clack/prompts (Node/TypeScript).

set -euo pipefail

CRK_PROMPTER_JS="${CRKCACHY_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}/lib/prompter/dist/cli.js"

_crk_prompter_prepare() {
  tput cnorm 2>/dev/null || true
  printf '\n'
}

_crk_prompt_need_tty() {
  if [[ ! -t 0 || ! -t 1 ]]; then
    log_error "$(msg node.no_tty)"
    return 1
  fi
  return 0
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

  tmp="$(mktemp "${TMPDIR:-/tmp}/crkcachy.prompt.XXXXXX")"
  err_file="${tmp}.err"
  printf '%s' "$json" > "$tmp"

  node "$CRK_PROMPTER_JS" "$cmd" --file "$tmp" 2>"$err_file" || rc=$?
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

# Fallback: nummeriertes Bash-Menü (value|label Zeilen)
_crk_bash_pick() {
  local message="$1"
  local initial_value="${2:-}"
  shift 2
  local -a keys=() labels=()
  local line key label i pick idx

  echo ""
  printf '%b%s%b\n' "${_C_BOLD}" "$message" "${_C_RESET}"
  i=1
  for line in "$@"; do
    key="${line%%|*}"
    label="${line#*|}"
    keys+=("$key")
    labels+=("$label")
    printf '  %2d) %s\n' "$i" "$label"
    i=$((i + 1))
  done
  echo ""

  if [[ -n "$initial_value" ]]; then
    for idx in "${!keys[@]}"; do
      if [[ "${keys[$idx]}" == "$initial_value" ]]; then
        printf '%b' "${_C_DIM}"
        printf '  (Enter = %s)\n' "${labels[$idx]}"
        printf '%b' "${_C_RESET}"
        break
      fi
    done
  fi

  read -r -p "$(msg ui.bash_pick_prompt) " pick
  if [[ -z "${pick:-}" && -n "$initial_value" ]]; then
    printf '%s' "$initial_value"
    return 0
  fi

  if [[ "${pick:-}" =~ ^[0-9]+$ ]] && (( pick >= 1 && pick <= ${#keys[@]} )); then
    printf '%s' "${keys[$((pick - 1))]}"
    return 0
  fi

  return 1
}

_crk_prompter_value() {
  local cmd="$1"
  local json="$2"
  local out val rc=0

  if ! _crk_prompt_need_tty; then
    return 1
  fi

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
  _crk_prompter_prepare
  _crk_prompter_run intro "$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1]}))' "$1")" >/dev/null || true
}

crk_outro() {
  _crk_prompter_run outro "$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1]}))' "$1")" >/dev/null || true
}

crk_note() {
  local body="$1"
  local title="${2:-}"
  local json
  _crk_prompter_prepare
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"title":sys.argv[2] or None}))' "$body" "$title")"
  _crk_prompter_run note "$json" >/dev/null || true
}

crk_select() {
  local message="$1"
  local initial_value="${2:-}"
  shift 2
  local json val

  json="$(_crk_build_select_json "$message" "" "$initial_value" "$@")"
  val="$(_crk_prompter_value select "$json")" || val="$(_crk_bash_pick "$message" "$initial_value" "$@")" || return 1
  printf '%s' "$val"
}

crk_autocomplete() {
  local message="$1"
  local placeholder="${2:-}"
  local initial_value="${3:-}"
  shift 3
  local json val

  json="$(_crk_build_select_json "$message" "$placeholder" "$initial_value" "$@")"
  val="$(_crk_prompter_value autocomplete "$json")" || val="$(_crk_bash_pick "$message" "$initial_value" "$@")" || return 1
  printf '%s' "$val"
}

crk_confirm() {
  local message="$1"
  local default_yes="${2:-false}"
  local json val rc=0 prompt

  if ! _crk_prompt_need_tty; then
    return 1
  fi

  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"initialValueConfirm": sys.argv[2] in ("true","1","yes")}))' "$message" "$default_yes")"
  val="$(_crk_prompter_value confirm "$json")" || rc=$?

  if [[ "$rc" -eq 0 ]]; then
    [[ "$val" == "true" ]]
    return
  fi

  _crk_prompter_prepare
  if [[ "$default_yes" == true ]]; then
    prompt="$(msg ui.confirm_yes_default)"
  else
    prompt="$(msg ui.confirm_no_default)"
  fi
  read -r -p "$prompt " answer
  case "${answer:-}" in
    j|J|y|Y|ja|yes) return 0 ;;
    n|N|no|nein) return 1 ;;
    "")
      [[ "$default_yes" == true ]]
      ;;
    *)
      return 1
      ;;
  esac
}

crk_text() {
  local message="$1"
  local placeholder="${2:-}"
  local default="${3:-}"
  local json val

  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"placeholder":sys.argv[2],"defaultValue":sys.argv[3]}))' "$message" "$placeholder" "$default")"
  val="$(_crk_prompter_value text "$json")" || {
    _crk_prompter_prepare
    read -r -p "$message " val
    val="${val:-$default}"
  }
  printf '%s' "$val"
}

crk_continue() {
  local message="${1:-$(msg ui.press_enter)}"
  local label="${2:-$(msg ui.ok_label)}"
  local json

  _crk_prompter_prepare
  json="$(python3 -c 'import json,sys; print(json.dumps({"message":sys.argv[1],"title":sys.argv[2]}))' "$message" "$label")"
  if _crk_prompter_run continue "$json" >/dev/null; then
    return 0
  fi
  echo ""
  read -r -p "${label} … " _
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
  if _crk_prompter_run spin "$json" >/dev/null; then
    return 0
  fi
  log_info "$title …"
  eval "$cmd"
}

crk_print_deps_hint() {
  local marker="${CRKCACHY_CACHE_ROOT:-${HOME}/.local/share/crkcachy}/.deps_hint_v${CRKCACHY_VERSION}"
  [[ -f "$marker" ]] && return 0
  echo ""
  crk_note "$(msg runtime.deps_cleanup)"
  mkdir -p "$(dirname "$marker")"
  touch "$marker"
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

  explain_block "$(msg node.missing_title)" "$(package_explain_text nodejs)

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
